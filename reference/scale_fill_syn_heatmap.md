# Continuous fill scale for an annotation track

Replace an individual heatmap's scale without changing gene or ribbon
colors. Line and bar value ranges are set by `limits` in
[`syn_track()`](https://loukesio.github.io/ggsynteny/reference/syn_track.md).

## Usage

``` r
scale_fill_syn_heatmap(
  track = 1,
  name = "GC (%)",
  limits = c(0, 100),
  palette = c("#F7FBFF", "#6BAED6", "#08306B"),
  na.value = "#BDBDBD",
  ...
)
```

## Arguments

- track:

  Track number in the order it was added, starting at 1.

- name:

  Legend title.

- limits:

  Two increasing finite numbers. Use the same limits supplied to
  [`syn_track()`](https://loukesio.github.io/ggsynteny/reference/syn_track.md)
  unless intentionally changing the displayed color range.

- palette:

  Color vector, built-in ltc name, or HCL palette name.

- na.value:

  Color for missing values.

- ...:

  Further arguments to
  [`ggplot2::scale_fill_gradientn()`](https://ggplot2.tidyverse.org/reference/scale_gradient.html),
  such as `breaks` and `labels`. Out-of-range values use `na.value` by
  default.

## Value

A ggplot2 continuous scale for the selected track.
