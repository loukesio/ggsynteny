"""Check the standalone gallery and dataset uploads in a running Studio.

GG_SYNTENY_URL defaults to http://127.0.0.1:3876.
"""
import json
import os
from pathlib import Path

from playwright.sync_api import sync_playwright, expect

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "dev/public-health/validation"
OUT.mkdir(exist_ok=True)
checks, errors = [], []

with sync_playwright() as pw:
    browser = pw.chromium.launch(channel="chrome", headless=True)
    page = browser.new_page(viewport={"width": 1400, "height": 1050})
    page.on("pageerror", lambda e: errors.append(str(e)))
    page.goto((ROOT / "dev/public-health/gallery/index.html").as_uri())
    expect(page.locator("svg.ggiraph-svg")).to_have_count(7)
    for i in range(7):
        svg = page.locator("svg.ggiraph-svg").nth(i)
        svg.scroll_into_view_if_needed()
        assert svg.locator("[data-id]").count() > 5
        svg.locator('[data-id^="gene_"], [data-id^="chr_"], rect[data-id]').first.hover(force=True)
        page.wait_for_function("Array.from(document.querySelectorAll('div[class^=tooltip_svg_]')).some(e => parseFloat(getComputedStyle(e).opacity) > 0 && e.textContent.length > 0)")
        if i >= 4:
            visible_tooltips = page.locator('div[class^="tooltip_svg_"]').evaluate_all(
                "els => els.filter(e => parseFloat(getComputedStyle(e).opacity) > 0).map(e => e.textContent)")
            assert any("Block ranks (not bp)" in t for t in visible_tooltips)
        matrix = "el => {const m=el.querySelector('g[id$=\"_rootg\"]').getCTM();return [m.a,m.b,m.c,m.d,m.e,m.f].join(',')}"
        before = svg.evaluate(matrix)
        box = svg.bounding_box()
        page.mouse.move(box["x"]+box["width"]/2, box["y"]+box["height"]/2)
        page.mouse.wheel(0, -300)
        page.wait_for_timeout(400)
        assert svg.evaluate(matrix) != before, "Zoom did not change the viewport"
        checks.append(f"standalone gallery panel {i+1}: SVG, tooltip and zoom")
        print(checks[-1], flush=True)
    page.screenshot(path=str(OUT / "gallery.png"))

    page.goto(os.environ.get("GG_SYNTENY_URL", "http://127.0.0.1:3876"), wait_until="networkidle")
    page.locator('input[name="source"][value="upload"]').check()

    def select(name, value):
        page.evaluate("([id,value]) => document.getElementById(id).selectize.setValue(value)", [name, value])

    def ready(count):
        page.wait_for_function("!document.documentElement.classList.contains('shiny-busy')")
        expect(page.locator("#data_status")).to_contain_text("Data ready")
        expect(page.locator(".metric").nth(2).locator("strong")).to_have_text(str(count))
        assert not page.locator(".shiny-output-error").all_text_contents()

    # Studio retains non-adjacent gene links in linear views. The curated
    # figure script restricts these explicitly, while macro selection is built in.
    for dataset, counts in [("bartonella", {"native": (111, 215), "genes": (46, 46)}),
                            ("plasmids", {"native": (6, 8), "genes": (31, 31)}),
                            ("anopheles", {"native": (380, 380)})]:
        for format, pair_counts in counts.items():
            select("format", format)
            names = ["chromosomes.tsv", "blocks.tsv"] if format == "native" else ["features.tsv", "links.tsv"]
            for i, filename in enumerate(names, 1):
                page.locator(f"#file_{format}_{i}").set_input_files(ROOT / "inst/extdata/public-health" / dataset / filename)
            for layout, count in zip(["linear", "circular"], pair_counts):
                page.locator(f'input[name="layout"][value="{layout}"]').check()
                ready(count)
                if format == "native":
                    page.locator("#orientation").check()
                page.locator("#interactive").uncheck()
                page.wait_for_function("document.querySelector('#plot img')?.naturalWidth > 0")
                page.locator("#interactive").check()
                page.wait_for_selector("#interactive_plot svg [data-id]", state="visible")
                ready(count)
                checks.append(f"{dataset} {format} {layout}: upload, static and interactive")
            with page.expect_download() as event:
                page.locator("#pdf").click()
            pdf = OUT / f"studio-{dataset}-{format}.pdf"
            event.value.save_as(pdf)
            assert pdf.read_bytes().startswith(b"%PDF-")
            page.locator("#interactive").uncheck()
    assert not errors, errors
    browser.close()

(OUT / "browser-results.json").write_text(json.dumps({"passed": checks, "javascript_errors": errors}, indent=2)+"\n")
print(json.dumps({"passed": len(checks), "checks": checks}, indent=2))
