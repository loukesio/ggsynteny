# Track rendering is separate from validation, stacking and label placement.
# Renderers receive the same interval table and coordinate context, and return
# lists of ordinary ggplot2 layers/scales. Add future renderers at this dispatch.
.track_layers <- function(object, context, number) {
  renderer <- switch(object$geom, heatmap = .track_heatmap,
                     line = .track_line, bar = .track_bar,
                     feature = .track_feature, axis = .track_axis)
  renderer(object, context, number)
}

.track_fraction <- function(value, limits) (value - limits[1]) / diff(limits)

.track_angle <- function(context, index, position) {
  s <- context$sectors
  s$theta_start[index] + (position - s$start[index]) /
    (s$end[index] - s$start[index]) * (s$theta_end[index] - s$theta_start[index])
}

# Every renderer projects genomic positions and relative track heights through
# this mapping. Values grow upward in linear plots and outward in circles.
.track_project <- function(context, index, position, fraction) {
  height <- context$lower + fraction * (context$upper - context$lower)
  if (context$circular) {
    theta <- .track_angle(context, index, position)
    data.frame(x = height * cos(theta), y = height * sin(theta))
  } else {
    s <- context$sectors
    data.frame(x = s$x[index] + position - s$start[index], y = s$y[index] + height,
               .track_row = match(s$y[index], sort(unique(s$y), decreasing = TRUE)) - 1L)
  }
}

.track_band <- function(context, index, start, end, bottom = 0, top = 1) {
  if (context$circular) {
    angle <- .track_angle(context, index, c(start, end))
    n <- max(2L, ceiling(abs(diff(angle)) * 60) + 1L)
  } else n <- 2L
  positions <- seq(start, end, length.out = n)
  rbind(.track_project(context, index, positions, top),
        .track_project(context, index, rev(positions), bottom))
}

.track_heatmap <- function(object, context, number) {
  d <- context$data
  polygons <- dplyr::bind_rows(lapply(seq_len(nrow(d)), function(i) {
    poly <- .track_band(context, context$index[i], d$start[i], d$end[i])
    poly$track_interval <- i
    poly$value <- d$value[i]
    poly
  }))
  aesthetic <- paste0("syn_track", number)
  mapping <- ggplot2::aes(x = x, y = y, group = track_interval)
  mapping[[aesthetic]] <- ggplot2::aes(fill = value)$fill
  c(.track_frame(object, context, axes = FALSE), list(ggplot2::layer(
    data = polygons, mapping = mapping, stat = "identity", position = "identity",
    geom = .track_geom(aesthetic), inherit.aes = FALSE,
    show.legend = stats::setNames(object$show.legend, aesthetic),
    params = list(colour = NA, na.rm = FALSE)),
    scale_fill_syn_heatmap(number, object$name, object$limits, object$palette, object$na.value)))
}

