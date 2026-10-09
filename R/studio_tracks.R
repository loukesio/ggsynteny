# Annotation tracks tab: stack syn_track_*() additions and a coordinate axis
# on the figure configured in the Synteny tab, or on the bundled chloroplast
# genome ring. Every control maps onto one argument of the exported wrappers,
# and the downloaded R script reproduces the figure from the same tables.

.tracks_slots <- 3L
.tracks_geoms <- c("Feature boxes (category)" = "feature", "Heatmap (value)" = "heatmap",
                   "Line (value)" = "line", "Bar (value)" = "bar")
.tracks_reserved <- c("species", "chr", "group", "seq_id", "bin_id", "start", "end", "strand", "value")

# The published Arabidopsis chloroplast as a ready-made five-ring example.
.tracks_chloroplast <- function() {
  dir <- system.file("extdata", "chloroplast", package = "ggsynteny")
  regions <- utils::read.csv(file.path(dir, "regions.csv"))
  genes <- utils::read.csv(file.path(dir, "genes.csv"))
  windows <- utils::read.csv(file.path(dir, "gc_windows.csv"))
  pairs <- utils::read.csv(file.path(dir, "ir_pairs.csv"))
  sp <- "Arabidopsis thaliana"
  pal_class <- c("Photosystems and electron transport" = "#009E73", "ATP synthase" = "#E69F00",
                 "NADH dehydrogenase" = "#CC79A7", "Ribosomal proteins" = "#0072B2",
                 "tRNA and rRNA" = "#D55E00", "Other genes" = "#9A9A9A")
  pal_region <- c(LSC = "#E9DCC4", IRb = "#7FB3B8", SSC = "#C9B79C", IRa = "#7FB3B8")
  base <- list(
    chromosomes = data.frame(species = sp, chr = "plastid", size = 154478, stringsAsFactors = FALSE),
    blocks = data.frame(species1 = sp, chr1 = "plastid", start1 = pairs$b_start, end1 = pairs$b_end,
                        species2 = sp, chr2 = "plastid", start2 = pairs$a_start, end2 = pairs$a_end,
                        class = pairs$class, stringsAsFactors = FALSE))
  tracks <- list(
    list(id = "regions", label = "Region band (LSC, IRb, SSC, IRa)", geom = "feature",
         data = regions[c("species", "start", "end", "region")], fill = "region", label_column = "region",
         strand = "none", palette = pal_region, name = "Region", show_legend = FALSE,
         position = "outside", height = 0.07, gap = 0, label_size = 3.2),
    list(id = "axis", label = "Ticks every 10 kb", geom = "axis", by = 10000, unit = "kb",
         position = "outside", height = 0.06, gap = 0),
    list(id = "genes", label = "Genes by strand and function", geom = "feature",
         data = genes[c("species", "gene", "start", "end", "strand", "class")], fill = "class",
         strand = "split", palette = pal_class, name = "Gene function",
         position = "inside", height = 0.14, gap = 0.015),
    list(id = "gc", label = "GC content line (20-60%)", geom = "line",
         data = data.frame(species = sp, start = windows$start, end = windows$start + 999,
                           value = 100 * windows$gc),
         name = "GC (%)", limits = c(20, 60), reference = 36.3, colour = "#3B1B36",
         position = "inside", height = 0.15, gap = 0.02),
    list(id = "skew", label = "GC skew heatmap", geom = "heatmap",
         data = data.frame(species = sp, start = windows$start, end = windows$start + 999,
                           value = windows$skew),
         name = "GC skew", limits = c(-0.25, 0.25), palette = c("#B2182B", "#F7F7F7", "#2166AC"),
         position = "inside", height = 0.05, gap = 0.015))
  list(base = base, species = sp, ribbon_palette = pal_class, tracks = tracks)
}

.tracks_chloroplast_plot <- function(example, title = NULL) {
  plot_circular_synteny(example$base, example$species, ribbon_fill = "class",
                        ribbon_palette = example$ribbon_palette, ribbon_alpha = 0.55,
                        ribbon_legend = FALSE, chr_palette = "#F1EDE6", chr_color = NA,
                        track_width = 0.02, label_size = 0, species_label_size = 0,
                        group_gap = 1.5, title = title)
}

