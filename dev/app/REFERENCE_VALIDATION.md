# Reference comparison integration - 24 September 2026

Verified the proposed changes in an isolated checkout based on main at
`3e137d6`, without merging the manuscript branch.

- R package check: 0 errors, 0 warnings, 0 notes; examples and vignettes pass.
- Full test suite: 497 passing expectations, no failures or skipped tests.
  The test log contains a local environment warning because Shiny was built
  under R 4.5.2 and the local R is 4.5.1; this is not a package-check warning.
- Reference browser checks: exact 1,234,567 bp hover readout; reference label
  restored outside the rings; transparent centre ignores mouse events;
  long centre text fits the required width; identity toggle, palette changes,
  genome and event filters, desktop/mobile layout and all downloads pass.
- Existing Studio browser checks: all 12 groups pass, including the four
  input formats, linear/circular views, interactive plots, uploads, validation,
  downloads and mobile layout. Neither browser suite reports JavaScript errors.
- The README code was extracted verbatim and run using the checked, installed
  package. It reads both bundled example tables and writes PDF and PNG.
  The README figure was regenerated and visually inspected; the legend rows
  align and the reference name/size remain inside the ruler.
- pkgdown reference pages and README home page build successfully.
- Static examples and all demonstration numbers are labelled as invented.

Reproduce from the package root:

```r
devtools::check(document = FALSE, manual = FALSE)
```

Start Studio, then run both browser scripts with its address:

```sh
GG_SYNTENY_URL=http://127.0.0.1:3882/ python3 dev/app/reference_browser_checks.py
GG_SYNTENY_URL=http://127.0.0.1:3882 python3 dev/app/browser_checks.py
Rscript data-raw/reference_readme_figure.R
```

This verifies local macOS behavior. GitHub's operating-system matrix runs
after publication. The separately hosted Posit Studio remains pinned to its
existing commit until its manifest is regenerated and the app is redeployed.
The preparation script now includes the optional font export dependencies.
