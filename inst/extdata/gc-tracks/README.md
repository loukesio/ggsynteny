# Simulated GC-track examples

All DNA sequences in this directory are simulated. The gene positions and links
reuse `demo_microsynteny_data()` as a layout template, with generic genome names
and gene identifiers. The GC measurements do not describe real organisms.

Regenerate from the repository root with `Rscript data-raw/gc_tracks.R`.
The fixed random seed is 20260920. Sequence composition varies along each contig;
Genome A contig 4 has 251 `N` bases at `[3991, 4242)` to demonstrate missing calls.

- `sequences.tsv`: DNA strings, keyed by group and sequence identifier.
- `features.tsv`, `links.tsv`: gene positions and supplied example homologies.
- `chromosomes.tsv`, `blocks.tsv`: the same coordinates in chromosome input form.
- `windows.tsv`: GC percentages in 250 bp windows (last window may be shorter).
- `genes.tsv`: per-gene GC percentages and counts of called/ambiguous bases.

Coordinates are zero-based, half-open base pairs throughout. GC percent is
`100 * (G + C) / (A + C + G + T)`. Other IUPAC bases do not enter the denominator.
An interval with no called bases has `NA` GC. It is not a zero-GC interval.
Short overlapping demo genes remain overlapping; later track tiles draw on top.

The example outputs are in `man/figures/gc-tracks/`. Everything here is generated
locally without network access and is covered by the repository license.
