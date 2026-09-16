# Circular-synteny experiment

Branch: `feature/circular-synteny`. This worktree now lives permanently at
`dev/circular-branch` inside the original ggsynteny project. Run commands from
this worktree's package root, which contains its own DESCRIPTION and README.

Open [the example gallery](index.html) for all three figures, R examples and
PDF downloads, or read the [package README](../../README.md). The generated
documentation is available locally at [docs/index.html](../../docs/index.html).

| Example | Vector PDF | Rebuild command from the package root |
|---|---|---|
| Rice and sorghum | [Chromosome synteny](../../man/figures/circular-macro.pdf) | `Rscript data-raw/circular_figures.R` |
| Demo gene cluster | [Circular microsynteny](../../man/figures/circular-micro.pdf) | `Rscript data-raw/circular_figures.R` |
| ZONMW-30, ZONMW-20, HI1 | [Three bacterial gene regions](../../man/figures/circular-bacteria.pdf) | `Rscript data-raw/circular_bacteria.R` |

The third example also rebuilds `inst/extdata/circular_bacterial_features.tsv`
and `inst/extdata/circular_bacterial_links.tsv` from the existing bacterial CSV
inputs. It contains 21 genes across four contigs and nine supplied links.
The README and worked guide describe region selection, unique feature IDs and
the absence of direct ZONMW-30–HI1 links. No homology or identity is inferred.

The branch first records the reviewed package baseline, then adds the circular
implementation. New commit messages contain no assistant trailers. The original
main worktree is preserved, including its uncommitted fixes and input examples.

The two exports use ordinary ggplot2 polygon/text layers in Cartesian coordinates
with a fixed aspect ratio. Shared helpers sample annular sectors, strand-aware
arrows and cubic Bezier ribbons. No new package dependencies are required; the
existing optional ggiraph backend supplies tooltips.

Read [the worked guide](../../vignettes/articles/circular-synteny.Rmd) for coordinate semantics, filtering,
metadata, orientation and examples. These are interval views, not an organism
similarity score or a link-count aggregation. The micro layout uses observed
feature bounds and does not infer full chromosome lengths.
