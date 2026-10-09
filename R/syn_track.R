#' Add a coordinate-aligned annotation track to a synteny plot
#'
#' Add with `p + syn_track(data)` to any of the four synteny plotting
#' functions. A track is a table of intervals on the displayed sequences and a
#' `geom` saying how to draw what each interval carries: `"feature"` boxes
#' coloured by a category, or a `"heatmap"`, `"line"` or `"bar"` for a numeric
#' `value`. Tracks stack in the order added: below each genome in linear plots,
#' and outward from the chromosome band (or inward with `position = "inside"`)
#' in circular plots. The wrappers [syn_track_feature()], [syn_track_heatmap()],
#' [syn_track_line()] and [syn_track_bar()] fix the geom and list only the
#' options that geom uses; they are the recommended spelling.
#'
#' @param data Data frame with one row per interval: `start` and `end` in the
#'   plot's coordinate units, plus the sequence keys `species`/`chr`
#'   (`group`/`seq_id` and `bin_id`/`seq_id` are also accepted). Keys may be
#'   omitted when the plot leaves no ambiguity: `species` when the plot shows one
#'   species, and `chr` when that species has one sequence. Numeric geoms read
#'   a `value` column; feature geoms read the columns named in `fill`, `label`
#'   and, for strand options, `strand`.
#' @param name Legend title. Defaults to `"GC (%)"` for numeric geoms and to
#'   the `fill` column name for features.
#' @param limits Numeric geoms only: two increasing finite numbers for the
#'   value scale, default 0 to 100. Non-missing values outside them error.
#' @param palette Colours. Numeric heatmaps use a gradient (colour vector,
#'   built-in ltc name or HCL palette name); features use one colour per
#'   category, from a vector named by category, an unnamed vector, an ltc name
#'   or an HCL palette name.
#' @param na.value Colour for a missing numeric value, or for a feature
#'   category absent from a named `palette`.
#' @param height,gap Lane thickness and preceding gap as fractions of linear
#'   tier spacing or of the original circle radius. Defaults: 0.10 and 0.03
#'   for numeric geoms, 0.08 and 0.02 for features.
#' @param show.legend Show this track's legend?
#' @param geom `"feature"`, `"heatmap"`, `"line"` or `"bar"`. `NULL` (the
#'   default) picks `"feature"` when `fill`, `label` or a strand option is
#'   given or there is no `value` column, and `"heatmap"` otherwise.
#' @param colour Line/bar colour (default `"#246B78"`), or the feature outline
#'   colour (default `NA`, no outline).
#' @param linewidth Line thickness (default 0.5) or feature outline width
#'   (default 0.2), in mm.
#' @param reference Line/bar geoms: optional value for a dashed guide.
#' @param baseline Bar geom: bar origin within `limits`, default the lower
#'   limit. Use zero with limits spanning zero for signed measurements.
#' @param axis Line/bar geoms: label the lane edges with the limits?
#' @param background,border Lane background and boundary lines as
#'   [ggplot2::element_rect()] / [ggplot2::element_line()], or
#'   `element_blank()`. `NULL` gives a light grey background and borders for
#'   lines and bars, and none for heatmaps and features.
#' @param reference_line Style of the `reference` guide as
#'   [ggplot2::element_line()]; `element_blank()` hides it.
#' @param position Circular placement: `"outside"` stacks rings outward from
#'   the chromosome band; `"inside"` stacks them inward, shrinking the ribbons
#'   toward the centre to make room. Linear plots ignore this argument.
#' @param out_of_bounds Intervals extending past a displayed sequence:
#'   `"error"` (default), `"clip"` to the sequence bounds, or `"drop"`.
#' @param fill Feature geom: the name of a column whose values colour the
#'   intervals as categories (with a legend), or one fixed colour. `NULL`
#'   draws one neutral grey.
#' @param strand Feature geom: `"none"` fills the whole lane; `"split"` puts
#'   `+` intervals in the outer/upper half and `-` in the inner/lower half;
#'   `"arrow"` draws strand arrows. Both read a `strand` column holding
#'   `"+"`/`"-"`, `"plus"`/`"minus"` or `1`/`-1`; other values are unstranded.
#' @param label Feature geom: optional column with text written at the middle
#'   of each interval, following the ring in circular plots.
#' @param label_size,label_colour,label_face Feature label size in mm, colour
#'   and font face.
#' @param alpha Feature fill transparency.
#' @return An object added to a ggplot with `+`. The resulting ggplot contains
#'   native ggplot2 layers and an independent legend per track. Its
#'   `synteny_tracks` attribute records the displayed interval tables.
#' @details Intervals must have positive widths. Rows for groups excluded from
#'   the plot are omitted with a warning; unknown sequences within displayed
#'   groups error. Overlaps are drawn in input order (later rows on top);
#'   overlapping sliding windows can instead be calculated with [gc_content()]
#'   and reduced to non-overlapping tiles. Lines support overlapping windows,
#'   require distinct midpoints within each sequence, and break at NA values,
#'   uncovered gaps and sequence boundaries. An isolated non-missing value is
#'   drawn as a point. Circular lines interpolate in genomic position and value,
#'   following the ring without joining its ends. Missing bars leave gaps;
#'   missing heatmap values use `na.value`.
#'
#'   Tracks do not change gene or ribbon colours, genomic positions or palette
#'   names. Each track owns a private aesthetic (`syn_track1`, `syn_feature2`,
#'   ... numbered in the order added) so legends stay independent without
#'   another package; replace a scale with [scale_fill_syn_heatmap()] or
#'   [scale_fill_syn_feature()]. Linear tracks stack below genes; rows spread
#'   apart to reserve a separate ribbon gap, and links skipping a row are shown
#'   in pieces across the gaps. Tracks are static, including on ggiraph-enabled
#'   plots. Add tracks before changing coordinates or applying facets.
#' @examples
#' micro <- example_microsynteny_data()
#' values <- micro$features
#' # Supplied measurements (illustrative, not measured from these demo genes).
#' values$value <- rep(c(35, 50, 65), length.out = nrow(values))
#' plot_microsynteny(micro$features, micro$links) + syn_track(values)
#' plot_circular_microsynteny(micro$features, micro$links) +
#'   syn_track(values, geom = "line", position = "inside")
#' @seealso [syn_track_feature()], [syn_track_heatmap()], [syn_track_line()],
#'   [syn_track_bar()] and [syn_axis()]; [syn_layout()] for the geometry.
#' @export
syn_track <- function(data, name = NULL, limits = c(0, 100), palette = NULL,
                      na.value = "#BDBDBD", height = NULL, gap = NULL,
                      show.legend = TRUE, geom = NULL, colour = NULL, linewidth = NULL,
                      reference = NULL, baseline = limits[1], axis = TRUE,
                      background = NULL, border = NULL,
                      reference_line = ggplot2::element_line(
                        colour = "#A6ADB4", linewidth = 0.25, linetype = "dashed"),
                      position = c("outside", "inside"),
                      out_of_bounds = c("error", "clip", "drop"),
                      fill = NULL, strand = c("none", "split", "arrow"), label = NULL,
                      label_size = 2.5, label_colour = "#333333", label_face = "plain",
                      alpha = 1) {
  position <- match.arg(position)
  out_of_bounds <- match.arg(out_of_bounds)
  strand <- match.arg(strand)
  data <- .track_intervals(data, require_keys = FALSE)
  if (is.null(geom)) {
    categorical <- (!is.null(fill) && fill %in% names(data)) || !is.null(label) || strand != "none"
    geom <- if (categorical || !"value" %in% names(data)) "feature" else "heatmap"
  }
  geom <- match.arg(geom, c("feature", "heatmap", "line", "bar"))
  feature <- geom == "feature"
  height <- height %||% if (feature) 0.08 else 0.10
  gap <- gap %||% if (feature) 0.02 else 0.03
  .circ_scalar(height, "height", 0.001, 1)
  .circ_scalar(gap, "gap", 0, 1)
  .circ_logical(show.legend, "show.legend")
  if (!is.null(name) && (!is.character(name) || length(name) != 1L || is.na(name)))
    stop("name must be one string.", call. = FALSE)
  common <- list(data = data, height = height, gap = gap, show.legend = show.legend, geom = geom,
                 position = position, out_of_bounds = out_of_bounds, na.value = na.value)
  object <- if (feature) {
    .track_build_feature(common, fill, palette, name, strand, label, label_size, label_colour,
                         label_face, colour %||% NA, linewidth %||% 0.2, alpha,
                         background %||% ggplot2::element_blank(),
                         border %||% ggplot2::element_blank())
  } else {
    .track_build_numeric(common, name %||% "GC (%)", limits,
                         palette %||% c("#F7FBFF", "#6BAED6", "#08306B"),
                         colour %||% "#246B78", linewidth %||% 0.5, reference, baseline, axis,
                         background, border, reference_line)
  }
  structure(object, class = "syn_track")
}

