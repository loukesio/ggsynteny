#' Add a coordinate-aligned annotation track to a synteny plot
#'
#' Add with `p + syn_track(data)` to any of the four synteny plotting functions.
#' Choose heatmap tiles, a line graph, or interval bars below each linear
#' chromosome/contig or in an outer circular ring. Linear genome rows expand
#' automatically, keeping ribbons in separate gaps. Circular additions stack outward.
#'
#' @param data Data frame with `group`, `seq_id`, `start`, `end`, and numeric
#'   `value`. `group` identifies a species (macro) or bin (micro). The key pairs
#'   `species`/`chr` and `bin_id`/`seq_id` are also accepted. Coordinates must
#'   use exactly the same origin and units as the underlying plot.
#' @param name Legend title.
#' @param limits Two increasing finite numbers for the value scale. Defaults
#'   to GC percentages, 0 to 100. Non-missing values outside these limits error.
#' @param palette Color vector, built-in ltc name, or HCL palette name.
#' @param na.value Color for an explicitly missing value (`NA`). Omitted
#'   intervals leave gaps; they are not interpreted as zero.
#' @param height,gap Track thickness and preceding gap, as fractions of linear
#'   tier spacing or of the original circle radius. Both layouts default to
#'   the same proportions. Linear rows expand to accommodate all tracks.
#' @param show.legend Show this track's legend?
#' @param geom Track display: `"heatmap"` (default), `"line"`, or `"bar"`.
#'   Lines join interval midpoints in genomic order; bars span each interval.
#' @param colour Fixed color for line or bar tracks. Heatmaps use `palette`.
#' @param linewidth Line thickness in mm for line tracks.
#' @param reference Optional value for a dashed guide in line/bar tracks.
#'   Use `NULL` (the default) to remove the middle guide.
#' @param background Track background as a [ggplot2::element_rect()].
#'   Use `element_blank()` for no background. `NULL` selects a light grey
#'   background for lines/bars and no background for heatmaps.
#' @param border Track boundary lines as a [ggplot2::element_line()].
#'   Use `element_blank()` for no borders. `NULL` selects light grey
#'   borders for lines/bars and no borders for heatmaps.
#' @param reference_line Reference guide style as a [ggplot2::element_line()].
#'   Use `element_blank()` to hide it, even when `reference` is supplied.
#' @param baseline Bar origin, within `limits`. Defaults to the lower limit.
#'   Use zero with limits spanning zero for signed measurements.
#' @param axis Show limit labels alongside line/bar tracks? Their lower/inner
#'   edge represents the lower limit, and upper/outer edge the upper limit.
#' @return An object added to a ggplot with `+`. The resulting ggplot contains
#'   native ggplot2 layers and an independent legend per track.
#'   Its `synteny_tracks` attribute records displayed interval tables.
#' @details Track intervals must have positive widths within displayed sequence
#'   bounds. Rows for groups excluded from the plot are omitted with a warning;
#'   unknown sequences within displayed groups error. Overlaps are drawn in
#'   input order (later rows on top); overlapping sliding windows can instead
#'   be calculated with [gc_content()] and reduced to non-overlapping tiles.
#'   Lines support overlapping windows, require distinct midpoints within each
#'   sequence, and break at NA values, uncovered gaps, and sequence boundaries.
#'   An isolated non-missing value is drawn as a point. Circular lines interpolate
#'   in genomic position and value, following the ring without joining its ends.
#'   Missing bars leave gaps; missing heatmap values use `na.value`.
#'
#'   Tracks do not change gene or ribbon colors, genomic positions or palette names.
#'   Linear tracks stack below genes; labels sit above genes. Rows spread apart
#'   to reserve a separate ribbon gap. Links skipping a row are shown in pieces
#'   across the gaps, never through intervening tracks. Their genomic positions
#'   and identities are retained. Circular layouts are unchanged.
#'   Heatmaps have separate aesthetics (`syn_track1`, `syn_track2`, ...),
#'   allowing independent legends without another package. Customize heatmap
#'   colors with [scale_fill_syn_track()]. Line/bar limits control geometry;
#'   specify them in `syn_track()`, not a global ggplot2 y scale. Tracks are static, including when
#'   added to a ggiraph-enabled plot; existing interactive layers still work.
#'   Add tracks before changing coordinates or applying facets. Faceting and
#'   transformed/replaced coordinates are not supported for track placement.
#' @examples
#' micro <- demo_microsynteny_data()
#' values <- micro$features
#' # Supplied measurements (illustrative, not measured from these demo genes).
#' values$value <- rep(c(35, 50, 65), length.out = nrow(values))
#' plot_microsynteny(micro$features, micro$links) + syn_track(values)
#' plot_circular_microsynteny(micro$features, micro$links) + syn_track(values)
#' @export
syn_track <- function(data, name = "GC (%)", limits = c(0, 100),
                      palette = c("#F7FBFF", "#6BAED6", "#08306B"),
                      na.value = "#BDBDBD", height = 0.10, gap = 0.03,
                      show.legend = TRUE, geom = c("heatmap", "line", "bar"),
                      colour = "#246B78", linewidth = 0.5, reference = NULL,
                      baseline = limits[1], axis = TRUE,
                      background = NULL, border = NULL,
                      reference_line = ggplot2::element_line(
                        colour = "#A6ADB4", linewidth = 0.25, linetype = "dashed")) {
  geom <- match.arg(geom)
  data <- .track_intervals(data)
  if (!"value" %in% names(data) || !is.numeric(data$value) ||
      any(!is.na(data$value) & !is.finite(data$value)))
    stop("Track value must be numeric and finite, or NA.", call. = FALSE)
  .track_limits(limits)
  if (any(data$value < limits[1] | data$value > limits[2], na.rm = TRUE))
    stop("Track values fall outside limits; GC values must be percentages (0 to 100).", call. = FALSE)
  .circ_scalar(height, "height", 0.001, 1)
  .circ_scalar(gap, "gap", 0, 1)
  .circ_logical(show.legend, "show.legend")
  .circ_logical(axis, "axis")
  .circ_scalar(linewidth, "linewidth", 0.01, 10)
  .circ_scalar(baseline, "baseline", limits[1], limits[2])
  if (!is.null(reference)) .circ_scalar(reference, "reference", limits[1], limits[2])
  if (!is.character(colour) || length(colour) != 1L || is.na(colour))
    stop("colour must be one non-missing color.", call. = FALSE)
  if (!is.character(name) || length(name) != 1L || is.na(name))
    stop("name must be one string.", call. = FALSE)
  colors <- syn_pal(palette, 256, continuous = TRUE)
  grDevices::col2rgb(c(colors, na.value, colour))
  if (is.null(background)) background <- if (geom == "heatmap") ggplot2::element_blank() else
    ggplot2::element_rect(fill = "#F4F6F8", colour = NA)
  if (is.null(border)) border <- if (geom == "heatmap") ggplot2::element_blank() else
    ggplot2::element_line(colour = "#D3D9DE", linewidth = 0.25)
  for (nm in c("background", "border", "reference_line")) {
    element <- get(nm)
    expected <- if (nm == "background") "element_rect" else "element_line"
    if (!inherits(element, expected) && !inherits(element, "element_blank"))
      stop(nm, " must be a ggplot2::", expected, "() or element_blank().", call. = FALSE)
  }
  structure(list(data = data, name = name, limits = limits, palette = colors,
                 na.value = na.value, height = height, gap = gap,
                 show.legend = show.legend, geom = geom, colour = colour,
                 linewidth = linewidth, reference = reference,
                 baseline = baseline, axis = axis, background = background,
                 border = border, reference_line = reference_line), class = "syn_track")
}