# Read an uploaded interval table: keys and categories stay text, coordinates
# and values become numbers. Nothing else is inferred.
.tracks_table <- function(path) {
  x <- .studio_table(path)
  x <- .studio_columns(x, c("start", "end"), "Track table")
  for (key in intersect(c("start", "end", "value"), names(x))) {
    value <- suppressWarnings(as.numeric(x[[key]]))
    blank <- is.na(x[[key]]) | x[[key]] %in% c("", "NA")
    if (key != "value" && any(!is.finite(value))) stop(key, " must contain valid numeric values.", call. = FALSE)
    if (key == "value" && any(!is.finite(value) & !blank)) stop("value must be numeric or NA.", call. = FALSE)
    x[[key]] <- value
  }
  if (!nrow(x)) stop("The track table has no rows.", call. = FALSE)
  x
}

# Columns that can colour or label feature boxes: anything beyond keys and coordinates.
.tracks_categories <- function(x) setdiff(names(x), .tracks_reserved)

# One track specification (a plain list) becomes one exported-function call.
.tracks_build <- function(t) {
  position <- t$position %||% "outside"
  if (t$geom == "axis")
    return(syn_axis(by = t$by, unit = t$unit, position = position,
                    height = t$height %||% 0.06, gap = t$gap %||% 0.01))
  common <- list(data = t$data, height = t$height, gap = t$gap, position = position,
                 out_of_bounds = t$out_of_bounds %||% "clip", show.legend = t$show_legend %||% TRUE)
  if (!is.null(t$name)) common$name <- t$name
  if (t$geom == "feature") {
    args <- c(common, list(fill = t$fill, strand = t$strand %||% "none", label = t$label_column))
    if (!is.null(t$palette)) args$palette <- t$palette
    if (!is.null(t$label_size)) args$label_size <- t$label_size
    return(do.call(syn_track_feature, args))
  }
  args <- common
  if (!is.null(t$limits)) args$limits <- t$limits
  if (t$geom == "heatmap") {
    if (!is.null(t$palette)) args$palette <- t$palette
    return(do.call(syn_track_heatmap, args))
  }
  if (!is.null(t$reference) && is.finite(t$reference)) args$reference <- t$reference
  if (!is.null(t$colour)) args$colour <- t$colour
  do.call(if (t$geom == "line") syn_track_line else syn_track_bar, args)
}

.tracks_plot <- function(base, tracks) {
  for (t in tracks) base <- base + .tracks_build(t)
  base
}

# Data tracks in display order (the axis carries no table).
.tracks_data <- function(tracks) Filter(function(t) t$geom != "axis", tracks)

# R code for the track additions. Data tracks are read from track1.tsv,
# track2.tsv, ... numbered in display order, matching the table downloads.
.tracks_code <- function(tracks) {
  quote_r <- function(x) paste(trimws(utils::capture.output(dput(x))), collapse = " ")
  lines <- character(); n <- 0L
  for (i in seq_along(tracks)) {
    t <- tracks[[i]]
    position <- t$position %||% "outside"
    if (t$geom == "axis") {
      args <- c(if (!is.null(t$by)) paste0("by = ", quote_r(t$by)),
                if (!is.null(t$unit)) paste0("unit = ", quote_r(t$unit)),
                paste0("position = ", quote_r(position)),
                paste0("height = ", quote_r(t$height %||% 0.06)), paste0("gap = ", quote_r(t$gap %||% 0.01)))
      lines <- c(lines, paste0("p <- p + syn_axis(", paste(args, collapse = ", "), ")"))
      next
    }
    n <- n + 1L
    var <- paste0("track", n)
    lines <- c(lines, paste0(var, ' <- read.delim("', var, '.tsv")'))
    args <- c(var, if (!is.null(t$name)) paste0("name = ", quote_r(t$name)))
    if (t$geom == "feature") {
      args <- c(args, paste0("fill = ", quote_r(t$fill)), paste0("strand = ", quote_r(t$strand %||% "none")),
                if (!is.null(t$label_column)) paste0("label = ", quote_r(t$label_column)),
                if (!is.null(t$palette)) paste0("palette = ", quote_r(t$palette)),
                if (!is.null(t$label_size)) paste0("label_size = ", quote_r(t$label_size)),
                if (isFALSE(t$show_legend)) "show.legend = FALSE")
    } else {
      args <- c(args, if (!is.null(t$limits)) paste0("limits = ", quote_r(t$limits)),
                if (t$geom == "heatmap" && !is.null(t$palette)) paste0("palette = ", quote_r(t$palette)),
                if (t$geom != "heatmap" && !is.null(t$reference) && is.finite(t$reference)) paste0("reference = ", quote_r(t$reference)),
                if (t$geom != "heatmap" && !is.null(t$colour)) paste0("colour = ", quote_r(t$colour)))
    }
    args <- c(args, paste0("position = ", quote_r(position)), paste0("height = ", quote_r(t$height)),
              paste0("gap = ", quote_r(t$gap)), paste0("out_of_bounds = ", quote_r(t$out_of_bounds %||% "clip")))
    lines <- c(lines, paste0("p <- p + syn_track_", t$geom, "(", paste(args, collapse = ", "), ")"))
  }
  lines
}

