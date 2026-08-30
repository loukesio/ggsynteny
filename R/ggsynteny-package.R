#' ggsynteny: Publication-Quality Synteny Plots
#'
#' Create publication-quality synteny visualizations for comparative genomics.
#' Supports both macro-synteny (chromosome-level) and micro-synteny (gene-level)
#' plots with flexible coloring schemes.
#'
#' @section Main Functions:
#' \itemize{
#'   \item \code{\link{plot_synteny}} - Create macro-synteny plots
#'   \item \code{\link{plot_microsynteny}} - Create micro-synteny plots
#' }
#'
#' @section Colour Palettes:
#' Every \code{palette} argument accepts, by name, all 32 palettes of the
#' \href{https://github.com/loukesio/ltc-color-palettes}{ltc package}
#' (vendored, so ltc need not be installed), e.g.
#' \code{plot_synteny(syn, sp_order, palette = "casa_natal")}.
#' List them with \code{\link{syn_palettes}}.
#'
#' @section Data Parsers:
#' \itemize{
#'   \item \code{\link{read_synteny_tsv}} - Read TSV format
#'   \item \code{\link{read_mcscanx}} - Read MCScanX format
#'   \item \code{\link{read_genespace}} - Read GENESPACE format
#' }
#'
#' @section Example Data:
#' \itemize{
#'   \item \code{\link{example_synteny_data}} - Macro-synteny example
#'   \item \code{\link{demo_microsynteny_data}} - Micro-synteny example
#' }
#'
#' @importFrom dplyr %>%
#' @keywords internal
"_PACKAGE"

# Data-frame column names used with dplyr non-standard evaluation
utils::globalVariables(c(
  ".chr_num", "bin_id", "body_x0", "body_x1", "bw", "chr", "chr1", "chr2",
  "chr_id", "chr_num", "conn_id", "cumstart", "end", "end1", "end2", "feat_id", "gene",
  "genome1", "genome2", "head_w", "label", "link_id", "lx", "ly", "name",
  "offset", "seq_id", "size", "size_mb", "species", "species1", "species2",
  "start", "start1", "start2", "strand", "tooltip", "total_width", "vjust",
  "x", "x0", "x1", "x_right", "x_sep", "xa0", "xb0", "xmax", "xmin", "y"
))
