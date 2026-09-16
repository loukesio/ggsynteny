# Geometry shared by the circular ggplot2 views. Angles are stored in radians.

.circ_columns <- function(x, required, label) {
  if (!is.data.frame(x)) stop(label, " must be a data frame.", call. = FALSE)
  missing <- setdiff(required, names(x))
  if (length(missing)) stop(label, " missing: ", paste(missing, collapse = ", "), call. = FALSE)
  as.data.frame(x, stringsAsFactors = FALSE)
}

.circ_text <- function(x, label) {
  x <- as.character(x)
  if (anyNA(x) || any(!nzchar(x))) stop(label, " must contain non-empty identifiers.", call. = FALSE)
  x
}

.circ_numbers <- function(x, label) {
  if (!is.numeric(x) || any(!is.finite(x))) stop(label, " must be finite numeric values.", call. = FALSE)
  x
}

.circ_scalar <- function(x, label, lower, upper) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x < lower || x > upper)
    stop(label, " must be a number between ", lower, " and ", upper, ".", call. = FALSE)
}

.circ_logical <- function(x, label) {
  if (!is.logical(x) || length(x) != 1L || is.na(x))
    stop(label, " must be TRUE or FALSE.", call. = FALSE)
}

.circ_order <- function(order, available, label) {
  if (is.null(order)) order <- unique(available)
  order <- .circ_text(order, label)
  if (!length(order) || anyDuplicated(order) || any(!order %in% available))
    stop(label, " must contain unique identifiers present in the data.", call. = FALSE)
  order
}

.circ_key <- function(group, sector) paste(nchar(group), group, sector, sep = ":")

.circ_layout <- function(sectors, group_order, gap, group_gap, start_angle, clockwise) {
  .circ_scalar(gap, "gap", 0, 180)
  .circ_scalar(group_gap, "group_gap", 0, 180)
  .circ_scalar(start_angle, "start_angle", -360, 360)
  .circ_logical(clockwise, "clockwise")
  sectors <- sectors[sectors$group_name %in% group_order, , drop = FALSE]
  numeric_sector <- suppressWarnings(as.numeric(sectors$sector_name))
  sectors <- sectors[order(match(sectors$group_name, group_order), numeric_sector,
                           sectors$sector_name), , drop = FALSE]
  spans <- sectors$end - sectors$start
  if (!nrow(sectors) || any(spans <= 0)) stop("Every sector must have a positive span.", call. = FALSE)
  last <- !duplicated(sectors$group_name, fromLast = TRUE)
  gaps <- ifelse(last, group_gap, gap)
  if (sum(gaps) >= 360) stop("Circular gaps consume the whole circle; reduce gap or group_gap.", call. = FALSE)
  widths <- (360 - sum(gaps)) * spans / sum(spans)
  offsets <- c(0, utils::head(cumsum(widths + gaps), -1))
  direction <- if (clockwise) -1 else 1
  sectors$theta_start <- (start_angle + direction * offsets) * pi / 180
  sectors$theta_end <- sectors$theta_start + direction * widths * pi / 180
  sectors$sector_id <- .circ_key(sectors$group_name, sectors$sector_name)
  rownames(sectors) <- NULL
  sectors
}

.circ_position <- function(layout, index, position) {
  layout$theta_start[index] + (position - layout$start[index]) /
    (layout$end[index] - layout$start[index]) *
    (layout$theta_end[index] - layout$theta_start[index])
}

.circ_arc <- function(start, end, radius) {
  theta <- seq(start, end, length.out = max(2L, ceiling(abs(end - start) * 60) + 1L))
  data.frame(x = radius * cos(theta), y = radius * sin(theta))
}

.circ_ring <- function(start, end, inner, outer) {
  rbind(.circ_arc(start, end, outer), .circ_arc(end, start, inner))
}

.circ_curve <- function(start, end, radius, curvature) {
  a <- radius * c(cos(start), sin(start))
  b <- radius * c(cos(end), sin(end))
  t <- seq(0, 1, length.out = 80)
  w1 <- (1 - t)^3 + 3 * (1 - t)^2 * t * (1 - curvature)
  w2 <- t^3 + 3 * (1 - t) * t^2 * (1 - curvature)
  data.frame(x = w1 * a[1] + w2 * b[1], y = w1 * a[2] + w2 * b[2])
}