.tracks_chloroplast_code <- function() {
  c('# The published Arabidopsis thaliana chloroplast (RefSeq NC_000932.1), bundled with ggsynteny.',
    'dir <- system.file("extdata", "chloroplast", package = "ggsynteny")',
    'pairs <- read.csv(file.path(dir, "ir_pairs.csv"))',
    'sp <- "Arabidopsis thaliana"',
    'syn <- list(chromosomes = data.frame(species = sp, chr = "plastid", size = 154478),',
    '            blocks = data.frame(species1 = sp, chr1 = "plastid", start1 = pairs$b_start, end1 = pairs$b_end,',
    '                                species2 = sp, chr2 = "plastid", start2 = pairs$a_start, end2 = pairs$a_end,',
    '                                class = pairs$class))',
    'pal_class <- c("Photosystems and electron transport" = "#009E73", "ATP synthase" = "#E69F00",',
    '               "NADH dehydrogenase" = "#CC79A7", "Ribosomal proteins" = "#0072B2",',
    '               "tRNA and rRNA" = "#D55E00", "Other genes" = "#9A9A9A")',
    'p <- plot_circular_synteny(syn, sp, ribbon_fill = "class", ribbon_palette = pal_class, ribbon_alpha = 0.55,',
    '                           ribbon_legend = FALSE, chr_palette = "#F1EDE6", chr_color = NA, track_width = 0.02,',
    '                           label_size = 0, species_label_size = 0, group_gap = 1.5)')
}

.tracks_ui <- function(id) {
  ns <- shiny::NS(id)
  slot <- function(i) shiny::div(class = "track-slot",
    shiny::div(class = "section-kicker", paste0("TRACK ", i)),
    shiny::fileInput(ns(paste0("file_", i)), "Interval table (TSV or CSV)",
                     accept = c(".tsv", ".csv", ".txt")),
    shiny::uiOutput(ns(paste0("controls_", i))))
  shiny::div(class = "studio-layout tracks-layout",
    shiny::tags$aside(class = "control-panel",
      shiny::div(class = "section-kicker", "01 / WHAT TO ANNOTATE"),
      shiny::radioButtons(ns("source"), "Start with",
        c("Chloroplast genome ring (example)" = "chloroplast", "The figure from the Synteny tab" = "figure")),
      shiny::conditionalPanel(sprintf("input['%s'] === 'chloroplast'", ns("source")),
        shiny::p(class = "example-note",
          "Arabidopsis thaliana chloroplast, RefSeq NC_000932.1: one circular molecule with its regions, genes, GC content and inverted-repeat links. Switch rings on and off and move them inside or outside the chromosome band."),
        shiny::uiOutput(ns("example_controls"))),
      shiny::conditionalPanel(sprintf("input['%s'] === 'figure'", ns("source")),
        shiny::div(class = "format-help",
          shiny::p("Tracks stack on the figure currently shown in the Synteny tab, in the same coordinate units."),
          shiny::p("A track table has start and end columns, plus either a numeric value column (heatmap, line, bar) or a category column to colour boxes by (feature). species/chr columns select the sequence; leave them out when the figure shows one sequence."),
          shiny::p("Intervals past a sequence end are clipped.")),
        lapply(seq_len(.tracks_slots), slot),
        shiny::div(class = "section-divider"),
        shiny::checkboxInput(ns("axis"), "Add a coordinate axis", FALSE),
        shiny::conditionalPanel(sprintf("input['%s']", ns("axis")),
          shiny::numericInput(ns("axis_by"), "Tick spacing (plot units; blank = automatic)", value = NA),
          shiny::selectInput(ns("axis_unit"), "Label unit", c("As is" = "none", "kb (coordinates in bp)" = "kb", "Mb (coordinates in bp)" = "Mb")),
          shiny::uiOutput(ns("axis_position")))),
      shiny::div(class = "section-divider"),
      shiny::textInput(ns("title"), "Figure title (optional)", value = ""),
      shiny::p(class = "control-note", "Each control is one argument of syn_track_feature(), syn_track_heatmap(), syn_track_line(), syn_track_bar() or syn_axis(). The R script download reproduces the figure.")),
    shiny::tags$main(class = "workspace",
      shiny::uiOutput(ns("status")), shiny::uiOutput(ns("metrics")),
      shiny::div(class = "plot-card",
        shiny::div(class = "card-heading", shiny::div(shiny::span(class = "section-kicker", "LIVE PREVIEW"),
          shiny::h2(shiny::textOutput(ns("heading"), inline = TRUE))),
          shiny::div(class = "download-row", shiny::downloadButton(ns("pdf"), "PDF"),
                     shiny::downloadButton(ns("png"), "PNG"), shiny::downloadButton(ns("code"), "R script"))),
        shiny::plotOutput(ns("plot"), height = "720px"),
        shiny::uiOutput(ns("note"))),
      shiny::div(class = "data-card",
        shiny::div(class = "card-heading", shiny::div(shiny::span(class = "section-kicker", "INSPECT"),
          shiny::h2("The tracks behind the figure"))),
        shiny::uiOutput(ns("previews")),
        shiny::p(class = "table-footnote", "Previews show the first 50 rows of each displayed track table. Tracks are static; the figure's own ribbons and genes keep their colours."))))
}

