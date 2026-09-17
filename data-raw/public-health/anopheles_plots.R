# Published Anopheles example; uses the unchanged ggsynteny plotting API.
# Coordinates represent block order, not base pairs.
library(ggplot2)
library(grid)
ano_here <- "inst/extdata/public-health/anopheles"
read_anopheles <- function(name) read.delim(file.path(ano_here, paste0(name, ".tsv")),
                                  stringsAsFactors = FALSE)
ano_syn <- list(chromosomes = read_anopheles("chromosomes"), blocks = read_anopheles("blocks"))
ano_arms <- read_anopheles("arm-summary")
ano_species <- c("An. gambiae", "An. stephensi")
stopifnot(nrow(ano_syn$chromosomes) == 10L, nrow(ano_syn$blocks) == 380L,
          sum(ano_syn$blocks$orientation == "minus") == 198L)

# Match colours by the published homologous arms, including 2L <-> 3L.
ano_arm_cols <- setNames(syn_pal("casa_natal", 5), c("2L", "2R", "3L", "3R", "X"))
ano_chr_cols <- c(setNames(ano_arm_cols, paste0(ano_species[1], "__", names(ano_arm_cols))),
              setNames(ano_arm_cols[ano_arms$gambiae_arm],
                       paste0(ano_species[2], "__", ano_arms$stephensi_arm)))
ano_block_cols <- unname(ano_arm_cols[ano_syn$blocks$chr1])
ano_style <- theme(text = element_text(family = "sans"),
               plot.title = element_text(size = 12, face = "bold"),
               plot.subtitle = element_text(size = 9, margin = margin(t = 4, b = 8)),
               plot.title.position = "plot", plot.margin = margin(8, 12, 8, 12))

make_anopheles_plots <- function(interactive = FALSE) {
  linear <- plot_synteny(ano_syn, ano_species, palette = "casa_natal",
      chr_fill = "custom", chr_palette = ano_chr_cols,
      ribbon_fill = "custom", ribbon_palette = ano_block_cols, ribbon_alpha = .48,
      show_inversions = TRUE, interactive = interactive, species_label_size = 0, label_size = 3) +
    annotate("text", x = -8, y = c(18, 0), label = ano_species,
             hjust = 1, size = 3.3, fontface = "bold.italic") +
    labs(title = "A  Conserved blocks connect different chromosome-arm arrangements",
         subtitle = "380 published blocks | five arms per species | colour follows the An. gambiae arm") +
    ano_style
  linear <- suppressMessages(linear + coord_cartesian(
    xlim = c(-78, 390), ylim = c(-5, 23), clip = "off"))

  # Both functions use their standard alphabetical arm order.
  circular <- plot_circular_synteny(ano_syn, ano_species,
      palette = "casa_natal", chr_fill = "custom", chr_palette = ano_chr_cols,
      ribbon_fill = "custom", ribbon_palette = ano_block_cols,
      ribbon_alpha = .34, group_gap = 14, gap = 3,
      show_orientation = TRUE, interactive = interactive, label_size = 3.1, species_label_size = 3.8) +
    labs(title = "B  The same block orders in a circular view",
         subtitle = "Arc lengths count blocks; chromosomes are biologically linear") + ano_style
  stopifnot(nrow(attr(circular, "circular_links")) == 380L)

  x_data <- list(chromosomes = subset(ano_syn$chromosomes, chr == "X"),
                 blocks = subset(ano_syn$blocks, chr1 == "X"))
  xplot <- plot_synteny(x_data, ano_species, palette = "casa_natal",
      chr_fill = "uniform", chr_palette = unname(ano_arm_cols["X"]),
      ribbon_fill = "uniform", ribbon_palette = unname(ano_arm_cols["X"]),
      ribbon_alpha = .55, show_inversions = TRUE, interactive = interactive, label_size = 0,
      species_label_size = 0) +
    annotate("text", x = -1, y = c(18, 0), label = ano_species,
             hjust = 1, size = 3, fontface = "bold.italic") +
    annotate("segment", x = .8, xend = 66.8, y = -3.2, yend = -3.2,
             linewidth = .3) +
    annotate("segment", x = c(1.3, 16.3, 32.3, 48.3, 66.3),
             xend = c(1.3, 16.3, 32.3, 48.3, 66.3),
             y = -3.2, yend = -3.7, linewidth = .3) +
    annotate("text", x = c(1.3, 16.3, 32.3, 48.3, 66.3), y = -5.1,
             label = c(1, 16, 32, 48, 66), size = 2.8) +
    annotate("text", x = 33.8, y = -8, label = "Block rank along An. stephensi X",
             size = 3) +
    labs(title = "C  X chromosome: changes in block order",
         subtitle = "66 blocks | 44 opposite in orientation in the source table") + ano_style
  xplot <- suppressMessages(xplot + coord_cartesian(
    xlim = c(-20, 68), ylim = c(-10, 22), clip = "off"))

  # Check the polygons retain every source link, including the 198 signed reversals.
  linear_links <- linear$layers[[1]]$data
  stopifnot(length(unique(linear_links$conn_id)) == 380L,
            length(unique(xplot$layers[[1]]$data$conn_id)) == 66L)
  links <- attr(circular, "circular_links")
  stopifnot(identical(as.character(links$orientation), ano_syn$blocks$orientation),
            all(links$start1 == ano_syn$blocks$start1),
            all(links$start2 == ano_syn$blocks$start2),
            all(links$end1 == ano_syn$blocks$end1),
            all(links$end2 == ano_syn$blocks$end2),
            all(links$chr1 == ano_syn$blocks$chr1), all(links$chr2 == ano_syn$blocks$chr2))

  plots <- list(linear = linear, circular = circular, x = xplot)
  if (interactive) for (i in seq_along(plots)) {
    for (j in seq_along(plots[[i]]$layers)) {
      data <- plots[[i]]$layers[[j]]$data
      if (is.data.frame(data) && "tooltip" %in% names(data)) {
        plots[[i]]$layers[[j]]$data$tooltip <- paste0("Block ranks (not bp) | ", data$tooltip)
      }
    }
  }
  plots
}

