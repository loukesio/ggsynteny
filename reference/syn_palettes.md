# List the built-in colour palettes

Returns the named palettes that every `palette` argument of
[`plot_synteny()`](https://loukesio.github.io/ggsynteny/reference/plot_synteny.md)
and
[`plot_microsynteny()`](https://loukesio.github.io/ggsynteny/reference/plot_microsynteny.md)
accepts as a string: the 32 palettes of the [ltc
package](https://github.com/loukesio/ltc-color-palettes) (vendored, so
ltc need not be installed; a few are curated for use as fills on a white
background — pure-black and near-white entries are dropped), plus
`"Okabe-Ito"`. Palette names are matched case-insensitively and ignore
spaces, underscores, and dashes, so `"casa_natal"`, `"Casa Natal"` and
`"casanatal"` are the same palette. The `heatmap0`–`heatmap3` palettes
are ordered ramps intended for continuous colouring (e.g.
`ribbon_fill = "identity"`) and are always interpolated end-to-end.

## Usage

``` r
syn_palettes()
```

## Value

A named list of hex-colour vectors.

## Examples

``` r
names(syn_palettes())
#>  [1] "paloma"     "maya"       "dora"       "ploen"      "olga"      
#>  [6] "mterese"    "gaby"       "franscoise" "fernande"   "sylvie"    
#> [11] "expevo"     "minou"      "kiss"       "hat"        "reading"   
#> [16] "alger"      "trio1"      "trio2"      "trio3"      "trio4"     
#> [21] "heatmap0"   "pantone23"  "remains"    "midnight"   "lincoln"   
#> [26] "luminaries" "seafarer"   "shuggie"    "heatmap1"   "heatmap2"  
#> [31] "heatmap3"   "casa_natal"
syn_palettes()$casa_natal
#> [1] "#245E55" "#ED773C" "#808BC5" "#C63F3E" "#EAC119" "#EAA7C7" "#9ED6DF"
```
