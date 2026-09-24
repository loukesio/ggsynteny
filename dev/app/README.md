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

Turn on the **Interactive plot** switch for ggiraph tooltips,
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

## Hosting

The public app is available at
[ggsynteny Studio](https://01a0ae1e-adb1-a4f8-1ced-261952037ebf.share.connect.posit.cloud/),
with no sign-in required.

The Posit Connect Cloud entry point and dependency manifest are in
[`deploy/posit-connect-cloud/`](../../deploy/posit-connect-cloud/README.md).
Prepare updates with `Rscript dev/app/prepare_connect_cloud.R` from the
package root, then publish using the documented GitHub or R workflow.
The hosting setup uses the installed package app and is excluded from
package builds.

## Reference comparison rings

The **Reference comparison** tab follows the supplied `Genome Ring.dc.html`
design: thin concentric tracks, IBM Plex Sans/Mono typography, outlined deletions,
capped insertion ticks, split duplication arcs, and solid inversion arcs.
It uses ggsynteny's ltc palettes (default `minou`) with stable type-to-colour
assignments when filtering. Fonts are bundled under the SIL Open Font License,
so the browser does not need an external font service.

One reference sequence occupies the inner ring; comparison genomes occupy
outer rings. Select one comparison for a two-genome figure. The event list
shows which genomes have the same supplied event type, coordinates, and optional
size/source fields. Click an event or ring mark to inspect its reference window.
Moving across the ring shows the reference position and calls in each genome.
Pale green tracks mean no identity score. Identity is read from an optional
window table; identity and alignment coverage are not inferred from variant calls. This view does not align sequences or call variants.

Upload CSV/TSV columns `sample`, `type`, `start`, `end`, and enter the reference
name and length in base pairs. Use one reference chromosome or contig at a time,
with zero-based starts and exclusive ends. Types: INS (insertion), DEL (deletion),
DUP (duplication), INV (inversion), SNP (single-base change). Point events may
have equal endpoints. Optional numeric `event_length` gives the inserted length;
optional `source_start` gives a duplication's source on the same reference.
Unknown optional values may be NA. Ribbons appear only when a source is supplied.
Insertion ticks have a fixed size and mark positions without implying a
direction. Supplied insertion lengths appear in the event list and hover details. Other arcs retain their true reference spans.
Overlapping calls may obscure one another.

The example contains 12 invented event patterns, 23 calls across five genomes,
and a 4,800,000-base reference. These are teaching numbers, not biological
findings. The example also includes invented 30-kb identity windows. Real-data shading
requires an uploaded identity table; absent values and uncovered regions stay
pale green. Deleted example intervals have no identity scores. Static PDF/PNG downloads use the same geometry and palette as
the app and include a reading guide. `save_reference_comparison()` uses the
bundled IBM Plex fonts (requires optional `showtext` and `sysfonts` packages).
PDF text is embedded as vector outlines. Plain `ggsave()` also works with the
plot function's default system fonts.

```r
v <- data.frame(sample = c("Genome A", "Genome B"),
                type = c("DEL", "SNP"),
                start = c(100, 700), end = c(200, 701))
p <- ggsynteny::plot_reference_comparison(
  v, genome_length = 1000, reference = "Reference", palette = "minou",
  title = "Invented teaching example"
)
ggsynteny::save_reference_comparison(p, "reference-comparison.pdf")
```

Validation on 24 September 2026 includes reference-coordinate geometry,
optional size/source validation, stable ltc colours, filtering, empty views,
font exports, and existing Studio regression checks. The installed Shiny and
testthat packages report that they were built under a newer R patch release.
Run `python3 dev/app/reference_browser_checks.py` against a local app on port
3881, or set `GG_SYNTENY_URL`, for visual and interaction checks. Example static
figures are in [`reference-examples/`](reference-examples/).

Initial redesign checks: 36 reference-view assertions and 113 existing Studio
assertions passed. Chrome checks passed for desktop/mobile layout, local fonts,
ltc palette changes, preserved filters, event selection, hover readouts, empty
views and all four downloads. The downloaded R script reproduced the static
figure, including a table whose optional source column was entirely missing.

The reference view shares Studio’s background. The transparent centre readout
shows reference length and name at rest, or exact base-pair position and
"POSITION ON REFERENCE" while hovering a ring. Both lines shrink to stay within
1.6 times the tick-label radius. The centre and ring gaps do not activate the
readout; a thin guide line crosses all rings at an active cursor position.
Static figures retain the resting centre label, with the same width constraint
measured during drawing. Both static legend rows use one shared column grid.
A plain-language example below the ring explains a supplied duplication source
and copy position.


### Identity windows and the reference ruler

Upload a second CSV/TSV with `sample`, `start`, `end`, `identity`. Positions use
zero-based starts and exclusive ends on the same reference sequence. Identity
is a percentage from 0 to 100; NA means unknown. Non-overlapping windows are
required within each genome. Samples without variant calls can be included
through this table. Missing windows are not filled or assigned low identity.
The **Identity** download saves the displayed windows; save it beside the
variants download when running the exported R script.

The identity scale is fixed across samples: 90% and below use the lightest
grey, 95% uses medium grey, 100% uses the darkest grey. Pale green means no
score. Higher identity means more matching aligned sequence, not better
biological function. Alignment coverage is not shown and cannot be inferred
from these percentages. The example scores are invented, not measured data.
The **Show identity shading** checkbox affects the live plot, static downloads,
and displayed-window export together.

The inner black/dark-grey bands are a coordinate ruler, not measurements.
They alternate every 500,000 bases for references of at least one million
bases; short references use a smaller labelled spacing. The last band may
be shorter. The ruler now uses real coordinate increments, rather than ten
equal subdivisions of an arbitrary reference length.

For real genomes, MUMmer's `nucmer` and `show-coords` can provide reference
alignment positions and percent identities, as described in the
[official tutorial](https://mummer4.github.io/tutorial/tutorial.html).
These are alignment-level results, not automatically fixed-window estimates.
Resolve overlapping alignments and calculate scores for the intended windows
from aligned sequence before upload; do not take an unweighted average of
alignment percentages. MUMmer coordinates are inclusive: convert the lower
reference endpoint to a zero-based start by subtracting one, and use the
upper endpoint as the exclusive end. Keep the alignment method and any
filtering with the analysis. No aligner is run by the app.

Identity extension: 62 reference-view assertions passed, including window
bounds, overlap rejection, missing scores, deletion consistency, sample
selection, real-table upload, invalid-score recovery, and static rendering.
The identity-enabled browser checks passed for shading on/off, existing
interactions, mobile layout, all downloads and empty variant selections.
The exported script reproduced the figure from both downloaded tables.

Centre-readout checks passed for an exact 1,234,567-bp cursor position, resting
reference name/size, inactive centre and ring gaps, reset on leaving the rings,
and long names constrained to 1.6 times the tick-label radius. Static fitting
also re-measures after font-size changes because PDF devices can round sizes.
Long-label measurements stayed within a 25-mm test viewport. Legend symbols
and labels share columns and vertical alignment across both rows.
