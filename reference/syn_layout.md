# Sector geometry of a synteny plot

Return the layout a ggsynteny plot was drawn with, so that further
ggplot2 layers can be placed in genomic coordinates with
[`syn_project()`](https://loukesio.github.io/ggsynteny/reference/syn_project.md).

## Usage

``` r
syn_layout(plot)
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

## Value

A list with `type` (`"circular"` or `"linear"`) and `sectors`, a data
frame with one row per displayed sequence: `group`, `seq_id`, genomic
`start` and `end`, and either `theta_start`/`theta_end` (angles in
radians, circular) or `x`/`y` (left end and centre line, linear).
Circular layouts also report `band` (inner and outer radius of the
chromosome band), `outer_edge` and `inner_edge` (the radii beyond which
the next outside/inside track would be drawn). Linear layouts report
`unit` (tier spacing), `half_height` of the gene band, and `lower_edge`
(offset below each centre line already taken by tracks).

## Examples

``` r
data(rice_sorghum)
p <- plot_circular_synteny(rice_sorghum, c("Rice", "Sorghum"))
syn_layout(p)$sectors
#>      group seq_id start   end theta_start  theta_end
#> 1     Rice      1     0 45.02   1.5707963  1.3293877
#> 2     Rice      2     0 36.79   1.3119344  1.1146572
#> 3     Rice      3     0 37.30   1.0972039  0.8971919
#> 4     Rice      4     0 36.06   0.8797386  0.6863758
#> 5     Rice      5     0 29.90   0.6689225  0.5085912
#> 6     Rice      6     0 32.10   0.4911379  0.3190096
#> 7     Rice      7     0 30.34   0.3015563  0.1388656
#> 8     Rice      8     0 28.50   0.1214123 -0.0314119
#> 9     Rice      9     0 23.82  -0.0488652 -0.1765940
#> 10    Rice     10     0 23.70  -0.1940473 -0.3211327
#> 11    Rice     11     0 31.22  -0.3385860 -0.5059955
#> 12    Rice     12     0 27.68  -0.5234488 -0.6718759
#> 13 Sorghum      1     0 73.83  -0.8464089 -1.2423039
#> 14 Sorghum      2     0 77.93  -1.2597572 -1.6776375
#> 15 Sorghum      3     0 74.44  -1.6950908 -2.0942569
#> 16 Sorghum      4     0 68.02  -2.1117101 -2.4764505
#> 17 Sorghum      5     0 62.33  -2.4939038 -2.8281330
#> 18 Sorghum      6     0 62.20  -2.8455863 -3.1791184
#> 19 Sorghum      7     0 64.31  -3.1965717 -3.5414181
#> 20 Sorghum      8     0 55.46  -3.5588714 -3.8562619
#> 21 Sorghum      9     0 59.62  -3.8737152 -4.1934126
#> 22 Sorghum     10     0 60.98  -4.2108659 -4.5378561
```