#' Continuous fill scale for an annotation track
#'
#' Replace an individual heatmap's scale without changing gene or ribbon colors.
#' Line and bar value ranges are set by `limits` in [syn_track()].
#' @param track Track number in the order it was added, starting at 1.
#' @param name Legend title.
#' @param limits Two increasing finite numbers. Use the same limits supplied
#'   to [syn_track()] unless intentionally changing the displayed color range.
#' @param palette Color vector, built-in ltc name, or HCL palette name.
#' @param na.value Color for missing values.
#' @param ... Further arguments to [ggplot2::scale_fill_gradientn()], such as
#'   `breaks` and `labels`. Out-of-range values use `na.value` by default.
#' @return A ggplot2 continuous scale for the selected track.
#' @export
scale_fill_syn_track <- function(track = 1, name = "GC (%)", limits = c(0, 100),
                                 palette = c("#F7FBFF", "#6BAED6", "#08306B"),
                                 na.value = "#BDBDBD", ...) {
  .circ_scalar(track, "track", 1, .Machine$integer.max)
  if (track != floor(track)) stop("track must be an integer.", call. = FALSE)
  .track_limits(limits)
  aesthetic <- paste0("syn_track", track)
  ggplot2::scale_fill_gradientn(
    aesthetics = aesthetic, colors = syn_pal(palette, 256, continuous = TRUE),
    name = name, limits = limits, na.value = na.value,
    guide = ggplot2::guide_colourbar(available_aes = aesthetic, order = min(track, 98)), ...)
}

