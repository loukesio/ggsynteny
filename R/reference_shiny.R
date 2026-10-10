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

# Data step: two file cards (variants required, identity optional), the
# reference name and length, and a readout. Inputs keep the module namespace
# so the server below works unchanged.
.reference_data_ui <- function(id, example = TRUE) {
  ns <- shiny::NS(id)
  cards <- list(
    list(label = "Variant calls", note = "One row per event call on the reference. Types: INS, DEL, DUP, INV, SNP. Zero-based positions in base pairs, exclusive end.",
         required = c("sample", "type", "start", "end"), optional = c("event_length (inserted bases)", "source_start (duplication source)"),
         sample = "variants_five_genomes.tsv", input = "file"),
    list(label = "Identity windows", note = "Optional. Non-overlapping reference windows with measured alignment identity per comparison genome.",
         required = c("sample", "start", "end", "identity"), optional = character(),
         sample = "identity_five_genomes.tsv", input = "identity_file"))
  shiny::tagList(
    shiny::div(class = "page-head", shiny::div(shiny::span(class = "kicker", "Step 1 \u00b7 Data"),
      shiny::h1(if (example) "The invented example" else "Bring your variant calls"),
      shiny::p("Every position is on one reference. The identity table is optional and comes from an alignment, never from the number of variants."))),
    shiny::div(class = "data-grid",
      shiny::div(
        shiny::div(class = "card", shiny::div(class = "export-opts",
          shiny::textInput(ns("reference"), .studio_arg("Reference sequence name", "reference"), "Example reference"),
          shiny::numericInput(ns("length"), .studio_arg("Reference length (bp)", "genome_length"), 4800000, min = 1))),
        shiny::div(style = "height:16px"),
        shiny::div(class = "file-cards", lapply(cards, function(c) .studio_file_card(
          list(label = c$label, note = c$note, required = c$required, optional = c$optional, sample = c$sample), c$input, example, ns))),
        shiny::div(class = "card preview-card", shiny::div(class = "card-head", shiny::div(shiny::span(class = "kicker", "As read"), shiny::h3("First rows"))),
          shiny::div(class = "table-scroll", shiny::tableOutput(ns("records"))))),
      shiny::uiOutput(ns("readout"))))
}

# Figure step: the workbench (ring, encoding, events, locus, cursor readout).
.reference_figure_ui <- function(id, samples = NULL) {
  ns <- shiny::NS(id)
  shiny::div(class = "reference-workbench",
    shiny::div(class = "ref-header",
      shiny::div(shiny::div(class = "ref-kicker", "Step 2 \u00b7 Figure \u00b7 comparative genome ring"), shiny::h1(shiny::textOutput(ns("heading"), inline = TRUE))),
      shiny::p("Reference at the centre, one ring per genome outward. Every ring shares the reference coordinates, so a line from the centre compares the same position across genomes.")),
    shiny::div(class = "ref-toolbar",
      shiny::div(class = "ref-genomes", shiny::selectizeInput(ns("samples"), .studio_arg("Comparison genomes \u00b7 inner to outer", "sample_order"), choices = samples, selected = samples, multiple = TRUE)),
      shiny::div(class = "ref-palette", shiny::selectInput(ns("palette"), .studio_arg("ltc palette", "palette"), choices = names(syn_palettes()), selected = "minou"), shiny::uiOutput(ns("swatches"))),
      shiny::div(class = "ref-palette", shiny::selectInput(ns("identity_palette"), .studio_arg("Identity shading", "identity_palette"),
        c("Grey ramp (default)" = "", "Sand to navy" = "sand", "heatmap0" = "heatmap0", "heatmap1" = "heatmap1", "heatmap3" = "heatmap3"))),
      shiny::div(class = "ref-palette", shiny::textInput(ns("title"), .studio_arg("Export title", "title"), ""))),
    shiny::div(class = "ref-status", shiny::uiOutput(ns("status"))),
    shiny::div(class = "ref-main-grid",
      shiny::div(class = "ref-figure", shiny::uiOutput(ns("preview")), shiny::uiOutput(ns("duplication_note"))),
      shiny::div(class = "ref-side", shiny::div(class = "ref-section-heading", "Encoding \u00b7 tick to show"),
        shiny::div(class = "ref-encoding", shiny::uiOutput(ns("encoding"))),
        shiny::checkboxInput(ns("show_identity"), "Show identity shading", TRUE), shiny::uiOutput(ns("identity_key")), shiny::uiOutput(ns("events")))),
    shiny::div(class = "ref-bottom-grid", shiny::div(shiny::uiOutput(ns("locus"))),
      shiny::div(shiny::div(class = "ref-section-heading", "At cursor", shiny::span(class = "ref-cursor-pos", "hover the ring")), shiny::uiOutput(ns("readout_rows")))),
    shiny::uiOutput(ns("guide")))
}

