#' Annotation tracks by geom
#'
#' One wrapper per track type, each calling [syn_track()] with its `geom`
#' fixed and listing only the options that type uses. Add any of them to a
#' plot with `+`, in any order; they stack as described in [syn_track()].
#'
#' @section Which one to use:
#' \describe{
#'   \item{`syn_track_feature()`}{Intervals as boxes coloured by a category:
#'     genes, regions, repeats, any annotation. Needs `start`/`end` and the
#'     columns named in `fill`, `label` and, for strand options, `strand`.
#'     `strand = "split"` separates the two strands into half lanes;
#'     `strand = "arrow"` draws gene arrows. A region band is a feature track
#'     with `fill` and `label` both set to the region column.}
#'   \item{`syn_track_heatmap()`}{One numeric `value` per interval, drawn as a
#'     colour tile on a gradient between `limits`. Best for per-gene
#'     summaries and non-overlapping windows.}
#'   \item{`syn_track_line()`}{One numeric `value` per interval, drawn as a
#'     line through the interval midpoints. Supports overlapping sliding
#'     windows; breaks at missing values, gaps and sequence boundaries.}
#'   \item{`syn_track_bar()`}{One numeric `value` per interval, drawn as a
#'     bar from `baseline` over the interval width. Use `limits` spanning zero
#'     and `baseline = 0` for signed measurements such as GC skew.}
#' }
#' Every wrapper accepts `height`, `gap`, `position`, `out_of_bounds` and
#' `show.legend`, and the sequence keys may be left out of `data` when the
#' plot leaves no ambiguity (one species, one sequence).
#'
#' @inheritParams syn_track
#' @return An object added to a ggplot with `+`; see [syn_track()].
#' @examples
#' dir <- system.file("extdata", "chloroplast", package = "ggsynteny")
#' genes <- read.csv(file.path(dir, "genes.csv"))
#' gc <- read.csv(file.path(dir, "gc_windows.csv"))
#' gc <- data.frame(start = gc$start, end = gc$start + 999,
#'                  value = 100 * gc$gc, skew = gc$skew)
#' sp <- "Arabidopsis thaliana"
#' syn <- list(chromosomes = data.frame(species = sp, chr = "plastid", size = 154478),
#'             blocks = data.frame(species1 = sp, chr1 = "plastid", start1 = 84171, end1 = 110434,
#'                                 species2 = sp, chr2 = "plastid", start2 = 128215, end2 = 154478))
#' plot_circular_synteny(syn, label_size = 0) +
#'   syn_track_feature(genes, fill = "class", strand = "split") +
#'   syn_track_line(gc, limits = c(20, 60), reference = 36.3, position = "inside",
#'                  out_of_bounds = "clip")
#' @name syn_track_geoms
NULL

#' @rdname syn_track_geoms
#' @export
syn_track_feature <- function(data, fill = NULL, palette = NULL, name = NULL,
                              strand = c("none", "split", "arrow"), label = NULL,
                              label_size = 2.5, label_colour = "#333333", label_face = "plain",
                              colour = NA, linewidth = 0.2, alpha = 1, na.value = "#BDBDBD",
                              height = 0.08, gap = 0.02, position = c("outside", "inside"),
                              out_of_bounds = c("error", "clip", "drop"), show.legend = TRUE,
                              background = ggplot2::element_blank(),
                              border = ggplot2::element_blank()) {
  syn_track(data, geom = "feature", fill = fill, palette = palette, name = name,
            strand = match.arg(strand), label = label, label_size = label_size,
            label_colour = label_colour, label_face = label_face, colour = colour,
            linewidth = linewidth, alpha = alpha, na.value = na.value, height = height, gap = gap,
            position = match.arg(position), out_of_bounds = match.arg(out_of_bounds),
            show.legend = show.legend, background = background, border = border)
}

#' @rdname syn_track_geoms
#' @export
syn_track_heatmap <- function(data, name = "GC (%)", limits = c(0, 100),
                              palette = c("#F7FBFF", "#6BAED6", "#08306B"), na.value = "#BDBDBD",
                              height = 0.10, gap = 0.03, position = c("outside", "inside"),
                              out_of_bounds = c("error", "clip", "drop"), show.legend = TRUE,
                              background = ggplot2::element_blank(),
                              border = ggplot2::element_blank()) {
  syn_track(data, geom = "heatmap", name = name, limits = limits, palette = palette,
            na.value = na.value, height = height, gap = gap, position = match.arg(position),
            out_of_bounds = match.arg(out_of_bounds), show.legend = show.legend,
            background = background, border = border)
}

#' @rdname syn_track_geoms
#' @export
syn_track_line <- function(data, name = "GC (%)", limits = c(0, 100), colour = "#246B78",
                           linewidth = 0.5, reference = NULL, axis = TRUE,
                           height = 0.10, gap = 0.03, position = c("outside", "inside"),
                           out_of_bounds = c("error", "clip", "drop"), show.legend = TRUE,
                           background = NULL, border = NULL,
                           reference_line = ggplot2::element_line(
                             colour = "#A6ADB4", linewidth = 0.25, linetype = "dashed")) {
  syn_track(data, geom = "line", name = name, limits = limits, colour = colour,
            linewidth = linewidth, reference = reference, axis = axis, height = height, gap = gap,
            position = match.arg(position), out_of_bounds = match.arg(out_of_bounds),
            show.legend = show.legend, background = background, border = border,
            reference_line = reference_line)
}

#' @rdname syn_track_geoms
#' @export
syn_track_bar <- function(data, name = "GC (%)", limits = c(0, 100), colour = "#246B78",
                          baseline = limits[1], reference = NULL, axis = TRUE,
                          height = 0.10, gap = 0.03, position = c("outside", "inside"),
                          out_of_bounds = c("error", "clip", "drop"), show.legend = TRUE,
                          background = NULL, border = NULL,
                          reference_line = ggplot2::element_line(
                            colour = "#A6ADB4", linewidth = 0.25, linetype = "dashed")) {
  syn_track(data, geom = "bar", name = name, limits = limits, colour = colour,
            baseline = baseline, reference = reference, axis = axis, height = height, gap = gap,
            position = match.arg(position), out_of_bounds = match.arg(out_of_bounds),
            show.legend = show.legend, background = background, border = border,
            reference_line = reference_line)
}

#' Discrete fill scale for a feature track
#'
#' Replace the colours of one feature track without changing gene, ribbon or
#' other track colours.
#' @param track Track number in the order it was added, starting at 1.
#' @param name Legend title.
#' @param values Colours named by category, as for [ggplot2::scale_fill_manual()].
#' @param na.value Colour for categories absent from `values`.
#' @param ... Further arguments to [ggplot2::scale_fill_manual()], such as
#'   `breaks`, `labels` or `guide`.
#' @return A ggplot2 discrete scale for the selected track.
#' @export
scale_fill_syn_feature <- function(track = 1, name = ggplot2::waiver(), values,
                                   na.value = "#BDBDBD", ...) {
  .circ_scalar(track, "track", 1, .Machine$integer.max)
  if (track != floor(track)) stop("track must be an integer.", call. = FALSE)
  aesthetic <- paste0("syn_feature", track)
  args <- list(aesthetics = aesthetic, values = values, name = name, na.value = na.value, ...)
  if (is.null(args$guide)) args$guide <- ggplot2::guide_legend(order = min(track, 98))
  do.call(ggplot2::scale_fill_manual, args)
}

utils::globalVariables(c("track_label"))
