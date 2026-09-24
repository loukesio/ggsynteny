.reference_types <- c("INS", "DEL", "DUP", "INV", "SNP")
.reference_labels <- c(INS = "Insertion", DEL = "Deletion", DUP = "Duplication", INV = "Inversion", SNP = "Single-base change")
.reference_colors <- stats::setNames(syn_pal("minou", 5), .reference_types)
.reference_style <- list(paper = "#f3f5ef", ink = "#1B1D22", muted = "#6B6E76", track = "#8A8D94", line = "#DAD6CD")
.reference_palette <- function(palette) stats::setNames(syn_pal(palette, 5), .reference_types)

.reference_validate <- function(variants, genome_length) {
  .circ_scalar(genome_length, "genome_length", 1, Inf)
  v <- .circ_columns(variants, c("sample", "type", "start", "end"), "Variants")
  v$sample <- .circ_text(v$sample, "sample")
  v$type <- .circ_text(v$type, "type")
  if (any(!v$type %in% .reference_types)) stop("Variant types must be INS, DEL, DUP, INV or SNP.", call. = FALSE)
  for (key in c("start", "end")) v[[key]] <- .circ_numbers(v[[key]], key)
  if (any(v$start < 0 | v$end < v$start | v$end > genome_length))
    stop("Variant coordinates must satisfy 0 <= start <= end <= genome_length.", call. = FALSE)
  for (key in intersect(c("event_length", "source_start"), names(v))) {
    if (is.logical(v[[key]]) && all(is.na(v[[key]]))) v[[key]] <- as.numeric(v[[key]])
    if (!is.numeric(v[[key]]) || any(!is.na(v[[key]]) & (!is.finite(v[[key]]) | v[[key]] < 0)))
      stop(key, " must be non-negative numeric values or NA.", call. = FALSE)
  }
  if ("source_start" %in% names(v) && any(v$source_start + v$end - v$start > genome_length, na.rm = TRUE))
    stop("Duplication source spans must fit within the reference.", call. = FALSE)
  v
}

.reference_event_key <- function(v) {
  keys <- intersect(c("type", "start", "end", "event_length", "source_start"), names(v))
  if (!nrow(v)) return(character())
  do.call(paste, c(v[keys], sep = ":"))
}

.reference_fmt <- function(x, unit = "Mb") {
  paste0(formatC(x / if (unit == "Mb") 1e6 else if (unit == "kb") 1e3 else 1,
                format = "f", digits = if (unit == "Mb") 3 else if (unit == "kb") 1 else 0), " ", unit)
}