.reference_server <- function(id, example = shiny::reactive(TRUE)) {
  shiny::moduleServer(id, function(input, output, session) {
    demo <- shiny::reactive(isTRUE(example()))
    source_data <- shiny::reactive({
      tryCatch({
        if (demo()) return(.reference_demo())
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
        if (demo()) return(.reference_identity_demo())
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
    choices <- shiny::reactive({
      d <- source_data(); w <- identity_source()
      if (is.null(d$problem)) sort(unique(c(d$sample, if (is.null(w$problem)) w$sample else character()))) else character()
    })
    samples <- shiny::reactive({
      picked <- intersect(input$samples, choices())
      if (length(picked)) picked else choices()
    })
    shiny::observeEvent(choices(), {
      shiny::updateSelectizeInput(session, "samples", choices = choices(), selected = choices())
    })
    identity_selected <- shiny::reactive({
      selected()
      w <- identity_source()
      shiny::validate(shiny::need(is.null(w$problem), w$problem))
      if (!isTRUE(input$show_identity)) return(w[FALSE, , drop = FALSE])
      w[w$sample %in% samples(), , drop = FALSE]
    })
    colors <- shiny::reactive(.reference_palette(if (is.null(input$palette)) "minou" else input$palette))
    selected <- shiny::reactive({
      d <- source_data()
      shiny::validate(shiny::need(is.null(d$problem), d$problem))
      shiny::validate(shiny::need(length(samples()) > 0, "Select at least one comparison genome."))
      tryCatch(.reference_validate(d, reference_length()),
               error = function(e) shiny::validate(shiny::need(FALSE, conditionMessage(e))))
      d[d$sample %in% samples() & d$type %in% input$types, , drop = FALSE]
    })
    reference_length <- shiny::reactive(if (demo() || is.null(input$length) || !is.finite(input$length)) 4800000 else input$length)
    event_table <- shiny::reactive({ d <- selected(); d[!duplicated(.reference_event_key(d)), , drop = FALSE] })
    selected_event <- shiny::reactive({
      d <- event_table(); if (!nrow(d)) return(NULL)
      key <- .reference_event_key(d); i <- match(input$event, key)
      if (!length(i) || is.na(i)) i <- if (any(d$type == "DEL")) which(d$type == "DEL")[1] else 1L
      d[i, , drop = FALSE]
    })
    output$heading <- shiny::renderText(paste(length(samples()), if (length(samples()) == 1) "genome against" else "genomes against", reference_name()))
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
      if (is.null(title) || !nzchar(title)) title <- paste(length(samples()), "genomes against", reference_name())
      if (demo()) paste(title, "\u00b7 invented example") else title
    })
    identity_palette <- shiny::reactive({
      choice <- input$identity_palette
      if (is.null(choice) || !nzchar(choice)) NULL else if (choice == "sand") c("#E8D5A8", "#6FA8C9", "#1B3A5C") else choice
    })
    reference_name <- shiny::reactive(if (is.null(input$reference) || !nzchar(input$reference)) "Example reference" else input$reference)
    plot <- function(interactive = FALSE) {
      tryCatch(plot_reference_comparison(selected(), reference_length(), reference = reference_name(),
        sample_order = samples(), title = figure_title(), interactive = interactive,
        palette = if (is.null(input$palette)) "minou" else input$palette, identity_windows = identity_selected(),
        identity_palette = identity_palette()),
        error = function(e) shiny::validate(shiny::need(FALSE, conditionMessage(e))))
    }
    output$status <- shiny::renderUI({
      d <- selected(); identity_selected()
      shiny::p(if (demo()) "INVENTED EXAMPLE \u00b7 " else "SUPPLIED VARIANTS \u00b7 ",
        nrow(event_table()), " event patterns \u00b7 ", nrow(d), " supplied calls \u00b7 ", length(samples()), " comparison genomes",
        if (demo()) " \u00b7 variants and identity are invented, not biological findings" else "")
    })
    output$preview <- shiny::renderUI({
      e <- selected_event()
      .reference_svg(selected(), reference_length(), samples(), input$reference, colors(), session$ns,
        if (is.null(e)) NULL else .reference_event_key(e), identity_windows = identity_selected())
    })
    output$identity_key <- shiny::renderUI({
      w <- identity_selected()
      shades <- .reference_identity_color(c(90, 95, 100, NA_real_), identity_palette())
      shiny::div(class = "ref-identity-key",
        shiny::div(class = "ref-section-heading", "Two different greys"),
        shiny::p(class = "ref-small", "Inner black/dark-grey bands: a ruler, alternating every ", format(.reference_ruler_step(reference_length()), big.mark = ",", scientific = FALSE), " bases. These are not data."),
        shiny::div(class = "ref-identity-scale", lapply(seq_along(shades), function(i)
          shiny::span(shiny::span(class = "ref-shade-chip", style = paste0("background:", shades[i])), c("\u226490%", "95%", "100%", "No score")[i]))),
        shiny::p(class = "ref-small", if (nrow(w)) "Outer windows: darker means higher supplied identity. For example, 99% means about 99 of 100 aligned bases match. Below 90% uses the lightest shade. Coverage is not shown." else "No identity windows are displayed. The pale tracks carry no similarity measurement.",
          if (demo() && nrow(w)) " These window scores are invented." else ""))
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
        if (demo()) " This is an invented teaching example." else "")
    })
    output$events <- shiny::renderUI({
      d <- event_table(); v <- selected(); keys <- .reference_event_key(v); e <- selected_event()
      active <- if (is.null(e)) "" else .reference_event_key(e)
      tags <- if (length(samples())<=26) LETTERS[seq_along(samples())] else as.character(seq_along(samples()))
      shiny::tagList(shiny::div(class = "ref-section-heading", "Events \u00b7 supplied presence", shiny::div(class = "ref-event-grid", lapply(tags, shiny::span))),
        shiny::div(class = "ref-events", lapply(seq_len(min(100, nrow(d))), function(i) {
          r <- d[i, ]; key <- .reference_event_key(r); col <- colors()[[r$type]]
          len <- if (r$type == "INS") if ("event_length" %in% names(r)) r$event_length else NA_real_ else r$end-r$start
          shiny::tags$button(type = "button", class = paste("ref-event-row", if (key == active) "is-selected" else ""), `data-event` = key,
            `aria-pressed` = if (key == active) "true" else "false",
            shiny::span(class = "ref-event-dot", style = paste0("background:", col)),
            shiny::span(.reference_labels[r$type]), shiny::span(class = "ref-event-pos", .reference_fmt(r$start), " \u00b7 ", if (is.na(len)) "size ?" else .reference_fmt(len, "kb")),
            shiny::div(class = "ref-event-grid", lapply(samples(), function(s) {
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
      .reference_locus(selected(), e, samples(), colors(), reference_length())
    })
    output$readout_rows <- shiny::renderUI({
      selected()
      shiny::div(class = "ref-readout", lapply(seq_along(samples()), function(i)
        shiny::div(class = "ref-readout-row", `data-sample` = samples()[i],
          shiny::span(class = "ref-mono", if (length(samples())<=26) LETTERS[i] else i),
          shiny::span(class = "ref-readout-dot", style = "background:#DAD6CD"),
          shiny::span(class = "ref-readout-state", "\u2014"))))
    })
    output$guide <- shiny::renderUI({
      shiny::div(class = "ref-guide",
        shiny::div(shiny::strong("01 / Read clockwise"), paste0("No x/y axes. R is the reference; A, B, \u2026 are genomes in the order above. M and Mb mean one million base pairs; kb means one thousand. For example, ", .reference_fmt(reference_length()/5), " is one fifth along this ", .reference_fmt(reference_length()), " reference.")),
        shiny::div(shiny::strong("02 / Read the marks"), "Colours follow the selected ltc palette. Arc length shows the reference span. Capped insertion ticks mark positions, not direction or inserted length; supplied lengths are in the event list and hover details. Curved ribbons join the supplied source of a duplicated region to the position of its extra copy. They do not show a physical path or prove how the duplication happened."),
        shiny::div(shiny::strong("03 / Interpret with care"), "Outer grey shading shows supplied identity; pale green means no score. Higher identity means closer sequence agreement, not better biology. Coverage is not shown. Overlaps may hide calls. More differences are not inherently better or worse, and these marks alone cannot show a biological effect. The example numbers are invented."))
    })
    output$records <- shiny::renderTable({
      d <- source_data(); if (!is.null(d$problem)) return(NULL)
      utils::head(d, 50)
    }, digits = 0)
    for (i in 1:2) local({
      i <- i
      output[[c("sample_file", "sample_identity_file")[i]]] <- shiny::downloadHandler(
        filename = function() c("variants_five_genomes.tsv", "identity_five_genomes.tsv")[i],
        content = function(file) file.copy(system.file("extdata", "reference_comparison",
          c("variants_five_genomes.tsv", "identity_five_genomes.tsv")[i], package = "ggsynteny"), file, overwrite = TRUE))
    })
    output$readout <- shiny::renderUI({
      d <- source_data(); w <- identity_source()
      if (!is.null(d$problem)) {
        waiting <- grepl("^Upload", d$problem)
        return(.studio_readout(if (waiting) "warn" else "err", if (waiting) "Waiting for the variant table" else "Cannot read the variants", d$problem,
          foot = shiny::tagList(shiny::span(class = "muted small", "Continue unlocks when the variant table parses."),
            shiny::actionButton("to_figure", "Continue", class = "btn-primary", disabled = NA))))
      }
      identity_note <- if (!is.null(w$problem)) paste("Identity windows not used:", w$problem) else if (nrow(w)) "Identity windows read." else "No identity windows; rings stay unscored."
      .studio_readout("ok", "Variants ready", paste(if (demo()) "Invented teaching data." else "Supplied calls.", identity_note),
        counts = list("Genomes" = length(unique(d$sample)), "Calls" = nrow(d), "Event types" = length(unique(d$type)),
                      "Identity windows" = if (is.null(w$problem)) nrow(w) else 0L),
        foot = shiny::tagList(shiny::span(class = "muted small", "Positions are zero-based; end is exclusive."),
          shiny::actionButton("to_figure", "Continue", class = "btn-primary")))
    })
    script <- shiny::reactive({
      selected(); identity_selected()
      q <- function(x) paste(utils::capture.output(dput(x)), collapse = "\n")
      pal <- identity_palette()
      paste(c('# Save both table downloads beside this script: variants.tsv and identity-windows.tsv.',
        'library(ggsynteny)',
        'identity_windows <- read.delim("identity-windows.tsv", colClasses = c(sample = "character", start = "numeric", end = "numeric", identity = "numeric"))',
        'variants <- read.delim("variants.tsv", colClasses = c(sample = "character", type = "character"))',
        paste0('p <- plot_reference_comparison(variants, genome_length = ', q(reference_length()),
          ', reference = ', q(reference_name()), ', sample_order = ', q(samples()), ', palette = ', q(input$palette %||% "minou"),
          ', title = ', q(figure_title()), ', identity_windows = identity_windows',
          if (!is.null(pal)) paste0(', identity_palette = ', q(pal)) else '', ')'),
        'print(p)', '# Bundled IBM Plex fonts; requires showtext and sysfonts.',
        'save_reference_comparison(p, "reference-comparison.pdf")'), collapse = "\n")
    })
    list(
      data = source_data, plot = function() plot(), code = script, samples = choices,
      variants = selected, identity = identity_selected,
      save = function(file, ext) {
        tmp <- tempfile(fileext = paste0(".", ext)); on.exit(unlink(tmp))
        save_reference_comparison(plot(), tmp)
        file.copy(tmp, file, overwrite = TRUE)
      },
      summary = shiny::reactive({
        d <- selected()
        items <- list("Figure" = "reference comparison rings", "Reference" = paste(reference_name(), .reference_fmt(reference_length())),
                      "Genomes" = paste(samples(), collapse = ", "), "Calls" = paste(nrow(d), "displayed"),
                      "Palette" = input$palette %||% "minou")
        shiny::div(class = "summary-list", lapply(names(items), function(n) shiny::tagList(shiny::span(class = "kicker", n), shiny::span(items[[n]]))))
      }))
  })
}
