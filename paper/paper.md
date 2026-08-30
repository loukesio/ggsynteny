---
title: 'ggsynteny: publication-quality macro- and micro-synteny plots for ggplot2'
tags:
  - R
  - comparative genomics
  - synteny
  - collinearity
  - data visualization
  - ggplot2
authors:
  - name: Loukas Theodosiou
    orcid: 0000-0001-6418-4652
    corresponding: true
    affiliation: 1
affiliations:
  - name: Max Planck Institute for Evolutionary Biology, Plön, Germany
    index: 1
date: 30 August 2026
bibliography: paper.bib
---

# Summary

Synteny — the conservation of gene order between genomes — is one of the
central observations of comparative genomics, and the ribbon plot that
connects chromosomes or genes across stacked genomes is its standard visual
language. `ggsynteny` is an R package that draws these figures at two
scales with two functions: `plot_synteny()` stacks any number of species as
tiers of chromosomes and connects their collinear blocks with Bézier
ribbons (macro-synteny), and `plot_microsynteny()` draws individual genes
as strand-aware arrows joined by homology ribbons whose colour can encode
percent identity (micro-synteny). Both return ordinary `ggplot2`
[@ggplot2] objects, so titles, themes, fonts, and the wider ggplot2
ecosystem apply unchanged.

The package ships parsers for the outputs of two widely used synteny
pipelines — MCScanX [@Wang2012] collinearity files and GENESPACE
[@Lovell2022] synteny hits — plus a minimal two-table TSV format, and it
bundles a real dataset: the rice–sorghum collinearity produced by running
MCScanX on its own example data and parsing the result with the package's
own reader (\autoref{fig:macro}). Every colour argument accepts, by name,
the 32 palettes of the `ltc` package [@ltc] (vendored, so no extra
dependency), chromosomes can be rounded into karyotype-style capsules (via
`ggforce` [@ggforce]), and `interactive = TRUE` turns any plot into a
hover-and-tooltip HTML widget through `ggiraph` [@ggiraph].

![Macro-synteny between rice and sorghum, drawn by `plot_synteny()` from
real MCScanX output bundled with the package.\label{fig:macro}](figures/rice_sorghum.png)

# Statement of need

Producing a publication-ready synteny figure today usually means either
accepting the static output of a pipeline's bundled visualiser or adopting
a full visualisation grammar. Researchers in comparative and evolutionary
genomics need something in between: a direct path from the files their
synteny pipeline already produces to a restylable, composable figure — at
the chromosome scale for whole-genome comparisons and at the gene scale
for cluster evolution. `ggsynteny` targets exactly this: one function call
from a standard pipeline output to a ggplot2 object, at either scale, with
styling and interactivity as arguments rather than as new frameworks to
learn. It is also aimed at instructors who need a low-friction way to show
conserved gene order in teaching.

# State of the field

The R ecosystem offers several routes to a synteny figure, each with a gap
that `ggsynteny` addresses. `genoPlotR` [@Guy2010] predates ggplot2 and
renders through base grid graphics, which excludes the theming and
composition tools most figures are finished with today. `gggenes`
[@gggenes] draws elegant gene-arrow maps but has no concept of links
between genomes, so it cannot show homology ribbons. `gggenomes`
[@gggenomes] is powerful and general, but that generality comes as a
grammar of tracks, seqs, and feats with a correspondingly steep entry cost
for the common case. `RIdeogram` [@Hao2020] outputs SVG outside the
ggplot2 object model. Outside R, `clinker` [@Gilchrist2021] and
pyGenomeViz [@pyGenomeViz] produce excellent gene-cluster figures but
require a Python toolchain, and MCScanX's own bundled visualisers emit
static images that are hard to restyle. Rather than contributing to one of
these — each of which is committed to a different rendering model or
grammar — `ggsynteny` fills the two-function, pure-ggplot2 niche between
them, and interoperates with the same upstream tools (MCScanX, GENESPACE)
they consume.

# Software design

The API is deliberately small: two plotting functions, three parsers, one
palette lister, and one interactive renderer. Design decisions that
usually cost users time are made explicit and documented:

- **Ribbon anchoring.** A gene arrow's tip carries strand information, so
  by default ribbons attach to the rectangular body only and arrowheads
  are never covered (`ribbon_anchor = "body"`); the `"full"` option
  switches to the whole-gene convention of clinker and gggenomes when
  link coverage is the message.
- **Colour semantics.** Qualitative palettes and ordered ramps are kept
  distinct: an identity ramp can only be restyled by an explicitly
  ordered palette, so a categorical palette cannot silently become a
  misleading gradient. Defaults are opinionated but quiet — dark
  chromosomes with white seams, ribbons carrying the colour.
- **Performance.** Ribbons, chromosomes, and gene arrows are each drawn
  as a single vectorised ggplot2 layer rather than one layer per polygon,
  keeping genome-scale figures responsive.
- **Input correctness.** The parsers are tested against real tool output.
  Notably, preparing the bundled rice–sorghum dataset uncovered that
  consecutive MCScanX alignment blocks are written with no separating
  blank line — a format detail a naive parser silently mishandles by
  dropping every block but the last; the reader is regression-tested
  against it.

# Research impact statement

`ggsynteny` is new software. It is in active use in the author's own
comparative analyses of bacterial gene clusters — the bundled
micro-synteny example (a molybdenum-cofactor *moa*/*moe* cluster across
bacterial strains, with per-link protein identities) derives from that
work — and it slots into an existing small family of interoperable
visualisation packages by the same author, `ltc` (colour palettes, on
CRAN) and `ggvmap` (Voronoi treemaps), that share palettes and
conventions. Its near-term significance is the removal of a recurring
friction: every group running MCScanX or GENESPACE currently re-implements
ribbon plotting or leaves the ggplot2 ecosystem to obtain it.

# AI usage disclosure

The package and this manuscript were developed with substantial assistance
from Claude (Anthropic), used as a coding and writing assistant under the
author's direction: code, documentation, and manuscript drafts were
AI-generated in an interactive session, then reviewed, tested, and edited
by the author. All design decisions, the underlying comparative-genomics
use cases, and the final content are the author's responsibility. The
package's automated test suite and `R CMD check` pass cleanly across
platforms.

# Acknowledgements

The rice–sorghum example data are distributed with MCScanX [@Wang2012];
the bacterial *moa*/*moe* gene-cluster example derives from the author's
own comparative analyses. `ggsynteny` builds on ggplot2 [@ggplot2] and R
[@R]. No specific financial support was received for the development of
this software.

# References
