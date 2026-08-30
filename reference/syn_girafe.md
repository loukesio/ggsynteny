# Render an interactive synteny plot

Wraps a plot built with `interactive = TRUE` (see
[`plot_synteny()`](https://loukesio.github.io/ggsynteny/reference/plot_synteny.md)
/
[`plot_microsynteny()`](https://loukesio.github.io/ggsynteny/reference/plot_microsynteny.md))
into a ggiraph widget with hover highlighting and tooltips, for HTML
output (R Markdown, Quarto, Shiny, pkgdown).

## Usage

``` r
syn_girafe(
  p,
  width_svg = 10,
  height_svg = 6,
  hover_css = "fill-opacity:0.9;stroke:#333333;stroke-width:1.2px;",
  opts = NULL,
  ...
)
```

## Arguments

- p:

  A ggplot built with `interactive = TRUE`.

- width_svg, height_svg:

  Width and height of the underlying SVG, in inches. Synteny plots are
  usually wide: the defaults are 10 x 6.

- hover_css:

  CSS applied to the hovered element.

- opts:

  A list of additional `ggiraph::opts_*()` options.

- ...:

  Passed on to
  [`ggiraph::girafe()`](https://davidgohel.github.io/ggiraph/reference/girafe.html).

## Value

A `girafe` htmlwidget.

## Examples

``` r
if (FALSE) { # \dontrun{
syn <- example_synteny_data()
p <- plot_synteny(syn, c("Arabidopsis", "Grape", "Rice"),
                  palette = "casa_natal", interactive = TRUE)
syn_girafe(p)
} # }
```
