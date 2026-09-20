# GC-content tracks: first implementation

Branch: `feature/gc-content-tracks`, based on main `3e137d6`.
Checkout: `dev/gc-content-tracks/` within the original project.

The public interface is `p + syn_track(table)` for all four plot functions.
The shared table has group/sequence keys, interval boundaries, and a numeric
value. The existing macro and micro key names are also accepted. A small
layout attribute records the original genomic-to-plot mapping; default plot
layers and function signatures are unchanged.

Tracks use ggplot2 polygon layers with independent continuous aesthetics,
`syn_track1`, `syn_track2`, etc. Each geom delegates drawing to `GeomPolygon`;
the track's mapped color becomes the polygon fill at draw time. This avoids
replacing the existing circular fill scale or adding a scale-management
dependency. `scale_fill_syn_track()` provides the corresponding public scale.
Layer/coordinate copies keep reusable base plots unchanged.

`gc_content()` calculates GC from supplied DNA, using prefix sums for interval
counts. It supports per-gene summaries and windows, including overlapping
windows. All sequence calculations use zero-based half-open base-pair bounds.
Non-ACGT IUPAC bases are excluded from the denominator, and missing/no-called
sequence gives NA. No values are inferred from links or block ranks.

## Review

- Four-page PDF: `man/figures/gc-tracks/gc-tracks.pdf`.
- Contact sheet: `man/figures/gc-tracks/overview.png`.
- Guide: `vignettes/articles/annotation-tracks.Rmd`.
- Runnable examples and data generation: `data-raw/gc_tracks.R`.
- Input provenance: `inst/extdata/gc-tracks/README.md` (all DNA simulated).

## Validation on 2026-09-20

- R 4.5.1, ggplot2 4.0.3, macOS arm64.
- Full R CMD check (`--no-manual --as-cran`): 0 errors, 0 warnings, 0 notes.
- 751 test expectations passed, including 316 new track expectations.
  The test log retains the existing warning that local Shiny was built with
  R 4.5.2. It does not produce an R CMD check warning.
- Tests cover exact GC counts, missing sequence, ambiguous bases, invalid
  intervals, both circle directions, reordered bins, multiple contigs, all
  four plot types, scale isolation/replacement, stacking, immutable base
  plots, missing values, and compatibility with existing ggiraph layers.
- Eight original default/casa_natal plots have identical built layer data
  and byte-identical PNGs against the original root checkout. All palette
  definitions and public plotting function signatures are identical.
  Reproduce with `Rscript dev/gc-tracks/compare_defaults.R`.
- All four example PNGs inspected via the overview; all four vector PDF
  views exported. The full track guide executes and renders successfully.
  Pandoc emits its existing deprecated syntax-highlighting-option notice.
- No new dependencies, release, deployed website, or Studio changes.

Local validation artifacts live in ignored `dev/gc-tracks/validation/`.

## Scope for later work

The first display type is a heatmap. Bar/line tracks, track hover tooltips,
Studio upload controls, FASTA-file readers, automatic clipping of window
tables to gene-view extents, faceting, and origin-wrapping windows are not
implemented. Overlapping intervals draw in input order, later on top;
non-overlapping windows give the clearest heatmaps. See the guide for details.
