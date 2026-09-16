# ggsynteny Studio

The optional Shiny app is included in ggsynteny 0.5.0. Install `shiny`, then
run `ggsynteny::ggsynteny_app()`. In a source checkout, first run
`devtools::load_all(".")` from the package root.

Studio reads existing MCScanX, GENESPACE, native chromosome/block tables, and
gene/link tables. It does not run the external analysis programs. Each format
includes a bundled example. Source data is validated before plotting; invalid
or incomplete uploads clear the old preview and explain what needs attention.

The live figure supports linear/circular layouts, genome selection and order,
ltc palettes, ribbon opacity, labels, orientation when supplied, gene anchoring,
identity colouring when supplied, and an explicit link limit. Export PDF/PNG,
displayed records and links, pair counts, or R code reproducing the figure.
The gene-region example does not infer missing links or identity scores.

The app code is additive (`R/studio.R`, `R/studio_shiny.R`, `inst/shiny/`).
Existing linear plotting code and ltc definitions are unchanged. A circular
species-pair colouring error for empty block tables was corrected during app
testing and is covered by a regression test.

## Validation

`tests/testthat/test-studio.R` covers all four importers, both layouts,
identifier preservation, invalid intervals and links, empty data, genome
selection, link limits, pair counts, exported R code and Shiny reactive state.

With Studio running on port 3876, run `python3 dev/app/browser_checks.py` from
the package root. It requires Playwright and a local Google Chrome. Set
`GG_SYNTENY_URL` to use another URL. This exercises real uploads, plot changes,
all downloads, invalid-file recovery and mobile layout. Generated validation
files stay under `dev/app/validation/` and are ignored by Git/package builds.
The README screenshot is generated from the tested app.
