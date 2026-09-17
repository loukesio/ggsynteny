# Read MCScanX output files

Parses MCScanX collinearity and GFF files into ggsynteny format.

## Usage

``` r
read_mcscanx(collinearity_file, gff_file)
```

## Arguments

- collinearity_file:

  Path to .collinearity file

- gff_file:

  Path to .gff file with gene positions

## Value

List with elements `chromosomes` and `blocks`

## Details

MCScanX convention: chromosome names are prefixed with species
abbreviation (e.g., "Hs1" for Human chromosome 1).

## Examples

``` r
if (FALSE) { # \dontrun{
syn <- read_mcscanx("output.collinearity", "output.gff")
} # }
```