.track_limits <- function(limits) {
  if (!is.numeric(limits) || length(limits) != 2L || any(!is.finite(limits)) ||
      limits[2] <= limits[1]) stop("limits must be two increasing finite numbers.", call. = FALSE)
}

.track_keys <- function(data) {
  if (!is.data.frame(data)) stop("Track data must be a data frame.", call. = FALSE)
  data <- as.data.frame(data)
  if (!all(c("group", "seq_id") %in% names(data))) {
    if (all(c("species", "chr") %in% names(data))) {
      data$group <- data$species
      data$seq_id <- data$chr
    } else if (all(c("bin_id", "seq_id") %in% names(data))) {
      data$group <- data$bin_id
    } else stop("Supply group/seq_id, species/chr, or bin_id/seq_id keys.", call. = FALSE)
  }
  data$group <- .circ_text(data$group, "group")
  data$seq_id <- .circ_text(data$seq_id, "seq_id")
  data
}

.track_intervals <- function(data) {
  data <- .track_keys(data)
  data <- .circ_columns(data, c("start", "end"), "Track data")
  for (nm in c("start", "end")) data[[nm]] <- .circ_numbers(data[[nm]], nm)
  if (any(data$start < 0 | data$end <= data$start))
    stop("Track intervals must have non-negative starts and positive widths.", call. = FALSE)
  data
}

.track_circular_layout <- function(layout) {
  list(type = "circular", unit = 1, edge = 1,
       sectors = data.frame(group = layout$group_name, seq_id = layout$sector_name,
                            layout[c("start", "end", "theta_start", "theta_end")]))
}

.track_clone <- function(parent, ...) {
  # ggproto retains its parent's expression: bind it in a fresh environment.
  force(parent)
  ggplot2::ggproto(NULL, parent, ...)
}

# A per-track aesthetic keeps the continuous fill scale independent of the
# existing identity fill scale. Drawing delegates to ggplot2's polygon geom.
.track_geom <- function(aesthetic) {
  defaults <- ggplot2::GeomPolygon$default_aes
  defaults[[aesthetic]] <- NA_character_
  ggplot2::ggproto(NULL, ggplot2::GeomPolygon,
    default_aes = defaults,
    draw_panel = function(data, panel_params, coord, ...) {
      data$fill <- data[[aesthetic]]
      ggplot2::GeomPolygon$draw_panel(data, panel_params, coord, ...)
    },
    draw_key = function(data, params, size) {
      if (is.null(data[[aesthetic]]) || all(is.na(data[[aesthetic]])))
        return(ggplot2::draw_key_blank(data, params, size))
      data$fill <- data[[aesthetic]]
      ggplot2::draw_key_polygon(data, params, size)
    })
}

