# Read GENESPACE/riparian output

Parses GENESPACE synHits file into ggsynteny format.

## Usage

``` r
read_genespace(synhits_file)
```

## Arguments

- synhits_file:

  Path to synHits file

## Value

List with elements `chromosomes` and `blocks`

## Details

GENESPACE outputs a synHits file with columns: ofID1, ofID2, chr1, chr2,
start1, start2, end1, end2, genome1, genome2, etc.

## Examples

``` r
if (FALSE) { # \dontrun{
syn <- read_genespace("synHits.tsv")
} # }
```
