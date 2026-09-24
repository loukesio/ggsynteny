.reference_svg <- function(v, genome_length, samples, reference, colors, ns, selected_key = NULL, identity_windows = NULL) {
  g <- .reference_geometry(v, genome_length, samples, colors, identity_windows)
  pt <- function(d) paste(paste(round(d$x, 3), round(-d$y, 3), sep = ","), collapse = " ")
  polygons <- split(g$polygons, g$polygons$group)
  paths <- lapply(polygons, function(d) {
    args <- list(points = pt(d), fill = d$fill[1], stroke = if (is.na(d$stroke[1])) "none" else d$stroke[1],
      `stroke-width` = d$width[1] * 2, `data-event` = if (d$role[1] == "event") d$data_id[1] else NULL, class = if (d$role[1] == "event") "ref-mark" else if (d$role[1] == "identity") "ref-identity-window" else NULL)
    if (d$role[1] == "identity") args <- c(args, list(`data-sample` = d$data_sample[1],
      `data-start` = d$window_start[1], `data-end` = d$window_end[1],
      `data-identity` = if (is.na(d$identity[1])) "" else d$identity[1], `data-color` = d$fill[1]))
    if (d$role[1] == "event") {
      row <- v[match(d$data_id[1], .reference_event_key(v)), , drop = FALSE]
      # A mark's tooltip identifies the actual sample even for shared event keys.
      sample <- d$data_sample[1]
      args <- c(args, list(`data-sample` = sample, `data-start` = row$start, `data-end` = row$end,
        `data-type` = .reference_labels[row$type], `data-color` = colors[[row$type]]))
    }
    if (max(sqrt(d$x^2 + d$y^2)) < 140) args[["pointer-events"]] <- "none"
    do.call(shiny::tags$polygon, c(args, list(shiny::tags$title(d$tooltip[1]))))
  })
  texts <- function(d, class) lapply(seq_len(nrow(d)), function(i)
    shiny::tags$text(x = d$x[i], y = -d$y[i], class = class, `text-anchor` = "middle", `dominant-baseline` = "middle", d$label[i]))
  selected <- NULL
  if (length(selected_key) && selected_key %in% .reference_event_key(v)) {
    row <- v[match(selected_key, .reference_event_key(v)), ]
    a <- g$angle(row$start); b <- g$angle(row$end)
    if (abs(a-b) < .025) { a <- a + .0125; b <- b - .0125 }
    selected <- shiny::tags$polygon(points = pt(.circ_ring(a, b, 132, g$outer)),
      fill = colors[[row$type]], `fill-opacity` = .10, stroke = colors[[row$type]], `stroke-opacity` = .25, `stroke-width` = .6)
  }
  lim <- max(240, g$outer + 32)
  bands <- paste(paste(g$bands$inner, g$bands$outer, sep = ":"), collapse = ",")
  shiny::tagList(shiny::div(class = "ref-coordinate-strip",
    shiny::span("REFERENCE SPAN \u00b7 ", shiny::strong(.reference_fmt(genome_length))),
    shiny::span("Curved ribbons link duplication sources to copies")),
  shiny::tags$svg(class = "reference-ring-svg", viewBox = paste(-lim, -lim, 2*lim, 2*lim), role = "img",
    `aria-label` = paste("Reference", reference, "with", length(samples), "comparison rings; read clockwise from the top."),
    `data-length` = genome_length, `data-outer` = max(g$bands$outer), `data-bands` = bands, `data-tick-radius` = 121, `data-input` = ns("event"),
    shiny::tags$title(paste("Comparisons against", reference)),
    selected, paths,
    lapply(split(g$lines, g$lines$group), function(d) shiny::tags$polyline(points = pt(d), fill = "none", stroke = d$color[1], `stroke-width` = d$width[1] * 2)),
    texts(g$ticks, "ref-tick"), texts(g$labels, "ref-ring-label"),
    shiny::tags$line(class = "ref-spoke", visibility = "hidden", stroke = .reference_style$ink, `stroke-width` = .75, `stroke-dasharray` = "2 3", `pointer-events` = "none"),
    shiny::tags$g(class = "ref-center-readout", `pointer-events` = "none", `aria-live` = "off",
      shiny::tags$text(x = 0, y = -7, class = "ref-center-main", `text-anchor` = "middle", `dominant-baseline` = "middle",
        `data-default` = .reference_fmt(genome_length), `data-base-size` = 24, .reference_fmt(genome_length)),
      shiny::tags$text(x = 0, y = 19, class = "ref-center-caption", `text-anchor` = "middle", `dominant-baseline` = "middle",
        `data-default` = paste(reference, "\u00b7 REFERENCE"), `data-base-size` = 10, paste(reference, "\u00b7 REFERENCE")))))
}

.reference_locus <- function(v, event, samples, colors, genome_length) {
  span <- max(event$end - event$start, 1000)
  lo <- max(0, event$start - max(span * 1.4, 12000)); hi <- min(genome_length, event$end + max(span * 1.4, 12000))
  x <- function(p) (p - lo) / (hi - lo) * 1000
  keys <- .reference_event_key(v); key <- .reference_event_key(event)
  rows <- lapply(seq_along(samples), function(i) {
    calls <- v[v$sample == samples[i] & v$start <= hi & v$end >= lo, , drop = FALSE]
    shapes <- lapply(seq_len(nrow(calls)), function(j) {
      r <- calls[j, ]; col <- colors[[r$type]]
      a <- max(0, x(r$start)); b <- min(1000, x(r$end))
      if (r$type %in% c("INS", "SNP")) shiny::tags$rect(x = a-2, y = 1, width = 4, height = 18, fill = col)
      else shiny::tags$rect(x = a, y = 5, width = max(1, b-a), height = 10,
        fill = if (r$type == "DEL") "#ffffff" else col, stroke = col, `stroke-width` = 1)
    })
    present <- any(v$sample == samples[i] & keys == key)
    shiny::div(class = "ref-locus-row", shiny::span(class = "ref-mono", if (length(samples)<=26) LETTERS[i] else i),
      shiny::tags$svg(viewBox = "0 0 1000 20", preserveAspectRatio = "none", role = "img", `aria-label` = paste(samples[i], "reference-coordinate window"),
        shiny::tags$rect(x = 0, y = 6, width = 1000, height = 8, fill = .reference_style$track), shapes),
      shiny::span(class = "ref-locus-state", style = paste0("color:", if (present) colors[[event$type]] else .reference_style$muted),
        if (present) .reference_labels[event$type] else "No matching call"))
  })
  shiny::tagList(
    shiny::div(class = "ref-section-heading", shiny::span("Locus view \u00b7 ", .reference_labels[event$type]),
      shiny::span(.reference_fmt(lo), " \u2013 ", .reference_fmt(hi))),
    shiny::div(class = "ref-locus", shiny::div(class = "ref-locus-row", shiny::span(class = "ref-mono", "R"),
      shiny::tags$svg(viewBox = "0 0 1000 20", preserveAspectRatio = "none", shiny::tags$rect(x = 0, y = 6, width = 1000, height = 8, fill = "#23262C")),
      shiny::span(class = "ref-locus-state", "Reference")), rows),
    shiny::p(class = "ref-small", "Read left to right along the reference window above; rows use the same positions. Marks show supplied calls. An unmarked row does not establish sequence identity."))
}
