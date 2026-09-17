# Plot micro-synteny across multiple genomes/bins

Draws gene-level synteny (microsynteny) showing individual genes as
arrows with ribbons connecting homologous genes across genomes.

## Usage

``` r
plot_microsynteny(
  features,
  links,
  bin_order = NULL,
  palette = NULL,
  tier_spacing = 6,
  gene_height = 0.35,
  arrowhead_frac = 0.18,
  contig_gap_frac = 0.04,
  curvature = 0.5,
  ribbon_anchor = "body",
  gene_radius = 0,
  gene_fill = "per_name",
  gene_palette = NULL,
  gene_color = "#333333",
  gene_alpha = 0.95,
  ribbon_fill = "identity",
  ribbon_palette = NULL,
  ribbon_alpha = 0.35,
  identity_low = "#DCEEFF",
  identity_high = "#08519C",
  label_genes = TRUE,
  label_size = 2.5,
  bin_label_size = 4.5,
  label_offset = 0.25,
  interactive = FALSE,
  title = NULL
)
```

## Arguments

- features:

  Data frame with columns: bin_id, seq_id, start, end, strand, feat_id,
  name

- links:

  Data frame with columns: feat_id_a, feat_id_b, identity (optional)

- bin_order:

  Character vector, top to bottom display order

- palette:

  A palette for the whole plot: the name of a built-in palette (all 32
  ltc palettes, e.g. `"casa_natal"` or `"minou"`; list them with
  [`syn_palettes`](https://loukesio.github.io/ggsynteny/reference/syn_palettes.md)),
  `"Okabe-Ito"`, or a vector of colors. Used for genes and ribbons
  unless `gene_palette` / `ribbon_palette` override it. With
  `ribbon_fill = "identity"`, ribbons keep their default blue ramp; pass
  an ordered palette (e.g. `"heatmap0"`) as `ribbon_palette` to restyle
  the ramp explicitly.

- tier_spacing:

  Numeric, vertical spacing between bins (default 6)

- gene_height:

  Numeric, gene arrow half-height (default 0.35)

- arrowhead_frac:

  Numeric, arrowhead size as fraction of gene length (default 0.18)

- contig_gap_frac:

  Numeric, gap between contigs as fraction of max gene size (default
  0.04)

- curvature:

  Numeric, ribbon curve strength 0-1 (default 0.5)

- ribbon_anchor:

  Where ribbons attach to a gene: `"body"` (default) anchors them to the
  rectangular body only, leaving the arrowhead free so the strand
  direction stays readable; `"full"` anchors them to the entire gene
  extent including the tip, the convention of clinker and gggenomes, so
  a fully-linked gene is visibly covered end-to-end. See Details.

- gene_radius:

  Corner radius of the gene arrows in millimetres (default 0 = crisp
  corners). Try 0.5-1 mm to soften the arrows; rounding uses ggforce.
  Not available together with `interactive = TRUE` (crisp corners are
  drawn instead, with a warning).

- gene_fill:

  Gene coloring mode: "per_name", "per_feat", or "uniform"

- gene_palette:

  Named vector of colors for genes

- gene_color:

  Gene outline color (default "#333333")

- gene_alpha:

  Gene transparency 0-1 (default 0.95)

- ribbon_fill:

  Ribbon coloring mode: "identity", "per_name", or "uniform"

- ribbon_palette:

  Named vector of colors for ribbons

- ribbon_alpha:

  Ribbon transparency 0-1 (default 0.35)

- identity_low:

  Color for low identity ribbons (default "#DCEEFF")

- identity_high:

  Color for high identity ribbons (default "#08519C")

- label_genes:

  Logical, show gene name labels (default TRUE)

- label_size:

  Gene label size (default 2.5)

- bin_label_size:

  Bin label size (default 4.5)

- label_offset:

  Vertical offset for gene labels (default 0.25)

- interactive:

  Logical; make genes and ribbons interactive (hover highlight and
  tooltips) using ggiraph? Render the result with
  [`syn_girafe()`](https://loukesio.github.io/ggsynteny/reference/syn_girafe.md).
  Default `FALSE`.

- title:

  Optional plot title

## Value

A ggplot2 object (pass to
[`syn_girafe()`](https://loukesio.github.io/ggsynteny/reference/syn_girafe.md)
to render an interactive widget when `interactive = TRUE`)

## Details

**Input Requirements:**

The `features` data frame must contain:

- bin_id: genome/bin name (used as row label)

- seq_id: contig/chromosome (for grouping)

- start: gene start position (bp)

- end: gene end position (bp)

- strand: "+" or "-"

- feat_id: unique gene identifier

- name: gene name (for labels and coloring)

The `links` data frame must contain:

- feat_id_a: gene in top genome

- feat_id_b: gene in bottom genome

- identity: optional 0-100 (for ribbon color intensity)

**Ribbon anchoring (ribbon_anchor):**

A gene arrow has a rectangular body and a pointed tip. With
`ribbon_anchor = "body"` (the default), ribbons attach to the body only
— the tip stays clear of every ribbon, so strand direction remains
readable even under dense links, at the cost that a fully-linked gene is
not covered wall-to-wall. With `ribbon_anchor = "full"`, ribbons span
the entire gene including the tip — the convention of clinker, gggenomes
and pyGenomeViz — which reads as "this whole gene is part of the link"
but lets ribbons run underneath the arrowheads.

## Examples

``` r
if (FALSE) { # \dontrun{
# See demo_microsynteny() for example data
p <- plot_microsynteny(features, links,
                       bin_order = c("ZONMW-30", "ZONMW-20", "ZONMW-10"),
                       gene_fill = "per_name",
                       ribbon_fill = "identity")
} # }
```
