# Calculate GC content from DNA sequences

Calculate `100 * (G + C) / (A + C + G + T)` for gene intervals or
genomic windows. Ambiguous IUPAC DNA bases are excluded from the
denominator. No called bases, or an explicitly missing sequence, gives
`NA`, never zero.

## Usage

``` r
gc_content(sequences, intervals = NULL, window = 1000, step = window)
```

## Arguments

- sequences:

  Data frame with `group`, `seq_id`, and `sequence` (character DNA
  strings, or `NA` for missing sequence). `species`/`chr` and
  `bin_id`/`seq_id` key pairs are also accepted. Keys must be unique.
  Sequences start at genomic coordinate zero. Lowercase is accepted;
  whitespace is removed. Gaps and non-IUPAC DNA characters are rejected.

- intervals:

  Optional data frame with the same keys and `start`, `end`. Uses
  zero-based, half-open base-pair coordinates: `[0, 4)` includes the
  first four bases. For per-gene summaries, pass the feature table after
  converting its coordinates if necessary. Extra columns are retained.

- window:

  Positive integer window width in bases, used only without `intervals`.
  The last window is shortened at the end of a sequence.

- step:

  Positive integer distance between window starts. Defaults to `window`
  (non-overlapping windows); smaller steps give sliding windows.

## Value

Data frame with `group`, `seq_id`, `start`, `end`, `value` (GC percent),
`n_called` (A/C/G/T count), and `n_ambiguous` (other IUPAC base count).
For missing sequences both counts are `NA`. Supplied interval columns
are retained, except these result columns which are replaced. Output can
be passed directly to
[`syn_track()`](https://loukesio.github.io/ggsynteny/reference/syn_track.md)
when plot units and origins match.

## Details

No sequence is inferred from synteny links or block ranks. Missing
sequence keys are errors; declare a sequence as `NA` to explicitly mark
it missing. Without intervals, missing sequences are rejected because
their lengths are unknown. Empty sequences produce no windows. Windows
stop at the sequence end and do not wrap across a circular origin. Split
intervals that cross the origin before calculating. Gene strand does not
affect GC.

## Examples

``` r
dna <- data.frame(group = "Genome A", seq_id = "chr1",
                  sequence = "ACGTGGCCNNAT")
gc_content(dna, window = 4)
#>      group seq_id start end value n_called n_ambiguous
#> 1 Genome A   chr1     0   4    50        4           0
#> 2 Genome A   chr1     4   8   100        4           0
#> 3 Genome A   chr1     8  12     0        2           2
genes <- data.frame(group = "Genome A", seq_id = "chr1",
                    start = c(0, 8), end = c(8, 12))
gc_content(dna, intervals = genes)
#>      group seq_id start end value n_called n_ambiguous
#> 1 Genome A   chr1     0   8    75        8           0
#> 2 Genome A   chr1     8  12     0        2           2
```
