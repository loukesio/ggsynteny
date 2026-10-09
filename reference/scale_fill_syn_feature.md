# Discrete fill scale for a feature track

Replace the colours of one feature track without changing gene, ribbon
or other track colours.

## Usage

``` r
scale_fill_syn_feature(
  track = 1,
  name = ggplot2::waiver(),
  values,
  na.value = "#BDBDBD",
  ...
)
```

## Arguments

- track:

  Track number in the order it was added, starting at 1.

- name:

  Legend title.

- values:

  Colours named by category, as for
  [`ggplot2::scale_fill_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html).

- na.value:

  Colour for categories absent from `values`.

- ...:

  Further arguments to
  [`ggplot2::scale_fill_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html),
  such as `breaks`, `labels` or `guide`.

## Value

A ggplot2 discrete scale for the selected track.
