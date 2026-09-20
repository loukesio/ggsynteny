# Installed-package example, no repository checkout or network access needed:
# source(system.file("examples", "annotation-tracks.R", package = "ggsynteny"))
# Only track_demo is created in the calling environment; no files are written.
# All DNA in this example is simulated.
track_demo <- local({
  if (!requireNamespace("ggsynteny", quietly = TRUE) ||
      !"syn_track" %in% getNamespaceExports("ggsynteny") ||
      !"geom" %in% names(formals(ggsynteny::syn_track)))
    stop("Install the feature/gc-content-tracks branch and restart R before running this demo.")
  data_dir <- system.file("extdata", "gc-tracks", package = "ggsynteny", mustWork = TRUE)
  read_example <- function(name) readr::read_tsv(
    file.path(data_dir, paste0(name, ".tsv")), show_col_types = FALSE)
  features <- read_example("features")
  links <- read_example("links")
  dna <- read_example("sequences")
  gene_gc <- ggsynteny::gc_content(dna, intervals = features)
  window_gc <- ggsynteny::gc_content(dna, window = 400, step = 100)
  ambiguous <- ggsynteny::gc_content(dna, window = 100)
  ambiguous$value <- 100 * ambiguous$n_ambiguous / (ambiguous$end - ambiguous$start)
  tracks <- list(
    ggsynteny::syn_track(gene_gc, geom = "heatmap", name = "Gene GC (%)", height = 0.055),
    ggsynteny::syn_track(window_gc, geom = "line", name = "Window GC (%)",
                         height = 0.19, gap = 0.025, colour = "#176D81", reference = 50),
    ggsynteny::syn_track(ambiguous, geom = "bar", name = "Ambiguous bases (%)",
                         height = 0.11, gap = 0.025, colour = "#BE7442", reference = 50)
  )
  # A guide-free linear style, without changing the circular example.
  linear_tracks <- list(tracks[[1]],
    ggsynteny::syn_track(window_gc, geom = "line", name = "Window GC (%)",
      height = 0.19, gap = 0.025, colour = "#176D81", reference = NULL,
      background = ggplot2::element_blank(),
      border = ggplot2::element_line(colour = "#BACACD", linewidth = 0.25)),
    ggsynteny::syn_track(ambiguous, geom = "bar", name = "Ambiguous bases (%)",
      height = 0.11, gap = 0.025, colour = "#BE7442", reference = NULL,
      background = ggplot2::element_blank(),
      border = ggplot2::element_line(colour = "#DDD0C7", linewidth = 0.25)))
  base <- ggsynteny::plot_microsynteny(features, links, palette = "casa_natal",
                                     ribbon_fill = "per_name", label_genes = FALSE,
                                     ribbon_alpha = 0.18)
  circular <- ggsynteny::plot_circular_microsynteny(features, links, palette = "casa_natal",
                                                  ribbon_fill = "per_name", label_genes = FALSE,
                                                  ribbon_alpha = 0.18)
  caption <- ggplot2::labs(caption = "Simulated DNA; GC excludes ambiguous bases. Tracks are ordered from genes outward.")
  style <- ggplot2::theme(plot.background = ggplot2::element_rect(fill = "white", colour = NA))
  list(base = base, heatmap = base + tracks[[1]], line = base + linear_tracks[[2]],
       linear = base + linear_tracks + caption + style,
       circular = circular + tracks + caption + style,
       tracks = tracks, linear_tracks = linear_tracks, features = features, links = links, sequences = dna,
       gene_gc = gene_gc, window_gc = window_gc, ambiguous = ambiguous)
})
print(track_demo$linear)
print(track_demo$circular)
message("Demo ready. Try print(track_demo$base), print(track_demo$line), or print(track_demo$linear).")
