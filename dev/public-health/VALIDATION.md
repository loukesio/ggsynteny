# Validation — 2026-09-17

Branch: `examples/public-health-bacteria`, based on main at `b4173b4`.
All package implementation files under `R/`, DESCRIPTION and NAMESPACE match
that baseline. The existing release and palette definitions are unchanged.

## Anopheles extension — 17 September 2026

The public dataset now also contains seven Anopheles files: the unchanged
published spreadsheet, four TSV tables, provenance JSON and reuse/methods notes.
The main manuscript draft is not part of this public branch.

| Check | Result |
|---|---|
| Source and conversion | Original workbook SHA-256 verified; all five arm counts match Jiang et al. Fig. 7; all 380 signed blocks reconstruct exactly from the plotting tables |
| Reproducibility | Four TSVs and provenance JSON regenerate byte-identically |
| Studio import/render | 20 combinations passed: the original 16 plus four Anopheles native-table combinations |
| Chrome gallery | All seven widgets passed SVG, hover and zoom checks; the three Anopheles widgets identify block-rank units in tooltips |
| Chrome Studio uploads | Ten dataset/format/layout workflows passed static and interactive rendering; five PDF downloads verified |
| Browser errors | Zero JavaScript errors across all 17 gallery/upload scenarios |
| Graphics | Three new individual views and the composite inspected; their PDFs and the eleven-page combined PDF have no text outside page boundaries |
| Existing bacterial graphics | PNGs unchanged; all eight regenerated PDFs rendered identically, and the original PDF bytes were retained |
| Source package | Build succeeded; all seven Anopheles dataset files match the checkout byte for byte inside the tarball |
| Core scope | Package implementation, palette definitions, DESCRIPTION and NAMESPACE unchanged from b4173b4; no new release |

The first browser run exposed a test selector that only recognized circular
chromosome identifiers; it was extended to recognize the linear rectangle
layers. The final complete run passed. No package behavior was changed.
The historical package-test result below was not rerun for this data-only
extension. This validation does not establish comparative runtime performance
or independently validate every rearrangement in the source study.

Reproduce the new conversion with
`python3 data-raw/public-health/prepare_anopheles.py`, followed by the shared
rendering, R validation and browser scripts listed below. The Anopheles source
limits and block-rank units are documented in its data-directory README.

## Original bacterial examples — recorded checks

| Check | Result |
|---|---|
| Preparation from versioned records | Seven complete circular sequence records parsed; source-file SHA-256 locks verified |
| Reproducibility | All 19 bundled result/documentation files byte-identical after regenerating the tables |
| Data validation | Reference lengths, coordinate bounds, pair coverage, feature uniqueness, protein coverage and link endpoints passed |
| Studio rendering through its actual import/selection path | All 16 dataset × format × layout × static/interactive combinations passed |
| Standalone HTML in Chrome | Four widgets rendered, with working hover tooltips and scroll zoom |
| Studio uploads in Chrome | Both datasets passed static and interactive linear/circular rendering at both data levels; four PDF downloads verified |
| Browser errors | Zero JavaScript errors across 12 scenarios |
| Figures | Eight PNGs visually inspected; eight individual PDFs and the combined eight-page PDF have no text outside page boundaries |
| Package tests | Existing testthat suite passed; no failures |
| Source package build | Successful; all 19 new data files match the source checkout byte for byte inside the tarball |
| Repository checks | Local documentation links resolve; `git diff --check` passes |

The curated linear gene figures contain adjacent-pair links (24 Bartonella,
21 plasmid links). Studio's current linear gene view retains all uploaded
gene links (46 and 31 respectively). Both behaviors were checked; this branch
does not change the app's selection rules.

Validation used macOS, R 4.5.1, Python 3.12.12, Biopython 1.86, BLAST+ 2.16.0+
and Chrome. The installed testthat, ggplot2 and Shiny binaries report that
they were built under R 4.5.2; the Shiny warning also appears in the existing
test suite. Fontconfig reports an unwritable default cache during rendering;
the Cairo outputs and browser figures were successfully generated and inspected.
No GitHub OS matrix or new release was run for this examples-only branch.

Re-run:

```sh
python3 data-raw/public-health/prepare.py
python3 data-raw/public-health/prepare_anopheles.py
Rscript data-raw/public-health/render.R
Rscript data-raw/public-health/validate.R
python3 dev/public-health/browser_checks.py
```

The browser script expects Studio on `http://127.0.0.1:3876`, or a URL supplied
through `GG_SYNTENY_URL`. Full logs, screenshots, session details and downloaded
test PDFs are retained locally in the ignored `dev/public-health/validation/`.