.reference_geometry <- function(v, genome_length, samples, colors, identity_windows = NULL) {
  identity_windows <- .reference_identity_validate(identity_windows, genome_length)
  n <- length(samples); step <- min(34, 170 / max(1, n - 1)); thick <- min(22, step * .65)
  angle <- function(x) pi / 2 - .075 - x / genome_length * (2 * pi - .15)
  radius <- function(i) 184 + (i - 1) * step
  point <- function(r, a) c(r * cos(a), r * sin(a))
  poly <- list(); lines <- list(); k <- 0L; j <- 0L; current_sample <- ""; current_start <- NA_real_; current_end <- NA_real_; current_identity <- NA_real_
  add <- function(d, fill, stroke = NA_character_, width = .3, id = "", tip = "", role = "track") {
    k <<- k + 1L
    poly[[k]] <<- transform(d, group = k, fill = fill, stroke = stroke, width = width, data_id = id, tooltip = tip, role = role, data_sample = current_sample, window_start = current_start, window_end = current_end, identity = current_identity)
  }
  line <- function(d, color, width = .5) {
    j <<- j + 1L; lines[[j]] <<- transform(d, group = j, color = color, width = width)
  }
  for (i in seq_along(samples)) add(.circ_ring(angle(0), angle(genome_length), radius(i), radius(i) + thick), "#E1E5DC")
  for (idx in seq_len(nrow(identity_windows))) {
    w <- identity_windows[idx, ]
    i <- match(w$sample, samples)
    if (is.na(i)) next
    current_sample <- w$sample; current_start <- w$start; current_end <- w$end; current_identity <- w$identity
    add(.circ_ring(angle(w$start), angle(w$end), radius(i), radius(i) + thick),
      .reference_identity_color(w$identity), id = paste0("identity-", idx),
      tip = paste(w$sample, paste0(w$start, "\u2013", w$end, " bp"),
                  if (is.na(w$identity)) "No identity score" else paste0(w$identity, "% identity; coverage not supplied"), sep = " | "), role = "identity")
  }
  current_sample <- ""; current_start <- NA_real_; current_end <- NA_real_; current_identity <- NA_real_
  breaks <- sort(unique(c(seq(0, genome_length, by = .reference_ruler_step(genome_length)), genome_length)))
  for (i in seq_len(length(breaks)-1)) add(.circ_ring(angle(breaks[i]), angle(breaks[i+1]), 140, 160), if (i %% 2) "#23262C" else "#4A4E57")
  ticks <- seq(0, genome_length, length.out = 21)[1:20]
  for (i in seq_along(ticks)) line(as.data.frame(rbind(point(139, angle(ticks[i])), point(if ((i-1) %% 4 == 0) 131 else 135, angle(ticks[i]))), col.names = c("x", "y")), .reference_style$ink, .35)
  # Fix base data.frame's generated coordinate names for the tick segments.
  lines <- lapply(lines, function(d) { names(d)[1:2] <- c("x", "y"); d })
  keys <- .reference_event_key(v)
  for (i in seq_len(nrow(v))) {
    current_sample <- v$sample[i]
    r0 <- radius(match(v$sample[i], samples)); r1 <- r0 + thick
    a <- angle(v$start[i]); b <- angle(v$end[i]); color <- colors[[v$type[i]]]
    id <- keys[i]
    tip <- paste(v$sample[i], .reference_labels[v$type[i]], paste0(v$start[i], "\u2013", v$end[i], " bp"), sep = " | ")
    if (v$type[i] == "DUP" && "source_start" %in% names(v) && !is.na(v$source_start[i]))
      tip <- paste0(tip, " | source: ", v$source_start[i], "\u2013", v$source_start[i] + v$end[i] - v$start[i],
                    " bp; copy: ", v$start[i], "\u2013", v$end[i], " bp (reference coordinates)")
    if (v$type[i] == "INS") {
      if ("event_length" %in% names(v) && !is.na(v$event_length[i]))
        tip <- paste0(tip, " | inserted length: ", v$event_length[i], " bp")
      # A capped position tick conveys an insertion without implying strand direction.
      add(.circ_ring(a + .004, a - .004, r0, r1 + 6), color, id = id, tip = tip, role = "event")
      add(.circ_ring(a + .012, a - .012, r1 + 5, r1 + 7), color, id = id, tip = tip, role = "event")
    } else if (v$type[i] == "SNP" || a == b) {
      add(.circ_ring(a + .004, a - .004, r0 - 1, r1 + 1), color, id = id, tip = tip, role = "event")
    } else {
      add(.circ_ring(a, b, r0, r1), if (v$type[i] == "DEL") .reference_style$paper else color,
          if (v$type[i] == "DEL") color else NA_character_, .6, id, tip, "event")
      if (v$type[i] == "DUP") {
        line(.circ_arc(a, b, (r0 + r1) / 2), .reference_style$paper, .65)
        if ("source_start" %in% names(v) && !is.na(v$source_start[i])) {
          src <- angle(v$source_start[i]); src_end <- angle(v$source_start[i] + v$end[i] - v$start[i])
          add(.circ_ring(src, src_end, 160, 164), color, id = id, tip = tip, role = "event")
          add(.circ_ribbon(src, src_end, a, b, 112, .85), grDevices::adjustcolor(color, .3), color, .3, id, tip, "event")
        }
      }
    }
  }
  tick_pos <- seq(0, genome_length, length.out = 6)[1:5]
  tick_labels <- data.frame(x = 121 * cos(angle(tick_pos)), y = 121 * sin(angle(tick_pos)),
    label = ifelse(tick_pos == 0, "0", if (genome_length >= 1e6) paste0(format(tick_pos / 1e6, trim = TRUE, scientific = FALSE), "M") else paste0(format(tick_pos, trim = TRUE, scientific = FALSE), " bp")))
  tags <- if (n <= 26) LETTERS[seq_len(n)] else as.character(seq_len(n))
  ring_labels <- data.frame(x = 0, y = c(150, radius(seq_len(n)) + thick/2), label = c("R", tags))
  list(polygons = do.call(rbind, poly), lines = do.call(rbind, lines), ticks = tick_labels,
       labels = ring_labels, tags = tags, outer = radius(n) + thick + 18, angle = angle,
       bands = data.frame(inner = c(140, radius(seq_len(n))), outer = c(160, radius(seq_len(n)) + thick)))
}