.tracks_server <- function(id, base_plot, layout, base_code) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    example <- .tracks_chloroplast()
    circular <- shiny::reactive(identical(input$source, "chloroplast") || identical(layout(), "circular"))
    position_input <- function(inputId, selected) shiny::selectInput(inputId, "Placement on a ring",
      c("Outside the chromosome band" = "outside", "Inside, next to the ribbons" = "inside"), selected = selected)

    # --- example mode -----------------------------------------------------
    output$example_controls <- shiny::renderUI({
      shiny::tagList(lapply(example$tracks, function(t) shiny::div(class = "track-example",
        shiny::checkboxInput(ns(paste0("ex_", t$id)), t$label, TRUE),
        shiny::conditionalPanel(sprintf("input['%s']", ns(paste0("ex_", t$id))),
          position_input(ns(paste0("ex_pos_", t$id)), t$position)))))
    })
    example_tracks <- shiny::reactive({
      kept <- list()
      for (t in example$tracks) {
        on <- input[[paste0("ex_", t$id)]]
        if (is.null(on) || isTRUE(on)) {
          pos <- input[[paste0("ex_pos_", t$id)]]
          if (!is.null(pos)) t$position <- pos
          kept[[length(kept) + 1L]] <- t
        }
      }
      kept
    })

    # --- upload mode --------------------------------------------------------
    tables <- lapply(seq_len(.tracks_slots), function(i) shiny::reactive({
      f <- input[[paste0("file_", i)]]
      if (is.null(f)) return(NULL)
      tryCatch(.tracks_table(f$datapath), error = function(e) list(problem = conditionMessage(e)))
    }))
    for (i in seq_len(.tracks_slots)) local({
      i <- i
      output[[paste0("controls_", i)]] <- shiny::renderUI({
        x <- tables[[i]]()
        if (is.null(x)) return(shiny::p(class = "example-note", "No table yet."))
        if (!is.null(x$problem)) return(shiny::div(class = "data-status pending", x$problem))
        categories <- .tracks_categories(x)
        has_value <- "value" %in% names(x)
        geom_id <- ns(paste0("geom_", i))
        shiny::tagList(
          shiny::selectInput(geom_id, "Draw as", .tracks_geoms, selected = if (has_value) "heatmap" else "feature"),
          shiny::conditionalPanel(sprintf("input['%s'] === 'feature'", geom_id),
            shiny::selectInput(ns(paste0("fill_", i)), "Colour boxes by", c("One colour" = "", categories)),
            shiny::selectInput(ns(paste0("strand_", i)), "Strand",
              c("Ignore" = "none", "Split + and - lanes" = "split", "Arrows" = "arrow"),
              selected = if ("strand" %in% names(x)) "split" else "none"),
            shiny::selectInput(ns(paste0("label_", i)), "Label boxes with", c("No labels" = "", categories))),
          shiny::conditionalPanel(sprintf("input['%s'] !== 'feature'", geom_id),
            shiny::textInput(ns(paste0("name_", i)), "Legend title", value = "Value"),
            shiny::div(class = "track-limits",
              shiny::numericInput(ns(paste0("min_", i)), "Scale minimum", value = if (has_value) floor(min(x$value, na.rm = TRUE)) else 0),
              shiny::numericInput(ns(paste0("max_", i)), "Scale maximum", value = if (has_value) ceiling(max(x$value, na.rm = TRUE)) else 100)),
            shiny::numericInput(ns(paste0("reference_", i)), "Dashed reference value (optional)", value = NA)),
          if (circular()) position_input(ns(paste0("position_", i)), "outside"),
          shiny::sliderInput(ns(paste0("height_", i)), "Lane height", min = 0.03, max = 0.3, value = 0.1, step = 0.01))
      })
    })
    upload_tracks <- shiny::reactive({
      specs <- list()
      for (i in seq_len(.tracks_slots)) {
        x <- tables[[i]]()
        if (is.null(x)) next
        if (!is.null(x$problem)) stop("Track ", i, ": ", x$problem, call. = FALSE)
        geom <- input[[paste0("geom_", i)]] %||% if ("value" %in% names(x)) "heatmap" else "feature"
        t <- list(id = paste0("track", i), label = paste("Track", i), geom = geom, data = x,
                  position = input[[paste0("position_", i)]] %||% "outside",
                  height = input[[paste0("height_", i)]] %||% 0.1, gap = 0.03, out_of_bounds = "clip")
        if (geom == "feature") {
          fill <- input[[paste0("fill_", i)]]
          t$fill <- if (is.null(fill) || !nzchar(fill)) NULL else fill
          t$strand <- input[[paste0("strand_", i)]] %||% "none"
          lab <- input[[paste0("label_", i)]]
          t$label_column <- if (is.null(lab) || !nzchar(lab)) NULL else lab
          t$name <- t$fill
          t$gap <- 0.02
        } else {
          if (!"value" %in% names(x)) stop("Track ", i, ": a ", geom, " needs a numeric value column.", call. = FALSE)
          lo <- input[[paste0("min_", i)]] %||% floor(min(x$value, na.rm = TRUE))
          hi <- input[[paste0("max_", i)]] %||% ceiling(max(x$value, na.rm = TRUE))
          if (!is.finite(lo) || !is.finite(hi) || hi <= lo) stop("Track ", i, ": the scale maximum must exceed the minimum.", call. = FALSE)
          t$limits <- c(lo, hi)
          t$name <- input[[paste0("name_", i)]] %||% "Value"
          ref <- input[[paste0("reference_", i)]]
          if (!is.null(ref) && is.finite(ref)) t$reference <- ref
        }
        specs[[length(specs) + 1L]] <- t
      }
      if (isTRUE(input$axis)) {
        by <- input$axis_by
        specs[[length(specs) + 1L]] <- list(id = "axis", label = "Coordinate axis", geom = "axis",
          by = if (is.null(by) || !is.finite(by) || by <= 0) NULL else by,
          unit = if (identical(input$axis_unit, "none") || is.null(input$axis_unit)) NULL else input$axis_unit,
          position = input$axis_position %||% "outside", height = 0.06, gap = 0.01)
      }
      specs
    })
    output$axis_position <- shiny::renderUI(if (circular()) position_input(ns("axis_position"), "outside"))

    # --- shared -------------------------------------------------------------
    tracks <- shiny::reactive(if (identical(input$source, "chloroplast")) example_tracks() else
      tryCatch(upload_tracks(), error = function(e) shiny::validate(shiny::need(FALSE, conditionMessage(e)))))
    title <- shiny::reactive(if (is.null(input$title) || !nzchar(input$title)) NULL else input$title)
    base <- shiny::reactive({
      if (identical(input$source, "chloroplast")) return(.tracks_chloroplast_plot(example, title()))
      p <- base_plot()
      if (!is.null(title())) p <- p + ggplot2::ggtitle(title())
      p
    })
    current <- shiny::reactive({
      tryCatch(.tracks_plot(base(), tracks()), error = function(e) shiny::validate(shiny::need(FALSE, conditionMessage(e))))
    })
    output$heading <- shiny::renderText(if (identical(input$source, "chloroplast")) "Chloroplast genome ring"
      else paste(length(.tracks_data(tracks())), "track(s) on your synteny figure"))
    output$status <- shiny::renderUI({
      if (identical(input$source, "chloroplast"))
        return(shiny::div(class = "data-status ready", role = "status", shiny::strong("Example loaded. "),
          "Measured, published annotation; the 17 ribbons join each inverted-repeat gene to its copy."))
      n <- sum(vapply(seq_len(.tracks_slots), function(i) !is.null(tables[[i]]()), logical(1)))
      if (n == 0) return(shiny::div(class = "data-status pending", role = "status",
        "Upload at least one interval table, or tick the coordinate axis, to annotate the Synteny tab figure."))
      shiny::div(class = "data-status ready", role = "status", shiny::strong("Tracks ready. "),
        "Coordinates must use the same unit and origin as the figure.")
    })
    output$metrics <- shiny::renderUI({
      ts <- tracks()
      data_tracks <- .tracks_data(ts)
      values <- c(length(data_tracks), sum(vapply(data_tracks, function(t) nrow(t$data), numeric(1))),
                  sum(vapply(ts, function(t) identical(t$position %||% "outside", "inside"), logical(1))),
                  as.integer(any(vapply(ts, function(t) t$geom == "axis", logical(1)))))
      labels <- c("Tracks", "Intervals", "Inside rings", "Axis")
      shiny::div(class = "metrics", lapply(seq_along(values), function(i) shiny::div(class = "metric",
        shiny::strong(format(values[i], big.mark = ",")), shiny::span(labels[i]))))
    })
    output$plot <- shiny::renderPlot(print(current()), res = 110)
    output$note <- shiny::renderUI({
      ts <- tracks()
      shiny::p(class = "plot-note", if (!length(ts)) "No tracks yet." else paste(
        "Rings stack in the order listed: outside tracks outward from the chromosome band, inside tracks inward, shrinking the ribbons.",
        "Lane heights are fractions of the circle radius or of the linear tier spacing."))
    })
    output$previews <- shiny::renderUI({
      ts <- .tracks_data(tracks())
      if (!length(ts)) return(shiny::p(class = "example-note", "Track tables appear here."))
      shiny::tagList(lapply(seq_along(ts), function(i) {
        output[[paste0("preview_", i)]] <- shiny::renderTable(utils::head(ts[[i]]$data, 50), striped = TRUE, bordered = FALSE, digits = 4)
        output[[paste0("tsv_", i)]] <- shiny::downloadHandler(filename = function() paste0("track", i, ".tsv"),
          content = function(file) utils::write.table(.tracks_data(tracks())[[i]]$data, file, sep = "\t", quote = TRUE, row.names = FALSE, na = "NA"))
        shiny::div(shiny::div(class = "track-preview-heading",
                     shiny::h3(class = "track-preview-title", paste0(i, ". ", ts[[i]]$label, " (", ts[[i]]$geom, ")")),
                     shiny::downloadButton(ns(paste0("tsv_", i)), paste0("track", i, ".tsv"))),
                   shiny::div(class = "table-scroll", shiny::tableOutput(ns(paste0("preview_", i)))))
      }))
    })
    figure_download <- function(ext) shiny::downloadHandler(
      filename = function() paste0("ggsynteny-tracks.", ext),
      content = function(file) ggplot2::ggsave(file, current(), device = ext, width = 10,
        height = if (circular()) 11 else 8, dpi = 300, bg = "white", limitsize = FALSE))
    output$pdf <- figure_download("pdf"); output$png <- figure_download("png")
    output$code <- shiny::downloadHandler(filename = "reproduce-tracks.R", content = function(file) {
      ts <- tracks()
      start <- if (identical(input$source, "chloroplast")) .tracks_chloroplast_code() else base_code()
      lines <- c('# Save the track table downloads beside this script as track1.tsv, track2.tsv, ...',
                 'library(ggsynteny)', start, '', .tracks_code(ts))
      if (!is.null(title())) lines <- c(lines, paste0('p <- p + ggplot2::ggtitle(', paste(utils::capture.output(dput(title())), collapse = ""), ')'))
      writeLines(c(lines, 'print(p)', 'ggplot2::ggsave("synteny-tracks.pdf", p, width = 10, height = 10)'), file)
    })
  })
}
