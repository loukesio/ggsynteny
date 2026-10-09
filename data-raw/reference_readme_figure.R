# Run alone with Rscript data-raw/reference_readme_figure.R, or via readme_figures.R.
# Five invented comparison genomes around a 4.8-Mb reference, with identity
# shading on a sand-to-navy ramp instead of the default greys.
devtools::load_all(".", quiet = TRUE)
dir <- system.file("extdata", "reference_comparison", package = "ggsynteny")
variants <- read.delim(file.path(dir, "variants_five_genomes.tsv"))
identity <- read.delim(file.path(dir, "identity_five_genomes.tsv"))
p <- plot_reference_comparison(
  variants, genome_length = 4800000, reference = "Example reference",
  sample_order = paste0("Genome_", LETTERS[1:5]), palette = "casa_natal",
  identity_windows = identity, identity_palette = c("#E8D5A8", "#6FA8C9", "#1B3A5C"),
  title = "Five invented genomes against one reference"
)
save_reference_comparison(p, "man/figures/README-reference-comparison.png", dpi = 150)
