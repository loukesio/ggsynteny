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

The package ships parsers for the outputs of the two most widely used
synteny pipelines — MCScanX [@Wang2012] collinearity files and GENESPACE
[@Lovell2022] synteny hits — plus a minimal two-table TSV format, and it
bundles a real dataset: the rice–sorghum collinearity produced by running
MCScanX on its own example data and parsing the result with the package's
own reader (\autoref{fig:macro}). Styling is first-class: every colour
argument accepts, by name, the 32 palettes of the `ltc` package
[@ltc] (vendored, so no extra dependency), sequential ramps are kept
distinct from qualitative sets so an identity ramp cannot silently become
misleading, chromosomes can be rounded into karyotype-style capsules
(via `ggforce` [@ggforce]), and `interactive = TRUE` turns any plot into a
hover-and-tooltip HTML widget through `ggiraph` [@ggiraph].

![Macro-synteny between rice and sorghum, drawn by `plot_synteny()` from
real MCScanX output bundled with the package.\label{fig:macro}](figures/rice_sorghum.png)

# Statement of need

The R ecosystem offers several routes to a synteny figure, each with a
gap that `ggsynteny` addresses. `genoPlotR` [@Guy2010] predates ggplot2
and renders through base grid graphics, which excludes the theming and
composition tools most figures are finished with today. `gggenes`
[@gggenes] draws elegant gene-arrow maps but has no concept of links
between genomes, so it cannot show homology ribbons. `gggenomes`
[@gggenomes] is powerful and general, but that generality comes as a
grammar of tracks, seqs, and feats with a correspondingly steep entry
cost for the common case. `RIdeogram` [@Hao2020] outputs SVG outside the
ggplot2 object model. Outside R, `clinker` [@Gilchrist2021] and
pyGenomeViz [@pyGenomeViz] produce excellent gene-cluster figures but
require a Python toolchain, and MCScanX's own bundled visualisers emit
static images that are hard to restyle.

`ggsynteny` targets the common case directly: from a standard pipeline
output to a publication-ready, restylable ggplot2 figure in one function
call, at either the chromosome or the gene scale. Design decisions that
usually cost users time are made explicit. Ribbons attach to the
rectangular body of a gene arrow by default so that arrowheads — the
carriers of strand information — are never covered; the
`ribbon_anchor = "full"` option switches to the whole-gene convention of
clinker and gggenomes when link coverage is the message. Defaults are
opinionated but quiet: dark chromosomes with white seams and ribbons that
carry the colour. Correctness of the input layer is tested against real
tool output; notably, developing the bundled rice–sorghum dataset
uncovered that consecutive MCScanX alignment blocks are written with no
separating blank line, a format detail that a naive parser silently
mishandles — the package's reader is regression-tested against it.

The package is aimed at researchers in comparative and evolutionary
genomics who need synteny figures for publication without adopting a new
visualisation grammar, and at instructors who need a low-friction way to
show conserved gene order in teaching. It is part of a small family of
interoperable visualisation packages — `ltc` (colour palettes) and
`ggvmap` (Voronoi treemaps) — that share palettes and conventions.

# Acknowledgements

The rice–sorghum example data are distributed with MCScanX [@Wang2012];
the bacterial moa/moe gene-cluster example derives from the author's own
comparative analyses. `ggsynteny` builds on ggplot2 [@ggplot2] and R
[@R].

# References