#' @export
#' @importFrom ggplot2 ggplot_add
ggplot_add.syn_track <- function(object, plot, object_name = NULL, ...) {
  layout <- attr(plot, "synteny_layout", exact = TRUE)
  if (is.null(layout))
    stop("Add syn_track() to a plot made by a ggsynteny plotting function.", call. = FALSE)
  if (!inherits(plot$facet, "FacetNull"))
    stop("Add tracks before faceting; faceted track placement is unsupported.", call. = FALSE)
  if (!class(plot$coordinates)[1] %in% c("CoordCartesian", "CoordFixed"))
    stop("Tracks require the original Cartesian coordinates; add tracks before changing coordinates.", call. = FALSE)
  sectors <- layout$sectors
  if (anyDuplicated(.circ_key(sectors$group, sectors$seq_id)))
    stop("Track placement requires unique sequence keys in the plot.", call. = FALSE)
  data <- object$data
  keep <- data$group %in% sectors$group
  if (any(!keep)) warning(sum(!keep), " track rows omitted for groups absent from the plot.", call. = FALSE)
  data <- data[keep, , drop = FALSE]
  if (!nrow(data)) return(plot)
  index <- match(.circ_key(data$group, data$seq_id), .circ_key(sectors$group, sectors$seq_id))
  if (anyNA(index)) stop("Track references an unknown sequence in a displayed group.", call. = FALSE)
  if (any(data$start < sectors$start[index] | data$end > sectors$end[index]))
    stop("Track intervals must lie within displayed sequence bounds.", call. = FALSE)
  used <- layout$used %||% 0
  increment <- (object$height + object$gap) * layout$unit
  lower <- layout$edge + used + object$gap * layout$unit
  upper <- layout$edge + used + increment
  circular <- layout$type == "circular"
  if (!circular) {
    plot <- .track_linear_reflow(plot, layout, increment)
    layout <- attr(plot, "synteny_layout", exact = TRUE)
    sectors <- layout$sectors
    # Values still increase upward, although successive lanes stack downward.
    bounds <- -c(upper, lower)
    lower <- bounds[1]; upper <- bounds[2]
  }
  context <- list(data = data, index = index, sectors = sectors,
                  circular = circular, lower = lower, upper = upper)

  # Clone modified layers/coordinates so adding tracks never mutates a reused p.
  for (i in seq_along(plot$layers)) {
    layer <- plot$layers[[i]]
    d <- layer$data
    if (!inherits(layer$geom, "GeomText") || !is.data.frame(d)) next
    if ("track_axis" %in% names(d)) next
    if (circular && all(c("text_angle", "x", "y") %in% names(d))) {
      radius <- sqrt(d$x^2 + d$y^2)
      d$x <- d$x * (radius + increment) / radius
      d$y <- d$y * (radius + increment) / radius
    } else next
    plot$layers[[i]] <- .track_clone(layer, data = d)
  }
  coord_limits <- plot$coordinates$limits
  if (circular) {
    coord_limits$x <- coord_limits$x + c(-increment, increment)
    coord_limits$y <- coord_limits$y + c(-increment, increment)
  }
  plot$coordinates <- .track_clone(plot$coordinates, limits = coord_limits)

  tracks <- attr(plot, "synteny_tracks", exact = TRUE) %||% list()
  number <- length(tracks) + 1L
  plot <- plot + .track_layers(object, context, number)
  tracks[[number]] <- list(name = object$name, data = data, lower = lower, upper = upper,
                           geom = object$geom, limits = object$limits)
  attr(plot, "synteny_tracks") <- tracks
  layout$used <- used + increment
  attr(plot, "synteny_layout") <- layout
  plot
}

utils::globalVariables(c("track_interval", "value"))
