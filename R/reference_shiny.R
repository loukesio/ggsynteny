.reference_demo <- function() {
  # Invented teaching events from the supplied design, not measured E. coli calls.
  events <- data.frame(type = c("INS", "DEL", "INS", "DEL", "DUP", "INS", "INV", "DUP", "DEL", "INS", "INV", "DEL"),
    start = c(350000, 612000, 880000, 1940000, 2230000, 2550000, 2800000, 3020000, 3410000, 4120000, 4400000, 4600000),
    event_length = c(5000, 38000, 9200, 12000, 30000, 22000, 110000, 18000, 64000, 3100, 45000, 8000),
    source_start = c(NA, NA, NA, NA, 2200000, NA, NA, 1210000, NA, NA, NA, NA))
  carriers <- list(2, 1:3, c(1,4,5), 4, 5, 3, 1, 3:4, c(2,5), 1:5, 4:5, 3)
  do.call(rbind, lapply(seq_len(nrow(events)), function(i) {
    r <- events[rep(i, length(carriers[[i]])), ]
    r$sample <- paste("Genome", LETTERS[carriers[[i]]])
    r$end <- r$start + ifelse(r$type == "INS", 0, r$event_length)
    r[, c("sample", "type", "start", "end", "event_length", "source_start")]
  }))
}

.reference_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::addResourcePath("ggsynteny-reference", system.file("shiny", "www", package = "ggsynteny"))
  shiny::tagList(
    shiny::tags$head(shiny::tags$link(rel = "stylesheet", href = "ggsynteny-reference/reference.css"), shiny::tags$script(src = "ggsynteny-reference/reference.js")),
    shiny::div(class = "reference-workbench",
      shiny::div(class = "ref-header",
        shiny::div(shiny::div(class = "ref-kicker", "Comparative genome ring \u00b7 ggsynteny"), shiny::h1(shiny::textOutput(ns("heading"), inline = TRUE))),
        shiny::p("Reference at the centre, one ring per genome outward. Every ring shares the reference coordinates, so a line from the centre compares the same position across genomes.")),
      shiny::div(class = "ref-toolbar",
        shiny::div(class = "ref-genomes", shiny::selectizeInput(ns("samples"), "Comparison genomes \u00b7 inner to outer", choices = NULL, multiple = TRUE)),
        shiny::div(class = "ref-palette", shiny::selectInput(ns("palette"), "ltc palette", choices = names(syn_palettes()), selected = "minou"), shiny::uiOutput(ns("swatches"))),
        shiny::div(class = "ref-downloads", shiny::downloadButton(ns("pdf"), "PDF"), shiny::downloadButton(ns("png"), "PNG"),
          shiny::downloadButton(ns("table"), "Variants"), shiny::downloadButton(ns("identity_table"), "Identity"), shiny::downloadButton(ns("code"), "R script"))),
      shiny::div(class = "ref-status", shiny::uiOutput(ns("status"))),
      shiny::div(class = "ref-main-grid",
        shiny::div(class = "ref-figure", shiny::uiOutput(ns("preview")), shiny::uiOutput(ns("duplication_note"))),
        shiny::div(class = "ref-side", shiny::div(class = "ref-section-heading", "Encoding \u00b7 tick to show"),
          shiny::div(class = "ref-encoding", shiny::uiOutput(ns("encoding"))),
          shiny::checkboxInput(ns("show_identity"), "Show identity shading", TRUE), shiny::uiOutput(ns("identity_key")), shiny::uiOutput(ns("events")))),
      shiny::div(class = "ref-bottom-grid", shiny::div(shiny::uiOutput(ns("locus"))),
        shiny::div(shiny::div(class = "ref-section-heading", "At cursor", shiny::span(class = "ref-cursor-pos", "hover the ring")), shiny::uiOutput(ns("readout")))),
      shiny::uiOutput(ns("guide")),
      shiny::tags$details(class = "ref-data-controls", shiny::tags$summary("Data, reference & figure settings"),
        shiny::div(class = "ref-data-fields",
          shiny::div(shiny::radioButtons(ns("source"), "Start with", c("Invented example" = "demo", "Upload variant table" = "upload")),
            shiny::fileInput(ns("file"), "Variant table (CSV or TSV)", accept = c(".csv", ".tsv", ".txt")),
            shiny::fileInput(ns("identity_file"), "Optional identity windows (CSV or TSV)", accept = c(".csv", ".tsv", ".txt"))),
          shiny::div(shiny::textInput(ns("reference"), "Reference sequence name", "Example reference"),
            shiny::numericInput(ns("length"), "Reference length (base pairs)", 4800000, min = 1),
            shiny::textInput(ns("title"), "Export title (optional)", "")),
          shiny::div(class = "ref-small", "Required columns: sample, type, start, end. Types: INS, DEL, DUP, INV, SNP. Positions must use one reference, in base pairs, starting at zero; end is exclusive. Insertions may have equal start and end.",
            shiny::p("Optional: event_length (inserted bases), source_start (duplication source on the reference). Unknown values may be NA. Identity upload columns: sample, start, end, identity (0\u2013100 percent or NA). Use non-overlapping windows on the same reference. No identity scores or duplication sources are inferred."),
            shiny::p("The example reference is fixed at 4,800,000 bp. To compare two genomes, choose one comparison genome above."))),
        shiny::tags$details(shiny::tags$summary("Inspect displayed records (first 50)"), shiny::div(class = "table-scroll", shiny::tableOutput(ns("records")))))))
}

