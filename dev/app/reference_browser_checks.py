from pathlib import Path
import os
from playwright.sync_api import sync_playwright, expect
out = Path(__file__).resolve().parent / 'validation' / 'reference'; out.mkdir(parents=True, exist_ok=True)
with sync_playwright() as p:
    browser = p.chromium.launch(channel='chrome', headless=True)
    page = browser.new_page(viewport={'width':1440,'height':1300}, device_scale_factor=1)
    errors=[]
    page.on('pageerror', lambda e: errors.append(str(e)))
    page.goto(os.environ.get('GG_SYNTENY_URL', 'http://127.0.0.1:3881/') + '#reference', wait_until='networkidle')
    page.locator('a[data-value="Reference comparison"]').click()
    page.wait_for_selector('.reference-ring-svg .ref-mark')
    page.wait_for_function("document.fonts.check('12px \"IBM Plex Mono\"') && document.fonts.check('12px \"IBM Plex Sans\"')")
    expect(page.locator('.ref-event-row')).to_have_count(12)
    assert page.locator('.ref-identity-window').count() > 700
    page.locator('#reference_comparison-show_identity').uncheck()
    expect(page.locator('.ref-identity-window')).to_have_count(0)
    page.locator('#reference_comparison-show_identity').check()
    page.wait_for_selector('.ref-identity-window')
    expect(page.locator('.ref-center-main')).to_have_text('4.800 Mb')
    expect(page.locator('.ref-center-caption')).to_have_text('Example reference · REFERENCE')
    def move_on_plot(radius, position):
        point = page.locator('.reference-ring-svg').evaluate("(svg,[r,pos]) => {const a=-Math.PI/2+.075+pos/Number(svg.dataset.length)*(2*Math.PI-.15);const p=new DOMPoint(r*Math.cos(a),r*Math.sin(a)).matrixTransform(svg.getScreenCTM());return {x:p.x,y:p.y};}",[radius,position])
        page.mouse.move(point['x'],point['y'])
    move_on_plot(195,1234567)
    expect(page.locator('.ref-center-main')).to_have_text('1,234,567 bp')
    expect(page.locator('.ref-center-caption')).to_have_text('POSITION ON REFERENCE')
    expect(page.locator('.ref-spoke')).to_have_attribute('visibility','visible')
    page.screenshot(path=str(out/'hover.png'),full_page=True)
    for radius in [0,120,170,400]:
        move_on_plot(radius,1234567)
        expect(page.locator('.ref-center-main')).to_have_text('4.800 Mb')
        expect(page.locator('.ref-spoke')).to_have_attribute('visibility','hidden')
    assert page.locator('.ref-center-readout').evaluate("e=>getComputedStyle(e).pointerEvents") == 'none'
    page.locator('.ref-data-controls > summary').click()
    long_name='Very long reference sequence name with an assembly accession and chromosome designation'
    page.locator('#reference_comparison-reference').fill(long_name)
    expect(page.locator('.ref-center-caption')).to_have_text(long_name+' · REFERENCE',timeout=30000)
    page.wait_for_function("Array.from(document.querySelectorAll('.ref-center-readout text')).every(t=>t.getBBox().width <= 1.6*121+.1)")
    page.locator('#reference_comparison-reference').fill('Example reference')
    expect(page.locator('.ref-center-caption')).to_have_text('Example reference · REFERENCE',timeout=30000)
    page.locator('.ref-data-controls > summary').click()
    page.screenshot(path=str(out/'desktop.png'),full_page=True)
    page.locator('.ref-event-row').nth(2).click()
    expect(page.locator('.ref-locus-state').filter(has_text='Insertion')).to_have_count(3)
    move_on_plot(195,1234567)
    expect(page.locator('.ref-cursor-pos')).to_have_text('1,234,567 bp')
    before=page.locator('.ref-event-dot').first.get_attribute('style')
    page.evaluate("document.getElementById('reference_comparison-palette').selectize.setValue('casa_natal')")
    page.wait_for_function("document.querySelector('.ref-event-dot').getAttribute('style').includes('#245E55')")
    assert before != page.locator('.ref-event-dot').first.get_attribute('style')
    page.locator('input[name="reference_comparison-types"][value="INS"]').uncheck()
    expect(page.locator('.ref-event-row')).to_have_count(8)
    page.evaluate("document.getElementById('reference_comparison-palette').selectize.setValue('minou')")
    expect(page.locator('input[name="reference_comparison-types"][value="INS"]')).not_to_be_checked()
    page.locator('input[name="reference_comparison-types"][value="INS"]').check()
    page.evaluate("document.getElementById('reference_comparison-samples').selectize.setValue(['Genome A'])")
    expect(page.locator('#reference_comparison-status')).to_contain_text('4 supplied calls')
    for key, name in [('pdf','comparison.pdf'),('png','comparison.png'),('table','variants.tsv'),('identity_table','identity-windows.tsv'),('code','reproduce.R')]:
        with page.expect_download() as event:
            page.locator('#reference_comparison-'+key).click()
        event.value.save_as(out/name)
        assert (out/name).stat().st_size > 0
    page.evaluate("document.getElementById('reference_comparison-samples').selectize.setValue(['Genome A','Genome B','Genome C','Genome D','Genome E'])")
    expect(page.locator('#reference_comparison-status')).to_contain_text('23 supplied calls')
    page.set_viewport_size({'width':390,'height':844})
    page.screenshot(path=str(out/'mobile.png'),full_page=True)
    assert page.evaluate('document.documentElement.scrollWidth <= window.innerWidth+2')
    for checkbox in page.locator('input[name="reference_comparison-types"]').all(): checkbox.uncheck()
    expect(page.locator('#reference_comparison-status')).to_contain_text('0 supplied calls', timeout=30000)
    assert page.locator('.reference-ring-svg').count()==1
    assert not errors, errors
    browser.close()
print('PASS: exact centre positions, rest/reset, ring-only hover, long-name width bound, layout, filters and exports; no browser errors')