.track_build_numeric <- function(common, name, limits, palette, colour, linewidth, reference,
                                 baseline, axis, background, border, reference_line) {
  data <- common$data
  geom <- common$geom
  if (!"value" %in% names(data) || !is.numeric(data$value) ||
      any(!is.na(data$value) & !is.finite(data$value)))
    stop("Track value must be numeric and finite, or NA.", call. = FALSE)
  .track_limits(limits)
  if (any(data$value < limits[1] | data$value > limits[2], na.rm = TRUE))
    stop("Track values fall outside limits; GC values must be percentages (0 to 100).", call. = FALSE)
  .circ_logical(axis, "axis")
  .circ_scalar(linewidth, "linewidth", 0.01, 10)
  .circ_scalar(baseline, "baseline", limits[1], limits[2])
  if (!is.null(reference)) .circ_scalar(reference, "reference", limits[1], limits[2])
  if (!is.character(colour) || length(colour) != 1L || is.na(colour))
    stop("colour must be one non-missing color.", call. = FALSE)
  colors <- syn_pal(palette, 256, continuous = TRUE)
  grDevices::col2rgb(c(colors, common$na.value, colour))
  if (is.null(background)) background <- if (geom == "heatmap") ggplot2::element_blank() else
    ggplot2::element_rect(fill = "#F4F6F8", colour = NA)
  if (is.null(border)) border <- if (geom == "heatmap") ggplot2::element_blank() else
    ggplot2::element_line(colour = "#D3D9DE", linewidth = 0.25)
  .track_elements(list(background = background, border = border, reference_line = reference_line),
                  c("background", "border", "reference_line"))
  c(common, list(name = name, limits = limits, palette = colors, colour = colour,
                 linewidth = linewidth, reference = reference, baseline = baseline, axis = axis,
                 background = background, border = border, reference_line = reference_line))
}

