# Save a reference comparison with the bundled IBM Plex fonts

Exports a static plot with the same fonts as Studio. Text is embedded as
vector outlines in PDF. Requires the optional showtext and sysfonts
packages.

## Usage

``` r
save_reference_comparison(plot, filename, width = 11, height = 11, dpi = 300)
```

## Arguments

- plot:

  A plot from
  [`plot_reference_comparison()`](https://loukesio.github.io/ggsynteny/reference/plot_reference_comparison.md).

- filename:

  Output PDF or PNG filename.

- width, height:

  Figure dimensions in inches.

- dpi:

  PNG resolution in dots per inch.

## Value

Invisibly, the output filename.
