# Run from this branch's package root: Rscript data-raw/modular_tracks.R
# Reuses the bundled simulated DNA. No measurements of real organisms.
pkgload::load_all(".", quiet = TRUE)
read_example <- function(name) readr::read_tsv(
  file.path("inst/extdata/gc-tracks", paste0(name, ".tsv")), show_col_types = FALSE)
features <- read_example("features")
links <- read_example("links")
dna <- read_example("sequences")
gene_gc <- gc_content(dna, intervals = features)
window_gc <- gc_content(dna, window = 400, step = 100)
ambiguous <- gc_content(dna, window = 100)
ambiguous$value <- 100 * ambiguous$n_ambiguous / (ambiguous$end - ambiguous$start)

# A reusable list of additions works with any of the four plot functions.
# Each renderer uses the same coordinates, but owns its value range and style.
tracks <- list(
  syn_track(gene_gc, name = "1  Gene GC (%)", geom = "heatmap", height = 0.055),
  syn_track(window_gc, name = "2  Window GC (%)", geom = "line",
            height = 0.19, gap = 0.025, colour = "#176D81", linewidth = 0.6, reference = 50),
  syn_track(ambiguous, name = "3  Ambiguous bases (%)", geom = "bar",
            height = 0.11, gap = 0.025, colour = "#BE7442", reference = 50))
style <- ggplot2::theme(
  plot.background = ggplot2::element_rect(fill = "white", colour = NA),
  plot.title = ggplot2::element_text(size = 18, face = "bold", colour = "#243746"),
  plot.subtitle = ggplot2::element_text(size = 11, colour = "#53616C"),
  plot.caption = ggplot2::element_text(size = 10, colour = "#53616C", hjust = 0),
  legend.title = ggplot2::element_text(size = 11, face = "bold"),
  legend.text = ggplot2::element_text(size = 9))
caption <- paste0("Simulated DNA. Tracks from genes outward: gene GC heatmap, window GC line, ambiguous-base bars.\n",
  "GC line: 400-base windows every 100 bases; dashed guide = 50%. Grey heatmap cells have no called bases.")
# The circular example keeps its original styling. Demonstrate the optional
# guide-free style independently in the linear example.
linear_tracks <- list(tracks[[1]],
  syn_track(window_gc, name = "2  Window GC (%)", geom = "line",
    height = 0.19, gap = 0.025, colour = "#176D81", linewidth = 0.6,
    reference = NULL, background = ggplot2::element_blank(),
    border = ggplot2::element_line(colour = "#BACACD", linewidth = 0.25)),
  syn_track(ambiguous, name = "3  Ambiguous bases (%)", geom = "bar",
    height = 0.11, gap = 0.025, colour = "#BE7442", reference = NULL,
    background = ggplot2::element_blank(),
    border = ggplot2::element_line(colour = "#DDD0C7", linewidth = 0.25)))
linear <- plot_microsynteny(features, links, palette = "casa_natal",
  ribbon_fill = "per_name", ribbon_alpha = 0.18, label_genes = FALSE) + linear_tracks + style +
  ggplot2::labs(title = "Each genome has its own tracks",
    subtitle = "Genes, GC heatmap, GC line, then bars | ribbons occupy separate gaps",
    caption = paste0("Simulated DNA. GC line: 400-base windows every 100 bases. Grey heatmap cells have no called bases.\n",
                     "Linear example: middle guides and backgrounds removed; track borders styled separately."))
circular <- plot_circular_microsynteny(features, links, palette = "casa_natal",
  ribbon_fill = "per_name", ribbon_alpha = 0.18, label_genes = FALSE) + tracks + style +
  ggplot2::labs(title = "The same three tracks around the genes",
    subtitle = "Values increase outward within each ring | each track keeps its own scale", caption = caption)

out <- "man/figures/gc-tracks"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
for (nm in c("linear", "circular")) {
  p <- get(nm)
  for (ext in c("png", "pdf")) ggplot2::ggsave(
    file.path(out, paste0("modular-", nm, ".", ext)), p,
    width = 13, height = 9, dpi = 160, bg = "white")
}
grDevices::pdf(file.path(out, "modular-tracks.pdf"), width = 13, height = 9)
print(linear)
print(circular)
grDevices::dev.off()
