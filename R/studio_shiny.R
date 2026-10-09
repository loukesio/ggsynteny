# ggsynteny Studio: one shell, four steps (Start, Data, Figure, Export) for
# three jobs (synteny, annotation tracks, reference comparison). The optional
# app lives behind requireNamespace('shiny') in its launcher. Every control is
# one argument of an exported function; the Export step shows that script.

.studio_jobs <- list(
  synteny = list(name = "Synteny", kicker = "Compare genomes with each other", thumb = "job-synteny.png",
    text = "Chromosome blocks or gene homologies between two or more genomes, as linear tiers or a ring.",
    bring = "chromosome + block tables, gene + link tables, or MCScanX / GENESPACE output",
    get = "one of four figures: chromosome-level or gene-level, linear or circular"),
  tracks = list(name = "Annotation tracks", kicker = "Add rings or lanes to a figure", thumb = "job-tracks.png",
    text = "GC content, genes by strand, heatmaps, bars and a coordinate axis stacked on a synteny figure.",
    bring = "the figure's tables, plus interval tables with start, end and a value or a category",
    get = "the figure with tracks inside or outside the chromosome band"),
  reference = list(name = "Reference comparison", kicker = "Compare genomes to one reference", thumb = "job-reference.png",
    text = "Concentric rings around a reference showing variant calls and alignment identity per window.",
    bring = "a variant-call table and, optionally, identity windows on the reference",
    get = "reference-centred rings with marks, identity shading and a locus view"))

.studio_steps <- c("Start", "Data", "Figure", "Export")

.studio_ui <- function() {
  www <- system.file("shiny", "www", package = "ggsynteny")
  shiny::addResourcePath("ggsynteny-studio", www)
  shiny::fluidPage(
    shiny::tags$head(shiny::tags$title("ggsynteny Studio"),
      shiny::tags$link(rel = "stylesheet", href = "ggsynteny-studio/tokens.css"),
      shiny::tags$link(rel = "stylesheet", href = "ggsynteny-studio/reference.css"),
      shiny::tags$script(src = "ggsynteny-studio/reference.js")),
    shiny::div(class = "studio-top", shiny::div(class = "studio-top-inner",
      shiny::actionButton("go_home", class = "brand", label = shiny::tagList(
        shiny::span(class = "brand-mark", "gg"), shiny::span(shiny::strong("ggsynteny"), shiny::span("Studio")))),
      shiny::uiOutput("stepper", inline = TRUE),
      shiny::div(class = "top-right", shiny::uiOutput("job_chip", inline = TRUE),
        shiny::span(class = "version-badge", paste0("v", utils::packageVersion("ggsynteny")))))),
    shiny::tabsetPanel(id = "step", type = "hidden",
      shiny::tabPanelBody("start", .studio_start_ui()),
      shiny::tabPanelBody("data", shiny::div(class = "page", shiny::uiOutput("data_page"))),
      shiny::tabPanelBody("figure", shiny::div(class = "page", shiny::uiOutput("figure_page"))),
      shiny::tabPanelBody("export", shiny::div(class = "page", shiny::uiOutput("export_page")))),
    shiny::p(class = "studio-footer", "Local data, ltc palettes, publication-ready figures. Powered by ggsynteny and ggplot2."))
}

# ---- Step 0: start -----------------------------------------------------------
.studio_start_ui <- function() {
  card <- function(id, job) shiny::div(class = "job-card",
    shiny::div(class = "job-thumb", shiny::img(src = paste0("ggsynteny-studio/figures/", job$thumb), alt = "")),
    shiny::div(class = "job-body",
      shiny::span(class = "kicker", job$kicker), shiny::h2(job$name), shiny::p(job$text),
      shiny::div(class = "bring-get", shiny::span(class = "kicker", "You bring"), shiny::span(job$bring),
                 shiny::span(class = "kicker", "You get"), shiny::span(job$get)),
      shiny::div(class = "job-actions",
        shiny::actionButton(paste0("start_", id, "_upload"), "Upload my data", class = "btn-primary"),
        shiny::actionButton(paste0("start_", id, "_example"), "Start from an example"))))
  steps <- list(c("00", "Start", "Pick a job or an example"), c("01", "Data", "Drop files, read the readout"),
                c("02", "Figure", "Shape it, figure always visible"), c("03", "Export", "PDF, PNG, tables, R script"))
  shiny::div(class = "page",
    shiny::div(class = "start-intro", shiny::span(class = "kicker", "ggsynteny Studio"),
      shiny::h1("What do you want to draw?"),
      shiny::p("Three jobs, one flow: choose, bring your tables, shape the figure, export it with the R script that reproduces it.")),
    shiny::div(class = "job-cards", lapply(names(.studio_jobs), function(id) card(id, .studio_jobs[[id]]))),
    shiny::div(class = "flow-strip", lapply(steps, function(s) shiny::div(class = "flow-step",
      shiny::span(class = "num", s[1]), shiny::div(shiny::strong(s[2]), shiny::span(s[3]))))))
}

