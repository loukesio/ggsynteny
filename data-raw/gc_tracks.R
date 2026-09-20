# Reproduce the GC-track example inputs and all four figures from the repo root:
# Rscript data-raw/gc_tracks.R
# All DNA is simulated. Existing demo gene coordinates and links provide a
# layout template; none of these GC values describe the original organisms.
pkgload::load_all(".", quiet = TRUE)
set.seed(20260920)
data_dir <- "inst/extdata/gc-tracks"
figure_dir <- "man/figures/gc-tracks"
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

m <- demo_microsynteny_data()
old_ids <- m$features$feat_id
m$features$bin_id <- paste("Genome", LETTERS[match(m$features$bin_id, unique(m$features$bin_id))])
m$features$feat_id <- sprintf("gene_%02d", seq_along(old_ids))
m$links$feat_id_a <- m$features$feat_id[match(m$links$feat_id_a, old_ids)]
m$links$feat_id_b <- m$features$feat_id[match(m$links$feat_id_b, old_ids)]
chromosomes <- aggregate(end ~ bin_id + seq_id, m$features, max)
names(chromosomes) <- c("species", "chr", "size")
chromosomes <- chromosomes[order(chromosomes$species, chromosomes$chr), ]
sequences <- data.frame(group = chromosomes$species, seq_id = chromosomes$chr,
                        sequence = vapply(seq_len(nrow(chromosomes)), function(i) {
  n <- chromosomes$size[i]
  prob_gc <- rep(c(0.25, 0.4, 0.65, 0.8, 0.5, 0.3, 0.7, 0.55), each = ceiling(n / 8))[seq_len(n)]
  is_gc <- runif(n) < prob_gc
  bases <- ifelse(is_gc, sample(c("G", "C"), n, TRUE), sample(c("A", "T"), n, TRUE))
  paste0(bases, collapse = "")
}, character(1)))
# Select by key, so the missing region is reproducible if table ordering changes.
missing_row <- which(sequences$group == "Genome A" & sequences$seq_id == "4")
substr(sequences$sequence[missing_row], 3992, 4242) <- paste(rep("N", 251), collapse = "")
a <- m$features[match(m$links$feat_id_a, m$features$feat_id), ]
b <- m$features[match(m$links$feat_id_b, m$features$feat_id), ]
blocks <- data.frame(species1 = a$bin_id, chr1 = a$seq_id, start1 = a$start, end1 = a$end,
                      species2 = b$bin_id, chr2 = b$seq_id, start2 = b$start, end2 = b$end)
syn <- list(chromosomes = chromosomes, blocks = blocks)
windows <- gc_content(sequences, window = 250)
genes <- gc_content(sequences, intervals = m$features)
tables <- list(sequences = sequences, chromosomes = chromosomes, blocks = blocks,
                features = m$features, links = m$links, windows = windows, genes = genes)
for (nm in names(tables)) readr::write_tsv(tables[[nm]], file.path(data_dir, paste0(nm, ".tsv")))

style <- ggplot2::theme(
  plot.background = ggplot2::element_rect(fill = "white", colour = NA),
  plot.title = ggplot2::element_text(size = 16, face = "bold", colour = "#243746"),
  plot.subtitle = ggplot2::element_text(size = 10, colour = "#53616C"),
  plot.caption = ggplot2::element_text(size = 9, colour = "#53616C", hjust = 0),
  legend.title = ggplot2::element_text(size = 10), legend.text = ggplot2::element_text(size = 9))
caption <- "Simulated DNA on demo gene coordinates. GC = 100 x (G+C)/(A+C+G+T).\nAmbiguous bases are excluded; grey tiles have no called bases."
plots <- list(
  `macro-linear` = plot_synteny(syn, unique(chromosomes$species), palette = "casa_natal") +
    syn_track(windows, name = "GC (%)\n250 bp windows") +
    ggplot2::theme(plot.margin = ggplot2::margin(10, 30, 10, 100)),
  `macro-circular` = plot_circular_synteny(syn, palette = "casa_natal") +
    syn_track(windows, name = "GC (%)\n250 bp windows"),
  `micro-linear` = plot_microsynteny(m$features, m$links, palette = "casa_natal", ribbon_fill = "per_name") +
    syn_track(genes, name = "GC (%)\nper gene"),
  `micro-circular` = plot_circular_microsynteny(m$features, m$links, palette = "casa_natal", ribbon_fill = "per_name") +
    syn_track(genes, name = "GC (%)\nper gene"))
titles <- c("Chromosomes with GC windows", "Circular chromosomes with GC windows",
              "Genes with GC tracks", "Circular genes with GC tracks")
for (i in seq_along(plots)) {
  plots[[i]] <- plots[[i]] + style + ggplot2::labs(title = titles[i],
    subtitle = "Native ggplot2 layers | optional annotation tracks", caption = caption)
  for (ext in c("png", "pdf")) ggplot2::ggsave(
    file.path(figure_dir, paste0(names(plots)[i], ".", ext)), plots[[i]],
    width = 11, height = 8, dpi = 160, bg = "white")
}
grDevices::pdf(file.path(figure_dir, "gc-tracks.pdf"), width = 11, height = 8)
for (p in plots) print(p)
grDevices::dev.off()
grDevices::png(file.path(figure_dir, "overview.png"), width = 2200, height = 1600, res = 130)
grid::grid.newpage()
grid::pushViewport(grid::viewport(layout = grid::grid.layout(2, 2)))
for (i in seq_along(plots)) print(plots[[i]], newpage = FALSE,
  vp = grid::viewport(layout.pos.row = ceiling(i / 2), layout.pos.col = (i - 1) %% 2 + 1))
grDevices::dev.off()
