#' Add a genomic coordinate axis to a synteny plot
#'
#' Draw tick marks and position labels along every displayed sequence. Add
#' with `p + syn_axis()`. The axis occupies a thin lane that stacks with the
#' other tracks: outside the chromosome band of a circular plot (or inside
#' with `position = "inside"`), or below each genome in a linear plot.
#'
#' @param by Distance between ticks in plot coordinate units. `NULL` picks a
#'   round step giving about eight ticks on the longest sequence.
#' @param unit Label unit, assuming plot coordinates in base pairs: `"kb"`,
#'   `"Mb"` or `"Gb"` divide and append the unit; `NULL` prints the raw
#'   coordinate (use this when the plot already uses kilobases).
#' @param labels Print tick labels? The label at each sequence start is
#'   omitted unless `label_start = TRUE`.
#' @param label_start Also label the tick at the start of each sequence?
#' @param label_size Label text size in mm.
#' @param colour,linewidth Tick, baseline and label colour; line width in mm.
#' @param line Draw a baseline along each sequence?
#' @param height,gap Lane thickness and preceding gap, as fractions of linear
#'   tier spacing or of the original circle radius.
#' @param position Circular placement, `"outside"` or `"inside"`.
#' @return An object added to a ggplot with `+`, as for [syn_track()].
#' @examples
#' data(rice_sorghum)
#' plot_circular_synteny(rice_sorghum, c("Rice", "Sorghum"), chr_fill = "per_species") +
#'   syn_axis(by = 10, unit = NULL)
#' @seealso [syn_track()], [syn_track_feature()]
#' @export
syn_axis <- function(by = NULL, unit = NULL, labels = TRUE, label_start = FALSE,
                     label_size = 2.1, colour = "#697680", linewidth = 0.3, line = TRUE,
                     height = 0.06, gap = 0.01, position = c("outside", "inside")) {
  position <- match.arg(position)
  if (!is.null(by)) .circ_scalar(by, "by", .Machine$double.eps, Inf)
  if (!is.null(unit) && !(is.character(unit) && length(unit) == 1L && unit %in% c("kb", "Mb", "Gb", "none")))
    stop("unit must be NULL, \"kb\", \"Mb\" or \"Gb\".", call. = FALSE)
  .circ_logical(labels, "labels")
  .circ_logical(label_start, "label_start")
  .circ_logical(line, "line")
  .circ_scalar(label_size, "label_size", 0, 20)
  .circ_scalar(linewidth, "linewidth", 0, 10)
  .circ_scalar(height, "height", 0.001, 1)
  .circ_scalar(gap, "gap", 0, 1)
  grDevices::col2rgb(colour)
  structure(list(data = NULL, name = "axis", limits = c(0, 1), height = height, gap = gap,
                 show.legend = FALSE, geom = "axis", by = by, unit = unit, labels = labels,
                 label_start = label_start, label_size = label_size, colour = colour,
                 linewidth = linewidth, line = line, reference = NULL, axis = FALSE,
                 background = ggplot2::element_blank(), border = ggplot2::element_blank(),
                 reference_line = ggplot2::element_blank(), position = position,
                 out_of_bounds = "error"), class = "syn_track")
}
