# Check the published tables through the same import path used by Studio.
# Run from the package root: Rscript data-raw/public-health/validate.R
devtools::load_all(".", quiet = TRUE)
root <- "inst/extdata/public-health"
records <- read.delim(file.path(root, "sequences.tsv"), stringsAsFactors = FALSE)
stopifnot(identical(records$length_bp,
                    c(1445021L, 2341328L, 1931047L, 1581384L, 80186L, 62589L, 50333L)),
          !anyDuplicated(records$accession), all(nchar(records$sequence_sha256) == 64L))
checked <- 0L
for (dataset in c("bartonella", "plasmids")) {
  folder <- file.path(root, dataset)
  for (format in c("native", "genes")) {
    files <- if (format == "native") c("chromosomes.tsv", "blocks.tsv") else c("features.tsv", "links.tsv")
    d <- ggsynteny:::.studio_load(format, FALSE, as.list(file.path(folder, files)))
    first <- d$first; second <- d$second
    if (format == "native") {
      order <- first$species
      stopifnot(all(first$size == records$length_bp[match(first$chr, records$accession)] / 1000),
                all(second$orientation %in% c("plus", "minus")),
                length(unique(paste(second$species1, second$species2))) == choose(length(order), 2))
    } else {
      order <- unique(first$bin_id)
      stopifnot(!anyDuplicated(first$feat_id), all(first$start >= 0), all(first$end > first$start),
                all(first$end <= records$length_bp[match(first$seq_id, records$accession)]),
                all(second$identity >= 50 & second$identity <= 100),
                all(as.numeric(second$query_coverage) >= 70 & as.numeric(second$subject_coverage) >= 70),
                all(second$feat_id_a %in% first$feat_id), all(second$feat_id_b %in% first$feat_id))
    }
    for (layout in c("linear", "circular")) for (interactive in c(FALSE, TRUE)) {
      selected <- ggsynteny:::.studio_select(d, order, limit = 1000, layout = layout)
      p <- ggsynteny:::.studio_plot(selected, layout = layout,
                                    palette = "casa_natal", orientation = format == "native",
                                    interactive = interactive)
      stopifnot(inherits(p, "ggplot"))
      ggplot2::ggplot_build(p)
      if (interactive) {
        widget <- syn_girafe(p)
        stopifnot(inherits(widget, "girafe"), nzchar(widget$x$html))
      }
      checked <- checked + 1L
    }
  }
}
cat("Validated source lengths, coordinate bounds, pair coverage and link endpoints;",
    checked, "Studio plot combinations passed.\n")