.reference_guide <- function(genome_length) {
  paste0("READ THE RINGS  \u00b7  Start at the top and move clockwise. There are no x/y axes; M means one million base pairs (bp).\n",
    "R is the reference; letters identify comparison genomes from inner to outer. For example, ",
    .reference_fmt(genome_length / 5), " is one fifth along this ", .reference_fmt(genome_length), " reference.\n",
    "Outlined gaps = deletions; capped ticks = insertions; split arcs = duplications; solid arcs = inversions; ticks = single-base changes.\n",
    "Arc lengths show reference spans. Insertion ticks mark positions only; their size does not indicate inserted length or direction.\n",
    "Curved ribbons connect supplied duplication source and copy positions. Colours identify variant calls independently of identity shading; overlaps may hide calls.\n",
    "More differences are not inherently better or worse. This figure does not establish a biological effect.")
}
#' Compare genomes on concentric reference-coordinate rings
#'
#' The inner ring is one reference sequence; each outer ring is a comparison
#' genome. All marks use coordinates on that same reference, not coordinates
#' on the comparison genomes. This function displays supplied variant calls;
#' it does not align sequences or infer variants. Missing marks do not establish
#' sequence identity or coverage. Overlapping intervals may obscure each other.
#'
#' @param variants Data frame with `sample`, `type`, `start`, `end`. Types are
#'   INS (insertion), DEL (deletion), DUP (duplication), INV (inversion), and
#'   SNP (single-base change). Optional `event_length` gives an insertion's
#'   supplied size; optional `source_start` gives a duplication's source position.
#'   Neither is inferred from missing values. Coordinates are zero-based reference positions
#'   in base pairs, with exclusive ends. Point events may have equal endpoints.
#' @param genome_length Length of the reference sequence in base pairs.
#' @param reference Name of the reference sequence.
#' @param sample_order Comparison genomes, from inner to outer. May include
#'   genomes with no supplied variants. One comparison gives a two-genome plot.
#' @param types Variant types to display. An empty vector hides all events.
#' @param title Optional title.
#' @param palette An ltc palette name or vector of colours.
#' @param family,mono_family Font families for prose and coordinate labels.
#'   Use IBM Plex Sans and IBM Plex Mono with [save_reference_comparison()].
#' @param identity_windows Optional data frame with `sample`, `start`, `end`,
#'   `identity` (percent, 0-100 or NA), using the same zero-based reference
#'   coordinates with exclusive ends. Windows must not overlap within a sample.
#'   Supply measured alignment identities; variant calls do not determine these.
#'   Shading uses a fixed 90-100 percent scale, with values below 90 clamped to
#'   the lightest shade. Coverage is not inferred.
#' @param interactive Add hover details for [syn_girafe()].
#' @return A ggplot, also suitable for `ggplot2::ggsave()`.
#' @examples
#' v <- data.frame(sample = c("Genome A", "Genome B"),
#'                 type = c("DEL", "SNP"), start = c(100, 700), end = c(200, 701))
#' plot_reference_comparison(v, 1000, title = "Invented teaching example")
#' @export
plot_reference_comparison <- function(variants, genome_length, reference = "Reference",
                                      sample_order = NULL, types = .reference_types,
                                      title = NULL, interactive = FALSE, palette = "minou",
                                      family = "sans", mono_family = "mono", identity_windows = NULL) {
  v <- .reference_validate(variants, genome_length)
  identity_windows <- .reference_identity_validate(identity_windows, genome_length)
  reference <- .circ_text(reference, "reference")
  if (length(reference) != 1L) stop("Supply one reference name.", call. = FALSE)
  if (is.null(sample_order)) sample_order <- unique(c(v$sample, identity_windows$sample))
  sample_order <- .circ_text(sample_order, "sample_order")
  if (!length(sample_order) || anyDuplicated(sample_order)) stop("Select at least one unique comparison genome.", call. = FALSE)
  if (anyNA(types) || any(!types %in% .reference_types)) stop("Unknown variant type.", call. = FALSE)
  .circ_logical(interactive, "interactive")
  if (interactive && !requireNamespace("ggiraph", quietly = TRUE)) stop("Install ggiraph for interactive plots.", call. = FALSE)
  v <- v[v$sample %in% sample_order & v$type %in% types, , drop = FALSE]
  colors <- .reference_palette(palette)
  identity_windows <- identity_windows[identity_windows$sample %in% sample_order, , drop = FALSE]
  g <- .reference_geometry(v, genome_length, sample_order, colors, identity_windows)
  p <- ggplot2::ggplot()
  if (interactive) p <- p + ggiraph::geom_polygon_interactive(data = g$polygons,
    ggplot2::aes(x = x, y = y, group = group, fill = fill, colour = stroke, linewidth = width, tooltip = tooltip, data_id = data_id))
  else p <- p + ggplot2::geom_polygon(data = g$polygons,
    ggplot2::aes(x = x, y = y, group = group, fill = fill, colour = stroke, linewidth = width))
  lim <- max(240, g$outer + 25)
  p <- p + ggplot2::geom_path(data = g$lines, ggplot2::aes(x = x, y = y, group = group, colour = color, linewidth = width)) +
    ggplot2::geom_text(data = g$ticks, ggplot2::aes(x = x, y = y, label = label), family = mono_family, size = 2.7, colour = .reference_style$muted) +
    ggplot2::geom_text(data = g$labels, ggplot2::aes(x = x, y = y, label = label), family = mono_family, size = 3.1) +
    ggplot2::annotation_custom(.reference_center_grob(.reference_fmt(genome_length), reference, mono_family),
      xmin = -96.8, xmax = 96.8, ymin = -40, ymax = 40) +
    ggplot2::scale_fill_identity() + ggplot2::scale_colour_identity() + ggplot2::scale_linewidth_identity() +
    ggplot2::coord_equal(xlim = c(-lim, lim), ylim = c(-lim-70, lim), clip = "off") + ggplot2::theme_void(base_family = family) +
    ggplot2::labs(title = if (is.null(title)) paste(length(sample_order), "genomes against", reference) else title,
      subtitle = paste0(reference, " \u00b7 reference span ", .reference_fmt(genome_length), "\n", paste(strwrap(paste(paste0(g$tags, " \u00b7 ", sample_order), collapse = "     "), 95), collapse = "\n")),
      caption = paste(.reference_guide(genome_length), .reference_identity_caption(identity_windows, genome_length), sep = "\n")) +
    ggplot2::theme(plot.background = ggplot2::element_rect(fill = .reference_style$paper, colour = NA),
      plot.title = ggplot2::element_text(size = 20, colour = .reference_style$ink, margin = ggplot2::margin(b = 8)),
      plot.subtitle = ggplot2::element_text(family = mono_family, size = 10, colour = .reference_style$muted),
      plot.caption = ggplot2::element_text(hjust = 0, size = 8.5, lineheight = 1.45, colour = .reference_style$muted),
      plot.margin = ggplot2::margin(25, 30, 20, 30))
  legend_x <- seq(-lim + 15, lim - 115, length.out = 5)
  # Both legend rows share the same five-column grid and text baseline.
  # A compact colour key; the detailed mark reading guide travels with the figure.
  for (i in seq_along(colors)) {
    x <- legend_x[i]
    p <- p + ggplot2::annotate("point", x = x, y = -lim - 15, shape = 15, size = 3, colour = colors[i]) +
      ggplot2::annotate("text", x = x + 14, y = -lim - 15, label = .reference_labels[i], hjust = 0, vjust = .5, size = 2.6, family = family, colour = .reference_style$ink)
  }
  labels <- c("Identity <=90%", "Identity 95%", "Identity 100%", "No identity score")
  shades <- .reference_identity_color(c(90, 95, 100, NA_real_))
  for (i in seq_along(shades)) {
    x <- legend_x[i]
    p <- p + ggplot2::annotate("point", x = x, y = -lim-45, shape = 15, size = 3, colour = shades[i]) +
      ggplot2::annotate("text", x = x + 14, y = -lim-45, label = labels[i], hjust = 0, vjust = .5, size = 2.6, family = family, colour = .reference_style$muted)
  }
  p
}

