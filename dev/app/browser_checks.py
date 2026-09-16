"""Run with an app listening on GG_SYNTENY_URL (default localhost:3876)."""
from pathlib import Path
import csv
import json
import os
from playwright.sync_api import sync_playwright, expect

root = Path(__file__).resolve().parents[2]
out = root / "dev/app/validation"
out.mkdir(parents=True, exist_ok=True)
checks = []

with sync_playwright() as p:
    browser = p.chromium.launch(channel="chrome", headless=True)
    page = browser.new_page(viewport={"width": 1440, "height": 1120}, device_scale_factor=1)
    errors = []
    page.on("pageerror", lambda e: errors.append(str(e)))
    page.goto(os.environ.get("GG_SYNTENY_URL", "http://127.0.0.1:3876"), wait_until="networkidle")

    def ready(links=None):
        page.wait_for_function("!document.documentElement.classList.contains('shiny-busy')")
        expect(page.locator("#data_status")).to_contain_text("Data ready")
        page.wait_for_function("document.querySelector('#plot img')?.naturalWidth > 0")
        if links is not None:
            expect(page.locator(".metric").nth(2).locator("strong")).to_have_text(str(links))
        assert not page.locator(".shiny-output-error").all_text_contents()

    def select(id, value):
        page.evaluate("([id,value]) => document.getElementById(id).selectize.setValue(value)", [id, value])

    def download(id, filename):
        with page.expect_download() as event:
            page.locator("#" + id).click()
        event.value.save_as(out / filename)
        assert (out / filename).stat().st_size > 0

    ready(9)
    page.screenshot(path=str(root / "man/figures/README-studio.png"))
    download("pdf", "studio.pdf")
    download("png", "studio.png")
    assert (out / "studio.pdf").read_bytes().startswith(b"%PDF-")
    assert (out / "studio.png").read_bytes().startswith(b"\x89PNG")
    download("code", "reproduce-synteny.R")
    download("first_tsv", "features.tsv")
    page.get_by_role("tab", name="Links", exact=True).click()
    download("second_tsv", "links.tsv")
    page.get_by_role("tab", name="Pair summary", exact=True).click()
    download("summary_tsv", "pairs.tsv")
    with (out / "features.tsv").open() as f:
        assert len(list(csv.DictReader(f, delimiter="\t"))) == 21
    with (out / "links.tsv").open() as f:
        assert len(list(csv.DictReader(f, delimiter="\t"))) == 9
    checks.append("PDF, PNG, tables, pair summary and R-script downloads")

    for format, count in [("native", 100), ("mcscanx", 2), ("genespace", 4), ("genes", 9)]:
        select("format", format)
        ready(count)
        for layout in ["linear", "circular"]:
            page.locator(f'input[name="layout"][value="{layout}"]').check()
            expect(page.locator("#plot_heading")).to_contain_text(layout.capitalize())
            ready(count)
        checks.append(format + " example in both layouts")

    select("palette", "minou")
    expect(page.locator(".palette-preview")).to_have_attribute("aria-label", "minou palette")
    select("organisms", ["ZONMW-30", "ZONMW-20"])
    ready(4)
    page.locator("#limit").fill("2")
    page.locator("#limit").press("Tab")
    ready(2)
    expect(page.locator("#plot_note")).to_contain_text("2 of 4")
    checks.append("palette, genome subset and explicit link cap")

    page.locator('input[name="source"][value="upload"]').check()
    expect(page.locator("#data_status")).to_contain_text("Upload")
    page.locator("#file_genes_1").set_input_files(root / "inst/extdata/circular_bacterial_features.tsv")
    page.locator("#file_genes_2").set_input_files(root / "inst/extdata/circular_bacterial_links.tsv")
    page.locator("#limit").fill("1000")
    page.locator("#limit").press("Tab")
    ready(9)
    bad = out / "bad-links.tsv"
    bad.write_text("feat_id_a\tfeat_id_b\nunknown\tmissing\n")
    page.locator("#file_genes_2").set_input_files(bad)
    expect(page.locator("#data_status")).to_contain_text("unknown gene")
    expect(page.locator("#plot")).to_contain_text("unknown gene")
    page.locator("#file_genes_2").set_input_files(root / "inst/extdata/circular_bacterial_links.tsv")
    ready(9)
    checks.append("gene uploads, invalid upload clears old plot, and recovery")

    uploads = {
        "native": ["chromosomes.tsv", "synteny_blocks.tsv"],
        "mcscanx": ["mcscanx_output.collinearity", "mcscanx_output.gff"],
        "genespace": ["genespace_synHits.tsv"],
    }
    for format, names in uploads.items():
        select("format", format)
        expect(page.locator("#data_status")).to_contain_text("Upload")
        for i, name in enumerate(names, 1):
            page.locator(f"#file_{format}_{i}").set_input_files(root / "inst/extdata" / name)
        ready({"native": 3, "mcscanx": 2, "genespace": 4}[format])
        checks.append(format + " uploaded files")

    page.locator('input[name="source"][value="demo"]').check()
    select("format", "genes")
    ready(9)
    page.set_viewport_size({"width": 390, "height": 844})
    page.wait_for_function("!document.documentElement.classList.contains('shiny-busy')")
    assert page.evaluate("document.documentElement.scrollWidth <= window.innerWidth + 1")
    page.screenshot(path=str(out / "mobile.png"), full_page=True)
    checks.append("mobile layout has no page-wide horizontal overflow")
    assert not errors, errors
    browser.close()

(out / "browser-results.json").write_text(json.dumps({"passed": checks, "javascript_errors": errors}, indent=2))
print(json.dumps({"passed": len(checks), "checks": checks}, indent=2))
