# Circular-synteny experiment

Branch: `feature/circular-synteny`. Open `index.html` for rendered macro/micro
examples and downloadable vector PDFs. Regenerate the figures from the package
root with `Rscript data-raw/circular_figures.R`.

The branch first records the reviewed package baseline, then adds the circular
implementation. New commit messages contain no assistant trailers. The original
main worktree is preserved, including its uncommitted fixes and input examples.

The two exports use ordinary ggplot2 polygon/text layers in Cartesian coordinates
with a fixed aspect ratio. Shared helpers sample annular sectors, strand-aware
arrows and cubic Bezier ribbons. No new package dependencies are required; the
existing optional ggiraph backend supplies tooltips.

Read `vignettes/articles/circular-synteny.Rmd` for coordinate semantics, filtering,
metadata, orientation and examples. These are interval views, not an organism
similarity score or a link-count aggregation. The micro layout uses observed
feature bounds and does not infer full chromosome lengths.
