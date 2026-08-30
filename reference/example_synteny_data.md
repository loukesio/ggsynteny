# Example synteny data (Arabidopsis, Grape, Rice)

Bundled example showing macro-synteny relationships between three plant
species with real chromosome sizes and simplified syntenic blocks.

## Usage

``` r
example_synteny_data()
```

## Value

List with two data frames:

- chromosomes:

  Data frame with columns: species, chr, size (in Mb)

- blocks:

  Data frame with columns: species1, chr1, start1, end1, species2, chr2,
  start2, end2

## Details

Chromosome sizes from NCBI genome assemblies:

- Arabidopsis thaliana (5 chromosomes)

- Vitis vinifera / Grape (10 chromosomes shown)

- Oryza sativa / Rice (12 chromosomes)

Synteny blocks are simplified from known paleopolyploidy relationships.

## Examples

``` r
syn <- example_synteny_data()
str(syn)
#> List of 2
#>  $ chromosomes: tibble [27 × 3] (S3: tbl_df/tbl/data.frame)
#>   ..$ species: chr [1:27] "Arabidopsis" "Arabidopsis" "Arabidopsis" "Arabidopsis" ...
#>   ..$ chr    : chr [1:27] "1" "2" "3" "4" ...
#>   ..$ size   : num [1:27] 30.4 19.7 23.5 18.6 26.9 23 18.8 19.3 24 25 ...
#>  $ blocks     : tibble [27 × 8] (S3: tbl_df/tbl/data.frame)
#>   ..$ species1: chr [1:27] "Arabidopsis" "Arabidopsis" "Arabidopsis" "Arabidopsis" ...
#>   ..$ chr1    : chr [1:27] "1" "1" "2" "2" ...
#>   ..$ start1  : num [1:27] 2 14 1 12 3 16 2 11 3 16 ...
#>   ..$ end1    : num [1:27] 12 25 10 18 15 22 10 17 14 24 ...
#>   ..$ species2: chr [1:27] "Grape" "Grape" "Grape" "Grape" ...
#>   ..$ chr2    : chr [1:27] "1" "3" "5" "2" ...
#>   ..$ start2  : num [1:27] 3 2 5 3 4 2 5 3 3 2 ...
#>   ..$ end2    : num [1:27] 14 13 16 10 16 10 14 10 15 12 ...

# Use with plot_synteny
if (FALSE) { # \dontrun{
p <- plot_synteny(syn, species_order = c("Arabidopsis", "Grape", "Rice"))
} # }
```
