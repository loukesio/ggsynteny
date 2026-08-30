# ═══════════════════════════════════════════════════════════════════════════
# Example Data for ggsynteny Package
# ═══════════════════════════════════════════════════════════════════════════

#' Example synteny data (Arabidopsis, Grape, Rice)
#'
#' Bundled example showing macro-synteny relationships between three plant
#' species with real chromosome sizes and simplified syntenic blocks.
#'
#' @return List with two data frames:
#' \describe{
#'   \item{chromosomes}{Data frame with columns: species, chr, size (in Mb)}
#'   \item{blocks}{Data frame with columns: species1, chr1, start1, end1, species2, chr2, start2, end2}
#' }
#'
#' @details
#' Chromosome sizes from NCBI genome assemblies:
#' \itemize{
#'   \item Arabidopsis thaliana (5 chromosomes)
#'   \item Vitis vinifera / Grape (10 chromosomes shown)
#'   \item Oryza sativa / Rice (12 chromosomes)
#' }
#'
#' Synteny blocks are simplified from known paleopolyploidy relationships.
#'
#' @examples
#' syn <- example_synteny_data()
#' str(syn)
#'
#' # Use with plot_synteny
#' \dontrun{
#' p <- plot_synteny(syn, species_order = c("Arabidopsis", "Grape", "Rice"))
#' }
#'
#' @export
#' @importFrom tibble tribble
example_synteny_data <- function() {

  chromosomes <- tibble::tribble(
    ~species,       ~chr,  ~size,
    # Arabidopsis thaliana (5 chromosomes)
    "Arabidopsis",  "1",   30.4,
    "Arabidopsis",  "2",   19.7,
    "Arabidopsis",  "3",   23.5,
    "Arabidopsis",  "4",   18.6,
    "Arabidopsis",  "5",   26.9,
    # Vitis vinifera (19 chromosomes, showing first 10 for clarity)
    "Grape",        "1",   23.0,
    "Grape",        "2",   18.8,
    "Grape",        "3",   19.3,
    "Grape",        "4",   24.0,
    "Grape",        "5",   25.0,
    "Grape",        "6",   21.5,
    "Grape",        "7",   21.7,
    "Grape",        "8",   22.4,
    "Grape",        "9",   23.0,
    "Grape",        "10",  18.1,
    # Oryza sativa (12 chromosomes)
    "Rice",         "1",   43.3,
    "Rice",         "2",   35.9,
    "Rice",         "3",   36.4,
    "Rice",         "4",   35.5,
    "Rice",         "5",   29.9,
    "Rice",         "6",   31.2,
    "Rice",         "7",   29.7,
    "Rice",         "8",   28.4,
    "Rice",         "9",   23.0,
    "Rice",        "10",   23.2,
    "Rice",        "11",   28.4,
    "Rice",        "12",   27.5
  )

  blocks <- tibble::tribble(
    ~species1,      ~chr1, ~start1, ~end1, ~species2,     ~chr2, ~start2, ~end2,
    # Arabidopsis ↔ Grape
    "Arabidopsis",  "1",   2,   12,  "Grape",   "1",   3,   14,
    "Arabidopsis",  "1",   14,  25,  "Grape",   "3",   2,   13,
    "Arabidopsis",  "2",   1,   10,  "Grape",   "5",   5,   16,
    "Arabidopsis",  "2",   12,  18,  "Grape",   "2",   3,   10,
    "Arabidopsis",  "3",   3,   15,  "Grape",   "4",   4,   16,
    "Arabidopsis",  "3",   16,  22,  "Grape",   "7",   2,   10,
    "Arabidopsis",  "4",   2,   10,  "Grape",   "8",   5,   14,
    "Arabidopsis",  "4",   11,  17,  "Grape",   "6",   3,   10,
    "Arabidopsis",  "5",   3,   14,  "Grape",   "9",   3,   15,
    "Arabidopsis",  "5",   16,  24,  "Grape",   "10",  2,   12,
    "Arabidopsis",  "1",   5,   15,  "Grape",   "6",   10,  19,
    "Arabidopsis",  "3",   5,   12,  "Grape",   "9",   14,  22,
    # Grape ↔ Rice
    "Grape",  "1",   2,   12,  "Rice",  "1",   5,   20,
    "Grape",  "1",  13,   21,  "Rice",  "5",   3,   15,
    "Grape",  "2",   2,   10,  "Rice",  "4",   5,   18,
    "Grape",  "3",   3,   15,  "Rice",  "1",  22,   35,
    "Grape",  "4",   2,   14,  "Rice",  "2",   5,   20,
    "Grape",  "4",  16,   22,  "Rice",  "7",   3,   12,
    "Grape",  "5",   3,   14,  "Rice",  "3",   5,   20,
    "Grape",  "5",  16,   24,  "Rice",  "9",   2,   14,
    "Grape",  "6",   2,   12,  "Rice",  "2",  22,   33,
    "Grape",  "7",   3,   15,  "Rice",  "6",   5,   20,
    "Grape",  "8",   2,   14,  "Rice",  "8",   3,   18,
    "Grape",  "9",   2,   12,  "Rice", "10",   2,   15,
    "Grape",  "9",  14,   22,  "Rice", "11",   3,   15,
    "Grape", "10",   2,   10,  "Rice", "12",   3,   14,
    "Grape", "10",  11,   17,  "Rice",  "3",  22,   32,
  )

  list(chromosomes = chromosomes, blocks = blocks)
}


