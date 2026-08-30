# Changelog

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