draw_anopheles_figure <- function(plots = make_anopheles_plots()) {
  linear <- plots$linear; circular <- plots$circular; xplot <- plots$x
  grid.newpage()
  grid.text("Anopheles: a published comparison of two malaria vectors",
            x = .025, y = .98, just = c("left", "top"),
            gp = gpar(fontsize = 16, fontface = "bold"))
  grid.text("BLOCK-ORDER VIEW  |  Equal-width blocks; distances and lengths are not base pairs",
            x = .025, y = .946, just = c("left", "top"),
            gp = gpar(fontsize = 10, col = "#4C4C4C"))
  print(linear, vp = viewport(x = .5, y = .77, width = .97, height = .30))
  print(circular, vp = viewport(x = .265, y = .335, width = .51, height = .55))
  print(xplot, vp = viewport(x = .76, y = .39, width = .46, height = .35))
  grid.text(paste("Reading the figure",
    "2L in An. gambiae corresponds to 3L in An. stephensi;",
    "3L in An. gambiae corresponds to 2L in An. stephensi.",
    "Ribbons preserve published block order and signs.",
    "Opposite-orientation blocks do not count inversion events.", sep = "\n"),
    x = .565, y = .19, just = c("left", "top"),
    gp = gpar(fontsize = 10, lineheight = 1.35, col = "#333333"))
  grid.text(paste("Source: Jiang et al. (2014), Genome Biology 15:459, doi:10.1186/s13059-014-0459-2; Additional file 2, Synteny Blocks.",
    "Published stephensi physical map covers ~62% of the assembly; 32/86 mapped scaffolds had experimentally assigned orientation.",
    "This figure illustrates comparative genome organization; it does not establish effects on malaria transmission or insecticide resistance.",
    sep = "\n"), x = .025, y = .058, just = c("left", "top"),
    gp = gpar(fontsize = 8.5, lineheight = 1.3, col = "#4C4C4C"))
}