.reference_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    source_data <- shiny::reactive({
      tryCatch({
        if (identical(input$source, "demo")) return(.reference_demo())
        if (is.null(input$file)) stop("Upload a variant table to begin.")
        v <- .studio_table(input$file$datapath)
        v <- .circ_columns(v, c("sample", "type", "start", "end"), "Variants")
        for (key in intersect(c("start", "end", "event_length", "source_start"), names(v))) {
          raw <- v[[key]]
          v[[key]] <- suppressWarnings(as.numeric(raw))
          if (any(is.na(v[[key]]) & !is.na(raw) & !raw %in% c("", "NA"))) stop(key, " contains non-numeric values.")
        }
        .reference_validate(v, input$length)
      }, error = function(e) list(problem = conditionMessage(e)))
    })
    identity_source <- shiny::reactive({
      tryCatch({
        if (identical(input$source, "demo")) return(.reference_identity_demo())
        if (is.null(input$identity_file)) return(.reference_identity_validate(NULL, reference_length()))
        w <- .studio_table(input$identity_file$datapath)
        w <- .circ_columns(w, c("sample", "start", "end", "identity"), "Identity windows")
        for (key in c("start", "end", "identity")) {
          raw <- w[[key]]; w[[key]] <- suppressWarnings(as.numeric(raw))
          if (any(is.na(w[[key]]) & !is.na(raw) & !raw %in% c("", "NA"))) stop(key, " contains non-numeric identity values.")
        }
        .reference_identity_validate(w, reference_length())
      }, error = function(e) list(problem = conditionMessage(e)))
    })
    shiny::observeEvent(list(source_data(), identity_source()), {
      d <- source_data(); w <- identity_source()
      choices <- if (is.null(d$problem)) sort(unique(c(d$sample, if (is.null(w$problem)) w$sample else character()))) else character()
      shiny::updateSelectizeInput(session, "samples", choices = choices, selected = choices)
    })
    identity_selected <- shiny::reactive({
      selected()
      w <- identity_source()
      shiny::validate(shiny::need(is.null(w$problem), w$problem))
      if (!isTRUE(input$show_identity)) return(w[FALSE, , drop = FALSE])
      w[w$sample %in% input$samples, , drop = FALSE]
    })
    colors <- shiny::reactive(.reference_palette(if (is.null(input$palette)) "minou" else input$palette))
    selected <- shiny::reactive({
      d <- source_data()
      shiny::validate(shiny::need(is.null(d$problem), d$problem))
      shiny::validate(shiny::need(length(input$samples) > 0, "Select at least one comparison genome."))
      tryCatch(.reference_validate(d, reference_length()),
               error = function(e) shiny::validate(shiny::need(FALSE, conditionMessage(e))))
      d[d$sample %in% input$samples & d$type %in% input$types, , drop = FALSE]
    })
    reference_length <- shiny::reactive(if (input$source == "demo") 4800000 else input$length)
    event_table <- shiny::reactive({ d <- selected(); d[!duplicated(.reference_event_key(d)), , drop = FALSE] })
    selected_event <- shiny::reactive({
      d <- event_table(); if (!nrow(d)) return(NULL)
      key <- .reference_event_key(d); i <- match(input$event, key)
      if (!length(i) || is.na(i)) i <- if (any(d$type == "DEL")) which(d$type == "DEL")[1] else 1L
      d[i, , drop = FALSE]
    })
    output$heading <- shiny::renderText(paste(length(input$samples), if (length(input$samples) == 1) "genome against" else "genomes against", input$reference))
    output$swatches <- shiny::renderUI(shiny::tagList(
      shiny::tags$style(shiny::HTML(paste0(".reference-workbench{", paste(paste0("--ref-", names(colors()), ":", colors()), collapse = ";"), "}"))),
      shiny::div(class = "ref-swatches", lapply(colors(), function(c) shiny::span(style = paste0("background:", c))))))
    output$encoding <- shiny::renderUI({
      cols <- stats::setNames(paste0("var(--ref-", .reference_types, ")"), .reference_types)
      selected_types <- .reference_types
      descriptions <- c(INS = "Capped tick \u00b7 added sequence", DEL = "Outlined gap \u00b7 absent sequence", DUP = "Split arc \u00b7 extra copy", INV = "Solid arc \u00b7 reversed sequence", SNP = "Fine tick \u00b7 one base changed")
      icons <- lapply(.reference_types, function(type) {
        col <- cols[[type]]
        shape <- switch(type,
          INS = shiny::tags$path(d = "M14 13V2M9 2H19", fill = "none", stroke = col, `stroke-width` = 2),
          DEL = shiny::tags$rect(x = 1, y = 2, width = 26, height = 10, fill = .reference_style$paper, stroke = col),
          DUP = shiny::tagList(shiny::tags$rect(x = 1, y = 2, width = 26, height = 10, fill = col), shiny::tags$path(d = "M1 7H27", stroke = "#F4F2ED")),
          INV = shiny::tags$rect(x = 1, y = 2, width = 26, height = 10, fill = col),
          SNP = shiny::tags$path(d = "M14 1V13", stroke = col, `stroke-width` = 2))
        shiny::tagList(shiny::tags$svg(viewBox = "0 0 28 14", class = "ref-legend-icon", `aria-hidden` = "true", shape),
          shiny::span(class = "ref-legend-name", .reference_labels[type]), shiny::span(class = "ref-legend-desc", descriptions[type]))
      })
      shiny::checkboxGroupInput(session$ns("types"), label = NULL, choiceNames = icons, choiceValues = .reference_types, selected = selected_types)
    })
    figure_title <- shiny::reactive({
      title <- input$title
      if (is.null(title) || !nzchar(title)) title <- paste(length(input$samples), "genomes against", input$reference)
      if (input$source == "demo") paste(title, "\u00b7 invented example") else title
    })
    plot <- function(interactive = FALSE) {
      tryCatch(plot_reference_comparison(selected(), reference_length(), reference = input$reference,
        sample_order = input$samples, title = figure_title(), interactive = interactive,
        palette = if (is.null(input$palette)) "minou" else input$palette, identity_windows = identity_selected()),
        error = function(e) shiny::validate(shiny::need(FALSE, conditionMessage(e))))
    }
    output$status <- shiny::renderUI({
      d <- selected(); identity_selected()
      shiny::p(if (input$source == "demo") "INVENTED EXAMPLE \u00b7 " else "SUPPLIED VARIANTS \u00b7 ",
        nrow(event_table()), " event patterns \u00b7 ", nrow(d), " supplied calls \u00b7 ", length(input$samples), " comparison genomes",
        if (input$source == "demo") " \u00b7 variants and identity are invented, not biological findings" else "")
    })
    output$preview <- shiny::renderUI({
      e <- selected_event()
      .reference_svg(selected(), reference_length(), input$samples, input$reference, colors(), session$ns,
        if (is.null(e)) NULL else .reference_event_key(e), identity_windows = identity_selected())
    })
    output$identity_key <- shiny::renderUI({
      w <- identity_selected()
      shades <- .reference_identity_color(c(90, 95, 100, NA_real_))
      shiny::div(class = "ref-identity-key",
        shiny::div(class = "ref-section-heading", "Two different greys"),
        shiny::p(class = "ref-small", "Inner black/dark-grey bands: a ruler, alternating every ", format(.reference_ruler_step(reference_length()), big.mark = ",", scientific = FALSE), " bases. These are not data."),
        shiny::div(class = "ref-identity-scale", lapply(seq_along(shades), function(i)
          shiny::span(shiny::span(class = "ref-shade-chip", style = paste0("background:", shades[i])), c("\u226490%", "95%", "100%", "No score")[i]))),
        shiny::p(class = "ref-small", if (nrow(w)) "Outer windows: darker means higher supplied identity. For example, 99% means about 99 of 100 aligned bases match. Below 90% uses the lightest shade. Coverage is not shown." else "No identity windows are displayed. The pale tracks carry no similarity measurement.",
          if (input$source == "demo" && nrow(w)) " These window scores are invented." else ""))
    })
    output$duplication_note <- shiny::renderUI({
      v <- selected()
      if (!"source_start" %in% names(v)) return(NULL)
      d <- v[v$type == "DUP" & !is.na(v$source_start), , drop = FALSE]
      if (!nrow(d)) return(NULL)
      r <- d[which.max(abs(d$start - d$source_start)), , drop = FALSE]
      carriers <- unique(d$sample[.reference_event_key(d) == .reference_event_key(r)])
      shiny::p(class = "ref-duplication-note", shiny::strong("What the curved ribbon means. "),
        "In ", paste(carriers, collapse = ", "), ", the supplied call links a ", .reference_fmt(r$end-r$start, "kb"),
        " source region at ", .reference_fmt(r$source_start), " to an extra copy at ", .reference_fmt(r$start),
        ". Both positions use the reference map. The ribbon joins positions; it does not show DNA moving.",
        if (input$source == "demo") " This is an invented teaching example." else "")
    })
    output$events <- shiny::renderUI({
      d <- event_table(); v <- selected(); keys <- .reference_event_key(v); e <- selected_event()
      active <- if (is.null(e)) "" else .reference_event_key(e)
      tags <- if (length(input$samples)<=26) LETTERS[seq_along(input$samples)] else as.character(seq_along(input$samples))
      shiny::tagList(shiny::div(class = "ref-section-heading", "Events \u00b7 supplied presence", shiny::div(class = "ref-event-grid", lapply(tags, shiny::span))),
        shiny::div(class = "ref-events", lapply(seq_len(min(100, nrow(d))), function(i) {
          r <- d[i, ]; key <- .reference_event_key(r); col <- colors()[[r$type]]
          len <- if (r$type == "INS") if ("event_length" %in% names(r)) r$event_length else NA_real_ else r$end-r$start
          shiny::tags$button(type = "button", class = paste("ref-event-row", if (key == active) "is-selected" else ""), `data-event` = key,
            `aria-pressed` = if (key == active) "true" else "false",
            shiny::span(class = "ref-event-dot", style = paste0("background:", col)),
            shiny::span(.reference_labels[r$type]), shiny::span(class = "ref-event-pos", .reference_fmt(r$start), " \u00b7 ", if (is.na(len)) "size ?" else .reference_fmt(len, "kb")),
            shiny::div(class = "ref-event-grid", lapply(input$samples, function(s) {
              present <- any(v$sample == s & keys == key)
              shiny::span(class = "ref-event-cell", title = paste(s, if (present) "supplied call" else "no matching call"),
                style = paste0("background:", if (present) col else "#E2DED6"))
            })))
        })), shiny::p(class = "ref-small", "Click a row or mark to inspect its region. Squares identify genomes with the same supplied type and coordinates; grey squares mean no matching call.",
          if (nrow(d)>100) " Showing the first 100 event patterns; downloads include every displayed call." else ""))
    })
    output$locus <- shiny::renderUI({
      e <- selected_event()
      if (is.null(e)) return(shiny::p(class = "ref-small", "No calls selected. Enable a variant type to inspect a region."))
      .reference_locus(selected(), e, input$samples, colors(), reference_length())
    })
    output$readout <- shiny::renderUI({
      selected()
      shiny::div(class = "ref-readout", lapply(seq_along(input$samples), function(i)
        shiny::div(class = "ref-readout-row", `data-sample` = input$samples[i],
          shiny::span(class = "ref-mono", if (length(input$samples)<=26) LETTERS[i] else i),
          shiny::span(class = "ref-readout-dot", style = "background:#DAD6CD"),
          shiny::span(class = "ref-readout-state", "\u2014"))))
    })
    output$guide <- shiny::renderUI({
      shiny::div(class = "ref-guide",
        shiny::div(shiny::strong("01 / Read clockwise"), paste0("No x/y axes. R is the reference; A, B, \u2026 are genomes in the order above. M and Mb mean one million base pairs; kb means one thousand. For example, ", .reference_fmt(reference_length()/5), " is one fifth along this ", .reference_fmt(reference_length()), " reference.")),
        shiny::div(shiny::strong("02 / Read the marks"), "Colours follow the selected ltc palette. Arc length shows the reference span. Capped insertion ticks mark positions, not direction or inserted length; supplied lengths are in the event list and hover details. Curved ribbons join the supplied source of a duplicated region to the position of its extra copy. They do not show a physical path or prove how the duplication happened."),
        shiny::div(shiny::strong("03 / Interpret with care"), "Outer grey shading shows supplied identity; pale green means no score. Higher identity means closer sequence agreement, not better biology. Coverage is not shown. Overlaps may hide calls. More differences are not inherently better or worse, and these marks alone cannot show a biological effect. The example numbers are invented."))
    })
    output$records <- shiny::renderTable(utils::head(selected(), 50), digits = 0)
    download <- function(ext) shiny::downloadHandler(filename = function() paste0("reference-comparison.", ext),
      content = function(file) {
        # Shiny's temporary destination has no extension.
        tmp <- tempfile(fileext = paste0(".", ext)); on.exit(unlink(tmp))
        save_reference_comparison(plot(), tmp)
        file.copy(tmp, file, overwrite = TRUE)
      })
    output$pdf <- download("pdf"); output$png <- download("png")
    output$identity_table <- shiny::downloadHandler(filename = "identity-windows.tsv", content = function(file) {
      utils::write.table(identity_selected(), file, sep = "\t", row.names = FALSE, quote = TRUE, na = "NA")
    })
    output$table <- shiny::downloadHandler(filename = "variants.tsv", content = function(file) {
      utils::write.table(selected(), file, sep = "\t", row.names = FALSE, quote = TRUE)
    })
    output$code <- shiny::downloadHandler(filename = "reference-comparison.R", content = function(file) {
      selected(); identity_selected()
      q <- function(x) paste(utils::capture.output(dput(x)), collapse = "\n")
      writeLines(c('# Save both downloads beside this script: variants.tsv and identity-windows.tsv.',
        'library(ggsynteny)', 'identity_windows <- read.delim("identity-windows.tsv", colClasses = c(sample = "character", start = "numeric", end = "numeric", identity = "numeric"))', 'variants <- read.delim("variants.tsv", colClasses = c(sample = "character", type = "character"))',
        paste0('p <- plot_reference_comparison(variants, genome_length = ', q(reference_length()),
          ', reference = ', q(input$reference), ', sample_order = ', q(input$samples), ', palette = ', q(input$palette), ', title = ', q(figure_title()), ', identity_windows = identity_windows)'),
        'print(p)', '# Bundled IBM Plex fonts; requires showtext and sysfonts.',
        'save_reference_comparison(p, "reference-comparison.pdf")'), file)
    })
  })
}