#' Save a reference comparison with the bundled IBM Plex fonts
#'
#' Exports a static plot with the same fonts as Studio. Text is embedded as
#' vector outlines in PDF. Requires the optional showtext and sysfonts packages.
#' @param plot A plot from [plot_reference_comparison()].
#' @param filename Output PDF or PNG filename.
#' @param width,height Figure dimensions in inches.
#' @param dpi PNG resolution in dots per inch.
#' @return Invisibly, the output filename.
#' @export
save_reference_comparison <- function(plot, filename, width = 11, height = 11, dpi = 300) {
  if (!requireNamespace("showtext", quietly = TRUE) || !requireNamespace("sysfonts", quietly = TRUE))
    stop("Install showtext and sysfonts to export the bundled IBM Plex fonts.", call. = FALSE)
  font_dir <- system.file("shiny", "www", "fonts", package = "ggsynteny")
  sysfonts::font_add("IBM Plex Sans", file.path(font_dir, "IBMPlexSans-Regular.ttf"))
  sysfonts::font_add("IBM Plex Mono", file.path(font_dir, "IBMPlexMono-Regular.ttf"))
  # Replace explicit layer families as well as theme text, preserving all data.
  plot <- plot + ggplot2::theme(text = ggplot2::element_text(family = "IBM Plex Sans"),
                                plot.subtitle = ggplot2::element_text(family = "IBM Plex Mono"))
  for (i in seq_along(plot$layers)) {
    if (inherits(plot$layers[[i]]$geom_params$grob, "reference_center")) {
      layer <- do.call(ggplot2::ggproto, list(NULL, plot$layers[[i]]))
      layer$geom_params <- plot$layers[[i]]$geom_params
      layer$geom_params$grob$family <- "IBM Plex Mono"
      plot$layers[[i]] <- layer
    }
    if (!is.null(plot$layers[[i]]$aes_params$family)) {
      layer <- do.call(ggplot2::ggproto, list(NULL, plot$layers[[i]]))
      layer$aes_params <- plot$layers[[i]]$aes_params
      layer$aes_params$family <- if (layer$aes_params$family %in% c("mono", "IBM Plex Mono")) "IBM Plex Mono" else "IBM Plex Sans"
      plot$layers[[i]] <- layer
    }
  }
  ext <- tolower(tools::file_ext(filename))
  if (!ext %in% c("pdf", "png")) stop("Use a .pdf or .png filename.", call. = FALSE)
  old <- showtext::showtext_opts(dpi = dpi)
  on.exit(showtext::showtext_opts(old), add = TRUE)
  if (ext == "pdf") grDevices::pdf(filename, width = width, height = height, bg = .reference_style$paper)
  else grDevices::png(filename, width = width, height = height, units = "in", res = dpi, bg = .reference_style$paper)
  on.exit(grDevices::dev.off(), add = TRUE)
  showtext::showtext_begin()
  tryCatch(print(plot), finally = showtext::showtext_end())
  invisible(filename)
}
