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
abbreviation (e.g., "Hs1" for Human chromosome 1). Block coordinates are
in Mb. The `orientation` column preserves MCScanX's `"plus"` or
`"minus"` alignment direction.
[`plot_synteny()`](https://loukesio.github.io/ggsynteny/reference/plot_synteny.md)
shows coverage by default; set `show_inversions = TRUE` to encode
inversions in the ribbons.

## Examples

``` r
if (FALSE) { # \dontrun{
syn <- read_mcscanx("output.collinearity", "output.gff")
} # }
```
