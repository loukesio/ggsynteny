#' Sector geometry of a synteny plot
#'
#' Return the layout a ggsynteny plot was drawn with, so that further
#' ggplot2 layers can be placed in genomic coordinates with [syn_project()].
#'
#' @param plot A ggplot made by [plot_synteny()], [plot_microsynteny()],
#'   [plot_circular_synteny()] or [plot_circular_microsynteny()], with or
#'   without tracks added.
#' @return A list with `type` (`"circular"` or `"linear"`) and `sectors`, a
#'   data frame with one row per displayed sequence: `group`, `seq_id`,
#'   genomic `start` and `end`, and either `theta_start`/`theta_end` (angles
#'   in radians, circular) or `x`/`y` (left end and centre line, linear).
#'   Circular layouts also report `band` (inner and outer radius of the
#'   chromosome band), `outer_edge` and `inner_edge` (the radii beyond which
#'   the next outside/inside track would be drawn). Linear layouts report
#'   `unit` (tier spacing), `half_height` of the gene band, and `lower_edge`
#'   (offset below each centre line already taken by tracks).
#' @examples
#' data(rice_sorghum)
#' p <- plot_circular_synteny(rice_sorghum, c("Rice", "Sorghum"))
#' syn_layout(p)$sectors
#' @export
syn_layout <- function(plot) {
  layout <- attr(plot, "synteny_layout", exact = TRUE)
  if (is.null(layout)) stop("plot must be made by a ggsynteny plotting function.", call. = FALSE)
  sectors <- layout$sectors
  rownames(sectors) <- NULL
  if (layout$type == "circular") {
    list(type = "circular", sectors = sectors,
         band = c(inner = layout$inner %||% 1, outer = layout$edge),
         outer_edge = layout$edge + (layout$used %||% 0),
         inner_edge = (layout$inner %||% 1) - (layout$inner_used %||% 0))
  } else {
    list(type = "linear", sectors = sectors, unit = layout$unit, half_height = layout$edge,
         lower_edge = layout$edge + (layout$used %||% 0))
  }
}

#' Project genomic positions onto a synteny plot
#'
#' Convert positions on displayed sequences to the x/y coordinates of a
#' ggsynteny plot, for adding ordinary ggplot2 layers.
#'
#' @inheritParams syn_layout
#' @param group,seq_id Sequence keys as used by the plot (species/chromosome
#'   or bin/sequence), recycled to the length of `position`.
#' @param position Genomic positions in plot units.
#' @param offset For circular plots, the radius to draw at (the chromosome
#'   band spans `band["inner"]` to `band["outer"]` from [syn_layout()]). For
#'   linear plots, the vertical distance above each sequence's centre line
#'   (negative values go below).
#' @return A data frame with `x` and `y`.
#' @examples
#' data(rice_sorghum)
#' p <- plot_circular_synteny(rice_sorghum, c("Rice", "Sorghum"))
#' xy <- syn_project(p, "Rice", "1", c(0, 20), offset = 1.1)
#' p + ggplot2::annotate("point", x = xy$x, y = xy$y)
#' @export
syn_project <- function(plot, group, seq_id, position, offset = 1) {
  layout <- attr(plot, "synteny_layout", exact = TRUE)
  if (is.null(layout)) stop("plot must be made by a ggsynteny plotting function.", call. = FALSE)
  position <- .circ_numbers(position, "position")
  n <- length(position)
  group <- rep_len(.circ_text(group, "group"), n)
  seq_id <- rep_len(.circ_text(seq_id, "seq_id"), n)
  offset <- rep_len(.circ_numbers(offset, "offset"), n)
  sectors <- layout$sectors
  index <- match(.circ_key(group, seq_id), .circ_key(sectors$group, sectors$seq_id))
  if (anyNA(index)) stop("Unknown sequence: ", paste(unique(paste(group, seq_id)[is.na(index)]), collapse = ", "), call. = FALSE)
  context <- list(sectors = sectors, circular = layout$type == "circular", lower = offset, upper = offset + 1)
  xy <- .track_project(context, index, position, 0)
  data.frame(x = xy$x, y = xy$y)
}