#' Example microsynteny data
#'
#' Bundled example showing gene-level synteny across three genomic bins
#' with moa/moe gene cluster.
#'
#' @return List with two data frames:
#' \describe{
#'   \item{features}{Gene features with columns: bin_id, seq_id, start, end, strand, feat_id, name}
#'   \item{links}{Homology links with columns: feat_id_a, feat_id_b, identity}
#' }
#'
#' @examples
#' micro <- demo_microsynteny_data()
#' str(micro)
#'
#' # Use with plot_microsynteny
#' \dontrun{
#' p <- plot_microsynteny(micro$features, micro$links,
#'                        bin_order = c("ZONMW-30", "ZONMW-20", "ZONMW-10"))
#' }
#'
#' @export
demo_microsynteny_data <- function() {

  features <- data.frame(
    bin_id  = c(rep("ZONMW-30", 8), rep("ZONMW-20", 4), rep("ZONMW-10", 4)),
    seq_id  = c(rep("4", 6), rep("7", 2), rep("10", 4), rep("2", 4)),
    start   = c(0, 444, 1333, 2325, 3991, 4742, 0, 1506,
                0, 1250, 2200, 3150,
                0, 1120, 2100, 3250),
    end     = c(443, 1340, 2325, 3491, 4242, 5331, 1181, 2417,
                1232, 2190, 3100, 4300,
                1100, 2050, 3200, 3900),
    strand  = c("+","+","+","+","+","-","+","+",
                "+","+","+","-",
                "+","+","+","-"),
    feat_id = c("moaE_30","moaC2_30","moaA_30","moeA_30","spacer_30","mobA_30",
                "moeA2_30","moaC3_30",
                "moeA_20","moaC2_20","moaA_20","mobA_20",
                "moaA_10","moaC2_10","moeA_10","moaE_10"),
    name    = c("moaE","moaC2","moaA","moeA","spacer","mobA","moeA","moaC2",
                "moeA","moaC2","moaA","mobA",
                "moaA","moaC2","moeA","moaE"),
    stringsAsFactors = FALSE
  )

  links <- data.frame(
    feat_id_a = c("moaE_30","moaC2_30","moaC2_30","moaA_30","moaA_30",
                  "moeA_30","moeA_30","mobA_30",
                  "moaC2_20","moaA_20","moeA_20"),
    feat_id_b = c("moaE_10","moaC2_20","moaC2_10","moaA_20","moaA_10",
                  "moeA_20","moeA_10","mobA_20",
                  "moaC2_10","moaA_10","moeA_10"),
    identity  = c(95.2, 88.4, 91.0, 93.1, 89.7,
                  78.3, 82.1, 71.5,
                  94.3, 90.2, 85.6),
    stringsAsFactors = FALSE
  )

  list(features = features, links = links)
}
