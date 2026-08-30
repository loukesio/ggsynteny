# Rice-sorghum macro-synteny (real MCScanX output)

Real collinearity between rice (*Oryza sativa*) and sorghum (*Sorghum
bicolor*), two grasses that diverged roughly 50 million years ago but
retain extensive synteny.

## Usage

``` r
rice_sorghum
```

## Format

A list with two data frames, ready for
[`plot_synteny`](https://loukesio.github.io/ggsynteny/reference/plot_synteny.md):

- chromosomes:

  22 rows: species, chr, size (Mb; inferred from the last annotated gene
  per chromosome)

- blocks:

  100 rows: species1, chr1, start1, end1, species2, chr2, start2, end2
  (Mb), plus MCScanX's score and the number of collinear gene pairs
  (n_genes)

## Source

MCScanX example data (<https://github.com/wyp1125/MCScanX>); Wang et al.
(2012) "MCScanX: a toolkit for detection and evolutionary analysis of
gene synteny and collinearity." *Nucleic Acids Research* 40(7):e49.
[doi:10.1093/nar/gkr1293](https://doi.org/10.1093/nar/gkr1293)

## Details

The dataset was produced by running MCScanX (default parameters) on the
rice-sorghum example data shipped with MCScanX itself (all-vs-all
protein BLAST plus gene positions), and parsing the resulting
`os_sb.collinearity` file with
[`read_mcscanx`](https://loukesio.github.io/ggsynteny/reference/read_mcscanx.md).
Only inter-genome blocks with at least 20 collinear gene pairs are kept,
so the default plot stays legible; the preparation script
(`data-raw/rice_sorghum.R`) documents the full pipeline.

## Examples

``` r
data(rice_sorghum)
p <- plot_synteny(rice_sorghum, c("Rice", "Sorghum"),
                  palette = "casa_natal")
```
