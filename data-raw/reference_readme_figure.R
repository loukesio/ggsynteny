# Run alone with Rscript data-raw/reference_readme_figure.R, or via readme_figures.R.
devtools::load_all(".", quiet = TRUE)
variants <- read.delim("inst/extdata/reference_comparison/variants.tsv")
identity_windows <- read.delim("inst/extdata/reference_comparison/identity_windows.tsv")
p <- plot_reference_comparison(
  variants, genome_length = 4800000, reference = "Example reference",
  sample_order = c("Genome_A", "Genome_B"), palette = "minou",
  identity_windows = identity_windows, title = "Invented reference comparison"
)
save_reference_comparison(p, "man/figures/README-reference-comparison.png", dpi = 150)
