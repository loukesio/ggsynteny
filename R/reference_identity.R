# Identity scores are supplied independently of variant calls, in reference coordinates.
.reference_identity_validate <- function(windows, genome_length) {
  if (is.null(windows)) return(data.frame(sample = character(), start = numeric(), end = numeric(), identity = numeric()))
  w <- .circ_columns(windows, c("sample", "start", "end", "identity"), "Identity windows")
  w$sample <- .circ_text(w$sample, "Identity sample")
  for (key in c("start", "end")) w[[key]] <- .circ_numbers(w[[key]], key)
  if (is.logical(w$identity) && all(is.na(w$identity))) w$identity <- as.numeric(w$identity)
  if (!is.numeric(w$identity) || any(!is.na(w$identity) & (!is.finite(w$identity) | w$identity < 0 | w$identity > 100)))
    stop("Identity must be a percentage from 0 to 100, or NA when unknown.", call. = FALSE)
  if (any(w$start < 0 | w$end <= w$start | w$end > genome_length))
    stop("Identity windows must have positive widths within the reference bounds.", call. = FALSE)
  for (sample in unique(w$sample)) {
    a <- w[w$sample == sample, ]; a <- a[order(a$start), ]
    if (nrow(a) > 1 && any(a$start[-1] < utils::head(cummax(a$end), -1)))
      stop("Identity windows must not overlap within a sample; resolve overlapping alignments before plotting.", call. = FALSE)
  }
  w
}

.reference_identity_color <- function(identity) {
  ramp <- grDevices::colorRampPalette(c("#D1D5DA", "#353A44"))(101)
  out <- rep("#E1E5DC", length(identity))
  valid <- !is.na(identity)
  out[valid] <- ramp[1 + round(pmax(0, pmin(1, (identity[valid] - 90) / 10)) * 100)]
  out
}

.reference_ruler_step <- function(genome_length) {
  if (genome_length >= 1e6) 500000 else max(1, 10^floor(log10(genome_length / 5)))
}

.reference_identity_demo <- function() {
  # Deterministic, invented 30-kb windows. No random state or biological claims.
  do.call(rbind, lapply(1:5, function(s) {
    i <- 0:159
    score <- 99.5 - .6 * abs(sin(i * 1.73 + s * .91))
    dips <- ((i * 37 + s * 11) %% 31) < 3
    score[dips] <- score[dips] - 2 - 4 * abs(cos(i[dips] + s))
    score[i >= 48 & i <= 52 & s >= 4] <- 94.5
    # Keep the synthetic example internally consistent: deletion spans have no identity.
    w <- data.frame(sample = paste("Genome", LETTERS[s]), start = i * 30000,
                    end = (i + 1) * 30000, identity = round(score, 2))
    deletions <- .reference_demo()
    deletions <- deletions[deletions$sample == paste("Genome", LETTERS[s]) & deletions$type == "DEL", ]
    # Cut windows at deletion boundaries and omit deleted pieces.
    pieces <- lapply(seq_len(nrow(w)), function(j) {
      bounds <- sort(unique(c(w$start[j], w$end[j],
        deletions$start[deletions$start > w$start[j] & deletions$start < w$end[j]],
        deletions$end[deletions$end > w$start[j] & deletions$end < w$end[j]])))
      a <- w[rep(j, length(bounds)-1), ]; a$start <- utils::head(bounds,-1); a$end <- bounds[-1]
      keep <- vapply(seq_len(nrow(a)), function(k) !any(a$start[k] < deletions$end & a$end[k] > deletions$start), logical(1))
      a[keep, ]
    })
    do.call(rbind, pieces)
  }))
}

.reference_identity_caption <- function(windows, genome_length) {
  paste0("Inner dark bands are a ruler: alternating every ", format(.reference_ruler_step(genome_length), big.mark = ",", scientific = FALSE), " bp, not measurements.\n",
    if (nrow(windows)) "Outer shading is supplied identity: darker = more matching aligned bases. Scale: light <=90%, mid 95%, dark 100%; pale green = no score.\n" else "Outer tracks have no supplied identity scores; their plain shade is not a measurement.\n",
    "For example, 99% identity means about 99 of 100 aligned bases match. Higher means more similar, not better; coverage is not shown.")
}
