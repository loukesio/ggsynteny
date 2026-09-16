# Prepare and render the three-bacterium circular example.
# Run from the package root: Rscript data-raw/circular_bacteria.R
# Original CSV inputs are preserved.
devtools::load_all(".", quiet = TRUE)
library(ggplot2)
source_dir <- "inst/extdata"
genes <- read.csv(file.path(source_dir, "bacterial_genes.csv"),
                  stringsAsFactors = FALSE)
homology <- read.csv(file.path(source_dir, "bacterial_links.csv"),
                     stringsAsFactors = FALSE)
bins <- c("ZONMW-30", "ZONMW-20", "HI1")

# Show ZONMW-30's main moa/moe region (contig 4). Its other contigs
# reuse feature IDs, so keeping them would make the supplied links ambiguous.
# Keep both ZONMW-20 contigs, including the separate mobA gene on contig 17.
# z_spacer rows are drawing placeholders, not annotated genes; genomic gaps
# remain visible because all retained start/end coordinates are unchanged.
features <- genes[genes$bin_id %in% bins &
                  (genes$bin_id != "ZONMW-30" | genes$seq_id == "4") &
                  genes$name != "z_spacer", , drop = FALSE]
features$source_feat_id <- features$feat_id
features$feat_id <- paste(features$bin_id, features$seq_id, features$start,
                           features$end, features$source_feat_id, sep = "__")
stopifnot(!anyDuplicated(features$feat_id))
original_key <- paste(features$bin_id, features$source_feat_id, sep = "::")
homology <- homology[homology$bin_id %in% bins & homology$bin_id2 %in% bins,
                     , drop = FALSE]
resolve <- function(bin, id) {
  key <- paste(bin, id, sep = "::")
  vapply(key, function(k) {
    rows <- which(original_key == k)
    if (length(rows) != 1L) stop("Ambiguous or absent input link endpoint: ", k)
    features$feat_id[rows]
  }, character(1), USE.NAMES = FALSE)
}
links <- data.frame(feat_id_a = resolve(homology$bin_id, homology$feat_id),
                     feat_id_b = resolve(homology$bin_id2, homology$feat_id2))

p <- plot_circular_microsynteny(
  features, links, bin_order = bins,
  palette = "casa_natal", ribbon_fill = "per_name",
  ribbon_alpha = 0.36, group_gap = 15, gap = 5,
  track_width = 0.055, label_size = 2.3, bin_label_size = 4.5
)
readme_plot <- p
p <- p + labs(
  title = "Three bacterial gene regions",
  subtitle = "moa/moe cluster | bundled ggsynteny example inputs",
  caption = paste0(nrow(features), " genes across 4 contigs; ", nrow(links),
                   " supplied links. Arrows show strand; colors identify gene names.\n",
                   "ZONMW-30: contig 4; ZONMW-20: contigs 10 and 17; HI1: contig 1.\n",
                   "No direct ZONMW-30 / HI1 links were supplied.")
) + theme(
  plot.title = element_text(size = 20, face = "bold", color = "#263F39"),
  plot.subtitle = element_text(size = 11, color = "#52645D", margin = margin(t = 7)),
  plot.caption = element_text(size = 9, color = "#52645D", hjust = 0,
                              lineheight = 1.3, margin = margin(t = 8)),
  plot.title.position = "plot", plot.caption.position = "plot",
  plot.margin = margin(20, 20, 18, 20)
)
stopifnot(inherits(p, "ggplot"),
          length(unique(p$data$group_name)) == 3L,
          nrow(attr(p, "circular_features")) == nrow(features),
          nrow(attr(p, "circular_links")) == nrow(links))
ggsave("man/figures/README-circular-bacteria.png", readme_plot, width = 10, height = 10.5,
       dpi = 180, bg = "white")
ggsave("man/figures/circular-bacteria.pdf", p, width = 10, height = 10.5,
       bg = "white")
# Keep the repository-relative PDF download link valid on the pkgdown site.
dir.create("pkgdown/assets/man/figures", recursive = TRUE, showWarnings = FALSE)
stopifnot(file.copy("man/figures/circular-bacteria.pdf",
                    "pkgdown/assets/man/figures", overwrite = TRUE))
write.table(features, file.path(source_dir, "circular_bacterial_features.tsv"), sep = "\t",
            row.names = FALSE, quote = FALSE)
write.table(links, file.path(source_dir, "circular_bacterial_links.tsv"), sep = "\t",
            row.names = FALSE, quote = FALSE)
cat(nrow(features), "genes;", nrow(links), "links;", nrow(p$data), "contigs\n")
print(table(homology$bin_id, homology$bin_id2))
