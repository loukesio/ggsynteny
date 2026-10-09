# Add a coordinate-aligned annotation track to a synteny plot

Add with `p + syn_track(data)` to any of the four synteny plotting
functions. A track is a table of intervals on the displayed sequences
and a `geom` saying how to draw what each interval carries: `"feature"`
boxes coloured by a category, or a `"heatmap"`, `"line"` or `"bar"` for
a numeric `value`. Tracks stack in the order added: below each genome in
linear plots, and outward from the chromosome band (or inward with
`position = "inside"`) in circular plots. The wrappers
[`syn_track_feature()`](https://loukesio.github.io/ggsynteny/reference/syn_track_geoms.md),
[`syn_track_heatmap()`](https://loukesio.github.io/ggsynteny/reference/syn_track_geoms.md),
[`syn_track_line()`](https://loukesio.github.io/ggsynteny/reference/syn_track_geoms.md)
and
[`syn_track_bar()`](https://loukesio.github.io/ggsynteny/reference/syn_track_geoms.md)
fix the geom and list only the options that geom uses; they are the
recommended spelling.

## Usage

``` r
syn_track(
  data,
  name = NULL,
  limits = c(0, 100),
  palette = NULL,
  na.value = "#BDBDBD",
  height = NULL,
  gap = NULL,
  show.legend = TRUE,
  geom = NULL,
  colour = NULL,
  linewidth = NULL,
  reference = NULL,
  baseline = limits[1],
  axis = TRUE,
  background = NULL,
  border = NULL,
  reference_line = ggplot2::element_line(colour = "#A6ADB4", linewidth = 0.25, linetype =
    "dashed"),
  position = c("outside", "inside"),
  out_of_bounds = c("error", "clip", "drop"),
  fill = NULL,
  strand = c("none", "split", "arrow"),
  label = NULL,
  label_size = 2.5,
  label_colour = "#333333",
  label_face = "plain",
  alpha = 1
)
```

## Arguments

- data:

  Data frame with one row per interval: `start` and `end` in the plot's
  coordinate units, plus the sequence keys `species`/`chr`
  (`group`/`seq_id` and `bin_id`/`seq_id` are also accepted). Keys may
  be omitted when the plot leaves no ambiguity: `species` when the plot
  shows one species, and `chr` when that species has one sequence.
  Numeric geoms read a `value` column; feature geoms read the columns
  named in `fill`, `label` and, for strand options, `strand`.

- name:

  Legend title. Defaults to `"GC (%)"` for numeric geoms and to the
  `fill` column name for features.

- limits:

  Numeric geoms only: two increasing finite numbers for the value scale,
  default 0 to 100. Non-missing values outside them error.

- palette:

  Colours. Numeric heatmaps use a gradient (colour vector, built-in ltc
  name or HCL palette name); features use one colour per category, from
  a vector named by category, an unnamed vector, an ltc name or an HCL
  palette name.

- na.value:

  Colour for a missing numeric value, or for a feature category absent
  from a named `palette`.

- height, gap:

  Lane thickness and preceding gap as fractions of linear tier spacing
  or of the original circle radius. Defaults: 0.10 and 0.03 for numeric
  geoms, 0.08 and 0.02 for features.

- show.legend:

  Show this track's legend?

- geom:

  `"feature"`, `"heatmap"`, `"line"` or `"bar"`. `NULL` (the default)
  picks `"feature"` when `fill`, `label` or a strand option is given or
  there is no `value` column, and `"heatmap"` otherwise.

- colour:

  Line/bar colour (default `"#246B78"`), or the feature outline colour
  (default `NA`, no outline).

- linewidth:

  Line thickness (default 0.5) or feature outline width (default 0.2),
  in mm.

- reference:

  Line/bar geoms: optional value for a dashed guide.

- baseline:

  Bar geom: bar origin within `limits`, default the lower limit. Use
  zero with limits spanning zero for signed measurements.

- axis:

  Line/bar geoms: label the lane edges with the limits?

- background, border:

  Lane background and boundary lines as
  [`ggplot2::element_rect()`](https://ggplot2.tidyverse.org/reference/element.html)
  /
  [`ggplot2::element_line()`](https://ggplot2.tidyverse.org/reference/element.html),
  or `element_blank()`. `NULL` gives a light grey background and borders
  for lines and bars, and none for heatmaps and features.

- reference_line:

  Style of the `reference` guide as
  [`ggplot2::element_line()`](https://ggplot2.tidyverse.org/reference/element.html);
  `element_blank()` hides it.

- position:

  Circular placement: `"outside"` stacks rings outward from the
  chromosome band; `"inside"` stacks them inward, shrinking the ribbons
  toward the centre to make room. Linear plots ignore this argument.

- out_of_bounds:

  Intervals extending past a displayed sequence: `"error"` (default),
  `"clip"` to the sequence bounds, or `"drop"`.

- fill:

  Feature geom: the name of a column whose values colour the intervals
  as categories (with a legend), or one fixed colour. `NULL` draws one
  neutral grey.

- strand:

  Feature geom: `"none"` fills the whole lane; `"split"` puts `+`
  intervals in the outer/upper half and `-` in the inner/lower half;
  `"arrow"` draws strand arrows. Both read a `strand` column holding
  `"+"`/`"-"`, `"plus"`/`"minus"` or `1`/`-1`; other values are
  unstranded.

- label:

  Feature geom: optional column with text written at the middle of each
  interval, following the ring in circular plots.

- label_size, label_colour, label_face:

  Feature label size in mm, colour and font face.

- alpha:

  Feature fill transparency.

## Value

An object added to a ggplot with `+`. The resulting ggplot contains
native ggplot2 layers and an independent legend per track. Its
`synteny_tracks` attribute records the displayed interval tables.

## Details

Intervals must have positive widths. Rows for groups excluded from the
plot are omitted with a warning; unknown sequences within displayed
groups error. Overlaps are drawn in input order (later rows on top);
overlapping sliding windows can instead be calculated with
[`gc_content()`](https://loukesio.github.io/ggsynteny/reference/gc_content.md)
and reduced to non-overlapping tiles. Lines support overlapping windows,
require distinct midpoints within each sequence, and break at NA values,
uncovered gaps and sequence boundaries. An isolated non-missing value is
drawn as a point. Circular lines interpolate in genomic position and
value, following the ring without joining its ends. Missing bars leave
gaps; missing heatmap values use `na.value`.

Tracks do not change gene or ribbon colours, genomic positions or
palette names. Each track owns a private aesthetic (`syn_track1`,
`syn_feature2`, ... numbered in the order added) so legends stay
independent without another package; replace a scale with
[`scale_fill_syn_heatmap()`](https://loukesio.github.io/ggsynteny/reference/scale_fill_syn_heatmap.md)
or
[`scale_fill_syn_feature()`](https://loukesio.github.io/ggsynteny/reference/scale_fill_syn_feature.md).
Linear tracks stack below genes; rows spread apart to reserve a separate
ribbon gap, and links skipping a row are shown in pieces across the
gaps. Tracks are static, including on ggiraph-enabled plots. Add tracks
before changing coordinates or applying facets.

## See also

[`syn_track_feature()`](https://loukesio.github.io/ggsynteny/reference/syn_track_geoms.md),
[`syn_track_heatmap()`](https://loukesio.github.io/ggsynteny/reference/syn_track_geoms.md),
[`syn_track_line()`](https://loukesio.github.io/ggsynteny/reference/syn_track_geoms.md),
[`syn_track_bar()`](https://loukesio.github.io/ggsynteny/reference/syn_track_geoms.md)
and
[`syn_axis()`](https://loukesio.github.io/ggsynteny/reference/syn_axis.md);
[`syn_layout()`](https://loukesio.github.io/ggsynteny/reference/syn_layout.md)
for the geometry.

## Examples

``` r
micro <- example_microsynteny_data()
values <- micro$features
# Supplied measurements (illustrative, not measured from these demo genes).
values$value <- rep(c(35, 50, 65), length.out = nrow(values))
plot_microsynteny(micro$features, micro$links) + syn_track(values)

plot_circular_microsynteny(micro$features, micro$links) +
  syn_track(values, geom = "line", position = "inside")
```
