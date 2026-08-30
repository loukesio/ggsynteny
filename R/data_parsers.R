# ═══════════════════════════════════════════════════════════════════════════
# Data Input Parsers for Common Synteny Formats
# ═══════════════════════════════════════════════════════════════════════════

#' Read synteny data from TSV files
#'
#' Reads the native ggsynteny format: two TSV files containing chromosome
#' sizes and syntenic blocks.
#'
#' @param chr_file Path to chromosomes.tsv with columns: species, chr, size
#' @param blocks_file Path to synteny_blocks.tsv with columns: species1, chr1, start1, end1, species2, chr2, start2, end2
#'
#' @return List with elements `chromosomes` and `blocks`
#'
#' @examples
#' \dontrun{
#' syn <- read_synteny_tsv("chromosomes.tsv", "synteny_blocks.tsv")
#' }
#'
#' @export
#' @importFrom readr read_tsv cols
read_synteny_tsv <- function(chr_file, blocks_file) {
  chrs   <- readr::read_tsv(chr_file,   col_types = "ccd")
  blocks <- readr::read_tsv(blocks_file, col_types = "ccddccdd")

  list(chromosomes = chrs, blocks = blocks)
}


#' Read MCScanX output files
#'
#' Parses MCScanX collinearity and GFF files into ggsynteny format.
#'
#' @param collinearity_file Path to .collinearity file
#' @param gff_file Path to .gff file with gene positions
#'
#' @return List with elements `chromosomes` and `blocks`
#'
#' @details
#' MCScanX convention: chromosome names are prefixed with species abbreviation
#' (e.g., "Hs1" for Human chromosome 1).
#'
#' @examples
#' \dontrun{
#' syn <- read_mcscanx("output.collinearity", "output.gff")
#' }
#'
#' @export
#' @importFrom readr read_tsv
#' @importFrom dplyr group_by summarise rename mutate filter select
read_mcscanx <- function(collinearity_file, gff_file) {

  # ── Parse GFF ──
  gff <- readr::read_tsv(gff_file, col_names = c("chr", "gene", "start", "end"),
                  col_types = "ccii", comment = "#")

  gff <- gff %>%
    mutate(
      species = sub("[0-9]+$", "", chr),
      chr_num = sub("^[A-Za-z]+", "", chr)
    )

  chr_table <- gff %>%
    group_by(species, chr, chr_num) %>%
    summarise(size = max(end), .groups = "drop") %>%
    rename(chr_raw = chr) %>%
    mutate(size_mb = size / 1e6)

  # ── Parse collinearity ──
  lines <- readLines(collinearity_file)

  blocks <- list()
  current_block <- NULL

  for (line in lines) {
    line <- trimws(line)
    if (grepl("^## Alignment", line)) {
      score  <- as.numeric(sub(".*score=([0-9.]+).*", "\\1", line))
      chrs   <- sub(".*\\s(\\S+&\\S+)\\s.*", "\\1", line)
      chr_pair <- strsplit(chrs, "&")[[1]]
      orient <- sub(".*(plus|minus)$", "\\1", line)
      current_block <- list(
        chr1 = chr_pair[1], chr2 = chr_pair[2],
        score = score, orient = orient, genes = list()
      )
    } else if (grepl("^\\d+-", line) && !is.null(current_block)) {
      parts <- strsplit(trimws(sub("^\\d+-\\s*\\d+:", "", line)), "\\s+")[[1]]
      if (length(parts) >= 2) {
        current_block$genes[[length(current_block$genes) + 1]] <- list(
          gene1 = parts[1], gene2 = parts[2]
        )
      }
    } else if (line == "" && !is.null(current_block)) {
      blocks[[length(blocks) + 1]] <- current_block
      current_block <- NULL
    }
  }
  if (!is.null(current_block)) {
    blocks[[length(blocks) + 1]] <- current_block
  }

  # ── Convert blocks to coordinate ranges ──
  block_rows <- list()
  for (b in blocks) {
    if (length(b$genes) == 0) next

    gene1_ids <- sapply(b$genes, function(g) g$gene1)
    gene2_ids <- sapply(b$genes, function(g) g$gene2)

    g1_info <- gff %>% filter(gene %in% gene1_ids)
    g2_info <- gff %>% filter(gene %in% gene2_ids)

    if (nrow(g1_info) == 0 || nrow(g2_info) == 0) next

    block_rows[[length(block_rows) + 1]] <- data.frame(
      species1 = g1_info$species[1],
      chr1     = g1_info$chr_num[1],
      start1   = min(g1_info$start) / 1e6,
      end1     = max(g1_info$end) / 1e6,
      species2 = g2_info$species[1],
      chr2     = g2_info$chr_num[1],
      start2   = min(g2_info$start) / 1e6,
      end2     = max(g2_info$end) / 1e6,
      score    = b$score,
      stringsAsFactors = FALSE
    )
  }

  blocks_df <- bind_rows(block_rows)
  chrs_df   <- chr_table %>%
    select(species, chr = chr_num, size = size_mb)

  list(chromosomes = chrs_df, blocks = blocks_df)
}


#' Read GENESPACE/riparian output
#'
#' Parses GENESPACE synHits file into ggsynteny format.
#'
#' @param synhits_file Path to synHits file
#'
#' @return List with elements `chromosomes` and `blocks`
#'
#' @details
#' GENESPACE outputs a synHits file with columns: ofID1, ofID2, chr1, chr2,
#' start1, start2, end1, end2, genome1, genome2, etc.
#'
#' @examples
#' \dontrun{
#' syn <- read_genespace("synHits.tsv")
#' }
#'
#' @export
#' @importFrom readr read_tsv cols
#' @importFrom dplyr transmute group_by summarise bind_rows
read_genespace <- function(synhits_file) {
  raw <- readr::read_tsv(synhits_file, col_types = readr::cols(.default = "c"))

  blocks <- raw %>%
    transmute(
      species1 = genome1,
      chr1     = chr1,
      start1   = as.numeric(start1) / 1e6,
      end1     = as.numeric(end1) / 1e6,
      species2 = genome2,
      chr2     = chr2,
      start2   = as.numeric(start2) / 1e6,
      end2     = as.numeric(end2) / 1e6
    )

  # Infer chromosome sizes from block extents
  chr1 <- blocks %>%
    group_by(species = species1, chr = chr1) %>%
    summarise(size = max(end1), .groups = "drop")
  chr2 <- blocks %>%
    group_by(species = species2, chr = chr2) %>%
    summarise(size = max(end2), .groups = "drop")
  chrs <- bind_rows(chr1, chr2) %>%
    group_by(species, chr) %>%
    summarise(size = max(size), .groups = "drop")

  list(chromosomes = chrs, blocks = blocks)
}
