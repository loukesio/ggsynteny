# ggsynteny Studio

The optional Shiny app is included in ggsynteny 0.5.0. Install `shiny`, then
run `ggsynteny::ggsynteny_app()`. In a source checkout, first run
`devtools::load_all(".")` from the package root.

Studio reads existing MCScanX, GENESPACE, native chromosome/block tables, and
gene/link tables. It does not run the external analysis programs. Each format
includes a bundled example. Source data is validated before plotting; invalid
or incomplete uploads clear the old preview and explain what needs attention.

The MCScanX and GENESPACE examples are explicitly simulated: four genomes,
32 chromosomes and all six genome pairs. MCScanX contains 240 blocks and
2,644 anchor pairs (180 plus / 60 minus blocks); GENESPACE contains 384
synHits-compatible interval matches. Run `Rscript data-raw/studio_simulated.R`
to regenerate them. The small parser fixtures are preserved.

The live figure supports linear/circular layouts, genome selection and order,
ltc palettes, ribbon opacity, labels, orientation when supplied, gene anchoring,
identity colouring when supplied, and an explicit link limit. Export PDF/PNG,
displayed records and links, pair counts, or R code reproducing the figure.
The gene-region example does not infer missing links or identity scores.

Turn on **Interactive plot (hover and zoom)** for ggiraph tooltips,
highlighting and zoom in all layouts. This requires optional `ggiraph` 0.9.2
or later.
Scroll to zoom, drag to pan, and use the toolbar to reset the view.
PDF/PNG downloads use static plots; the R download includes both static and
interactive code when enabled. Invalid data clears both types of preview.

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