.circ_ribbon <- function(a0, a1, b0, b1, radius, curvature, same_direction = FALSE) {
  # Coverage ribbons join opposite boundaries. With orientation enabled,
  # a plus block connects genomic start-to-start and end-to-end.
  if (same_direction) {
    temp <- b0
    b0 <- b1
    b1 <- temp
  }
  rbind(.circ_arc(a0, a1, radius), .circ_curve(a1, b0, radius, curvature),
        .circ_arc(b0, b1, radius), .circ_curve(b1, a0, radius, curvature))
}

.circ_arrow <- function(start, end, strand, inner, outer, head) {
  if (strand == "+") {
    body <- end - head
    rbind(.circ_arc(start, body, outer),
          data.frame(x = mean(c(inner, outer)) * cos(end), y = mean(c(inner, outer)) * sin(end)),
          .circ_arc(body, start, inner))
  } else {
    body <- start + head
    rbind(.circ_arc(end, body, outer),
          data.frame(x = mean(c(inner, outer)) * cos(start), y = mean(c(inner, outer)) * sin(start)),
          .circ_arc(body, end, inner))
  }
}

.circ_tag <- function(poly, id, fill, tooltip) {
  poly$circular_id <- id
  poly$fill_color <- unname(fill)
  poly$tooltip <- tooltip
  poly
}

.circ_labels <- function(theta, radius, label) {
  angle <- (theta * 180 / pi + 90) %% 360
  angle <- ifelse(angle > 90 & angle < 270, (angle + 180) %% 360, angle)
  data.frame(x = radius * cos(theta), y = radius * sin(theta), label = label,
             text_angle = angle, stringsAsFactors = FALSE)
}

.circ_canvas <- function(layout, title) {
  p <- ggplot2::ggplot(layout) + ggplot2::scale_fill_identity() +
    ggplot2::coord_equal(xlim = c(-1.4, 1.4), ylim = c(-1.4, 1.4), expand = FALSE, clip = "off") +
    ggplot2::theme_void() + ggplot2::theme(plot.margin = ggplot2::margin(15, 15, 15, 15))
  if (!is.null(title)) p <- p + ggplot2::ggtitle(title)
  p
}

.circ_add_polygons <- function(p, data, alpha = 1, color = NA, interactive = FALSE) {
  if (!nrow(data)) return(p)
  if (interactive) {
    p + ggiraph::geom_polygon_interactive(
      data = data, ggplot2::aes(x = x, y = y, group = circular_id, fill = fill_color,
                                tooltip = tooltip, data_id = circular_id),
      color = color, alpha = alpha, linewidth = 0.25, inherit.aes = FALSE)
  } else {
    p + ggplot2::geom_polygon(
      data = data, ggplot2::aes(x = x, y = y, group = circular_id, fill = fill_color),
      color = color, alpha = alpha, linewidth = 0.25, inherit.aes = FALSE)
  }
}

.circ_add_labels <- function(p, data, size, face = "plain") {
  if (!nrow(data)) return(p)
  p + ggplot2::geom_text(data = data,
                         ggplot2::aes(x = x, y = y, label = label, angle = text_angle),
                         size = size, fontface = face, color = "#333333", inherit.aes = FALSE)
}

.circ_group_labels <- function(layout, radius = 1.25) {
  dplyr::bind_rows(lapply(unique(layout$group_name), function(group) {
    rows <- which(layout$group_name == group)
    theta <- mean(c(layout$theta_start[rows[1]], layout$theta_end[utils::tail(rows, 1)]))
    .circ_labels(theta, radius, group)
  }))
}

.circ_interactive <- function(interactive) {
  .circ_logical(interactive, "interactive")
  if (interactive && !requireNamespace("ggiraph", quietly = TRUE))
    stop("interactive = TRUE requires the 'ggiraph' package.", call. = FALSE)
}

utils::globalVariables(c("circular_id", "fill_color", "text_angle"))
