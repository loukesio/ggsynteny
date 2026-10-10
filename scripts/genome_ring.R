# A complete genome ring from exported functions only: the Arabidopsis
# chloroplast (NC_000932.1) with its regions, kb ticks, strand-split genes
# coloured by function, GC content, GC skew and the inverted-repeat links.
# Run from the package root: Rscript scripts/genome_ring.R
library(ggplot2)
library(ggsynteny)

dir <- system.file("extdata", "chloroplast", package = "ggsynteny")
regions <- read.csv(file.path(dir, "regions.csv"))
genes   <- read.csv(file.path(dir, "genes.csv"))
gc      <- read.csv(file.path(dir, "gc_windows.csv"))
pairs   <- read.csv(file.path(dir, "ir_pairs.csv"))

# One circular molecule, one sector. The tables carry the species name the
# plot uses; the single sequence "plastid" is filled in from the plot.
syn <- list(
  chromosomes = data.frame(species = "Arabidopsis thaliana", chr = "plastid", size = 154478),
  blocks = data.frame(species1 = "Arabidopsis thaliana", chr1 = "plastid", start1 = pairs$b_start, end1 = pairs$b_end,
                      species2 = "Arabidopsis thaliana", chr2 = "plastid", start2 = pairs$a_start, end2 = pairs$a_end,
                      class = pairs$class))
gc <- data.frame(start = gc$start, end = gc$start + 999, value = 100 * gc$gc)
skew <- data.frame(start = gc$start, end = gc$end, value = read.csv(file.path(dir, "gc_windows.csv"))$skew)

pal_class <- c("Photosystems and electron transport" = "#009E73", "ATP synthase" = "#E69F00",
               "NADH dehydrogenase" = "#CC79A7", "Ribosomal proteins" = "#0072B2",
               "tRNA and rRNA" = "#D55E00", "Other genes" = "#9A9A9A")
pal_region <- c(LSC = "#E9DCC4", IRb = "#7FB3B8", SSC = "#C9B79C", IRa = "#7FB3B8")

ring <- plot_circular_synteny(syn, ribbon_fill = "class", ribbon_palette = pal_class, ribbon_alpha = 0.55,
                              ribbon_legend = FALSE, chr_palette = "#F1EDE6", chr_color = NA,
                              track_width = 0.02, label_size = 0, species_label_size = 0, group_gap = 1.5) +
  syn_track_feature(regions, fill = "region", label = "region", palette = pal_region,
                    height = 0.07, gap = 0, show.legend = FALSE, label_size = 3.2) +
  syn_axis(by = 10000, unit = "kb", gap = 0) +
  syn_track_feature(genes, fill = "class", strand = "split", palette = pal_class, name = "Gene function",
                    position = "inside", height = 0.14, gap = 0.015, out_of_bounds = "clip") +
  syn_track_line(gc, name = "GC (%)", limits = c(20, 60), reference = 36.3, colour = "#3B1B36",
                 position = "inside", height = 0.15, gap = 0.02, out_of_bounds = "clip") +
  syn_track_heatmap(skew, name = "GC skew", limits = c(-0.25, 0.25), palette = c("#B2182B", "#F7F7F7", "#2166AC"),
                    position = "inside", height = 0.05, gap = 0.015, out_of_bounds = "clip") +
  labs(title = "The inverted repeat joins the genome to itself",
       subtitle = "Arabidopsis thaliana chloroplast · 154,478 bp · NC_000932.1",
       caption = paste("Outer band: the four regions with ticks every 10 kb. Inside it: genes on the + strand (outer)",
                       "and - strand (inner) coloured by function, GC content in 1-kb windows (20-60%, dashed at the",
                       "36.3% mean), and GC skew (G - C)/(G + C) per window, blue positive and red negative.",
                       "Ribbons join each IRb gene to its IRa copy.", sep = "\n")) +
  theme(legend.position = "bottom", legend.box = "vertical", plot.title = element_text(face = "bold", size = 15),
        plot.caption = element_text(hjust = 0, size = 8.5), plot.title.position = "plot",
        plot.caption.position = "plot") +
  guides(syn_feature3 = guide_legend(nrow = 2, order = 1))

out <- file.path("man", "figures", "gc-tracks", "genome-ring.png")
ggsave(out, ring, width = 8, height = 9.4, dpi = 180, bg = "white")
cat("Saved", out, "\n")
