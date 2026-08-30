# Changelog

## ggsynteny 0.3.0

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
