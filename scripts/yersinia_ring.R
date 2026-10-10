# The plague genome annotated: rearrangement ribbons inside, four rings outside.
# Run from the root of this branch: Rscript scripts/yersinia_ring.R
library(ggsynteny)
library(ggplot2)

read_tsv <- function(p) read.delim(p, stringsAsFactors = FALSE)
chrom <- read_tsv("data/yersinia/chromosomes.tsv")
blocks <- read_tsv("data/yersinia/blocks.tsv")
windows <- read_tsv("data/yersinia/ring-windows.tsv")
features <- read_tsv("data/yersinia/ring-features.tsv")

pair <- c("Y. pseudotuberculosis", "Y. pestis CO92")
syn <- list(chromosomes = chrom[chrom$species %in% pair, ],
            blocks = blocks[blocks$species1 %in% pair & blocks$species2 %in% pair, ])

gc <- transform(windows[c("species", "chr", "start", "end")], value = windows$gc)
skew <- transform(windows[c("species", "chr", "start", "end")], value = windows$skew)
limit <- ceiling(max(abs(skew$value), na.rm = TRUE) * 100) / 100
gc_limits <- c(floor(min(gc$value, na.rm = TRUE)), ceiling(max(gc$value, na.rm = TRUE)))
family_colours <- c(Transposase = "#C2452D", Integrase = "#E8A33D", `Recombinase or resolvase` = "#4F7C8A")

ring <- plot_circular_synteny(syn, pair, palette = "minou", chr_fill = "per_species",
                              ribbon_fill = "species_pair", ribbon_alpha = 0.22,
                              show_orientation = TRUE, group_gap = 14,
                              label_size = 0, species_label_size = 4, track_width = 0.03) +
  syn_axis(by = 500, unit = NULL, height = 0.05, gap = 0.005) +
  syn_track_feature(features, fill = "family", palette = family_colours,
                    name = "Mobile-element CDS", height = 0.05, gap = 0.012,
                    out_of_bounds = "clip") +
  syn_track_line(gc, name = "GC (%)", limits = gc_limits, reference = round(mean(gc$value, na.rm = TRUE), 1),
                 colour = "#2F3B45", height = 0.11, gap = 0.02, out_of_bounds = "clip") +
  syn_track_heatmap(skew, name = "GC skew", limits = c(-limit, limit),
                    palette = c("#B2182B", "#F7F7F7", "#2166AC"),
                    height = 0.045, gap = 0.015, out_of_bounds = "clip") +
  labs(title = "The elements that moved, and the genome they moved in",
       subtitle = paste("Yersinia pseudotuberculosis and Yersinia pestis CO92 ·",
                        nrow(syn$blocks), "blocks,", sum(syn$blocks$orientation == "minus"), "reversed ·",
                        "positions in kb"),
       caption = paste(
         "Outward from each genome: 500 kb ticks, mobile-element CDS from the record's own product text,",
         "GC content in 10 kb windows with the genome mean dashed, and GC skew per window.",
         "CO92 carries 203 transposase CDS against 50 in the ancestor. Ribbons are megablast blocks of at least 10 kb;",
         "reversed ones are twisted. Counts are annotations and alignments, not inferred mobilisation events.", sep = "\n")) +
  theme(plot.title = element_text(face = "bold", size = 16),
        plot.caption = element_text(hjust = 0, colour = "grey35", size = 8.5),
        plot.title.position = "plot", plot.caption.position = "plot",
        legend.position = "bottom", legend.box = "vertical")

ggsave("figures/yersinia-ring.png", ring, width = 10, height = 11.5, dpi = 150, bg = "white")
ggsave("figures/yersinia-ring.pdf", ring, width = 10, height = 11.5)
cat("Wrote the annotated ring:", nrow(features), "mobile-element CDS,", nrow(windows), "windows\n")
