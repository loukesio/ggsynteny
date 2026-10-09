# ggsynteny (development version)

* Rebuild Studio as one shell in four steps, following the 10 October design
  handout. A start screen presents the three jobs with examples; the data
  step pairs every drop zone with its column list and a sample download and
  reports what was read, including skipped rows with row and reason; the
  figure step groups controls by what they change and names each
  ggsynteny argument; the export step offers PDF at journal widths, PNG,
  the tables drawn and the R script on the page. Tracks are a reorderable
  list. One `tokens.css` replaces the two previous style sheets.
  `.studio_validate(strict = FALSE)` skips bad rows instead of stopping.
* `plot_circular_synteny()` ribbons can be coloured by a `blocks` column
  from Studio (`ribbon_fill = "<column>"`), and the reference comparison
  identity shading can use `identity_palette` from Studio.

* Studio gains an **Annotation tracks** tab: upload up to three interval
  tables, draw each as feature boxes, a heatmap, a line or bars with the
  `syn_track_*()` options (colour column, strand split or arrows, labels,
  scale limits, reference guide, inside or outside placement, lane height),
  add a coordinate axis, and stack them on the figure from the Synteny tab.
  A built-in chloroplast genome ring shows the five rings with switches.
  PDF, PNG, per-track TSV and a reproducing R script download.
* `plot_reference_comparison()` gains `identity_palette` for the identity
  shading; the bundled five-genome demonstration tables are new.

- Add optional reference-coordinate identity windows, separate ruler and
  identity keys, a shared percentage scale, and explicit unscored regions.
  Example identity windows are labelled as invented; identity data can be
  uploaded and exported alongside variant calls.

- Add reference comparison rings to Studio, with a shared reference sequence,
  one or more comparison genomes, variant filtering, hover details, and static
  PDF/PNG exports. Add `plot_reference_comparison()` for use directly in R.
- Match the supplied Genome Ring design with IBM Plex fonts, ltc palettes,
  distinct variant marks, an event list, cursor readouts and a linked region
  view. Add `save_reference_comparison()` for static exports with bundled fonts.

* `syn_track()` now draws categorical intervals too: `geom = "feature"`
  colours genes or regions by a column with an independent legend, with
  `strand = "split"` or `"arrow"` lanes and optional text labels along the
  ring. The geom is chosen from the table when not given. One wrapper per
  geom, `syn_track_feature()`, `syn_track_heatmap()`, `syn_track_line()` and
  `syn_track_bar()`, lists only the options that geom uses.
  `scale_fill_syn_feature()` replaces a feature track's colours.
* Track tables may omit the `species`/`chr` keys when the plot shows one
  species or one sequence; they are filled in from the plot.
* Add `syn_axis()`: genomic coordinate ticks and labels along every sequence,
  with `by` and `unit` (`"kb"`, `"Mb"`) formatting, in every layout.
* Circular tracks accept `position = "inside"`, stacking inward from the
  chromosome band and shrinking the ribbons toward the centre. All tracks
  accept `out_of_bounds = "clip"` or `"drop"` for intervals that extend past
  a sequence (windows at the end of a genome, genes crossing a boundary).
* `plot_circular_synteny()` gains `chr_order` (factor levels, `"input"`, a
  vector or a per-species list) and colours ribbons by any `blocks` column
  given to `ribbon_fill`, with an optional legend (`ribbon_legend`).
  Defaults and existing calls are unchanged; the new arguments are appended.
* Rename `scale_fill_syn_track()` to `scale_fill_syn_heatmap()` so scale
  names mirror the track wrappers, and `demo_microsynteny_data()` to
  `example_microsynteny_data()` to match `example_synteny_data()`. The old
  example-data name still works with a deprecation message.
* Export `syn_layout()` and `syn_project()` so custom ggplot2 layers can be
  placed in genomic coordinates without internal functions.
* Bundle the published *Arabidopsis thaliana* chloroplast annotation
  (RefSeq NC_000932.1) in `inst/extdata/chloroplast/` and draw a complete
  genome ring from exported functions only (`data-raw/genome_ring.R`).

* Extend `syn_track()` with modular `geom = "line"` and `geom = "bar"`
  renderers that compose with heatmaps in every layout. Lines follow window
  centers, break at missing values/gaps/contig boundaries, and interpolate
  within circular rings. Bars support signed values and a chosen baseline.
  Each numerical track has independent limits, guides, labels and legends.
  Add a reproducible three-track linear/circular example.

* Add optional GC-content and numeric annotation tracks with `p + syn_track()`
  in all four linear/circular, chromosome/gene views. Native ggplot2 polygon
  layers use independent continuous scales, stack outward, and move labels
  to make room. Existing plotting defaults and ltc palettes are unchanged.
* Add `gc_content()` for per-gene and window summaries from supplied DNA.
  Ambiguous bases are excluded from the denominator; missing sequence and
  intervals without A/C/G/T bases return NA. Include runnable simulated
  sequence examples and `scale_fill_syn_heatmap()` for scale customization.

* Add a Studio interactive-plot toggle for hover tooltips, highlighting and
  zoom across all four plot types, using optional ggiraph. Figure exports
  remain static; exported R code can also recreate the interactive view.
* Enlarge the registered MCScanX and GENESPACE Studio examples to four
  simulated genomes and 32 chromosomes, with 240 blocks and 384 compatible
  interval matches respectively. Label the examples as simulated and include
  their reproducible generator; preserve the small parser fixtures.

