# Run from the branch root. The baseline root checkout has unchanged R code
# relative to main; pass another baseline checkout as the first argument.
args <- commandArgs(trailingOnly = TRUE)
baseline <- normalizePath(if (length(args)) args[1] else "../..")
candidate <- normalizePath(".")
output <- file.path(candidate, "dev/gc-tracks/validation")
dir.create(output, recursive = TRUE, showWarnings = FALSE)
snapshot <- function(path, label) {
  pkgload::load_all(path, quiet = TRUE)
  m <- demo_microsynteny_data()
  s <- example_synteny_data()
  plots <- list()
  for (palette in list(NULL, "casa_natal")) {
    plots <- c(plots, list(
      plot_synteny(s, unique(s$chromosomes$species), palette = palette),
      plot_circular_synteny(s, palette = palette),
      plot_microsynteny(m$features, m$links, palette = palette),
      plot_circular_microsynteny(m$features, m$links, palette = palette)))
  }
  files <- file.path(output, paste0(label, "-", seq_along(plots), ".png"))
  for (i in seq_along(plots)) ggplot2::ggsave(files[i], plots[[i]], width = 8, height = 6, dpi = 100, bg = "white")
  list(data = lapply(plots, function(p) ggplot2::ggplot_build(p)$data),
       hashes = unname(tools::md5sum(files)), palettes = syn_palettes(),
       signatures = lapply(list(plot_synteny, plot_circular_synteny,
                                plot_microsynteny, plot_circular_microsynteny), formals))
}
before <- snapshot(baseline, "before")
after <- snapshot(candidate, "after")
stopifnot(identical(before$data, after$data), identical(before$hashes, after$hashes),
          identical(before$palettes, after$palettes), identical(before$signatures, after$signatures))
result <- c("PASS: all 8 baseline plots have identical built layer data and PNG bytes.",
            "PASS: all palette definitions and plotting function signatures are unchanged.")
writeLines(result, file.path(output, "defaults.txt"))
cat(paste(result, collapse = "\n"), "\n")
