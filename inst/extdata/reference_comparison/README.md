# Reference comparison example data

These small tables are invented teaching data for
`plot_reference_comparison()`. They are not measurements from biological
samples.

`variants.tsv` contains event calls in one reference coordinate system.
`identity_windows.tsv` contains independently supplied alignment identity
scores for non-overlapping reference windows. A missing identity window means
that no score was supplied; it is not treated as low identity.

Coordinates use zero-based starts and exclusive ends, in base pairs. `INS` and
`SNP` calls may have equal `start` and `end`. `event_length` is optional and is
the inserted length. `source_start` is optional and identifies the source of a
duplication on the same reference.