# ggsynteny 0.5.0

* Add `ggsynteny_app()`, an optional Shiny app for MCScanX, GENESPACE,
  native chromosome/block tables, and gene/link tables. It previews inputs
  and plots, supports linear and circular layouts, and exports figures,
  displayed records, pair summaries and a reproducible R script.
* `plot_circular_synteny()` and `plot_circular_microsynteny()`
  draw chromosome arcs and strand-aware gene arrows with internal homology
  ribbons, using native ggplot2 polygon/text layers and fixed-aspect coordinates.
  Both accept existing package data formats, ltc palette names, and optional
  ggiraph rendering. No new dependencies are introduced.
* Circular layouts retain genomic interval widths, expose their layout data,
  and display all supplied relationships among selected genomes, including
  non-adjacent genomes. They do not aggregate interval widths into coverage.
* Document both circular functions with argument tables, runnable examples,
  and vector PDFs. Add prepared three-bacterium feature/link tables and a
  reproducible moa/moe-region example for ZONMW-30, ZONMW-20 and HI1.

* Preserve MCScanX block orientation. `plot_synteny(show_inversions = TRUE)`
  optionally displays inverted blocks as twisted ribbons; the default coverage
  view is unchanged. This option requires `blocks$orientation` metadata.
* Fix uniform fills with color vectors and HCL palette names, and honor HCL
  palettes for micro-synteny identity ribbons. All 32 ltc palette definitions
  and their name aliases are unchanged.
* Match numeric chromosome identifiers to named color keys and share gene-name
  colors between genes and ribbons when the same palette is used.
* Draw genes without ribbons when no links remain; attach micro-synteny ribbons
  to the facing gene edges when bins are reordered.
* Exclude local ZIP archives from package builds and repair the README saving
  example and vignette placeholders.

# ggsynteny 0.3.0

* New default look for `plot_synteny()`: with nothing specified,
  chromosomes are quiet dark boxes ("#333333", `chr_fill = "uniform"`) with
  white seams (new `chr_color` argument), and ribbons take their colors
  from the `alger` palette. The old auto-generated HCL hues are gone;
  `alger` is now the fallback palette wherever no palette is given.

* New `chr_radius` (in `plot_synteny()`) and `gene_radius` (in
  `plot_microsynteny()`): corner rounding in millimetres via ggforce —
  `chr_radius = 1.5` turns chromosomes into karyotype-style capsules.
  Corners stay square/crisp by default.
* Interactive plots: `plot_synteny()` and `plot_microsynteny()` gain
  `interactive = TRUE` (hover highlighting and tooltips via ggiraph), and the
  new `syn_girafe()` renders the widget — see the
  [Interactive article](https://loukesio.github.io/ggsynteny/articles/interactive.html).
* New bundled dataset `rice_sorghum`: real macro-synteny between rice and
  sorghum, produced by running MCScanX on its own example data and parsing
  the output with `read_mcscanx()` — see the
  [Real data article](https://loukesio.github.io/ggsynteny/articles/real-data.html).
* New `ribbon_anchor` argument in `plot_microsynteny()`: `"body"` (default)
  keeps arrowheads clear of ribbons so strand direction stays readable;
  `"full"` spans the whole gene including the tip (the clinker/gggenomes
  convention).
* Fixed `read_mcscanx()`: real MCScanX output writes alignment blocks
  back-to-back with no blank line between them, and every block except the
  last was silently dropped. Block coordinates now also trust each
  alignment header's chromosome pair, and blocks carry `score` and
  `n_genes` columns.
* With `ribbon_fill = "identity"`, the top-level `palette` no longer
  restyles the identity ramp (a qualitative palette makes a misleading
  ramp); pass an ordered palette as `ribbon_palette` explicitly.
* Tooltip-free plots are unchanged; interactive layers are only built when
  `interactive = TRUE` and ggiraph is installed (Suggests).

# ggsynteny 0.2.0

* New `palette` argument in `plot_synteny()` and `plot_microsynteny()`: all 32
  palettes of the [ltc package](https://github.com/loukesio/ltc-color-palettes)
  now work by name, e.g. `palette = "casa_natal"` (vendored — ltc need not be
  installed). Names match case-insensitively and ignore spaces, underscores,
  and dashes. `"Okabe-Ito"`, colour vectors, and `hcl.colors()` names are
  accepted too.
* New `syn_palettes()` lists the built-in palettes.
* `chr_palette`, `ribbon_palette`, and `gene_palette` also accept palette
  names; named vectors keep working as explicit key-to-colour mappings.
* With `ribbon_fill = "identity"`, a named ordered palette (e.g. `"heatmap0"`)
  is used as the identity colour ramp.
* `plot_synteny()` and `plot_microsynteny()` now validate their `*_fill`
  arguments and error early on typos instead of silently falling back.
* Chromosome ordering no longer emits NA warnings for non-numeric chromosome
  names (numeric labels still sort numerically).
* `read_synteny_tsv()` no longer truncates decimal chromosome sizes and block
  coordinates (previously parsed as integers) and reads exactly the documented
  eight block columns.
* Ribbons, chromosomes, and gene arrows are each drawn as a single ggplot2
  layer instead of one layer per polygon — much faster for large datasets.

# ggsynteny 0.1.0

* Initial version: `plot_synteny()`, `plot_microsynteny()`, parsers for
  MCScanX, GENESPACE, and TSV, and bundled example data.