# Optional lane backgrounds and boundary/reference guides use ggplot2 elements.
.track_frame <- function(object, context, axes = TRUE) {
  sectors <- context$sectors
  displayed <- sort(unique(context$index))
  background <- dplyr::bind_rows(lapply(displayed, function(j) {
    poly <- .track_band(context, j, sectors$start[j], sectors$end[j])
    poly$track_interval <- j
    poly
  }))
  result <- list()
  if (!inherits(object$background, "element_blank")) result <- list(ggplot2::geom_polygon(data = background,
    ggplot2::aes(x = x, y = y, group = track_interval),
    fill = object$background$fill %||% NA, colour = object$background$colour %||% NA,
    linewidth = object$background$linewidth %||% 0.25,
    linetype = object$background$linetype %||% "solid", inherit.aes = FALSE))
  levels <- c(object$limits, if (axes) object$reference)
  guides <- dplyr::bind_rows(lapply(seq_along(levels), function(k) {
    dplyr::bind_rows(lapply(displayed, function(j) {
      pos <- seq(sectors$start[j], sectors$end[j], length.out = if (context$circular) 400 else 2)
      d <- .track_project(context, j, pos, .track_fraction(levels[k], object$limits))
      d$track_interval <- paste(j, k)
      d$is_reference <- k > 2L
      d
    }))
  }))
  for (ref in c(FALSE, TRUE)) {
    style <- if (ref) object$reference_line else object$border
    if (inherits(style, "element_blank")) next
    d <- guides[guides$is_reference == ref, , drop = FALSE]
    if (nrow(d)) result <- c(result, list(ggplot2::geom_path(data = d,
      ggplot2::aes(x = x, y = y, group = track_interval), inherit.aes = FALSE,
      colour = style$colour %||% "black", linewidth = style$linewidth %||% 0.25,
      linetype = style$linetype %||% "solid", lineend = style$lineend %||% "butt")))
  }
  if (axes && object$axis) {
    # One axis per genome: the last displayed contig in linear layouts and
    # the first in circular layouts. Circular labels sit just inside the gap.
    groups <- sectors$group[displayed]
    axes <- displayed[!duplicated(groups, fromLast = !context$circular)]
    labels <- dplyr::bind_rows(lapply(axes, function(j) {
      if (context$circular) {
        sign <- sign(sectors$theta_end[j] - sectors$theta_start[j])
        theta <- sectors$theta_start[j] - sign * 0.025
        d <- .circ_labels(rep(theta, 2), c(context$lower, context$upper),
                           format(object$limits, trim = TRUE))
        outward <- sin(theta - d$text_angle[1] * pi / 180) > 0
        d$track_vjust <- if (outward) c(0, 1) else c(1, 0)
      } else {
        d <- .track_project(context, j, sectors$end[j], c(0, 1))
        d$label <- format(object$limits, trim = TRUE)
        d$text_angle <- 0
        d$track_vjust <- c(0, 1)
      }
      d
    }))
    labels$track_axis <- TRUE
    result <- c(result, list(ggplot2::geom_text(data = labels,
      ggplot2::aes(x = x, y = y, label = label, angle = text_angle, vjust = track_vjust),
      hjust = if (context$circular) 0.5 else -0.2, size = 2.1,
      colour = "#697680", inherit.aes = FALSE)))
  }
  result
}

# Fixed-color numerical tracks have a separate legend aesthetic, leaving all
# heatmap scales and existing gene/ribbon colors independent.
.track_key_geom <- function(base, aesthetic, target) {
  force(base); force(aesthetic); force(target)
  defaults <- base$default_aes
  defaults[[aesthetic]] <- NA_character_
  ggplot2::ggproto(NULL, base, default_aes = defaults,
    draw_panel = function(data, panel_params, coord, ...) {
      data[[target]] <- data[[aesthetic]]
      base$draw_panel(data, panel_params, coord, ...)
    },
    draw_key = function(data, params, size) {
      # An explicitly shown layer may be offered to another track's guide.
      # Unmapped custom aesthetics must not paint over that guide's key.
      if (is.null(data[[aesthetic]]) || all(is.na(data[[aesthetic]])))
        return(ggplot2::draw_key_blank(data, params, size))
      data[[target]] <- data[[aesthetic]]
      base$draw_key(data, params, size)
    })
}

.track_key_scale <- function(object, number) {
  label <- paste(format(object$limits, trim = TRUE), collapse = " to ")
  if (!is.null(object$reference) && !inherits(object$reference_line, "element_blank")) {
    style <- object$reference_line$linetype %||% "solid"
    label <- paste0(label, "; ", style, ": ", object$reference)
  }
  ggplot2::scale_colour_manual(aesthetics = paste0("syn_track_key", number),
    name = object$name, values = stats::setNames(object$colour, object$name),
    breaks = object$name, labels = label,
    guide = ggplot2::guide_legend(order = min(number, 98)))
}

.track_key_layer <- function(data, object, number, base, target, params = list()) {
  aesthetic <- paste0("syn_track_key", number)
  data$track_name <- rep(object$name, nrow(data))
  mapping <- ggplot2::aes(x = x, y = y, group = track_interval)
  mapping[[aesthetic]] <- ggplot2::aes(colour = track_name)$colour
  ggplot2::layer(data = data, mapping = mapping, stat = "identity", position = "identity",
    geom = .track_key_geom(base, aesthetic, target), inherit.aes = FALSE,
    show.legend = stats::setNames(object$show.legend, aesthetic), params = params)
}

