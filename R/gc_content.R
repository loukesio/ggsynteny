#' Calculate GC content from DNA sequences
#'
#' Calculate `100 * (G + C) / (A + C + G + T)` for gene intervals or genomic
#' windows. Ambiguous IUPAC DNA bases are excluded from the denominator. No
#' called bases, or an explicitly missing sequence, gives `NA`, never zero.
#'
#' @param sequences Data frame with `group`, `seq_id`, and `sequence` (character
#'   DNA strings, or `NA` for missing sequence). `species`/`chr` and
#'   `bin_id`/`seq_id` key pairs are also accepted. Keys must be unique.
#'   Sequences start at genomic coordinate zero. Lowercase is accepted;
#'   whitespace is removed. Gaps and non-IUPAC DNA characters are rejected.
#' @param intervals Optional data frame with the same keys and `start`, `end`.
#'   Uses zero-based, half-open base-pair coordinates: `[0, 4)` includes the
#'   first four bases. For per-gene summaries, pass the feature table after
#'   converting its coordinates if necessary. Extra columns are retained.
#' @param window Positive integer window width in bases, used only without
#'   `intervals`. The last window is shortened at the end of a sequence.
#' @param step Positive integer distance between window starts. Defaults to
#'   `window` (non-overlapping windows); smaller steps give sliding windows.
#' @return Data frame with `group`, `seq_id`, `start`, `end`, `value` (GC percent),
#'   `n_called` (A/C/G/T count), and `n_ambiguous` (other IUPAC base count).
#'   For missing sequences both counts are `NA`. Supplied interval columns
#'   are retained, except these result columns which are replaced. Output can
#'   be passed directly to [syn_track()] when plot units and origins match.
#' @details No sequence is inferred from synteny links or block ranks. Missing
#'   sequence keys are errors; declare a sequence as `NA` to explicitly mark it
#'   missing. Without intervals, missing sequences are rejected because their
#'   lengths are unknown. Empty sequences produce no windows. Windows stop at
#'   the sequence end and do not wrap across a circular origin. Split intervals
#'   that cross the origin before calculating. Gene strand does not affect GC.
#' @examples
#' dna <- data.frame(group = "Genome A", seq_id = "chr1",
#'                   sequence = "ACGTGGCCNNAT")
#' gc_content(dna, window = 4)
#' genes <- data.frame(group = "Genome A", seq_id = "chr1",
#'                     start = c(0, 8), end = c(8, 12))
#' gc_content(dna, intervals = genes)
#' @export
gc_content <- function(sequences, intervals = NULL, window = 1000, step = window) {
  sequences <- .track_keys(sequences)
  if (!"sequence" %in% names(sequences) || !is.character(sequences$sequence))
    stop("sequences$sequence must contain character DNA strings or NA.", call. = FALSE)
  keys <- .circ_key(sequences$group, sequences$seq_id)
  if (anyDuplicated(keys)) stop("Sequence keys must be unique.", call. = FALSE)
  dna <- toupper(gsub("[[:space:]]", "", sequences$sequence))
  if (any(!is.na(dna) & grepl("[^ACGTRYSWKMBDHVN]", dna)))
    stop("Sequences must contain IUPAC DNA bases only (no gaps).", call. = FALSE)
  lengths <- nchar(dna)
  if (is.null(intervals)) {
    for (nm in c("window", "step")) {
      x <- get(nm)
      .circ_scalar(x, nm, 1, .Machine$integer.max)
      if (x != floor(x)) stop(nm, " must be an integer.", call. = FALSE)
    }
    if (anyNA(dna)) stop("Missing sequences require explicit intervals.", call. = FALSE)
    rows <- lapply(seq_along(dna), function(i) {
      starts <- if (lengths[i] > 0) seq(0, lengths[i] - 1, by = step) else numeric()
      data.frame(group = rep(sequences$group[i], length(starts)),
                  seq_id = rep(sequences$seq_id[i], length(starts)),
                  start = starts, end = pmin(starts + window, lengths[i]))
    })
    intervals <- if (length(rows)) dplyr::bind_rows(rows) else
      data.frame(group = character(), seq_id = character(), start = numeric(), end = numeric())
  }
  intervals <- .track_intervals(intervals)
  if (any(intervals$start != floor(intervals$start) | intervals$end != floor(intervals$end)))
    stop("GC intervals must use integer base-pair coordinates.", call. = FALSE)
  index <- match(.circ_key(intervals$group, intervals$seq_id), keys)
  if (anyNA(index)) stop("Intervals reference an unknown sequence key.", call. = FALSE)
  if (any(intervals$end > lengths[index], na.rm = TRUE))
    stop("GC intervals exceed sequence bounds.", call. = FALSE)
  intervals$value <- rep(NA_real_, nrow(intervals))
  intervals$n_called <- rep(NA_real_, nrow(intervals))
  intervals$n_ambiguous <- rep(NA_real_, nrow(intervals))
  # Prefix sums count overlapping windows and genes in linear sequence time,
  # instead of repeatedly scanning every extracted interval.
  for (i in unique(index)) {
    if (is.na(dna[i])) next
    rows <- which(index == i)
    bases <- strsplit(dna[i], "", fixed = TRUE)[[1]]
    called <- c(0, cumsum(bases %in% c("A", "C", "G", "T")))
    gc <- c(0, cumsum(bases %in% c("G", "C")))
    a <- intervals$start[rows] + 1
    b <- intervals$end[rows] + 1
    n <- called[b] - called[a]
    intervals$n_called[rows] <- n
    intervals$n_ambiguous[rows] <- intervals$end[rows] - intervals$start[rows] - n
    intervals$value[rows] <- ifelse(n > 0, 100 * (gc[b] - gc[a]) / n, NA_real_)
  }
  intervals
}
