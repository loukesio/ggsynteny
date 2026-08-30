# Read synteny data from TSV files

Reads the native ggsynteny format: two TSV files containing chromosome
sizes and syntenic blocks.

## Usage

``` r
read_synteny_tsv(chr_file, blocks_file)
```

## Arguments

- chr_file:

  Path to chromosomes.tsv with columns: species, chr, size

- blocks_file:

  Path to synteny_blocks.tsv with columns: species1, chr1, start1, end1,
  species2, chr2, start2, end2

## Value

List with elements `chromosomes` and `blocks`

## Examples

``` r
if (FALSE) { # \dontrun{
syn <- read_synteny_tsv("chromosomes.tsv", "synteny_blocks.tsv")
} # }
```
