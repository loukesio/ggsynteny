# Plot macro-synteny across multiple species

Creates publication-quality synteny plots showing chromosomal
relationships across multiple species with flexible coloring options.

## Usage

``` r
plot_synteny(
  syn_data,
  species_order,
  palette = NULL,
  tier_spacing = 18,
  chr_fill = "per_species",
  chr_palette = NULL,
  ribbon_fill = "source_chr",
  ribbon_palette = NULL,
  ribbon_alpha = 0.3,
  curvature = 0.55,
  label_size = 2.5,
  species_label_size = 4.5,
  title = NULL
)
```

## Arguments

- syn_data:

  List containing `chromosomes` and `blocks` data frames. See
  [`example_synteny_data`](https://loukesio.github.io/ggsynteny/reference/example_synteny_data.md)
  for format.

- species_order:

  Character vector specifying species display order (top to bottom)

- palette:

  A palette for the whole plot: the name of a built-in palette (all 32
  ltc palettes, e.g. `"casa_natal"` or `"minou"`; list them with
  [`syn_palettes`](https://loukesio.github.io/ggsynteny/reference/syn_palettes.md)),
  `"Okabe-Ito"`, or a vector of colors. Used for both chromosomes and
  ribbons unless `chr_palette` / `ribbon_palette` override it.

- tier_spacing:

  Numeric, vertical spacing between species tiers (default 18)

- chr_fill:

  Chromosome coloring mode: "per_species", "uniform", "per_chr", or
  "custom"

- chr_palette:

  Color palette for chromosomes: a built-in palette name, an unnamed
  color vector, or a named vector mapping keys to colors (see Details)

- ribbon_fill:

  Ribbon coloring mode: "source_chr", "target_chr", "species_pair",
  "uniform", or "custom"

- ribbon_palette:

  Color palette for ribbons: a built-in palette name, an unnamed color
  vector, or a named vector mapping keys to colors (see Details)

- ribbon_alpha:

  Ribbon transparency (0-1, default 0.30)

- curvature:

  Ribbon curve strength (0-1, default 0.55)

- label_size:

  Chromosome label size (default 2.5)

- species_label_size:

  Species label size (default 4.5)

- title:

  Optional plot title

## Value

A ggplot2 object

## Details

**Chromosome Coloring (chr_fill):**

- "per_species" — one color per species. chr_palette = "casa_natal" or
  c("Human" = "#4477AA", ...)

- "uniform" — all chromosomes same color. chr_palette = "#E8E4DF"

- "per_chr" — one color per chromosome label. chr_palette = "casa_natal"
  or c("1" = "#4477AA", ...)

- "custom" — full control. chr_palette as named vector with
  "species\_\_chr" keys

**Ribbon Coloring (ribbon_fill):**

- "source_chr" — colored by the source (top) chromosome

- "target_chr" — colored by the target (bottom) chromosome

- "species_pair" — one color per tier gap. ribbon_palette = c("At_Vv" =
  "#3A6EA5", ...)

- "uniform" — all same color. ribbon_palette = "#6688AA"

- "custom" — per-block. ribbon_palette = vector of colors

Wherever a palette is expected, a single unnamed string is first matched
against the built-in palette names (case-insensitively, ignoring spaces,
underscores and dashes) — so `"casa_natal"`, `"Casa Natal"` and
`"casanatal"` all find the same palette. Named vectors are used as
explicit key-to-color mappings, exactly as before.

## Examples

``` r
# Load example data
syn <- example_synteny_data()
sp_order <- c("Arabidopsis", "Grape", "Rice")

# Default: per-species chromosomes + source-chr ribbons
p <- plot_synteny(syn, sp_order)

# One ltc palette for the whole plot
p <- plot_synteny(syn, sp_order, palette = "casa_natal")

# Custom colors
p <- plot_synteny(syn, sp_order,
                  chr_fill = "uniform",
                  chr_palette = "#E8E4DF",
                  ribbon_fill = "species_pair",
                  ribbon_palette = c("Arabidopsis_Grape" = "#3A6EA5",
                                     "Grape_Rice" = "#E8573A"))
```