.track_line <- function(object, context, number) {
  d <- context$data
  d$sector <- context$index
  d$midpoint <- (d$start + d$end) / 2
  d <- d[order(d$sector, d$midpoint), , drop = FALSE]
  if (anyDuplicated(d[c("sector", "midpoint")]))
    stop("Line tracks require distinct window midpoints within each sequence.", call. = FALSE)
  paths <- list(); points <- list(); id <- 0L
  for (j in unique(d$sector)) {
    rows <- d[d$sector == j, , drop = FALSE]
    # Compute runs before removing NA, so missing values cannot be bridged.
    separated <- c(TRUE, rows$start[-1] > utils::head(rows$end, -1) |
                     is.na(rows$value[-1]) | is.na(utils::head(rows$value, -1)))
    rows$run <- cumsum(separated)
    rows <- rows[!is.na(rows$value), , drop = FALSE]
    for (run in unique(rows$run)) {
      r <- rows[rows$run == run, , drop = FALSE]
      id <- id + 1L
      if (nrow(r) == 1L) {
        xy <- .track_project(context, j, r$midpoint, .track_fraction(r$value, object$limits))
        xy$track_interval <- id
        points[[length(points) + 1L]] <- xy
      } else {
        xy <- dplyr::bind_rows(lapply(seq_len(nrow(r) - 1L), function(i) {
          # Interpolate before projection: straight Cartesian chords would
          # cut across the inner edge of a circular lane for sparse windows.
          n <- if (context$circular) max(2L, ceiling(abs(diff(.track_angle(
            context, j, r$midpoint[c(i, i + 1L)]))) * 180) + 1L) else 2L
          .track_project(context, j, seq(r$midpoint[i], r$midpoint[i + 1L], length.out = n),
            .track_fraction(seq(r$value[i], r$value[i + 1L], length.out = n), object$limits))
        }))
        xy$track_interval <- id
        paths[[length(paths) + 1L]] <- xy
      }
    }
  }
  result <- .track_frame(object, context)
  if (length(paths)) result <- c(result, list(.track_key_layer(dplyr::bind_rows(paths),
    object, number, ggplot2::GeomPath, "colour", list(linewidth = object$linewidth))))
  if (length(points)) result <- c(result, list(.track_key_layer(dplyr::bind_rows(points),
    object, number, ggplot2::GeomPoint, "colour", list(size = max(1, object$linewidth * 2)))))
  if (length(paths) || length(points)) c(result, list(.track_key_scale(object, number))) else result
}

.track_bar <- function(object, context, number) {
  d <- context$data
  base <- .track_fraction(object$baseline, object$limits)
  polygons <- dplyr::bind_rows(lapply(which(!is.na(d$value)), function(i) {
    poly <- .track_band(context, context$index[i], d$start[i], d$end[i], base,
                        .track_fraction(d$value[i], object$limits))
    poly$track_interval <- i
    poly
  }))
  result <- .track_frame(object, context)
  if (nrow(polygons)) result <- c(result, list(.track_key_layer(polygons,
    object, number, ggplot2::GeomPolygon, "fill", list(colour = NA))))
  if (nrow(polygons)) c(result, list(.track_key_scale(object, number))) else result
}

utils::globalVariables(c("track_name", "track_vjust"))

# Points along one lane edge between two genomic positions, densified on rings.
.track_edge <- function(context, index, from, to, fraction) {
  if (context$circular) {
    angle <- .track_angle(context, index, c(from, to))
    n <- max(2L, ceiling(abs(diff(angle)) * 60) + 1L)
  } else n <- 2L
  .track_project(context, index, seq(from, to, length.out = n), fraction)
}

# A strand-aware arrow spanning [start, end] in the lane [bottom, top].
.track_arrow <- function(context, index, start, end, strand, bottom, top, head) {
  middle <- (bottom + top) / 2
  if (strand == "+") {
    body <- max(start, end - head)
    rbind(.track_edge(context, index, start, body, top),
          .track_project(context, index, end, middle),
          .track_edge(context, index, body, start, bottom))
  } else {
    body <- min(end, start + head)
    rbind(.track_edge(context, index, end, body, top),
          .track_project(context, index, start, middle),
          .track_edge(context, index, body, end, bottom))
  }
}

