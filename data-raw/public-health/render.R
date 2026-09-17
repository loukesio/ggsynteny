# Render from the committed tables; no downloads or external aligner needed.
# Run from the package root: Rscript data-raw/public-health/render.R
devtools::load_all(".", quiet = TRUE)
library(ggplot2)

input <- "inst/extdata/public-health"
figures <- "man/figures/public-health"
gallery <- "dev/public-health/gallery"
dir.create(figures, recursive = TRUE, showWarnings = FALSE)
dir.create(gallery, recursive = TRUE, showWarnings = FALSE)
gallery <- normalizePath(gallery)
read_table <- function(path) readr::read_tsv(path, show_col_types = FALSE)
all_plots <- list()
plot_index <- list()
widgets <- list()
dir.create("dev/public-health/validation", recursive = TRUE, showWarnings = FALSE)

style <- function(p, title, subtitle, caption) {
  p + labs(title = title, subtitle = subtitle, caption = caption) + theme(
    text = element_text(family = "sans"),
    plot.title = element_text(size = 20, face = "bold", color = "#263F39"),
    plot.subtitle = element_text(size = 11, color = "#52645D", margin = margin(t = 7, b = 8)),
    plot.caption = element_text(size = 9, color = "#52645D", hjust = 0,
                               lineheight = 1.25, margin = margin(t = 12)),
    plot.title.position = "plot", plot.caption.position = "plot",
    plot.margin = margin(18, 24, 18, 24)
  )
}

