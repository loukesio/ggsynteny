# Annotation tracks in Studio: a reorderable list of syn_track_*() additions
# and one syn_axis() stacked on the figure from the Data step, or on the
# bundled chloroplast genome ring. List order is stacking order. Every row
# option is one argument of the exported wrappers, and .tracks_code() writes
# the same calls into the Export script.

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
    list(id = "regions", label = "Region band", geom = "feature", table = "regions.csv",
         data = regions[c("species", "start", "end", "region")], fill = "region", label_column = "region",
         strand = "none", palette = pal_region, name = "Region", show_legend = FALSE,
         position = "outside", height = 0.07, gap = 0, label_size = 3.2, swatch = "#7FB3B8"),
    list(id = "axis", label = "Ticks every 10 kb", geom = "axis", by = 10000, unit = "kb",
         position = "outside", height = 0.06, gap = 0, swatch = "#6b6e76"),
    list(id = "genes", label = "Genes by strand and function", geom = "feature", table = "genes.csv",
         data = genes[c("species", "gene", "start", "end", "strand", "class")], fill = "class",
         strand = "split", palette = pal_class, name = "Gene function",
         position = "inside", height = 0.14, gap = 0.015, swatch = "#0072B2"),
    list(id = "gc", label = "GC content line", geom = "line", table = "gc_windows.csv",
         data = data.frame(species = sp, start = windows$start, end = windows$start + 999, value = 100 * windows$gc),
         name = "GC (%)", limits = c(20, 60), reference = 36.3, colour = "#3B1B36",
         position = "inside", height = 0.15, gap = 0.02, swatch = "#3B1B36"),
    list(id = "skew", label = "GC skew heatmap", geom = "heatmap", table = "gc_windows.csv",
         data = data.frame(species = sp, start = windows$start, end = windows$start + 999, value = windows$skew),
         name = "GC skew", limits = c(-0.25, 0.25), palette = c("#B2182B", "#F7F7F7", "#2166AC"),
         position = "inside", height = 0.05, gap = 0.015, swatch = "#2166AC"))
  list(base = base, species = sp, ribbon_palette = pal_class, tracks = tracks)
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

.tracks_categories <- function(x) setdiff(names(x), .tracks_reserved)
.tracks_data <- function(tracks) Filter(function(t) t$geom != "axis", tracks)

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

# Apply an uploaded table to a fresh row specification.
.tracks_spec_from_table <- function(x, uid) {
  has_value <- "value" %in% names(x)
  categories <- .tracks_categories(x)
  list(uid = uid, id = uid, label = paste("Track", sub("^t", "", uid)), geom = if (has_value) "heatmap" else "feature",
       table = "uploaded table", data = x, on = TRUE,
       fill = if (!has_value && length(categories)) categories[1] else NULL,
       strand = if (!has_value && "strand" %in% names(x)) "split" else "none", label_column = NULL,
       name = if (has_value) "Value" else categories[1],
       limits = if (has_value) c(floor(min(x$value, na.rm = TRUE)), ceiling(max(x$value, na.rm = TRUE))) else NULL,
       reference = NULL, position = "outside", height = if (has_value) 0.10 else 0.08, gap = if (has_value) 0.03 else 0.02,
       out_of_bounds = "clip", swatch = if (has_value) "#246B78" else "#6E7B85")
}

.tracks_panel_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::div(class = "tracks-panel",
    shiny::div(class = "card-head", shiny::div(shiny::span(class = "kicker", "Tracks · list order is stacking order"),
      shiny::h3("Annotation tracks")), shiny::span(class = "mono muted", shiny::textOutput(ns("count"), inline = TRUE))),
    shiny::uiOutput(ns("list")),
    shiny::div(class = "track-foot",
      shiny::checkboxInput(ns("axis"), .studio_arg("Coordinate axis", "syn_axis()"), FALSE),
      shiny::conditionalPanel(sprintf("input['%s']", ns("axis")),
        shiny::div(class = "export-opts",
          shiny::numericInput(ns("axis_by"), "Tick spacing (blank = auto)", value = NA),
          shiny::selectInput(ns("axis_unit"), "Unit", c("As is" = "none", "kb" = "kb", "Mb" = "Mb")),
          shiny::uiOutput(ns("axis_position")))),
      shiny::div(class = "add-track", shiny::div(class = "dropzone", shiny::fileInput(ns("add_file"), NULL, accept = c(".tsv", ".csv", ".txt"),
                                                                      placeholder = "Add a track: drop an interval table")),
        shiny::p(class = "muted small", style = "margin:8px 0 0", "start, end, then a numeric value column (heatmap, line, bar) or a category column (feature boxes). Leave species/chr out when the figure shows one sequence.")),
      shiny::uiOutput(ns("add_problem"))))
}

