# Yersinia example tables

Three deposited complete genomes: the enteric pathogen *Yersinia
pseudotuberculosis* and two strains of *Yersinia pestis*, the plague
bacterium that descends from it.

| Genome | Versioned record | Strain | Length |
|---|---|---|---:|
| *Y. pseudotuberculosis* | [NC_006155.1](https://www.ncbi.nlm.nih.gov/nuccore/NC_006155.1) | IP 32953 | 4,744,671 bp |
| *Y. pestis CO92* | [NC_003143.1](https://www.ncbi.nlm.nih.gov/nuccore/NC_003143.1) | CO92 | 4,653,728 bp |
| *Y. pestis KIM10+* | [NC_004088.1](https://www.ncbi.nlm.nih.gov/nuccore/NC_004088.1) | KIM10+ | 4,600,755 bp |

`chromosomes.tsv` and `blocks.tsv` are native ggsynteny tables.
Coordinates are **zero-based, half-open kilobases**, matching the other
whole-sequence datasets on this branch. `orientation` is `plus` or `minus`
and is taken from the alignment, not inferred from block order.

| Pair | Retained blocks | Reversed |
|---|---:|---:|
| Y. pseudotuberculosis vs Y. pestis CO92 | 161 | 62 |
| Y. pseudotuberculosis vs Y. pestis KIM10+ | 162 | 92 |
| Y. pestis CO92 vs Y. pestis KIM10+ | 81 | 57 |

Total 404 blocks.

## Method

Downloaded from NCBI Nucleotide with E-utilities. `provenance.json` records
each record's accession version, length and SHA-256 of the sequence itself,
so a changed record is detected. Alignments are megablast of each ordered
pair, E-value at most 1e-20, dust and soft masking off.
A hit is retained at 10,000 bp or longer and
90.0% identity or higher. Hits are
processed by decreasing bit score and one is discarded when more than half of
it overlaps an accepted hit on either genome.

Rebuild with `python3 scripts/prepare_yersinia.py` from the branch root, then
`Rscript scripts/yersinia_plots.R`. Aligner: blastn: 2.16.0+.

## What these tables do and do not show

They are **local alignments between deposited sequences**. A reversed block
means the two records align in opposite orientation; the block counts are not
an inference of how many inversion events occurred, nor of their order or
dates. The rearrangements in *Y. pestis* are attributed in the literature to
insertion-sequence elements, which these tables do not analyse. Nothing here
addresses virulence, transmission or treatment.