.track_build_feature <- function(common, fill, palette, name, strand, label, label_size,
                                 label_colour, label_face, colour, linewidth, alpha,
                                 background, border) {
  data <- common$data
  .circ_scalar(alpha, "alpha", 0, 1)
  .circ_scalar(linewidth, "linewidth", 0, 10)
  .circ_scalar(label_size, "label_size", 0, 20)
  if (!(length(colour) == 1L && (is.na(colour) || is.character(colour))))
    stop("colour must be NA or one color.", call. = FALSE)
  grDevices::col2rgb(c(common$na.value, label_colour, if (!is.na(colour)) colour))
  if (strand != "none") {
    if (!"strand" %in% names(data)) stop("strand = \"", strand, "\" requires a strand column.", call. = FALSE)
    if (all(is.na(.track_strand(data$strand))))
      stop("No strand values were recognised; use '+'/'-', 'plus'/'minus' or 1/-1.", call. = FALSE)
  }
  fill_column <- NULL; fill_colour <- "#6E7B85"; colors <- NULL
  if (!is.null(fill)) {
    if (!is.character(fill) || length(fill) != 1L || is.na(fill))
      stop("fill must be one column name or one color.", call. = FALSE)
    if (fill %in% names(data)) {
      fill_column <- fill
      values <- data[[fill]]
      if (anyNA(values)) stop("fill column '", fill, "' must not contain NA.", call. = FALSE)
      levels <- if (is.factor(values)) levels(values)[levels(values) %in% values]
                else unique(as.character(values))
      data$track_key <- as.character(values)
      colors <- keyed_colors(palette, levels)
      colors <- colors[levels]
      names(colors) <- levels
      colors[is.na(colors)] <- common$na.value
      grDevices::col2rgb(colors)
    } else {
      ok <- tryCatch({ grDevices::col2rgb(fill); TRUE }, error = function(e) FALSE)
      if (!ok) stop("fill must name a column of data or be a valid color.", call. = FALSE)
      fill_colour <- fill
    }
  }
  if (is.null(fill_column)) data$track_key <- rep(NA_character_, nrow(data))
  if (!is.null(label)) {
    if (!is.character(label) || length(label) != 1L || !label %in% names(data))
      stop("label must name a column of data.", call. = FALSE)
    data$track_label <- as.character(data[[label]])
  }
  .track_elements(list(background = background, border = border), c("background", "border"))
  common$data <- data
  c(common, list(name = name %||% fill_column %||% "", limits = c(0, 1), palette = colors,
                 colour = colour, linewidth = linewidth, alpha = alpha, reference = NULL,
                 fill_column = fill_column, fill_colour = fill_colour, strand = strand,
                 label_column = label, label_size = label_size, label_colour = label_colour,
                 label_face = label_face, axis = FALSE, background = background, border = border,
                 reference_line = ggplot2::element_blank()))
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
scale_fill_syn_heatmap <- function(track = 1, name = "GC (%)", limits = c(0, 100),
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

.track_keys <- function(data, require_keys = TRUE) {
  if (!is.data.frame(data)) stop("Track data must be a data frame.", call. = FALSE)
  data <- as.data.frame(data)
  if (!"group" %in% names(data)) {
    if ("species" %in% names(data)) data$group <- data$species
    else if ("bin_id" %in% names(data)) data$group <- data$bin_id
  }
  if (!"seq_id" %in% names(data) && "chr" %in% names(data)) data$seq_id <- data$chr
  missing <- setdiff(c("group", "seq_id"), names(data))
  if (length(missing) && require_keys)
    stop("Supply group/seq_id, species/chr, or bin_id/seq_id keys.", call. = FALSE)
  if ("group" %in% names(data)) data$group <- .circ_text(data$group, "group")
  if ("seq_id" %in% names(data)) data$seq_id <- .circ_text(data$seq_id, "seq_id")
  data
}

# Fill in keys a track table left out, when the plot makes them unambiguous.
.track_infer_keys <- function(data, sectors) {
  if (!"group" %in% names(data)) {
    if ("seq_id" %in% names(data)) {
      shared <- sectors$seq_id[duplicated(sectors$seq_id)]
      if (any(data$seq_id %in% shared))
        stop("Track data needs a species/group column: sequence names are shared by several groups.",
             call. = FALSE)
      owner <- sectors$group[match(data$seq_id, sectors$seq_id)]
      if (anyNA(owner))
        stop("Track references an unknown sequence: ",
             paste(unique(data$seq_id[is.na(owner)]), collapse = ", "), call. = FALSE)
      data$group <- owner
    } else {
      groups <- unique(sectors$group)
      if (length(groups) != 1L)
        stop("Track data needs a species/group column: the plot shows ", length(groups), " groups.",
             call. = FALSE)
      data$group <- rep(groups, nrow(data))
    }
  }
  if (!"seq_id" %in% names(data)) {
    # Groups absent from the plot are reported later, with the usual warning.
    counts <- table(sectors$group)
    used <- intersect(unique(data$group), names(counts))
    if (any(counts[used] != 1L))
      stop("Track data needs a chr/seq_id column: ",
           paste(used[counts[used] != 1L], collapse = ", "), " has several sequences.", call. = FALSE)
    data$seq_id <- sectors$seq_id[match(data$group, sectors$group)]
  }
  data
}

.track_intervals <- function(data, require_keys = TRUE) {
  data <- .track_keys(data, require_keys)
  data <- .circ_columns(data, c("start", "end"), "Track data")
  for (nm in c("start", "end")) data[[nm]] <- .circ_numbers(data[[nm]], nm)
  if (any(data$start < 0 | data$end <= data$start))
    stop("Track intervals must have non-negative starts and positive widths.", call. = FALSE)
  data
}

.track_circular_layout <- function(layout, inner = 1) {
  list(type = "circular", unit = 1, edge = 1, inner = inner,
       sectors = data.frame(group = layout$group_name, seq_id = layout$sector_name,
                            layout[c("start", "end", "theta_start", "theta_end")]))
}

.track_elements <- function(object, names) {
  for (nm in names) {
    element <- object[[nm]]
    expected <- if (nm == "background") "element_rect" else "element_line"
    if (!inherits(element, expected) && !inherits(element, "element_blank"))
      stop(nm, " must be a ggplot2::", expected, "() or element_blank().", call. = FALSE)
  }
}

# Restrict track intervals to the displayed sequence bounds.
.track_bounds <- function(data, sectors, index, policy) {
  lo <- sectors$start[index]; hi <- sectors$end[index]
  outside <- data$start < lo | data$end > hi
  if (!any(outside)) return(data)
  if (policy == "error")
    stop("Track intervals must lie within displayed sequence bounds; ",
         "use out_of_bounds = \"clip\" or \"drop\" to keep going.", call. = FALSE)
  if (policy == "drop") return(data[!outside, , drop = FALSE])
  data$start <- pmax(data$start, lo)
  data$end <- pmin(data$end, hi)
  data[data$end > data$start, , drop = FALSE]
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
  if (is.null(data))   # axes cover every displayed sequence
    data <- data.frame(group = sectors$group, seq_id = sectors$seq_id,
                       start = sectors$start, end = sectors$end, stringsAsFactors = FALSE)
  data <- .track_infer_keys(data, sectors)
  keep <- data$group %in% sectors$group
  if (any(!keep)) warning(sum(!keep), " track rows omitted for groups absent from the plot.", call. = FALSE)
  data <- data[keep, , drop = FALSE]
  if (!nrow(data)) return(plot)
  index <- match(.circ_key(data$group, data$seq_id), .circ_key(sectors$group, sectors$seq_id))
  if (anyNA(index)) stop("Track references an unknown sequence in a displayed group.", call. = FALSE)
  data <- .track_bounds(data, sectors, index, object$out_of_bounds %||% "error")
  if (!nrow(data)) return(plot)
  index <- match(.circ_key(data$group, data$seq_id), .circ_key(sectors$group, sectors$seq_id))
  circular <- layout$type == "circular"
  inside <- circular && identical(object$position, "inside")
  increment <- (object$height + object$gap) * layout$unit
  if (inside) {
    used <- layout$inner_used %||% 0
    inner <- layout$inner %||% 1
    if (inner - used - increment <= 0.05)
      stop("No room left inside the circle for another track; reduce height or gap.", call. = FALSE)
    upper <- inner - used - object$gap * layout$unit
    lower <- inner - used - increment
  } else {
    used <- layout$used %||% 0
    lower <- layout$edge + used + object$gap * layout$unit
    upper <- layout$edge + used + increment
  }
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
  if (inside) {
    # Ribbons attach at the current inner edge: scale them toward the centre.
    factor <- lower / (inner - used)
    for (i in seq_along(plot$layers)) {
      d <- plot$layers[[i]]$data
      if (!is.data.frame(d) || !"circular_id" %in% names(d) || !nrow(d)) next
      if (!all(grepl("^(block|link)_", d$circular_id))) next
      d$x <- d$x * factor
      d$y <- d$y * factor
      plot$layers[[i]] <- .track_clone(plot$layers[[i]], data = d)
    }
  } else {
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
  }

  tracks <- attr(plot, "synteny_tracks", exact = TRUE) %||% list()
  number <- length(tracks) + 1L
  plot <- plot + .track_layers(object, context, number)
  tracks[[number]] <- list(name = object$name, data = data, lower = lower, upper = upper,
                           geom = object$geom, limits = object$limits,
                           position = if (inside) "inside" else "outside")
  attr(plot, "synteny_tracks") <- tracks
  if (inside) layout$inner_used <- used + increment else layout$used <- used + increment
  attr(plot, "synteny_layout") <- layout
  plot
}

utils::globalVariables(c("track_interval", "value"))
