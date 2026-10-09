# Plot chromosome-level synteny around a circle

Arrange chromosomes as proportional arcs grouped by species, and connect
syntenic intervals with ribbons inside the circle. Returns an ordinary
ggplot2 object with polygon and text layers.

## Usage

``` r
plot_circular_synteny(
  syn_data,
  species_order = NULL,
  palette = NULL,
  chr_fill = "uniform",
  chr_palette = NULL,
  chr_color = "white",
  ribbon_fill = "source_chr",
  ribbon_palette = NULL,
  ribbon_alpha = 0.3,
  gap = 1,
  group_gap = 10,
  start_angle = 90,
  clockwise = TRUE,
  curvature = 0.65,
  track_width = 0.055,
  label_size = 2.5,
  species_label_size = 4,
  show_orientation = FALSE,
  interactive = FALSE,
  title = NULL,
  ribbon_legend = TRUE,
  chr_order = NULL
)
```

## Arguments

- syn_data:

  List containing `chromosomes` and `blocks`, in the same format as
  [`plot_synteny()`](https://loukesio.github.io/ggsynteny/reference/plot_synteny.md).
  All sizes and coordinates must use the same unit.

- species_order:

  Species in circular display order. Defaults to first appearance in
  `chromosomes`; may select a subset.

- palette:

  Built-in ltc name (e.g. `"casa_natal"`), `"Okabe-Ito"`, HCL palette
  name, or color vector. See
  [`syn_palettes()`](https://loukesio.github.io/ggsynteny/reference/syn_palettes.md).

- chr_fill:

  Chromosome coloring: `"uniform"`, `"per_species"`, `"per_chr"`, or
  `"custom"`.

- chr_palette:

  Overrides `palette` for chromosomes. Named vectors map species,
  chromosome labels, or `"species__chr"` keys in custom mode.

- chr_color:

  Chromosome outline color.

- ribbon_fill:

  Ribbon coloring: `"source_chr"`, `"target_chr"`, `"species_pair"`,
  `"uniform"`, `"custom"`, or the name of any other column of `blocks`
  (for example `"class"`), whose values are colored as categories with a
  legend. Source is the earlier species in `species_order` (input order
  for within-species blocks).

- ribbon_palette:

  Overrides `palette` for ribbons. In custom mode, provide one color or
  one color per row of the original `blocks` table. When coloring by a
  column, a named vector maps its values to colors.

- ribbon_alpha:

  Ribbon transparency, between 0 and 1.

- gap:

  Gap between chromosomes within a species, in degrees.

- group_gap:

  Gap between species, in degrees.

- start_angle:

  Angle where the first sector starts, in degrees; 90 is top.

- clockwise:

  Draw increasing genomic coordinates clockwise?

- curvature:

  Pull of ribbon control points toward the center (0 to 1).

- track_width:

  Radial thickness of chromosomes; the outer radius is 1.

- label_size:

  Chromosome label size in mm. Set to 0 to hide labels.

- species_label_size:

  Species label size in mm. Set to 0 to hide labels.

- show_orientation:

  Connect genomic endpoints according to the `orientation` column
  (`"plus"` or `"minus"`)? Default `FALSE` draws coverage ribbons.
  Around a circle, a twist alone does not identify an inversion: the
  direction in which both chromosomes are drawn also matters.

- interactive:

  Build ggiraph layers for rendering with
  [`syn_girafe()`](https://loukesio.github.io/ggsynteny/reference/syn_girafe.md)?

- title:

  Optional title.

- ribbon_legend:

  Show a legend when `ribbon_fill` names a column of `blocks`? Ignored
  for the built-in coloring modes.

- chr_order:

  Chromosome order within each species: `NULL` (the default) follows
  factor levels when `chr` is a factor and otherwise sorts numeric
  names, then remaining names alphabetically; `"input"` keeps the row
  order of `chromosomes`; a character vector orders the chromosome names
  explicitly; a list named by species gives one vector per species.

## Value

A ggplot object. Its `data` contains the sector layout, including
genomic bounds and angles in radians. The `circular_links` attribute
records the displayed block rows and their angular endpoints.

## Details

Sector widths are proportional to chromosome lengths across all
displayed species. Ribbons attach at the supplied genomic coordinates;
all available pairs among displayed species are shown, including
non-adjacent species and within-species blocks. This is a
genomic-coordinate view, not an aggregation of link counts or an
estimate of unique coverage.

The circular presentation does not imply that the chromosomes are
biologically circular. Duplicate chromosome keys, unmatched chromosome
references, and invalid or out-of-bounds intervals are rejected.

## See also

[`syn_track()`](https://loukesio.github.io/ggsynteny/reference/syn_track.md),
[`syn_track_feature()`](https://loukesio.github.io/ggsynteny/reference/syn_track_geoms.md)
and
[`syn_axis()`](https://loukesio.github.io/ggsynteny/reference/syn_axis.md)
for rings added outside or inside the chromosome band;
[`syn_layout()`](https://loukesio.github.io/ggsynteny/reference/syn_layout.md)
for the sector geometry of the returned plot.

## Examples

``` r
data(rice_sorghum)
p <- plot_circular_synteny(rice_sorghum, c("Rice", "Sorghum"),
                           palette = "casa_natal", chr_fill = "per_species")
p + ggplot2::labs(caption = "Rice and sorghum syntenic intervals")
```
