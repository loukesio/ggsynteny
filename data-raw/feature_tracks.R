# Feature tracks, a coordinate axis and a GC line on the bundled simulated
# gene example, in the linear and circular gene views.
# Run from the package root: Rscript data-raw/feature_tracks.R
pkgload::load_all(".", quiet = TRUE)
library(ggplot2)
read_example <- function(name) readr::read_tsv(
  file.path("inst/extdata/gc-tracks", paste0(name, ".tsv")), show_col_types = FALSE)
features <- read_example("features")
links <- read_example("links")
dna <- read_example("sequences")
gene_gc <- gc_content(dna, intervals = features)
window_gc <- gc_content(dna, window = 300, step = 100)

# A category derived from the simulated sequence itself: GC-rich or AT-rich genes.
gene_gc$gc_class <- ifelse(is.na(gene_gc$value), "No called bases",
                           ifelse(gene_gc$value >= 50, "GC-rich gene (>= 50%)", "AT-rich gene (< 50%)"))
pal <- c("GC-rich gene (>= 50%)" = "#176D81", "AT-rich gene (< 50%)" = "#D9A441", "No called bases" = "#C8CDD2")

tracks <- function(position) list(
  syn_track_feature(gene_gc, fill = "gc_class", strand = "arrow", palette = pal,
                    name = "Gene class", height = 0.07, gap = 0.02, position = position),
  syn_axis(by = 1000, unit = "kb", height = 0.05, gap = 0.01, position = position),
  syn_track_line(window_gc, name = "Window GC (%)", height = 0.16, gap = 0.02,
                 colour = "#3B1B36", reference = 50, position = position))

linear <- plot_microsynteny(features, links, gene_fill = "uniform", gene_palette = "#B8C2CC",
                            ribbon_fill = "per_name", palette = "casa_natal", label_genes = FALSE) +
  tracks("outside") +
  labs(title = "Feature arrows, kb ticks and a GC line below each contig",
       subtitle = "Simulated DNA: gene class is derived from the sequence, not a measurement of any organism") +
  theme(legend.position = "bottom", legend.box = "vertical")
ggsave("man/figures/gc-tracks/feature-tracks-linear.png", linear, width = 10, height = 7.5, dpi = 150, bg = "white")

circular <- plot_circular_microsynteny(features, links, gene_fill = "uniform", gene_palette = "#B8C2CC",
                                       ribbon_fill = "per_name", palette = "casa_natal", label_genes = FALSE) +
  tracks("inside") +
  labs(title = "The same three additions stacked inside the ring",
       subtitle = "position = \"inside\" shrinks the ribbons toward the centre to make room") +
  theme(legend.position = "bottom", legend.box = "vertical")
ggsave("man/figures/gc-tracks/feature-tracks-circular.png", circular, width = 8.5, height = 9, dpi = 150, bg = "white")
cat("Saved feature-tracks-linear.png and feature-tracks-circular.png\n")
