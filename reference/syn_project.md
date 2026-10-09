# Project genomic positions onto a synteny plot

Convert positions on displayed sequences to the x/y coordinates of a
ggsynteny plot, for adding ordinary ggplot2 layers.

## Usage

``` r
syn_project(plot, group, seq_id, position, offset = 1)
```

## Arguments

- plot:

  A ggplot made by
  [`plot_synteny()`](https://loukesio.github.io/ggsynteny/reference/plot_synteny.md),
  [`plot_microsynteny()`](https://loukesio.github.io/ggsynteny/reference/plot_microsynteny.md),
  [`plot_circular_synteny()`](https://loukesio.github.io/ggsynteny/reference/plot_circular_synteny.md)
  or
  [`plot_circular_microsynteny()`](https://loukesio.github.io/ggsynteny/reference/plot_circular_microsynteny.md),
  with or without tracks added.

- group, seq_id:

  Sequence keys as used by the plot (species/chromosome or
  bin/sequence), recycled to the length of `position`.

- position:

  Genomic positions in plot units.

- offset:

  For circular plots, the radius to draw at (the chromosome band spans
  `band["inner"]` to `band["outer"]` from
  [`syn_layout()`](https://loukesio.github.io/ggsynteny/reference/syn_layout.md)).
  For linear plots, the vertical distance above each sequence's centre
  line (negative values go below).

## Value

A data frame with `x` and `y`.

## Examples

``` r
data(rice_sorghum)
p <- plot_circular_synteny(rice_sorghum, c("Rice", "Sorghum"))
xy <- syn_project(p, "Rice", "1", c(0, 20), offset = 1.1)
p + ggplot2::annotate("point", x = xy$x, y = xy$y)
```
