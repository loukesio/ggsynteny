# Changelog

## ggsynteny (development version)

- Add optional reference-coordinate identity windows, separate ruler and
  identity keys, a shared percentage scale, and explicit unscored
  regions. Example identity windows are labelled as invented; identity
  data can be uploaded and exported alongside variant calls.

- Add reference comparison rings to Studio, with a shared reference
  sequence, one or more comparison genomes, variant filtering, hover
  details, and static PDF/PNG exports. Add
  [`plot_reference_comparison()`](https://loukesio.github.io/ggsynteny/reference/plot_reference_comparison.md)
  for use directly in R.

- Match the supplied Genome Ring design with IBM Plex fonts, ltc
  palettes, distinct variant marks, an event list, cursor readouts and a
  linked region view. Add
  [`save_reference_comparison()`](https://loukesio.github.io/ggsynteny/reference/save_reference_comparison.md)
  for static exports with bundled fonts.

- [`syn_track()`](https://loukesio.github.io/ggsynteny/reference/syn_track.md)
  now draws categorical intervals too: `geom = "feature"` colours genes
  or regions by a column with an independent legend, with
  `strand = "split"` or `"arrow"` lanes and optional text labels along
  the ring. The geom is chosen from the table when not given. One
  wrapper per geom,
  [`syn_track_feature()`](https://loukesio.github.io/ggsynteny/reference/syn_track_geoms.md),
  [`syn_track_heatmap()`](https://loukesio.github.io/ggsynteny/reference/syn_track_geoms.md),
  [`syn_track_line()`](https://loukesio.github.io/ggsynteny/reference/syn_track_geoms.md)
  and
  [`syn_track_bar()`](https://loukesio.github.io/ggsynteny/reference/syn_track_geoms.md),
  lists only the options that geom uses.
  [`scale_fill_syn_feature()`](https://loukesio.github.io/ggsynteny/reference/scale_fill_syn_feature.md)
  replaces a feature track’s colours.

- Track tables may omit the `species`/`chr` keys when the plot shows one
  species or one sequence; they are filled in from the plot.

- Add
  [`syn_axis()`](https://loukesio.github.io/ggsynteny/reference/syn_axis.md):
  genomic coordinate ticks and labels along every sequence, with `by`
  and `unit` (`"kb"`, `"Mb"`) formatting, in every layout.

- Circular tracks accept `position = "inside"`, stacking inward from the
  chromosome band and shrinking the ribbons toward the centre. All
  tracks accept `out_of_bounds = "clip"` or `"drop"` for intervals that
  extend past a sequence (windows at the end of a genome, genes crossing
  a boundary).

- [`plot_circular_synteny()`](https://loukesio.github.io/ggsynteny/reference/plot_circular_synteny.md)
  gains `chr_order` (factor levels, `"input"`, a vector or a per-species
  list) and colours ribbons by any `blocks` column given to
  `ribbon_fill`, with an optional legend (`ribbon_legend`). Defaults and
  existing calls are unchanged; the new arguments are appended.

- Rename `scale_fill_syn_track()` to
  [`scale_fill_syn_heatmap()`](https://loukesio.github.io/ggsynteny/reference/scale_fill_syn_heatmap.md)
  so scale names mirror the track wrappers, and
  [`demo_microsynteny_data()`](https://loukesio.github.io/ggsynteny/reference/example_microsynteny_data.md)
  to
  [`example_microsynteny_data()`](https://loukesio.github.io/ggsynteny/reference/example_microsynteny_data.md)
  to match
  [`example_synteny_data()`](https://loukesio.github.io/ggsynteny/reference/example_synteny_data.md).
  The old example-data name still works with a deprecation message.

- Export
  [`syn_layout()`](https://loukesio.github.io/ggsynteny/reference/syn_layout.md)
  and
  [`syn_project()`](https://loukesio.github.io/ggsynteny/reference/syn_project.md)
  so custom ggplot2 layers can be placed in genomic coordinates without
  internal functions.

- Bundle the published *Arabidopsis thaliana* chloroplast annotation
  (RefSeq NC_000932.1) in `inst/extdata/chloroplast/` and draw a
  complete genome ring from exported functions only
  (`data-raw/genome_ring.R`).

- Extend
  [`syn_track()`](https://loukesio.github.io/ggsynteny/reference/syn_track.md)
  with modular `geom = "line"` and `geom = "bar"` renderers that compose
  with heatmaps in every layout. Lines follow window centers, break at
  missing values/gaps/contig boundaries, and interpolate within circular
  rings. Bars support signed values and a chosen baseline. Each
  numerical track has independent limits, guides, labels and legends.
  Add a reproducible three-track linear/circular example.

- Add optional GC-content and numeric annotation tracks with
  `p + syn_track()` in all four linear/circular, chromosome/gene views.
  Native ggplot2 polygon layers use independent continuous scales, stack
  outward, and move labels to make room. Existing plotting defaults and
  ltc palettes are unchanged.

- Add
  [`gc_content()`](https://loukesio.github.io/ggsynteny/reference/gc_content.md)
  for per-gene and window summaries from supplied DNA. Ambiguous bases
  are excluded from the denominator; missing sequence and intervals
  without A/C/G/T bases return NA. Include runnable simulated sequence
  examples and
  [`scale_fill_syn_heatmap()`](https://loukesio.github.io/ggsynteny/reference/scale_fill_syn_heatmap.md)
  for scale customization.

- Add a Studio interactive-plot toggle for hover tooltips, highlighting
  and zoom across all four plot types, using optional ggiraph. Figure
  exports remain static; exported R code can also recreate the
  interactive view.

- Enlarge the registered MCScanX and GENESPACE Studio examples to four
  simulated genomes and 32 chromosomes, with 240 blocks and 384
  compatible interval matches respectively. Label the examples as
  simulated and include their reproducible generator; preserve the small
  parser fixtures.

## ggsynteny 0.5.0

- Add
  [`ggsynteny_app()`](https://loukesio.github.io/ggsynteny/reference/ggsynteny_app.md),
  an optional Shiny app for MCScanX, GENESPACE, native chromosome/block
  tables, and gene/link tables. It previews inputs and plots, supports
  linear and circular layouts, and exports figures, displayed records,
  pair summaries and a reproducible R script.

- [`plot_circular_synteny()`](https://loukesio.github.io/ggsynteny/reference/plot_circular_synteny.md)
  and
  [`plot_circular_microsynteny()`](https://loukesio.github.io/ggsynteny/reference/plot_circular_microsynteny.md)
  draw chromosome arcs and strand-aware gene arrows with internal
  homology ribbons, using native ggplot2 polygon/text layers and
  fixed-aspect coordinates. Both accept existing package data formats,
  ltc palette names, and optional ggiraph rendering. No new dependencies
  are introduced.

- Circular layouts retain genomic interval widths, expose their layout
  data, and display all supplied relationships among selected genomes,
  including non-adjacent genomes. They do not aggregate interval widths
  into coverage.

- Document both circular functions with argument tables, runnable
  examples, and vector PDFs. Add prepared three-bacterium feature/link
  tables and a reproducible moa/moe-region example for ZONMW-30,
  ZONMW-20 and HI1.

- Preserve MCScanX block orientation.
  `plot_synteny(show_inversions = TRUE)` optionally displays inverted
  blocks as twisted ribbons; the default coverage view is unchanged.
  This option requires `blocks$orientation` metadata.

- Fix uniform fills with color vectors and HCL palette names, and honor
  HCL palettes for micro-synteny identity ribbons. All 32 ltc palette
  definitions and their name aliases are unchanged.

- Match numeric chromosome identifiers to named color keys and share
  gene-name colors between genes and ribbons when the same palette is
  used.

- Draw genes without ribbons when no links remain; attach micro-synteny
  ribbons to the facing gene edges when bins are reordered.

- Exclude local ZIP archives from package builds and repair the README
  saving example and vignette placeholders.

## ggsynteny 0.3.0

- New default look for
  [`plot_synteny()`](https://loukesio.github.io/ggsynteny/reference/plot_synteny.md):
  with nothing specified, chromosomes are quiet dark boxes (“#333333”,
  `chr_fill = "uniform"`) with white seams (new `chr_color` argument),
  and ribbons take their colors from the `alger` palette. The old
  auto-generated HCL hues are gone; `alger` is now the fallback palette
  wherever no palette is given.

- New `chr_radius` (in
  [`plot_synteny()`](https://loukesio.github.io/ggsynteny/reference/plot_synteny.md))
  and `gene_radius` (in
  [`plot_microsynteny()`](https://loukesio.github.io/ggsynteny/reference/plot_microsynteny.md)):
  corner rounding in millimetres via ggforce — `chr_radius = 1.5` turns
  chromosomes into karyotype-style capsules. Corners stay square/crisp
  by default.

- Interactive plots:
  [`plot_synteny()`](https://loukesio.github.io/ggsynteny/reference/plot_synteny.md)
  and
  [`plot_microsynteny()`](https://loukesio.github.io/ggsynteny/reference/plot_microsynteny.md)
  gain `interactive = TRUE` (hover highlighting and tooltips via
  ggiraph), and the new
  [`syn_girafe()`](https://loukesio.github.io/ggsynteny/reference/syn_girafe.md)
  renders the widget — see the [Interactive
  article](https://loukesio.github.io/ggsynteny/articles/interactive.html).

- New bundled dataset `rice_sorghum`: real macro-synteny between rice
  and sorghum, produced by running MCScanX on its own example data and
  parsing the output with
  [`read_mcscanx()`](https://loukesio.github.io/ggsynteny/reference/read_mcscanx.md)
  — see the [Real data
  article](https://loukesio.github.io/ggsynteny/articles/real-data.html).

- New `ribbon_anchor` argument in
  [`plot_microsynteny()`](https://loukesio.github.io/ggsynteny/reference/plot_microsynteny.md):
  `"body"` (default) keeps arrowheads clear of ribbons so strand
  direction stays readable; `"full"` spans the whole gene including the
  tip (the clinker/gggenomes convention).

- Fixed
  [`read_mcscanx()`](https://loukesio.github.io/ggsynteny/reference/read_mcscanx.md):
  real MCScanX output writes alignment blocks back-to-back with no blank
  line between them, and every block except the last was silently
  dropped. Block coordinates now also trust each alignment header’s
  chromosome pair, and blocks carry `score` and `n_genes` columns.

- With `ribbon_fill = "identity"`, the top-level `palette` no longer
  restyles the identity ramp (a qualitative palette makes a misleading
  ramp); pass an ordered palette as `ribbon_palette` explicitly.

- Tooltip-free plots are unchanged; interactive layers are only built
  when `interactive = TRUE` and ggiraph is installed (Suggests).

## ggsynteny 0.2.0

- New `palette` argument in
  [`plot_synteny()`](https://loukesio.github.io/ggsynteny/reference/plot_synteny.md)
  and
  [`plot_microsynteny()`](https://loukesio.github.io/ggsynteny/reference/plot_microsynteny.md):
  all 32 palettes of the [ltc
  package](https://github.com/loukesio/ltc-color-palettes) now work by
  name, e.g. `palette = "casa_natal"` (vendored — ltc need not be
  installed). Names match case-insensitively and ignore spaces,
  underscores, and dashes. `"Okabe-Ito"`, colour vectors, and
  [`hcl.colors()`](https://rdrr.io/r/grDevices/palettes.html) names are
  accepted too.
- New
  [`syn_palettes()`](https://loukesio.github.io/ggsynteny/reference/syn_palettes.md)
  lists the built-in palettes.
- `chr_palette`, `ribbon_palette`, and `gene_palette` also accept
  palette names; named vectors keep working as explicit key-to-colour
  mappings.
- With `ribbon_fill = "identity"`, a named ordered palette
  (e.g. `"heatmap0"`) is used as the identity colour ramp.
- [`plot_synteny()`](https://loukesio.github.io/ggsynteny/reference/plot_synteny.md)
  and
  [`plot_microsynteny()`](https://loukesio.github.io/ggsynteny/reference/plot_microsynteny.md)
  now validate their `*_fill` arguments and error early on typos instead
  of silently falling back.
- Chromosome ordering no longer emits NA warnings for non-numeric
  chromosome names (numeric labels still sort numerically).
- [`read_synteny_tsv()`](https://loukesio.github.io/ggsynteny/reference/read_synteny_tsv.md)
  no longer truncates decimal chromosome sizes and block coordinates
  (previously parsed as integers) and reads exactly the documented eight
  block columns.
- Ribbons, chromosomes, and gene arrows are each drawn as a single
  ggplot2 layer instead of one layer per polygon — much faster for large
  datasets.

## ggsynteny 0.1.0

- Initial version:
  [`plot_synteny()`](https://loukesio.github.io/ggsynteny/reference/plot_synteny.md),
  [`plot_microsynteny()`](https://loukesio.github.io/ggsynteny/reference/plot_microsynteny.md),
  parsers for MCScanX, GENESPACE, and TSV, and bundled example data.