# Legend-only layer: draws nothing, but offers polygon keys for a manual scale
# on a private aesthetic so existing identity fills stay untouched.
.syn_key_layers <- function(aesthetic, colours, name, alpha = 1, anchor, order = 99) {
  force(aesthetic); force(alpha)
  d <- data.frame(x = rep(anchor$x[1], length(colours)), y = rep(anchor$y[1], length(colours)),
                  track_key = names(colours), stringsAsFactors = FALSE)
  mapping <- ggplot2::aes(x = x, y = y)
  mapping[[aesthetic]] <- ggplot2::aes(fill = track_key)$fill
  defaults <- ggplot2::aes()
  defaults[[aesthetic]] <- NA_character_
  geom <- ggplot2::ggproto(NULL, ggplot2::GeomBlank, default_aes = defaults,
    required_aes = c("x", "y"),
    draw_key = function(data, params, size) {
      data$fill <- data[[aesthetic]]
      data$alpha <- alpha
      data$colour <- NA
      data$linewidth <- data$linewidth %||% 0.5
      data$linetype <- data$linetype %||% 1
      ggplot2::draw_key_polygon(data, params, size)
    })
  list(ggplot2::layer(data = d, mapping = mapping, stat = "identity", position = "identity",
                      geom = geom, inherit.aes = FALSE,
                      show.legend = stats::setNames(TRUE, aesthetic), params = list()),
       ggplot2::scale_fill_manual(aesthetics = aesthetic, values = colours, breaks = names(colours),
                                  name = name, guide = ggplot2::guide_legend(order = order)))
}

# Normalize strand notation to "+", "-" or NA (unstranded).
.track_strand <- function(x) {
  x <- tolower(trimws(as.character(x)))
  out <- rep(NA_character_, length(x))
  out[x %in% c("+", "plus", "1", "forward", "fwd")] <- "+"
  out[x %in% c("-", "minus", "-1", "reverse", "rev")] <- "-"
  out
}

.track_feature <- function(object, context, number) {
  d <- context$data
  s <- context$sectors
  strand <- if (object$strand == "none") rep(NA_character_, nrow(d)) else .track_strand(d$strand)
  # Lane bounds: split puts + above/outside and - below/inside.
  bottom <- rep(0, nrow(d)); top <- rep(1, nrow(d))
  if (object$strand == "split") {
    bottom[!is.na(strand) & strand == "+"] <- 0.55
    top[!is.na(strand) & strand == "-"] <- 0.45
  }
  span <- s$end[context$index] - s$start[context$index]
  head <- pmin(0.4 * (d$end - d$start), 0.012 * span)
  polygons <- dplyr::bind_rows(lapply(seq_len(nrow(d)), function(i) {
    j <- context$index[i]
    poly <- if (object$strand == "arrow" && !is.na(strand[i]))
      .track_arrow(context, j, d$start[i], d$end[i], strand[i], bottom[i], top[i], head[i])
    else .track_band(context, j, d$start[i], d$end[i], bottom[i], top[i])
    poly$track_interval <- i
    poly$track_key <- d$track_key[i]
    poly
  }))
  result <- .track_frame(object, context, axes = FALSE)
  params <- list(colour = object$colour, linewidth = object$linewidth, alpha = object$alpha,
                 na.rm = FALSE)
  if (is.null(object$fill_column)) {
    params$fill <- object$fill_colour
    result <- c(result, list(ggplot2::geom_polygon(data = polygons,
      ggplot2::aes(x = x, y = y, group = track_interval), inherit.aes = FALSE,
      fill = object$fill_colour, colour = object$colour, linewidth = object$linewidth,
      alpha = object$alpha)))
  } else {
    aesthetic <- paste0("syn_feature", number)
    mapping <- ggplot2::aes(x = x, y = y, group = track_interval)
    mapping[[aesthetic]] <- ggplot2::aes(fill = track_key)$fill
    result <- c(result, list(ggplot2::layer(
      data = polygons, mapping = mapping, stat = "identity", position = "identity",
      geom = .track_geom(aesthetic), inherit.aes = FALSE,
      show.legend = stats::setNames(object$show.legend, aesthetic), params = params),
      scale_fill_syn_feature(number, object$name, object$palette, object$na.value,
                             guide = if (object$show.legend) ggplot2::guide_legend(order = min(number, 98)) else "none")))
  }
  if (!is.null(object$label_column)) {
    middle <- (d$start + d$end) / 2
    fraction <- (bottom + top) / 2
    labels <- dplyr::bind_rows(lapply(seq_len(nrow(d)), function(i) {
      xy <- .track_project(context, context$index[i], middle[i], fraction[i])
      if (context$circular) {
        theta <- .track_angle(context, context$index[i], middle[i])
        lab <- .circ_labels(theta, sqrt(xy$x^2 + xy$y^2), d$track_label[i])
      } else lab <- data.frame(x = xy$x, y = xy$y, label = d$track_label[i], text_angle = 0,
                               stringsAsFactors = FALSE)
      lab
    }))
    labels <- labels[!is.na(labels$label) & nzchar(labels$label), , drop = FALSE]
    if (nrow(labels)) {
      labels$track_axis <- TRUE
      result <- c(result, list(ggplot2::geom_text(data = labels,
        ggplot2::aes(x = x, y = y, label = label, angle = text_angle), size = object$label_size,
        colour = object$label_colour, fontface = object$label_face, inherit.aes = FALSE)))
    }
  }
  result
}