.tracks_server <- function(id, base_plot, layout, example) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    rows <- shiny::reactiveValues(list = list(), n = 0L, problem = NULL)
    chloro <- .tracks_chloroplast()
    circular <- shiny::reactive(isTRUE(example()) || identical(layout(), "circular"))

    shiny::observeEvent(example(), {
      rows$list <- if (isTRUE(example())) lapply(chloro$tracks, function(t) { t$uid <- t$id; t$on <- TRUE; t }) else list()
      rows$n <- 0L
    }, ignoreNULL = FALSE)

    shiny::observeEvent(input$add_file, {
      f <- input$add_file
      x <- tryCatch(.tracks_table(f$datapath), error = function(e) e)
      if (inherits(x, "error")) { rows$problem <- conditionMessage(x); return() }
      rows$problem <- NULL
      rows$n <- rows$n + 1L
      spec <- .tracks_spec_from_table(x, paste0("t", rows$n))
      spec$table <- f$name
      rows$list <- c(rows$list, list(spec))
    })
    output$add_problem <- shiny::renderUI(if (!is.null(rows$problem)) shiny::div(class = "readout-head err", style = "border-radius:6px",
      shiny::span(class = "dot"), shiny::div(shiny::strong("Table not added"), shiny::span(rows$problem))))

    # Row controls are keyed by uid so re-rendering keeps their values. Observers
    # are registered the first time a uid appears, so uploaded rows get them too.
    field <- function(uid, name) input[[paste0(name, "_", uid)]]
    update_row <- function(uid, name, value) {
      i <- which(vapply(rows$list, `[[`, "", "uid") == uid)
      if (!length(i) || identical(rows$list[[i]][[name]], value)) return(invisible())
      rows$list[[i]][[name]] <- value
      rows$list[[i]]$editing <- TRUE
    }
    move <- function(uid, by) {
      i <- which(vapply(rows$list, `[[`, "", "uid") == uid); j <- i + by
      if (!length(i) || j < 1 || j > length(rows$list)) return()
      l <- rows$list; tmp <- l[[i]]; l[[i]] <- l[[j]]; l[[j]] <- tmp; rows$list <- l
    }
    registered <- character()
    shiny::observe({
      uids <- vapply(rows$list, `[[`, "", "uid")
      for (uid in setdiff(uids, registered)) local({
        uid <- uid
        registered <<- c(registered, uid)
        shiny::observe({
          on <- field(uid, "on"); if (!is.null(on)) update_row(uid, "on", isTRUE(on))
          pos <- field(uid, "position"); if (!is.null(pos)) update_row(uid, "position", pos)
          h <- field(uid, "height"); if (!is.null(h) && is.finite(h)) update_row(uid, "height", h)
          geom <- field(uid, "geom"); if (!is.null(geom)) update_row(uid, "geom", geom)
          fill <- field(uid, "fill"); if (!is.null(fill)) update_row(uid, "fill", if (nzchar(fill)) fill else NULL)
          strand <- field(uid, "strand"); if (!is.null(strand)) update_row(uid, "strand", strand)
          lab <- field(uid, "label"); if (!is.null(lab)) update_row(uid, "label_column", if (nzchar(lab)) lab else NULL)
          nm <- field(uid, "name"); if (!is.null(nm)) update_row(uid, "name", nm)
          lo <- field(uid, "min"); hi <- field(uid, "max")
          if (!is.null(lo) && !is.null(hi) && is.finite(lo) && is.finite(hi) && hi > lo) update_row(uid, "limits", c(lo, hi))
          ref <- field(uid, "reference"); if (!is.null(ref)) update_row(uid, "reference", if (is.finite(ref)) ref else NULL)
        })
        shiny::observeEvent(input[[paste0("up_", uid)]], move(uid, -1L), ignoreInit = TRUE)
        shiny::observeEvent(input[[paste0("down_", uid)]], move(uid, 1L), ignoreInit = TRUE)
        shiny::observeEvent(input[[paste0("remove_", uid)]], {
          rows$list <- Filter(function(r) r$uid != uid, rows$list)
        }, ignoreInit = TRUE)
      })
    })

    position_input <- function(inputId, selected) shiny::selectInput(inputId, .studio_arg("Placement", "position"),
      c("Outside the chromosome band" = "outside", "Inside, next to the ribbons" = "inside"), selected = selected)
    output$list <- shiny::renderUI({
      l <- rows$list
      if (!length(l)) return(shiny::div(class = "track-row", style = "grid-template-columns:1fr",
        shiny::span(class = "muted small", "No tracks yet. Drop an interval table below to add one.")))
      shiny::div(class = "track-list", lapply(seq_along(l), function(i) {
        t <- l[[i]]; uid <- t$uid
        meta <- paste(c(t$geom, t$table %||% "", if (circular()) t$position %||% "outside"), collapse = " · ")
        editable <- t$geom != "axis" && is.null(t$palette)   # example rings keep their curated options
        shiny::div(class = paste("track-row", if (!isTRUE(t$on)) "is-off"),
          shiny::checkboxInput(ns(paste0("on_", uid)), NULL, isTRUE(t$on)),
          shiny::span(class = "track-swatch", style = paste0("background:", t$swatch %||% "#6b6e76")),
          shiny::div(shiny::span(class = "track-name", t$label), shiny::span(class = "track-meta", meta)),
          shiny::div(class = "track-tools",
            shiny::actionButton(ns(paste0("up_", uid)), "↑", class = "btn-icon", title = "Move up"),
            shiny::actionButton(ns(paste0("down_", uid)), "↓", class = "btn-icon", title = "Move down"),
            if (!isTRUE(example())) shiny::actionButton(ns(paste0("remove_", uid)), "×", class = "btn-icon", title = "Remove")),
          shiny::tags$details(class = "track-edit", open = if (isTRUE(t$editing)) NA else NULL, shiny::tags$summary(class = "muted small", "Edit"),
            if (circular()) position_input(ns(paste0("position_", uid)), t$position %||% "outside"),
            shiny::sliderInput(ns(paste0("height_", uid)), .studio_arg("Lane height", "height"), min = 0.03, max = 0.3, value = t$height %||% 0.1, step = 0.01),
            if (editable) {
              x <- t$data; categories <- .tracks_categories(x); has_value <- "value" %in% names(x)
              shiny::tagList(
                shiny::selectInput(ns(paste0("geom_", uid)), .studio_arg("Draw as", "geom"), .tracks_geoms, selected = t$geom),
                if (t$geom == "feature") shiny::tagList(
                  shiny::selectInput(ns(paste0("fill_", uid)), .studio_arg("Colour boxes by", "fill"), c("One colour" = "", categories), selected = t$fill %||% ""),
                  shiny::selectInput(ns(paste0("strand_", uid)), .studio_arg("Strand", "strand"), c("Ignore" = "none", "Split + and - lanes" = "split", "Arrows" = "arrow"), selected = t$strand %||% "none"),
                  shiny::selectInput(ns(paste0("label_", uid)), .studio_arg("Label boxes with", "label"), c("No labels" = "", categories), selected = t$label_column %||% ""))
                else if (has_value) shiny::tagList(
                  shiny::textInput(ns(paste0("name_", uid)), .studio_arg("Legend title", "name"), value = t$name %||% "Value"),
                  shiny::div(class = "export-opts",
                    shiny::numericInput(ns(paste0("min_", uid)), .studio_arg("Scale min", "limits"), value = t$limits[1]),
                    shiny::numericInput(ns(paste0("max_", uid)), "Scale max", value = t$limits[2])),
                  if (t$geom != "heatmap") shiny::numericInput(ns(paste0("reference_", uid)), .studio_arg("Dashed reference", "reference"), value = t$reference %||% NA))
                else shiny::p(class = "muted small", "This table has no value column, so only feature boxes can be drawn."))
            }))
      }))
    })
    output$axis_position <- shiny::renderUI(if (circular()) position_input(ns("axis_position"), "outside"))
    output$count <- shiny::renderText({
      l <- rows$list; on <- sum(vapply(l, function(t) isTRUE(t$on), logical(1)))
      paste(on, "of", length(l), "on")
    })

    active <- shiny::reactive({
      l <- Filter(function(t) isTRUE(t$on), rows$list)
      l <- lapply(l, function(t) {
        if (t$geom %in% c("heatmap", "line", "bar") && !"value" %in% names(t$data)) t$geom <- "feature"
        t
      })
      if (isTRUE(input$axis) && !any(vapply(l, function(t) t$geom == "axis", logical(1)))) {
        by <- input$axis_by
        l <- c(l, list(list(uid = "axis", id = "axis", label = "Coordinate axis", geom = "axis", on = TRUE,
          by = if (is.null(by) || !is.finite(by) || by <= 0) NULL else by,
          unit = if (is.null(input$axis_unit) || identical(input$axis_unit, "none")) NULL else input$axis_unit,
          position = input$axis_position %||% "outside", height = 0.06, gap = 0.01)))
      }
      l
    })
    base <- shiny::reactive(base_plot())
    plot <- shiny::reactive({
      tryCatch(.tracks_plot(base(), active()), error = function(e) shiny::validate(shiny::need(FALSE, conditionMessage(e))))
    })
    list(plot = plot, tracks = active, base = base, example = chloro)
  })
}

.tracks_chloroplast_plot <- function(example, title = NULL) {
  plot_circular_synteny(example$base, example$species, ribbon_fill = "class",
                        ribbon_palette = example$ribbon_palette, ribbon_alpha = 0.55,
                        ribbon_legend = FALSE, chr_palette = "#F1EDE6", chr_color = NA,
                        track_width = 0.02, label_size = 0, species_label_size = 0,
                        group_gap = 1.5, title = title)
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
