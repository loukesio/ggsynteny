# The optional app lives behind requireNamespace('shiny') in its launcher.
.studio_synteny_ui <- function() {
  shiny::fluidPage(
    shiny::tags$head(shiny::tags$title("ggsynteny Studio"),
      shiny::includeCSS(system.file("shiny", "www", "studio.css", package = "ggsynteny"))),
    shiny::div(class = "studio-header",
      shiny::div(shiny::span(class = "brand-mark", "gg"),
        shiny::div(shiny::h1("ggsynteny", shiny::span("Studio")),
                    shiny::p("Explore the connections between genomes."))),
      shiny::span(class = "version-badge", paste("v", utils::packageVersion("ggsynteny"), sep = ""))),
    shiny::div(class = "studio-layout",
      shiny::tags$aside(class = "control-panel",
        shiny::div(class = "section-kicker", "01 / YOUR DATA"),
        shiny::radioButtons("source", "Start with", c("Example data" = "demo", "Upload results" = "upload"), inline = TRUE),
        shiny::selectInput("format", "Results from", choices = .studio_formats, selected = "genes"),
        shiny::uiOutput("format_help"), shiny::uiOutput("upload_controls"),
        shiny::div(class = "section-divider"),
        shiny::div(class = "section-kicker", "02 / YOUR FIGURE"),
        shiny::radioButtons("layout", "Layout", c("Circular" = "circular", "Linear" = "linear"), inline = TRUE),
        shiny::div(class = "form-group shiny-input-container studio-switch",
          shiny::tags$label(
            shiny::tags$input(id = "interactive", type = "checkbox", role = "switch", class = "shiny-input-checkbox"),
            shiny::span(class = "studio-switch-track", `aria-hidden` = "true"),
            shiny::span(class = "studio-switch-copy", "Interactive plot", shiny::tags$small("Hover and zoom")),
            shiny::span(class = "studio-switch-off", `aria-hidden` = "true", "Off"),
            shiny::span(class = "studio-switch-on", `aria-hidden` = "true", "On"))),
        shiny::selectizeInput("organisms", "Genomes / bins in display order", choices = NULL, multiple = TRUE),
        shiny::selectInput("palette", "Palette", choices = names(syn_palettes()), selected = "casa_natal"),
        shiny::uiOutput("palette_preview"),
        shiny::sliderInput("alpha", "Ribbon opacity", min = 0.05, max = 1, value = 0.35, step = 0.05),
        shiny::checkboxInput("labels", "Show chromosome / gene labels", TRUE),
        shiny::uiOutput("type_controls"),
        shiny::conditionalPanel("input.layout === 'circular'",
          shiny::sliderInput("gap", "Gap between genomes (degrees)", min = 0, max = 30, value = 10)),
        shiny::numericInput("limit", "Maximum links to display", value = 1000, min = 1, max = 10000, step = 100),
        shiny::textInput("title", "Figure title (optional)", value = ""),
        shiny::p(class = "control-note", "The plot and tables update as you change settings. Downloads use the displayed records.")),
      shiny::tags$main(class = "workspace",
        shiny::uiOutput("data_status"), shiny::uiOutput("metrics"),
        shiny::div(class = "plot-card",
          shiny::div(class = "card-heading", shiny::div(shiny::span(class = "section-kicker", "LIVE PREVIEW"),
            shiny::h2(shiny::textOutput("plot_heading", inline = TRUE))),
            shiny::div(class = "download-row", shiny::downloadButton("pdf", "PDF"), shiny::downloadButton("png", "PNG"))),
          shiny::conditionalPanel("!input.interactive", shiny::plotOutput("plot", height = "640px")),
          shiny::conditionalPanel("input.interactive", shiny::uiOutput("interactive_ui")),
          shiny::uiOutput("plot_note")),
        shiny::div(class = "data-card",
          shiny::div(class = "card-heading", shiny::div(shiny::span(class = "section-kicker", "INSPECT & EXTRACT"),
            shiny::h2("The data behind the figure")), shiny::downloadButton("code", "R script")),
          shiny::tabsetPanel(id = "data_tab",
            shiny::tabPanel("Records", shiny::downloadButton("first_tsv", "Records TSV"), shiny::div(class = "table-scroll", shiny::tableOutput("first_preview"))),
            shiny::tabPanel("Links", shiny::downloadButton("second_tsv", "Links TSV"), shiny::div(class = "table-scroll", shiny::tableOutput("second_preview"))),
            shiny::tabPanel("Pair summary", shiny::downloadButton("summary_tsv", "Pair summary TSV"), shiny::tableOutput("pair_preview"))),
          shiny::p(class = "table-footnote", "Table previews show the first 50 displayed records. Downloads include every displayed row. Counts describe supplied links, not unique genomic coverage.")),
        shiny::p(class = "studio-footer", "Local data, familiar palettes, publication-ready figures. Powered by ggsynteny and ggplot2."))))
}