.axis_format <- function(position, unit) {
  divisor <- switch(unit %||% "none", kb = 1e3, Mb = 1e6, Gb = 1e9, 1)
  value <- position / divisor
  text <- formatC(value, format = "fg", digits = 7, big.mark = ",")
  text <- trimws(text)
  if (is.null(unit) || unit == "none") text else paste(text, unit)
}

.track_axis <- function(object, context, number) {
  s <- context$sectors
  displayed <- sort(unique(context$index))
  span <- max(s$end[displayed] - s$start[displayed])
  by <- object$by %||% diff(pretty(c(0, span), n = 8))[1]
  outward <- !context$circular || isTRUE(object$position == "outside")
  # Ticks start at the edge nearest the chromosome; labels sit beyond them.
  origin <- if (outward) 0 else 1
  tip <- if (outward) 0.4 else 0.6
  text_at <- if (outward) 0.74 else 0.26
  if (!context$circular) { origin <- 1; tip <- 0.6; text_at <- 0.26 }
  result <- list()
  if (object$line) {
    base <- dplyr::bind_rows(lapply(displayed, function(j) {
      xy <- .track_project(context, j, seq(s$start[j], s$end[j], length.out = if (context$circular) 400 else 2), origin)
      xy$track_interval <- j
      xy
    }))
    result <- c(result, list(ggplot2::geom_path(data = base, ggplot2::aes(x = x, y = y, group = track_interval),
      colour = object$colour, linewidth = object$linewidth, inherit.aes = FALSE)))
  }
  ticks <- dplyr::bind_rows(lapply(displayed, function(j) {
    at <- seq(ceiling(s$start[j] / by) * by, s$end[j], by = by)
    if (!length(at)) return(NULL)
    data.frame(sector = j, at = at)
  }))
  if (!nrow(ticks)) return(result)
  marks <- dplyr::bind_rows(lapply(seq_len(nrow(ticks)), function(i) {
    xy <- .track_project(context, ticks$sector[i], rep(ticks$at[i], 2), c(origin, tip))
    xy$track_interval <- i
    xy
  }))
  result <- c(result, list(ggplot2::geom_path(data = marks, ggplot2::aes(x = x, y = y, group = track_interval),
    colour = object$colour, linewidth = object$linewidth, lineend = "butt", inherit.aes = FALSE)))
  if (object$labels) {
    labelled <- ticks[ticks$at > s$start[ticks$sector] | isTRUE(object$label_start), , drop = FALSE]
    if (nrow(labelled)) {
      labels <- dplyr::bind_rows(lapply(seq_len(nrow(labelled)), function(i) {
        j <- labelled$sector[i]
        xy <- .track_project(context, j, labelled$at[i], text_at)
        if (context$circular) {
          .circ_labels(.track_angle(context, j, labelled$at[i]), sqrt(xy$x^2 + xy$y^2),
                       .axis_format(labelled$at[i], object$unit))
        } else data.frame(x = xy$x, y = xy$y, label = .axis_format(labelled$at[i], object$unit),
                          text_angle = 0, stringsAsFactors = FALSE)
      }))
      labels$track_axis <- TRUE
      result <- c(result, list(ggplot2::geom_text(data = labels,
        ggplot2::aes(x = x, y = y, label = label, angle = text_angle), size = object$label_size,
        colour = object$colour, inherit.aes = FALSE)))
    }
  }
  result
}

utils::globalVariables(c("track_key"))
