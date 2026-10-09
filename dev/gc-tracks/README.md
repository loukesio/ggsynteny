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
dependency. `scale_fill_syn_heatmap()` provides the corresponding public scale.
Layer/coordinate copies keep reusable base plots unchanged.

`R/track_geoms.R` separates the individual renderers from layout and validation.
Every renderer receives a common context (data, sequence mapping and lane
bounds) and returns a list of native ggplot2 layers/scales. Shared helpers
project genomic positions and normalized values into linear or circular space.
Future renderers can reuse those helpers without modifying any plot function.

`R/track_linear.R` reserves a bundle for each genome: labels above, genes,
then tracks below. Adding a track spreads rows and shifts earlier layers with
their genome. Ribbons occupy separate gaps, not masked areas behind tracks.
Links skipping rows are clipped into pieces in those gaps, retaining link IDs,
colors and tooltips. Single-row links remain within the gene band. Circular
placement is unchanged. Backgrounds, boundary lines and reference guides accept
ggplot2 `element_rect()`, `element_line()` or `element_blank()` settings.

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

## Feature tracks, axes and inside placement (9 October 2026)

Driven by `dev/circlize-parity/README.md` in the main checkout (the chloroplast
genome ring from *Biological Data, Visualised*, chapter 14). Its acceptance
test, a full genome ring from exported functions only, is now
`data-raw/genome_ring.R` and the last test of `tests/testthat/test-track-features.R`.

- `syn_track()` is the single engine with `geom = "feature" | "heatmap" |
  "line" | "bar"`, chosen from the table when not given (`value` column means
  heatmap, otherwise feature). `R/syn_track_geoms.R` holds one thin wrapper
  per geom, `syn_track_feature()`, `syn_track_heatmap()`, `syn_track_line()`
  and `syn_track_bar()`, each with an explicit signature listing only the
  options that geom uses; this is the spelling the docs teach. Feature
  tracks own a private discrete aesthetic (`syn_featureN`, numbered with the
  other tracks), `strand = "split"`/`"arrow"`, labels along the ring, and
  `scale_fill_syn_feature()`. A labelled region band is a feature track with
  `fill` and `label` set (circlize gaps 1, 2 and 5).
- Track tables may omit `species`/`chr`: `.track_infer_keys()` fills them in
  from the plot when it shows one species, or when a sequence name is unique
  across species, and errors with a specific message otherwise. The
  chloroplast tables therefore need no key columns beyond the species name.
- `R/syn_axis.R`: tick marks and position labels (`by`, `unit`) as a thin
  stacking lane (gap 3). It has no data; `ggplot_add.syn_track()` fills in
  the displayed sequences.
- `syn_track()` and the new functions accept `position = "inside"` (gap 9).
  Inside rings stack inward from the band's inner radius, recorded as
  `inner` in the layout attribute; ribbon layers (`circular_id` prefixed
  `block_`/`link_`) are scaled uniformly toward the centre. Outside rings
  are unchanged. Counters are `used` (outside) and `inner_used` (inside);
  the names must not share a prefix because `$` partial-matches lists.
- `out_of_bounds = "error" | "clip" | "drop"` on every track (gap 6).
- `plot_circular_synteny(chr_order=)` and factor levels (gap 4);
  `ribbon_fill = "<column>"` with a legend-only `GeomBlank` layer on the
  `syn_ribbon` aesthetic (`.syn_key_layers()`), hidden by `ribbon_legend = FALSE`.
  Both arguments are appended after `title` so positional calls still work.
- Names agreed with the author on 9 October: `scale_fill_syn_track()` became
  `scale_fill_syn_heatmap()` (unreleased, no alias) and
  `demo_microsynteny_data()` became `example_microsynteny_data()` (released
  in 0.5.0, so the old name stays as a `.Deprecated` alias). `plot_*` names
  and `syn_girafe()` stay.
- `syn_layout()` / `syn_project()` export the geometry (gap 8). Gap 7
  (genome coordinates in) disappears once a molecule is one sector.
- Data: `inst/extdata/chloroplast/` (RefSeq NC_000932.1, provenance in its
  README). Figures: `man/figures/gc-tracks/genome-ring.png` (now with a GC-skew heatmap ring),
  `feature-tracks-linear.png`, `feature-tracks-circular.png`.

Validation on 2026-10-09 (R 4.5.1, ggplot2 4.0.3, macOS arm64):

- 1,258 test expectations pass (1,084 before, 174 new), 0 failures.
- `Rscript dev/gc-tracks/compare_defaults.R <checkout of c968b78>`: all 8
  default plots have identical built layer data and PNG bytes; palettes
  unchanged; plotting signatures only append arguments (the script now
  checks a prefix instead of identity).
- `R CMD check --as-cran --no-manual` on the built tarball: 0 errors; one
  WARNING from this machine's pandoc binary failing to run (README
  conversion, not a package issue) and the usual CRAN-incoming NOTE.

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
- 1,084 test expectations passed, including 649 track expectations.
  The test log retains the existing warning that local Shiny was built with
  R 4.5.2. It does not produce an R CMD check warning.
- Tests cover exact GC counts, missing sequence, ambiguous bases, invalid
  intervals, both circle directions, reordered bins, multiple contigs, all
  four plot types, scale isolation/replacement, stacking, immutable base
  plots, missing values, and compatibility with existing ggiraph layers.
  The additional 87 line/bar checks cover midpoint/value geometry, both circle
  directions, local radial interpolation, missing/gap/contig separation, signed
  bars, mixed-track legend isolation, earlier axes staying aligned when stacking,
  all four plot types, and interactive rendering with the original gene layers.
- 246 additional checks cover automatic linear row expansion, separate ribbon
  gaps, skipped-row and within-row links, label placement, and independent
  ggplot2 element styling/removal in both layouts. Circular mixed-track PNG
  bytes are identical to the previous development version.
- Eight original default/casa_natal plots have identical built layer data
  and byte-identical PNGs against the original root checkout. All palette
  definitions and public plotting function signatures are identical.
  Reproduce with `Rscript dev/gc-tracks/compare_defaults.R`.
- All four example PNGs inspected via the overview; all four vector PDF
  views exported. The full track guide executes and renders successfully.
  Pandoc emits its existing deprecated syntax-highlighting-option notice.
- Linear and circular three-track previews inspected and opened automatically
  in the user's PDF viewer, as requested. The single-heatmap examples were
  regenerated with the new linear layout. Temporary legend-debug output lives in the ignored validation
  directory; it is not a package file.
- No new dependencies, release, deployed website, or Studio changes.

Local validation artifacts live in ignored `dev/gc-tracks/validation/`.

## Scope for later work

Track hover tooltips, Studio upload controls, FASTA-file readers, faceting,
origin-wrapping windows, `out_of_bounds = "split"` (one interval drawn in two
sectors), and `seq_order` for `plot_circular_microsynteny()` are not
implemented. The region band is drawn as a ring next to the chromosome band,
not in place of it. Overlapping heatmap/bar intervals draw in input order, later on
top; lines directly support overlapping windows with distinct midpoints.
Non-overlapping windows give the clearest heatmaps. See the guide for details.
