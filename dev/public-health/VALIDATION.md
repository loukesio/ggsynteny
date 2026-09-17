# Validation — 2026-09-17

Branch: `examples/public-health-bacteria`, based on main at `b4173b4`.
All package implementation files under `R/`, DESCRIPTION and NAMESPACE match
that baseline. The existing release and palette definitions are unchanged.

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
Rscript data-raw/public-health/render.R
Rscript data-raw/public-health/validate.R
python3 dev/public-health/browser_checks.py
```

The browser script expects Studio on `http://127.0.0.1:3876`, or a URL supplied
through `GG_SYNTENY_URL`. Full logs, screenshots, session details and downloaded
test PDFs are retained locally in the ignored `dev/public-health/validation/`.
