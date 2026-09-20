# Modular GC-content and numeric tracks

Branch: `feature/gc-content-tracks`, based on main `3e137d6`.
Checkout: `dev/gc-content-tracks/` within the original project.
Development package version: `0.5.0.9000`.

For installation and a plain-language walkthrough, start with
[the tutorial README](tutorial/README.md). A complete demo ships in the
installed package at `system.file("examples", "annotation-tracks.R", package = "ggsynteny")`.

The public interface is `p + syn_track(table)` for all four plot functions.
Choose `geom = "heatmap"`, `"line"`, or `"bar"`. Multiple additions, or a
reusable list of additions, stack in order in either layout.
The shared table has group/sequence keys, interval boundaries, and a numeric
value. The existing macro and micro key names are also accepted. A small
layout attribute records the original genomic-to-plot mapping; default plot
layers and function signatures are unchanged.

Heatmaps use ggplot2 polygon layers with independent continuous aesthetics,
`syn_track1`, `syn_track2`, etc. Each geom delegates drawing to `GeomPolygon`;
the track's mapped color becomes the polygon fill at draw time. This avoids
replacing the existing circular fill scale or adding a scale-management
dependency. `scale_fill_syn_track()` provides the corresponding public scale.
Layer/coordinate copies keep reusable base plots unchanged.

`R/track_geoms.R` separates the individual renderers from layout and validation.
Every renderer receives a common context (data, sequence mapping and lane
bounds) and returns a list of native ggplot2 layers/scales. Shared helpers
project genomic positions and normalized values into linear or circular space.
Future renderers can reuse those helpers without modifying any plot function.

Lines use `GeomPath`, plus points for isolated values. They sort window centers
and start a new run at NA, uncovered gaps and contig boundaries. Circular paths
interpolate genomic position/value before projection to avoid cutting across
the inner edge of a ring. Bars use the full interval width and support a chosen
baseline, including zero for signed measurements. Each numeric lane has edge
labels, optional reference guides, and a fixed-color key. Custom legend
aesthetics keep unrelated layers from changing or painting over those keys.

`gc_content()` calculates GC from supplied DNA, using prefix sums for interval
counts. It supports per-gene summaries and windows, including overlapping
windows. All sequence calculations use zero-based half-open base-pair bounds.
Non-ACGT IUPAC bases are excluded from the denominator, and missing/no-called
sequence gives NA. No values are inferred from links or block ranks.

## Review

- Four-page PDF: `man/figures/gc-tracks/gc-tracks.pdf`.
- Mixed-type two-page PDF: `man/figures/gc-tracks/modular-tracks.pdf`.
- Reproduce mixed tracks: `Rscript data-raw/modular_tracks.R`.
- Verify GitHub installation and execute the tutorial from the installed
  package: `Rscript dev/gc-tracks/validate_install.R` (temporary R library).
- Contact sheet: `man/figures/gc-tracks/overview.png`.
- Guide: `vignettes/articles/annotation-tracks.Rmd`.
- Runnable examples and data generation: `data-raw/gc_tracks.R`.
- Input provenance: `inst/extdata/gc-tracks/README.md` (all DNA simulated).

## Validation on 2026-09-20

- R 4.5.1, ggplot2 4.0.3, macOS arm64.
- Full R CMD check (`--no-manual --as-cran`): 0 errors, 0 warnings, 0 notes.
- 838 test expectations passed, including 403 track expectations.
  The test log retains the existing warning that local Shiny was built with
  R 4.5.2. It does not produce an R CMD check warning.
- Tests cover exact GC counts, missing sequence, ambiguous bases, invalid
  intervals, both circle directions, reordered bins, multiple contigs, all
  four plot types, scale isolation/replacement, stacking, immutable base
  plots, missing values, and compatibility with existing ggiraph layers.
  The additional 87 line/bar checks cover midpoint/value geometry, both circle
  directions, local radial interpolation, missing/gap/contig separation, signed
  bars, mixed-track legend isolation, earlier axes staying fixed when stacking,
  all four plot types, and interactive rendering with the original gene layers.
- Eight original default/casa_natal plots have identical built layer data
  and byte-identical PNGs against the original root checkout. All palette
  definitions and public plotting function signatures are identical.
  Reproduce with `Rscript dev/gc-tracks/compare_defaults.R`.
- All four example PNGs inspected via the overview; all four vector PDF
  views exported. The full track guide executes and renders successfully.
  Pandoc emits its existing deprecated syntax-highlighting-option notice.
- Linear and circular three-track previews inspected and opened automatically
  in the user's PDF viewer, as requested. The original heatmap example files
  are retained. Temporary legend-debug output lives in the ignored validation
  directory; it is not a package file.
- No new dependencies, release, deployed website, or Studio changes.

Local validation artifacts live in ignored `dev/gc-tracks/validation/`.

## Scope for later work

Track hover tooltips, Studio upload controls, FASTA-file readers, automatic clipping of window
tables to gene-view extents, faceting, and origin-wrapping windows are not
implemented. Overlapping heatmap/bar intervals draw in input order, later on
top; lines directly support overlapping windows with distinct midpoints.
Non-overlapping windows give the clearest heatmaps. See the guide for details.
