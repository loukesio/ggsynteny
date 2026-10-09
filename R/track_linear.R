# Linear genomes are bundles: labels, genes, then annotation lanes. Insert
# space for each new lane and move the link gaps intact below those bundles.
# All geometry stays in native ggplot2 layers; there are no masking rectangles.
.track_linear_reflow <- function(plot, layout, increment) {
  rows <- sort(unique(layout$sectors$y), decreasing = TRUE)
  first <- !isTRUE(layout$linear_reflow)
  label_space <- rep(layout$edge, length(rows))
  if (first) for (layer in plot$layers) {
    d <- layer$data
    if (!is.data.frame(d) || !all(c("ly", "y") %in% names(d))) next
    for (j in seq_along(rows)) {
      offsets <- abs(d$ly[d$y == rows[j]] - rows[j])
      if (length(offsets)) label_space[j] <- max(label_space[j], offsets + 0.08 * layout$unit)
    }
  }
  for (i in seq_along(plot$layers)) {
    layer <- plot$layers[[i]]
    d <- layer$data
    if (!is.data.frame(d) || !nrow(d) || !"y" %in% names(d)) next
    mapping <- layer$mapping
    params <- layer$aes_params
    ribbon_id <- intersect(c("link_id", "conn_id"), names(d))
    if (first && length(ribbon_id)) {
      d <- .track_linear_ribbons(d, ribbon_id[1], rows, layout$edge, label_space)
      mapping$group <- ggplot2::aes(group = .track_piece)$group
      if (length(params$fill) > 1L) params$fill <- d$ribbon_color
    } else if (!".track_row" %in% names(d)) {
      d$.track_row <- vapply(d$y, function(y) which.min(abs(rows - y)) - 1L, integer(1))
    }
    if (first && all(c("ly", "y") %in% names(d))) {
      d$ly <- d$y + abs(d$ly - d$y)
      if ("vjust" %in% names(d)) d$vjust <- 0
    }
    for (nm in intersect(c("y", "ly", "ymin", "ymax", "yend"), names(d)))
      d[[nm]] <- d[[nm]] - d$.track_row * increment
    plot$layers[[i]] <- .track_clone(layer, data = d, mapping = mapping, aes_params = params)
  }
  rank <- match(layout$sectors$y, rows) - 1L
  layout$sectors$y <- layout$sectors$y - rank * increment
  layout$linear_reflow <- TRUE
  limits <- plot$coordinates$limits
  limits$y[1] <- limits$y[1] - length(rows) * increment
  plot$coordinates <- .track_clone(plot$coordinates, limits = limits)
  attr(plot, "synteny_layout") <- layout
  plot
}

# Clip at a horizontal boundary, interpolating x at each new edge. Retain link
# IDs, colours and tooltips, including when a non-adjacent link spans many gaps.
.track_clip_y <- function(d, boundary, above) {
  if (!nrow(d)) return(d)
  inside <- if (above) d$y >= boundary else d$y <= boundary
  output <- list()
  previous <- nrow(d)
  for (i in seq_len(nrow(d))) {
    if (inside[i] != inside[previous]) {
      edge <- d[i, , drop = FALSE]
      fraction <- (boundary - d$y[previous]) / (d$y[i] - d$y[previous])
      edge$x <- d$x[previous] + fraction * (d$x[i] - d$x[previous])
      edge$y <- boundary
      output[[length(output) + 1L]] <- edge
    }
    if (inside[i]) output[[length(output) + 1L]] <- d[i, , drop = FALSE]
    previous <- i
  }
  if (length(output)) dplyr::bind_rows(output) else d[FALSE, , drop = FALSE]
}

.track_linear_ribbons <- function(data, id, rows, edge, label_space) {
  pieces <- list()
  for (key in unique(data[[id]])) {
    d <- data[data[[id]] == key, , drop = FALSE]
    # Within-row links stay with their genes, entirely inside the gene band.
    same <- which(vapply(rows, function(y) all(abs(d$y - y) <= edge + 1e-8), logical(1)))
    if (length(same)) {
      d$.track_row <- same[1] - 1L
      d$.track_piece <- paste(key, "row", same[1], sep = "_")
      pieces[[length(pieces) + 1L]] <- d
      next
    }
    for (j in seq_len(length(rows) - 1L)) {
      bottom <- rows[j + 1L] + edge
      top <- rows[j] - edge
      piece <- .track_clip_y(.track_clip_y(d, bottom, TRUE), top, FALSE)
      if (nrow(piece) < 3L || diff(range(piece$y)) < 1e-10) next
      # Reserve labels above the lower genome without changing endpoint x.
      new_bottom <- rows[j + 1L] + label_space[j + 1L]
      if (new_bottom >= top)
        stop("Gene labels leave no ribbon gap; increase tier_spacing or reduce label_offset.", call. = FALSE)
      piece$y <- new_bottom + (piece$y - bottom) / (top - bottom) * (top - new_bottom)
      piece$.track_row <- j
      piece$.track_piece <- paste(key, "gap", j, sep = "_")
      pieces[[length(pieces) + 1L]] <- piece
    }
  }
  if (length(pieces)) return(dplyr::bind_rows(pieces))
  data <- data[FALSE, , drop = FALSE]
  data$.track_row <- integer(); data$.track_piece <- character()
  data
}

utils::globalVariables(c(".track_piece"))
