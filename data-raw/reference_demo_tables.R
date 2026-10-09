# Write Studio's invented five-genome reference demonstration to TSV files so
# the README and articles can read it with exported functions only.
# Run from the package root: Rscript data-raw/reference_demo_tables.R
pkgload::load_all(".", quiet = TRUE)
variants <- .reference_demo()
identity <- .reference_identity_demo()
variants$sample <- sub("Genome ", "Genome_", variants$sample)
identity$sample <- sub("Genome ", "Genome_", identity$sample)
dir <- "inst/extdata/reference_comparison"
write.table(variants, file.path(dir, "variants_five_genomes.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
write.table(identity, file.path(dir, "identity_five_genomes.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
cat(nrow(variants), "variants and", nrow(identity), "identity windows written for",
    length(unique(variants$sample)), "genomes\n")