# ---- Step 1: data ------------------------------------------------------------
.studio_file_card <- function(spec, input_id, example, ns = identity) {
  cols <- shiny::tags$ul(class = "cols",
    lapply(spec$required, function(c) shiny::tags$li(shiny::span(class = "req", "●"), c)),
    lapply(spec$optional, function(c) shiny::tags$li(shiny::span(class = "opt", "○"), paste(c, "(optional)"))))
  left <- if (example) shiny::div(shiny::span(class = "example-pill", "Example loaded"),
      shiny::p(class = "muted", "The bundled sample file is in use. Switch to Upload my data on the start screen to bring your own."))
    else shiny::div(class = "dropzone", shiny::fileInput(ns(input_id), NULL, accept = c(".tsv", ".csv", ".txt", ".gff", ".collinearity"),
                                                       placeholder = "Drop a file here or click to browse"))
  shiny::div(class = "file-card",
    shiny::div(shiny::span(class = "kicker", if (example) "Example file" else "Drop zone"), shiny::h3(spec$label),
      shiny::p(class = "muted", spec$note), left),
    shiny::div(shiny::span(class = "kicker", "Columns"), cols,
      shiny::div(class = "sample-link", shiny::downloadLink(ns(paste0("sample_", input_id)), paste("Download sample:", spec$sample)))))
}

.studio_readout <- function(state, title, detail, counts = NULL, skipped = NULL, foot = NULL) {
  shiny::div(class = "readout",
    shiny::div(class = paste("readout-head", state), shiny::span(class = "dot"),
      shiny::div(shiny::strong(title), shiny::span(detail))),
    if (!is.null(counts) || (!is.null(skipped) && nrow(skipped))) shiny::div(class = "readout-body",
      if (!is.null(counts)) shiny::div(class = "counts", lapply(names(counts), function(n) shiny::div(class = "count",
        shiny::strong(format(counts[[n]], big.mark = ",")), shiny::span(n)))),
      if (!is.null(skipped) && nrow(skipped)) shiny::div(class = "skipped",
        shiny::p(shiny::strong(nrow(skipped)), " row(s) skipped:"),
        shiny::tags$table(shiny::tags$tr(shiny::tags$th("table"), shiny::tags$th("row"), shiny::tags$th("reason")),
          lapply(seq_len(min(nrow(skipped), 12)), function(i) shiny::tags$tr(
            shiny::tags$td(skipped$table[i]), shiny::tags$td(skipped$row[i]), shiny::tags$td(skipped$reason[i])))),
        if (nrow(skipped) > 12) shiny::p(class = "muted", "and ", nrow(skipped) - 12, " more"))),
    if (!is.null(foot)) shiny::div(class = "readout-foot", foot))
}

# ---- Step 2: figure ----------------------------------------------------------
.studio_group <- function(name, value_id, ..., open = FALSE) {
  shiny::tags$details(class = "group", open = if (open) NA else NULL,
    shiny::tags$summary(shiny::span(class = "name", name), shiny::span(class = "value", shiny::textOutput(value_id, inline = TRUE))),
    shiny::div(class = "group-body", ...))
}

.studio_arg <- function(label, arg) shiny::tagList(label, shiny::span(class = "arg", arg))

