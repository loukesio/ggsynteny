# Fit the two centre lines in the physical size of the bounded plotting viewport.
#' @importFrom grid makeContent
#' @export
#' @noRd
makeContent.reference_center <- function(x) {
  available <- grid::convertWidth(grid::unit(1, "npc"), "inches", valueOnly = TRUE)
  children <- lapply(seq_along(x$labels), function(i) {
    size <- x$font_sizes[i]
    # Some PDF devices round font sizes. Re-measure after shrinking rather
    # than assuming glyph widths scale exactly with the requested size.
    for (attempt in seq_len(12)) {
      label <- grid::textGrob(x$labels[i], x = .5, y = c(.7, .3)[i],
        gp = grid::gpar(fontfamily = x$family, fontsize = size, col = x$colors[i]))
      measured <- grid::convertWidth(grid::grobWidth(label), "inches", valueOnly = TRUE)
      if (!is.finite(measured) || measured <= available || measured <= 0) break
      size <- size * min(.95, available / measured * .99)
    }
    label
  })
  grid::setChildren(x, do.call(grid::gList, children))
}

.reference_center_grob <- function(size, reference, family = "mono") {
  grid::gTree(labels = c(size, paste(reference, "\u00b7 REFERENCE")), family = family,
    font_sizes = c(22, 9), colors = c(.reference_style$ink, .reference_style$muted),
    cl = "reference_center")
}