for (dataset in c("bartonella", "plasmids")) {
  path <- file.path(input, dataset)
  syn <- list(chromosomes = read_table(file.path(path, "chromosomes.tsv")),
              blocks = read_table(file.path(path, "blocks.tsv")))
  features <- read_table(file.path(path, "features.tsv"))
  links <- read_table(file.path(path, "links.tsv"))
  order <- syn$chromosomes$species
  # Linear panels display adjacent pairs. Circular panels include every pair.
  linear_syn <- syn
  adjacent <- abs(match(syn$blocks$species1, order) - match(syn$blocks$species2, order)) == 1L
  linear_syn$blocks <- syn$blocks[adjacent, ]
  a <- features$bin_id[match(links$feat_id_a, features$feat_id)]
  b <- features$bin_id[match(links$feat_id_b, features$feat_id)]
  linear_links <- links[abs(match(a, order) - match(b, order)) == 1L, ]
  bart <- dataset == "bartonella"
  name <- if (bart) "Four Bartonella genomes" else "Three hospital-associated plasmids"
  source <- if (bart) "Mauve backbone distributed with genoPlotR; blocks >=10 kb on both genomes." else
    "Conlan et al. (2014), Fig. 5 plasmids; new BLASTn matches >=1 kb and >=95% identity."
  note <- if (bart) "Original reference coordinates; reversed ribbons retain alignment orientation." else
    "Original sequence coordinates; short HSP overlaps <=50 bp retained. Similarity does not establish transmission."
  micro_subtitle <- if (bart) "Nine annotated CDS around rpoB in each genome" else
    "Annotated CDS fully inside the 2,000-10,700 bp backbone window"

  make_plot <- function(type, circular, interactive = FALSE) {
    if (type == "macro") {
      d <- if (circular) syn else linear_syn
      if (circular) {
        p <- plot_circular_synteny(d, order, palette = "casa_natal", chr_fill = "per_species",
          ribbon_fill = "species_pair", ribbon_alpha = 0.25, group_gap = 14,
          show_orientation = TRUE, interactive = interactive,
          label_size = 2.7, species_label_size = 4.3)
      } else {
        p <- plot_synteny(d, order, palette = "casa_natal", chr_fill = "per_species",
          ribbon_fill = "species_pair", ribbon_alpha = 0.32,
          show_inversions = TRUE, interactive = interactive,
          label_size = 3, species_label_size = 3.6)
        # The examples use kb. Adjust the returned ggplot's viewport so long
        # bacterial labels have room, without changing any package functions.
        width <- max(d$chromosomes$size)
        p <- suppressMessages(p + coord_cartesian(
          xlim = c(-width * 0.34, width * 1.03),
          ylim = c(-5, (length(order)-1)*18 + 5), clip = "off"))
        scale_length <- if (bart) 500 else 20
        p <- p + annotate("segment", x = width-scale_length, xend = width,
                          y = -4, yend = -4, linewidth = 0.65) +
          annotate("text", x = width-scale_length/2, y = -5.2,
                   label = paste(scale_length, "kb"), size = 2.7)
      }
      caption <- paste0(source, "\n", nrow(d$blocks), " pairwise interval links; lengths in kb. ", note)
      subtitle <- if (circular) "Whole sequences | all genome pairs | casa_natal" else
        "Whole sequences | adjacent genome pairs | casa_natal"
    } else {
      l <- if (circular) links else linear_links
      if (circular) {
        p <- plot_circular_microsynteny(features, l, order,
          palette = "casa_natal", ribbon_fill = "uniform", ribbon_palette = "#839C92",
          ribbon_alpha = 0.28, group_gap = 18, track_width = 0.055,
          label_genes = FALSE, bin_label_size = 4, interactive = interactive)
        # Stagger close labels radially using the public plot's feature layout.
        d <- attr(p, "circular_features")
        d$theta <- (d$theta_start+d$theta_end)/2
        d$radius <- 1.08
        for (bin in order) {
          idx <- which(d$bin_id == bin)
          for (j in seq_along(idx)[-1]) {
            here <- idx[j]; previous <- idx[j-1]
            if (abs(d$theta[here]-d$theta[previous]) < 0.06 && d$radius[previous] == 1.08)
              d$radius[here] <- 1.16
          }
        }
        d$x <- d$radius*cos(d$theta); d$y <- d$radius*sin(d$theta)
        d$angle <- (d$theta*180/pi+90) %% 360
        d$angle <- ifelse(d$angle > 90 & d$angle < 270, (d$angle+180) %% 360, d$angle)
        displaced <- d[d$radius > 1.08, ]
        p <- p + geom_segment(data = displaced,
          aes(x = 1.025*cos(theta), y = 1.025*sin(theta),
              xend = 1.13*cos(theta), yend = 1.13*sin(theta)),
          linewidth = 0.25, color = "#9AA7A0", inherit.aes = FALSE) +
          geom_text(data = d, aes(x, y, label = name, angle = angle),
                    size = 2.1, fontface = "italic", color = "#333333", inherit.aes = FALSE)
      } else {
        p <- plot_microsynteny(features, l, order,
          palette = "casa_natal", ribbon_fill = "uniform", ribbon_palette = "#839C92",
          ribbon_alpha = 0.32, label_genes = FALSE, bin_label_size = 3.5,
          interactive = interactive)
        # Label with angled text to keep closely spaced short genes legible.
        widths <- vapply(order, function(bin) {
          f <- features[features$bin_id == bin, ]; max(f$end)-min(f$start)
        }, numeric(1))
        max_width <- max(widths)
        label_data <- do.call(rbind, lapply(seq_along(order), function(i) {
          f <- features[features$bin_id == order[i], ]
          f$x <- (f$start+f$end)/2 - min(f$start) + (max_width-widths[i])/2
          f$y <- (length(order)-i)*6 + 0.7
          # Stagger labels whose gene centers are close together.
          near <- c(FALSE, diff(f$x) < max_width*0.03)
          f$y[near] <- f$y[near] + 0.7
          f
        }))
        p <- suppressMessages(p + coord_cartesian(
          xlim = c(-max_width*0.28, max_width*1.07),
          ylim = c(-2, (length(order)-1)*6+4), clip = "off")) +
          geom_text(data = label_data, aes(x, y, label = name), angle = 50,
                    hjust = 0, size = 2.6, fontface = "italic", color = "#333333")
        p <- p + annotate("segment", x = max_width-2000, xend = max_width,
                          y = -1.5, yend = -1.5, linewidth = 0.65) +
          annotate("text", x = max_width-1000, y = -2.1, label = "2 kb", size = 2.7)
      }
      subtitle <- paste0(micro_subtitle, " | ", if (circular) "all pairs" else "adjacent pairs")
      caption <- paste0(nrow(features), " annotated CDS; ", nrow(l), " reciprocal-best protein links within the selected windows.\n",
        "BLASTp: >=50% identity, >=70% coverage of both proteins, E <=1e-20; tied best hits excluded.\n",
        "Colors identify gene names or abbreviated products; arrows show strand. HP: hypothetical protein.",
        if (circular) "\nThese are local windows drawn around a circle, not complete circular gene maps." else "")
    }
    style(p, name, subtitle, caption)
  }

  for (type in c("macro", "micro")) for (circular in c(FALSE, TRUE)) {
    layout <- if (circular) "circular" else "linear"
    stem <- paste(dataset, type, layout, sep = "-")
    p <- make_plot(type, circular)
    stopifnot(inherits(p, "ggplot"))
    ggplot_build(p)
    height <- if (circular) 12 else 7.5
    ggsave(file.path(figures, paste0(stem, ".png")), p, width = 12, height = height,
           dpi = 150, bg = "white")
    ggsave(file.path(figures, paste0(stem, ".pdf")), p, width = 12, height = height,
           device = cairo_pdf, bg = "white")
    all_plots[[stem]] <- p
    plot_index[[stem]] <- data.frame(dataset, type, layout, file = stem)
    if (circular) {
      widget <- syn_girafe(make_plot(type, TRUE, TRUE), width_svg = 12, height_svg = 12,
        opts = list(ggiraph::opts_zoom(min = 1, max = 5, default_on = TRUE)))
      widgets[[stem]] <- htmltools::tags$section(
        htmltools::tags$h2(paste(name, if (type == "macro") "- whole sequences" else "- gene windows")),
        widget)
    }
  }
}