.studio_synteny_controls <- function(organisms = NULL) {
  shiny::tagList(
    .studio_group("Layout", "val_layout", open = TRUE,
      shiny::radioButtons("layout", .studio_arg("Layout", "plot_*()"), c("Circular" = "circular", "Linear" = "linear"), inline = TRUE),
      shiny::selectizeInput("organisms", .studio_arg("Genomes in display order", "species_order / bin_order"),
                            choices = organisms, selected = organisms, multiple = TRUE),
      shiny::conditionalPanel("input.layout === 'circular'",
        shiny::sliderInput("gap", .studio_arg("Gap between genomes (degrees)", "group_gap"), min = 0, max = 30, value = 10)),
      shiny::numericInput("limit", "Maximum links to display", value = 1000, min = 1, max = 10000, step = 100)),
    .studio_group("Colours", "val_colours",
      shiny::selectInput("palette", .studio_arg("Palette", "palette"), choices = names(syn_palettes()), selected = "casa_natal"),
      shiny::uiOutput("palette_preview")),
    .studio_group("Ribbons", "val_ribbons",
      shiny::sliderInput("alpha", .studio_arg("Ribbon opacity", "ribbon_alpha"), min = 0.05, max = 1, value = 0.35, step = 0.05),
      shiny::uiOutput("type_controls")),
    .studio_group("Labels", "val_labels",
      shiny::checkboxInput("labels", .studio_arg("Show chromosome / gene labels", "label_size / label_genes"), TRUE),
      shiny::textInput("title", .studio_arg("Figure title", "title"), value = "")))
}

