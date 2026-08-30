# The bundled `rice_sorghum` dataset — real macro-synteny between rice
# (Oryza sativa) and sorghum (Sorghum bicolor).
#
# Provenance:
#   1. Input data: data/os_sb.blast + data/os_sb.gff shipped with MCScanX
#      (https://github.com/wyp1125/MCScanX; Wang et al. 2012,
#      Nucleic Acids Research 40:e49) — all-vs-all protein BLAST and gene
#      positions for the two genomes.
#   2. MCScanX was compiled and run with default parameters:
#        ./MCScanX data/os_sb
#      producing os_sb.collinearity (676 collinear blocks).
#   3. Parsed with ggsynteny's own read_mcscanx(), then:
#        - keep only inter-genome (rice ↔ sorghum) blocks,
#        - keep blocks with >= 20 collinear gene pairs (the plot stays
#          legible; the full file is preserved by the pipeline above),
#        - rename the species codes os/sb to Rice/Sorghum.
#
# To regenerate, set MCSCANX_DIR to a checkout of MCScanX where the command
# in step 2 has been run, then source this script from the package root.

MCSCANX_DIR <- Sys.getenv("MCSCANX_DIR", "MCScanX")

devtools::load_all(".", quiet = TRUE)
library(dplyr)

syn <- read_mcscanx(file.path(MCSCANX_DIR, "data/os_sb.collinearity"),
                    file.path(MCSCANX_DIR, "data/os_sb.gff"))

species_names <- c(os = "Rice", sb = "Sorghum")

blocks <- syn$blocks %>%
  filter(species1 != species2, n_genes >= 20) %>%
  mutate(species1 = species_names[species1],
         species2 = species_names[species2],
         dplyr::across(c(start1, end1, start2, end2), ~ round(.x, 2)))

chromosomes <- syn$chromosomes %>%
  filter(species %in% names(species_names)) %>%
  mutate(species = species_names[species],
         size = round(size, 2))

rice_sorghum <- list(chromosomes = as.data.frame(chromosomes),
                     blocks      = as.data.frame(blocks))

cat("Chromosomes:", nrow(rice_sorghum$chromosomes),
    "| Blocks:", nrow(rice_sorghum$blocks), "\n")

usethis::use_data(rice_sorghum, overwrite = TRUE, compress = "xz")