.studio_server <- function(input, output, session) {
  .reference_server("reference_comparison")
  dataset <- shiny::reactive({
    shiny::req(input$format, input$source)
    paths <- list()
    if (identical(input$source, "upload")) {
      n <- if (input$format == "genespace") 1L else 2L
      paths <- lapply(seq_len(n), function(i) {
        f <- input[[paste0("file_", input$format, "_", i)]]
        if (is.null(f)) return(character())
        f$datapath
      })
    }
    tryCatch(.studio_load(input$format, demo = input$source == "demo", paths = paths),
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
    shiny::validate(shiny::need(length(input$organisms) > 0, "Select at least one genome or bin."))
    tryCatch(.studio_select(d, input$organisms, input$limit, input$layout), error = function(e) {
      shiny::validate(shiny::need(FALSE, conditionMessage(e)))
    })
  })
  settings <- shiny::reactive({
    d <- selected_data()
    list(layout = input$layout, palette = input$palette, alpha = input$alpha,
         labels = isTRUE(input$labels), orientation = isTRUE(input$orientation) && d$type == "macro" && "orientation" %in% names(d$second),
         identity = isTRUE(input$identity) && d$type == "micro" && "identity" %in% names(d$second),
         anchor = if (is.null(input$anchor)) "body" else input$anchor,
         gap = input$gap, title = if (is.null(input$title) || !nzchar(input$title)) NULL else input$title)
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
                  height_svg = if (input$layout == "circular") 10 else 7,
                  opts = list(ggiraph::opts_zoom(max = 4, default_on = TRUE),
                              ggiraph::opts_toolbar(hidden = "zoom_onoff")))
    })
  }
  output$format_help <- shiny::renderUI({
    shiny::req(input$format)
    shiny::div(class = "format-help", lapply(.studio_schema(input$format), shiny::p))
  })
  output$upload_controls <- shiny::renderUI({
    if (!identical(input$source, "upload")) {
      note <- switch(input$format,
        mcscanx = "Simulated example: 4 genomes, 32 chromosomes and 240 blocks.",
        genespace = "Simulated example: 4 genomes, 32 chromosomes and 384 interval matches.",
        "Example loaded.")
      return(shiny::p(class = "example-note", note, " Switch to Upload results to use your own files."))
    }
    labels <- switch(input$format, native = c("Chromosome table", "Block table"),
                      mcscanx = c("Collinearity output", "MCScanX GFF"),
                      genespace = "synHits TSV", genes = c("Gene features", "Homology links"))
    shiny::tagList(lapply(seq_along(labels), function(i) shiny::fileInput(
      paste0("file_", input$format, "_", i), labels[i], accept = c(".tsv", ".csv", ".txt", ".gff", ".collinearity"))))
  })
  output$type_controls <- shiny::renderUI({
    d <- dataset()
    if (!is.null(d$problem)) return(NULL)
    if (d$type == "macro") {
      if ("orientation" %in% names(d$second)) shiny::checkboxInput("orientation", "Use block orientation", FALSE)
    } else shiny::tagList(
      shiny::selectInput("anchor", "Ribbon attachment", c("Gene body" = "body", "Full gene" = "full")),
      if ("identity" %in% names(d$second)) shiny::checkboxInput("identity", "Colour ribbons by identity", FALSE))
  })
  output$palette_preview <- shiny::renderUI({
    shiny::req(input$palette)
    colors <- syn_palettes()[[input$palette]]
    shiny::div(class = "palette-preview", role = "img", `aria-label` = paste(input$palette, "palette"),
      lapply(colors, function(color) shiny::span(style = paste0("background:", color), title = color)))
  })
  output$data_status <- shiny::renderUI({
    d <- dataset()
    if (!is.null(d$problem)) return(shiny::div(class = "data-status pending", role = "status", d$problem))
    note <- switch(d$format,
      native = "Chromosome lengths and block coordinates share the unit in your input.",
      mcscanx = "MCScanX coordinates are shown in Mb. Chromosome spans end at the last annotated gene.",
      genespace = "GENESPACE coordinates are shown in Mb. Chromosome spans are inferred from supplied blocks.",
      genes = "Gene regions use the supplied coordinate scale. Contig spans cover the first to last gene; no flanks or homology are inferred.")
    if (identical(input$source, "demo") && d$format %in% c("mcscanx", "genespace"))
      note <- paste("Simulated example data.", note)
    shiny::div(class = "data-status ready", role = "status", shiny::strong("Data ready. "), note)
  })
  output$metrics <- shiny::renderUI({
    d <- selected_data()
    values <- c(length(d$organisms), nrow(d$first), nrow(d$second), nrow(.studio_pairs(d)))
    labels <- c("Genomes / bins", if (d$type == "macro") "Chromosomes" else "Genes", "Displayed links", "Connected pairs")
    shiny::div(class = "metrics", lapply(seq_along(values), function(i) shiny::div(class = "metric",
      shiny::strong(format(values[i], big.mark = ",")), shiny::span(labels[i]))))
  })
  output$plot_heading <- shiny::renderText({
    d <- dataset()
    paste(if (input$layout == "circular") "Circular" else "Linear",
          if (identical(d$type, "macro")) "chromosome synteny" else "microsynteny")
  })
  output$plot <- shiny::renderPlot({ print(current_plot()) }, res = 110)
  output$plot_note <- shiny::renderUI({
    d <- selected_data()
    notes <- paste(nrow(d$second), "of", d$matching_links, "matching links displayed.")
    if (d$matching_links > nrow(d$second)) notes <- paste(notes, "The first rows in input order are shown; increase the limit to display more.")
    if (d$type == "macro" && input$layout == "linear")
      notes <- paste(notes, d$layout_omitted, "other links are omitted by the linear layout. Use circular view to include non-adjacent and within-genome pairs.")
    if (isTRUE(input$interactive))
      notes <- paste(notes, "Hover over a ribbon or feature for details. Scroll to zoom, drag to pan, and use the toolbar to reset. PDF and PNG downloads are static figures.")
    shiny::p(class = "plot-note", notes)
  })
  output$first_preview <- shiny::renderTable(utils::head(selected_data()$first, 50), striped = TRUE, bordered = FALSE, digits = 6)
  output$second_preview <- shiny::renderTable(utils::head(selected_data()$second, 50), striped = TRUE, bordered = FALSE, digits = 6)
  output$pair_preview <- shiny::renderTable(.studio_pairs(selected_data()), striped = TRUE)
  figure_download <- function(ext) shiny::downloadHandler(
    filename = function() paste0("ggsynteny-", input$layout, ".", ext),
    content = function(file) {
      ggplot2::ggsave(file, current_plot(), device = ext, width = 10,
                       height = if (input$layout == "circular") 10 else 7,
                       dpi = 300, bg = "white", limitsize = FALSE)
    })
  output$pdf <- figure_download("pdf"); output$png <- figure_download("png")
  table_download <- function(which) shiny::downloadHandler(
    filename = function() {
      d <- selected_data()
      if (which == "summary") return("pair-summary.tsv")
      if (d$type == "macro") if (which == "first") "chromosomes.tsv" else "blocks.tsv"
      else if (which == "first") "features.tsv" else "links.tsv"
    }, content = function(file) {
      d <- selected_data()
      table <- if (which == "summary") .studio_pairs(d) else d[[which]]
      utils::write.table(table, file, sep = "\t", quote = TRUE, row.names = FALSE, na = "NA")
    })
  output$first_tsv <- table_download("first"); output$second_tsv <- table_download("second")
  output$summary_tsv <- table_download("summary")
  output$code <- shiny::downloadHandler(filename = "reproduce-synteny.R", content = function(file) {
    writeLines(.studio_code(selected_data(), settings(), interactive = isTRUE(input$interactive)), file)
  })
}

.studio_app <- function() shiny::shinyApp(.studio_ui(), .studio_server)

.studio_ui <- function() {
  shiny::navbarPage("ggsynteny Studio",
    shiny::tabPanel("Synteny", .studio_synteny_ui()),
    shiny::tabPanel("Reference comparison", .reference_ui("reference_comparison")))
}
