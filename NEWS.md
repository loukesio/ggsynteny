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