cairo_pdf(file.path(figures, "public-health-examples.pdf"), width = 12, height = 12)
for (p in all_plots) print(p)
dev.off()
readr::write_tsv(do.call(rbind, plot_index), file.path(input, "plots.tsv"))
page <- htmltools::tags$html(lang = "en",
  htmltools::tags$head(htmltools::tags$title("ggsynteny | Public bacterial examples"),
    htmltools::tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    htmltools::tags$style(htmltools::HTML("body{font-family:Arial,sans-serif;color:#263f39;background:#f7f8f5;margin:0}main{max-width:1100px;margin:auto;padding:30px}h1{font-size:2.2rem}p{line-height:1.6}section{background:white;border:1px solid #dce4df;border-radius:12px;padding:18px;margin:24px 0}h2{font-size:1.25rem}a{color:#286459}.girafe{width:100%}"))),
  htmltools::tags$body(htmltools::tags$main(
    htmltools::tags$h1("Public bacterial examples"),
    htmltools::tags$p("Four Bartonella genomes and three hospital-associated plasmids, drawn with ggsynteny and casa_natal. Hover for identifiers and coordinates; scroll to zoom, drag to pan, and use the toolbar to reset."),
    htmltools::tags$p("Whole-sequence coordinates are in kb; gene-window coordinates are in bp. Gene links are reciprocal best matches within the selected windows. Circular gene views show local regions, not complete circular molecules."),
    htmltools::tags$p(htmltools::tags$a(href = "https://github.com/loukesio/ggsynteny/tree/examples/public-health-bacteria/dev/public-health", "Methods, source records, download tables and PDFs")),
    htmltools::tagList(widgets))))
htmltools::save_html(page, file.path(gallery, "index-source.html"), libdir = "widget-libs")
pandoc_template <- normalizePath("data-raw/public-health/gallery-template.html")
rmarkdown::pandoc_convert(file.path(gallery, "index-source.html"), from = "markdown", to = "html",
                         output = file.path(gallery, "index.html"),
                         options = c("--embed-resources", "--standalone", "--template",
                                     pandoc_template))
# Embedded dependency CSS can contain trailing spaces; keep generated output
# clean for repository whitespace checks without changing the widget payloads.
html_file <- file.path(gallery, "index.html")
writeLines(sub("[ \t]+$", "", readLines(html_file, warn = FALSE)), html_file)
writeLines(capture.output(sessionInfo()), "dev/public-health/validation/render-session.txt")
cat("Rendered", length(all_plots), "figures, an eight-page PDF and four interactive circular views.\n")