.studio_server <- function(input, output, session) {
  state <- shiny::reactiveValues(job = NULL, mode = "example", step = "start")
  go <- function(step) { state$step <- step; shiny::updateTabsetPanel(session, "step", selected = step) }
  for (id in names(.studio_jobs)) local({
    id <- id
    shiny::observeEvent(input[[paste0("start_", id, "_upload")]], { state$job <- id; state$mode <- "upload"; go("data") })
    shiny::observeEvent(input[[paste0("start_", id, "_example")]], { state$job <- id; state$mode <- "example"; go("data") })
  })
  shiny::observeEvent(input$go_home, go("start"))
  shiny::observeEvent(input$to_figure, go("figure"))
  shiny::observeEvent(input$to_export, go("export"))
  shiny::observeEvent(input$back_data, go("data"))
  shiny::observeEvent(input$back_figure, go("figure"))
  for (i in seq_along(.studio_steps)) local({
    i <- i
    shiny::observeEvent(input[[paste0("stepper_", i)]], go(c("start", "data", "figure", "export")[i]))
  })
  job <- shiny::reactive(state$job)
  example <- shiny::reactive(identical(state$mode, "example"))
  base_job <- shiny::reactive(if (identical(job(), "reference")) "reference" else "synteny")
  ready <- shiny::reactive({
    if (is.null(job())) return(FALSE)
    if (job() == "reference") is.null(reference$data()$problem) else is.null(dataset()$problem)
  })

  output$stepper <- shiny::renderUI({
    current <- match(state$step, c("start", "data", "figure", "export"))
    allowed <- c(TRUE, !is.null(job()), ready(), ready())
    shiny::div(class = "stepper", lapply(seq_along(.studio_steps), function(i) shiny::tagList(
      if (i > 1) shiny::span(class = "step-sep"),
      shiny::actionButton(paste0("stepper_", i), class = paste("step", if (i == current) "is-active", if (i < current) "is-done"),
        label = shiny::tagList(shiny::span(class = "num", sprintf("%02d", i - 1)), .studio_steps[i]),
        disabled = if (allowed[i]) NULL else NA))))
  })
  output$job_chip <- shiny::renderUI(if (!is.null(job())) shiny::span(class = "job-chip",
    paste(.studio_jobs[[job()]]$name, "·", if (example()) "example" else "your data")))

  # ---- synteny / tracks data ----
  chloroplast <- .tracks_chloroplast()
  dataset <- shiny::reactive({
    if (identical(job(), "tracks") && example())
      return(.studio_validate(list(type = "macro", first = chloroplast$base$chromosomes,
                                   second = chloroplast$base$blocks, format = "native"), strict = FALSE))
    shiny::req(input$format)
    paths <- list()
    if (!example()) {
      files <- .studio_files(input$format)
      paths <- lapply(seq_along(files), function(i) {
        f <- input[[paste0("file_", input$format, "_", i)]]
        if (is.null(f)) return(character())
        f$datapath
      })
    }
    tryCatch(.studio_load(input$format, demo = example(), paths = paths, strict = FALSE),
             error = function(e) list(problem = conditionMessage(e)))
  })
  shiny::observeEvent(dataset(), {
    d <- dataset()
    choices <- if (is.null(d$problem)) d$organisms else character()
    shiny::updateSelectizeInput(session, "organisms", choices = choices, selected = choices)
  }, priority = 20)
  selected_data <- shiny::reactive({
    d <- dataset()
    shiny::validate(shiny::need(is.null(d$problem), d$problem))
    organisms <- intersect(input$organisms, d$organisms)
    if (!length(organisms)) organisms <- d$organisms
    shiny::validate(shiny::need(length(organisms) > 0, "Select at least one genome or bin."))
    tryCatch(.studio_select(d, organisms, input$limit %||% 1000, input$layout %||% "circular"), error = function(e) {
      shiny::validate(shiny::need(FALSE, conditionMessage(e)))
    })
  })
  settings <- shiny::reactive({
    d <- selected_data()
    list(layout = input$layout %||% "circular", palette = input$palette %||% "casa_natal", alpha = input$alpha %||% 0.35,
         labels = isTRUE(input$labels %||% TRUE), orientation = isTRUE(input$orientation) && d$type == "macro" && "orientation" %in% names(d$second),
         identity = isTRUE(input$identity) && d$type == "micro" && "identity" %in% names(d$second),
         anchor = if (is.null(input$anchor)) "body" else input$anchor,
         ribbon_by = input$ribbon_by %||% if (identical(job(), "tracks") && example()) "class" else "species_pair",
         gap = input$gap %||% 10, title = if (is.null(input$title) || !nzchar(input$title)) NULL else input$title)
  })
  current_plot <- shiny::reactive({
    tryCatch(do.call(.studio_plot, c(list(d = selected_data()), settings())), error = function(e) {
      shiny::validate(shiny::need(FALSE, conditionMessage(e)))
    })
  })
  current_interactive_plot <- shiny::reactive({
    shiny::req(isTRUE(input$interactive))
    shiny::validate(shiny::need(requireNamespace("ggiraph", quietly = TRUE) &&
      utils::packageVersion("ggiraph") >= "0.9.2",
      "Install ggiraph 0.9.2 or later to enable interactive plots: install.packages('ggiraph')."))
    tryCatch(do.call(.studio_plot, c(list(d = selected_data(), interactive = TRUE), settings())), error = function(e) {
      shiny::validate(shiny::need(FALSE, conditionMessage(e)))
    })
  })
  tracks <- .tracks_server("tracks", base_plot = current_plot, layout = shiny::reactive(input$layout %||% "circular"),
                           example = shiny::reactive(example() && identical(job(), "tracks")))
  reference <- .reference_server("reference_comparison", example = example)
  figure <- shiny::reactive(if (identical(job(), "tracks")) tracks$plot() else current_plot())

  # ---- data page ----
  output$data_page <- shiny::renderUI({
    shiny::req(job())
    if (job() == "reference") return(.reference_data_ui("reference_comparison", example()))
    shiny::tagList(
      shiny::div(class = "page-head", shiny::div(shiny::span(class = "kicker", "Step 1 · Data"),
        shiny::h1(if (example()) "The example tables" else "Bring your tables"),
        shiny::p(if (job() == "tracks") "Tracks need a figure to sit on. Choose the tables that draw it here; the track tables come in the next step."
                 else "Choose the format your results are in, then drop one file per card. The readout on the right says what was read and what was skipped."))),
      shiny::div(class = "data-grid",
        shiny::div(
          if (job() == "tracks" && example()) shiny::div(class = "card", shiny::span(class = "example-pill", "Example loaded"),
            shiny::h3("Arabidopsis thaliana chloroplast"),
            shiny::p(class = "muted", "RefSeq NC_000932.1, 154,478 bp: one circular molecule as one sector, with the 17 inverted-repeat genes joined to their copies as blocks. The five annotation rings are added in the next step."))
          else shiny::div(class = "card", shiny::selectInput("format", .studio_arg("Results from", "read_mcscanx() / read_genespace() / tables"),
            choices = .studio_formats, selected = "genes")),
          shiny::div(style = "height:16px"),
          if (!(job() == "tracks" && example())) shiny::uiOutput("file_cards"),
          shiny::uiOutput("data_preview")),
        shiny::uiOutput("data_readout")))
  })
  output$file_cards <- shiny::renderUI({
    shiny::req(input$format)
    files <- .studio_files(input$format)
    shiny::div(class = "file-cards", lapply(seq_along(files), function(i)
      .studio_file_card(files[[i]], paste0("file_", input$format, "_", i), example())))
  })
  for (format in unname(.studio_formats)) local({
    format <- format
    files <- .studio_files(format)
    for (i in seq_along(files)) local({
      i <- i
      output[[paste0("sample_file_", format, "_", i)]] <- shiny::downloadHandler(
        filename = function() files[[i]]$sample,
        content = function(file) file.copy(system.file("extdata", files[[i]]$sample, package = "ggsynteny"), file, overwrite = TRUE))
    })
  })
  output$data_readout <- shiny::renderUI({
    d <- dataset()
    if (!is.null(d$problem)) {
      waiting <- grepl("^Upload", d$problem)
      return(.studio_readout(if (waiting) "warn" else "err", if (waiting) "Waiting for files" else "Cannot read the tables", d$problem,
        foot = shiny::tagList(shiny::span(class = "muted small", "Continue unlocks when every required file parses."),
          shiny::actionButton("to_figure", "Continue", class = "btn-primary", disabled = NA))))
    }
    counts <- if (d$type == "macro") list("Genomes" = length(d$organisms), "Chromosomes" = nrow(d$first), "Blocks" = nrow(d$second))
              else list("Genomes" = length(d$organisms), "Genes" = nrow(d$first), "Links" = nrow(d$second))
    .studio_readout("ok", "Data ready", switch(d$format,
        native = "Chromosome lengths and block coordinates share the unit in your input.",
        mcscanx = "MCScanX coordinates are shown in Mb. Chromosome spans end at the last annotated gene.",
        genespace = "GENESPACE coordinates are shown in Mb. Chromosome spans are inferred from supplied blocks.",
        genes = "Contig spans cover the first to last gene; no flanks or homology are inferred."),
      counts = counts, skipped = d$skipped,
      foot = shiny::tagList(shiny::span(class = "muted small", if (nrow(d$skipped)) "Skipped rows are left out of every figure and export." else "Every row was read."),
        shiny::actionButton("to_figure", "Continue", class = "btn-primary")))
  })
  output$data_preview <- shiny::renderUI({
    d <- dataset()
    if (!is.null(d$problem)) return(NULL)
    labels <- if (d$type == "macro") c("Chromosomes", "Blocks") else c("Genes", "Links")
    shiny::div(class = "card preview-card", shiny::div(class = "card-head", shiny::div(shiny::span(class = "kicker", "As read"), shiny::h3("First rows"))),
      shiny::div(class = "preview-tabs", shiny::tabsetPanel(
        shiny::tabPanel(labels[1], shiny::div(class = "table-scroll", shiny::tableOutput("first_preview"))),
        shiny::tabPanel(labels[2], shiny::div(class = "table-scroll", shiny::tableOutput("second_preview"))))))
  })
  output$first_preview <- shiny::renderTable(utils::head(dataset()$first, 50), striped = FALSE, bordered = FALSE, digits = 6)
  output$second_preview <- shiny::renderTable(utils::head(dataset()$second, 50), striped = FALSE, bordered = FALSE, digits = 6)

  # ---- figure page ----
  output$figure_page <- shiny::renderUI({
    shiny::req(job())
    if (job() == "reference") return(shiny::tagList(.reference_figure_ui("reference_comparison", reference$samples()),
      shiny::div(class = "btn-row", style = "margin-top:16px;justify-content:space-between",
        shiny::actionButton("back_data", "Back to data"), shiny::actionButton("to_export", "Continue to export", class = "btn-primary"))))
    shiny::tagList(
      shiny::div(class = "page-head", shiny::div(shiny::span(class = "kicker", "Step 2 · Figure"),
        shiny::h1(if (job() == "tracks") "Stack the tracks" else "Shape the figure"),
        shiny::p("Controls are grouped by what they change; each one names its ggsynteny argument. The figure stays on screen."))),
      shiny::div(class = "figure-grid",
        shiny::div(class = "panel",
          if (job() == "tracks") .tracks_panel_ui("tracks"),
          .studio_synteny_controls(if (is.null(dataset()$problem)) dataset()$organisms),
          shiny::div(class = "btn-row", style = "justify-content:space-between",
            shiny::actionButton("back_data", "Back to data"), shiny::actionButton("to_export", "Continue to export", class = "btn-primary"))),
        shiny::div(class = "figure-card",
          shiny::div(class = "figure-head", shiny::div(shiny::h2(shiny::textOutput("plot_heading", inline = TRUE)), shiny::div(class = "meta", shiny::textOutput("plot_meta", inline = TRUE))),
            if (job() == "synteny") shiny::tags$label(class = "switch", shiny::tags$input(id = "interactive", type = "checkbox", class = "shiny-input-checkbox"), "Interactive: hover and zoom")),
          shiny::div(class = "figure-body",
            shiny::conditionalPanel("!input.interactive", shiny::plotOutput("plot", height = if (job() == "tracks") "720px" else "640px")),
            shiny::conditionalPanel("input.interactive", shiny::uiOutput("interactive_ui"))),
          shiny::uiOutput("plot_note"),
          shiny::tags$details(class = "fold", shiny::tags$summary("The data behind the figure"),
            shiny::div(class = "fold-body", shiny::div(class = "preview-tabs", shiny::tabsetPanel(
              shiny::tabPanel("Records", shiny::div(class = "table-scroll", shiny::tableOutput("records_preview"))),
              shiny::tabPanel("Links", shiny::div(class = "table-scroll", shiny::tableOutput("links_preview"))),
              shiny::tabPanel("Pair summary", shiny::tableOutput("pair_preview")))))))))
  })
  output$val_layout <- shiny::renderText(paste(if (identical(input$layout, "linear")) "linear" else "circular", "\u00b7", length(input$organisms %||% dataset()$organisms), "genomes"))
  output$val_colours <- shiny::renderText(input$palette %||% "casa_natal")
  output$val_ribbons <- shiny::renderText(paste0("alpha ", input$alpha %||% 0.35, if (isTRUE(input$identity)) " · identity" else ""))
  output$val_labels <- shiny::renderText(paste(if (isTRUE(input$labels %||% TRUE)) "labels on" else "labels off", if (!is.null(input$title) && nzchar(input$title)) "· titled" else ""))
  output$interactive_ui <- shiny::renderUI({
    shiny::req(isTRUE(input$interactive))
    if (!requireNamespace("ggiraph", quietly = TRUE) || utils::packageVersion("ggiraph") < "0.9.2")
      return(shiny::div(class = "shiny-output-error-validation",
        "Install ggiraph 0.9.2 or later to enable interactive plots: install.packages('ggiraph'). PDF and PNG downloads remain available."))
    preview <- tryCatch(current_interactive_plot(), error = function(e) e)
    if (inherits(preview, "error"))
      return(shiny::div(class = "shiny-output-error-validation", conditionMessage(preview)))
    ggiraph::girafeOutput("interactive_plot", width = "100%", height = "640px")
  })
  if (requireNamespace("ggiraph", quietly = TRUE)) {
    output$interactive_plot <- ggiraph::renderGirafe({
      shiny::req(isTRUE(input$interactive))
      syn_girafe(current_interactive_plot(), width_svg = 10,
                  height_svg = if (identical(input$layout, "linear")) 7 else 10,
                  opts = list(ggiraph::opts_zoom(max = 4, default_on = TRUE),
                              ggiraph::opts_toolbar(hidden = "zoom_onoff")))
    })
  }
  output$type_controls <- shiny::renderUI({
    d <- dataset()
    if (!is.null(d$problem)) return(NULL)
    if (d$type == "macro") {
      extra <- setdiff(names(d$second), c("species1", "chr1", "start1", "end1", "species2", "chr2", "start2", "end2", "block_id", "orientation", "n_genes", "score"))
      shiny::tagList(
        shiny::selectInput("ribbon_by", .studio_arg("Colour ribbons by", "ribbon_fill"),
          c("Species pair" = "species_pair", "Source chromosome" = "source_chr", stats::setNames(extra, paste("Column:", extra))),
          selected = if (identical(job(), "tracks") && example() && "class" %in% extra) "class" else "species_pair"),
        if (length(extra)) shiny::p(class = "help-text", "Column colouring applies to circular layouts."),
        if ("orientation" %in% names(d$second)) shiny::checkboxInput("orientation", .studio_arg("Use block orientation", "show_orientation / show_inversions"), FALSE))
    } else shiny::tagList(
      shiny::selectInput("anchor", .studio_arg("Ribbon attachment", "ribbon_anchor"), c("Gene body" = "body", "Full gene" = "full")),
      if ("identity" %in% names(d$second)) shiny::checkboxInput("identity", .studio_arg("Colour ribbons by identity", "ribbon_fill"), FALSE))
  })
  output$palette_preview <- shiny::renderUI({
    shiny::req(input$palette)
    colors <- syn_palettes()[[input$palette]]
    shiny::div(class = "palette-preview", role = "img", `aria-label` = paste(input$palette, "palette"),
      lapply(colors, function(color) shiny::span(style = paste0("background:", color), title = color)))
  })
  output$plot_heading <- shiny::renderText({
    d <- dataset()
    paste(if (identical(input$layout, "linear")) "Linear" else "Circular",
          if (identical(d$type, "macro")) "chromosome synteny" else "microsynteny",
          if (identical(job(), "tracks")) "with tracks" else "")
  })
  output$plot_meta <- shiny::renderText({
    d <- selected_data()
    paste(input$palette %||% "casa_natal", "·", length(d$organisms), "genomes ·", nrow(d$second), "links")
  })
  output$plot <- shiny::renderPlot({ print(figure()) }, res = 110)
  output$plot_note <- shiny::renderUI({
    d <- selected_data()
    notes <- paste(nrow(d$second), "of", d$matching_links, "matching links displayed.")
    if (d$matching_links > nrow(d$second)) notes <- paste(notes, "The first rows in input order are shown; raise the limit to display more.")
    if (d$type == "macro" && identical(input$layout, "linear"))
      notes <- paste(notes, d$layout_omitted, "other links are omitted by the linear layout. Use circular view to include non-adjacent and within-genome pairs.")
    if (isTRUE(input$interactive))
      notes <- paste(notes, "Hover over a ribbon or feature for details. Scroll to zoom, drag to pan.")
    shiny::div(class = "figure-note", notes)
  })
  output$records_preview <- shiny::renderTable(utils::head(selected_data()$first, 50), striped = FALSE, bordered = FALSE, digits = 6)
  output$links_preview <- shiny::renderTable(utils::head(selected_data()$second, 50), striped = FALSE, bordered = FALSE, digits = 6)
  output$pair_preview <- shiny::renderTable(.studio_pairs(selected_data()), striped = FALSE)

  # ---- export page ----
  script <- shiny::reactive({
    if (identical(job(), "reference")) return(reference$code())
    base <- .studio_code(selected_data(), settings(), interactive = isTRUE(input$interactive))
    if (!identical(job(), "tracks")) return(base)
    paste(c('# Save the table downloads beside this script: the Synteny tables and track1.tsv, track2.tsv, ...',
            'library(ggsynteny)', .studio_code(selected_data(), settings(), script = FALSE)[-1], '',
            .tracks_code(tracks$tracks()), 'print(p)', 'ggplot2::ggsave("synteny-tracks.pdf", p, width = 10, height = 10)'), collapse = "\n")
  })
  output$export_page <- shiny::renderUI({
    shiny::req(job())
    is_ref <- identical(job(), "reference")
    tables <- if (is_ref) list(c("variants.tsv", "export_variants"), c("identity-windows.tsv", "export_identity"))
      else c(list(c(if (identical(dataset()$type, "macro")) "chromosomes.tsv" else "features.tsv", "export_first"),
                  c(if (identical(dataset()$type, "macro")) "blocks.tsv" else "links.tsv", "export_second"),
                  c("pair-summary.tsv", "export_pairs")),
             if (identical(job(), "tracks")) lapply(seq_along(.tracks_data(tracks$tracks())), function(i) c(paste0("track", i, ".tsv"), paste0("export_track_", i))))
    shiny::tagList(
      shiny::div(class = "page-head", shiny::div(shiny::span(class = "kicker", "Step 3 · Export"), shiny::h1("Take it with you"),
        shiny::p("Four outputs in the order people need them. The script is the proof that every control was one function argument."))),
      shiny::div(class = "export-grid",
        shiny::div(shiny::div(class = "thumb", shiny::plotOutput("export_thumb", height = if (is_ref) "460px" else "300px")),
          shiny::div(class = "card", shiny::span(class = "kicker", "This figure"), shiny::uiOutput("export_summary")),
          shiny::div(class = "btn-row", style = "margin-top:16px", shiny::actionButton("back_figure", "Back to figure"))),
        shiny::div(class = "export-cards",
          shiny::div(class = "export-card", shiny::div(shiny::h3("PDF"), shiny::p("Vector output for journals; text stays editable."),
            shiny::div(class = "export-opts", shiny::selectInput("pdf_width", "Width", c("Single column, 89 mm" = "89", "1.5 column, 120 mm" = "120", "Double column, 183 mm" = "183", "Large, 254 mm" = "254"), selected = "183"))),
            shiny::downloadButton("pdf", "Download PDF", class = "btn-primary")),
          shiny::div(class = "export-card", shiny::div(shiny::h3("PNG"), shiny::p("Raster output for slides and the web."),
            shiny::div(class = "export-opts", shiny::selectInput("png_dpi", "Resolution", c("150 dpi" = "150", "300 dpi" = "300", "600 dpi" = "600"), selected = "300"),
              shiny::selectInput("png_bg", "Background", c("White" = "white", "Transparent" = "transparent")))),
            shiny::downloadButton("png", "Download PNG", class = "btn-primary")),
          shiny::div(class = "export-card", shiny::div(shiny::h3("The tables actually drawn"), shiny::p("Exactly the rows in the figure, after your selection and any skipped rows."),
            shiny::div(class = "tables-list", lapply(tables, function(t) shiny::div(shiny::span(class = "mono", t[1]), shiny::downloadButton(t[2], "TSV", class = "btn-sm"))))),
            NULL),
          shiny::div(class = "export-card", style = "grid-template-columns:1fr", shiny::div(shiny::div(class = "card-head", shiny::div(shiny::h3("R script"),
              shiny::p("Reads the tables above and recreates the figure with ggsynteny.")), shiny::downloadButton("code", "Download script", class = "btn-primary")),
            shiny::verbatimTextOutput("script_text"))))))
  })
  output$export_thumb <- shiny::renderPlot({ print(if (identical(job(), "reference")) reference$plot() else figure()) }, res = 72)
  output$export_summary <- shiny::renderUI({
    if (identical(job(), "reference")) return(reference$summary())
    s <- settings(); d <- selected_data()
    items <- list("Figure" = paste(if (s$layout == "linear") "linear" else "circular", if (d$type == "macro") "chromosome synteny" else "microsynteny"),
                  "Genomes" = paste(d$organisms, collapse = ", "), "Palette" = s$palette, "Ribbons" = paste0("opacity ", s$alpha),
                  "Links" = paste(nrow(d$second), "displayed"),
                  "Tracks" = if (identical(job(), "tracks")) paste(length(.tracks_data(tracks$tracks())), "tracks") else NULL)
    items <- Filter(Negate(is.null), items)
    shiny::div(class = "summary-list", lapply(names(items), function(n) shiny::tagList(shiny::span(class = "kicker", n), shiny::span(items[[n]]))))
  })
  output$script_text <- shiny::renderText(script())
  figure_download <- function(ext) shiny::downloadHandler(
    filename = function() paste0("ggsynteny-", job(), ".", ext),
    content = function(file) {
      if (identical(job(), "reference")) return(reference$save(file, ext))
      width_mm <- as.numeric(input$pdf_width %||% 183)
      circular <- !identical(input$layout, "linear")
      ratio <- if (identical(job(), "tracks")) 1.1 else if (circular) 1 else 0.7
      if (ext == "pdf") ggplot2::ggsave(file, figure(), device = "pdf", width = width_mm, height = width_mm * ratio, units = "mm", bg = "white", limitsize = FALSE)
      else ggplot2::ggsave(file, figure(), device = "png", width = 10, height = 10 * ratio, dpi = as.numeric(input$png_dpi %||% 300),
                           bg = input$png_bg %||% "white", limitsize = FALSE)
    })
  output$pdf <- figure_download("pdf"); output$png <- figure_download("png")
  table_download <- function(get, name) shiny::downloadHandler(filename = function() name(), content = function(file)
    utils::write.table(get(), file, sep = "\t", quote = TRUE, row.names = FALSE, na = "NA"))
  output$export_first <- table_download(function() selected_data()$first, function() if (identical(dataset()$type, "macro")) "chromosomes.tsv" else "features.tsv")
  output$export_second <- table_download(function() selected_data()$second, function() if (identical(dataset()$type, "macro")) "blocks.tsv" else "links.tsv")
  output$export_pairs <- table_download(function() .studio_pairs(selected_data()), function() "pair-summary.tsv")
  output$export_variants <- table_download(function() reference$variants(), function() "variants.tsv")
  output$export_identity <- table_download(function() reference$identity(), function() "identity-windows.tsv")
  for (i in 1:12) local({
    i <- i
    output[[paste0("export_track_", i)]] <- table_download(function() .tracks_data(tracks$tracks())[[i]]$data, function() paste0("track", i, ".tsv"))
  })
  output$code <- shiny::downloadHandler(filename = function() paste0("reproduce-", job(), ".R"), content = function(file) writeLines(script(), file))
}

.studio_app <- function() shiny::shinyApp(.studio_ui(), .studio_server)
