# Example microsynteny data

Bundled example showing gene-level synteny across three genomic bins
with moa/moe gene cluster.

## Usage

``` r
demo_microsynteny_data()
```

## Value

List with two data frames:

- features:

  Gene features with columns: bin_id, seq_id, start, end, strand,
  feat_id, name

- links:

  Homology links with columns: feat_id_a, feat_id_b, identity

## Examples

``` r
micro <- demo_microsynteny_data()
str(micro)
#> List of 2
#>  $ features:'data.frame':    16 obs. of  7 variables:
#>   ..$ bin_id : chr [1:16] "ZONMW-30" "ZONMW-30" "ZONMW-30" "ZONMW-30" ...
#>   ..$ seq_id : chr [1:16] "4" "4" "4" "4" ...
#>   ..$ start  : num [1:16] 0 444 1333 2325 3991 ...
#>   ..$ end    : num [1:16] 443 1340 2325 3491 4242 ...
#>   ..$ strand : chr [1:16] "+" "+" "+" "+" ...
#>   ..$ feat_id: chr [1:16] "moaE_30" "moaC2_30" "moaA_30" "moeA_30" ...
#>   ..$ name   : chr [1:16] "moaE" "moaC2" "moaA" "moeA" ...
#>  $ links   :'data.frame':    11 obs. of  3 variables:
#>   ..$ feat_id_a: chr [1:11] "moaE_30" "moaC2_30" "moaC2_30" "moaA_30" ...
#>   ..$ feat_id_b: chr [1:11] "moaE_10" "moaC2_20" "moaC2_10" "moaA_20" ...
#>   ..$ identity : num [1:11] 95.2 88.4 91 93.1 89.7 78.3 82.1 71.5 94.3 90.2 ...

# Use with plot_microsynteny
if (FALSE) { # \dontrun{
p <- plot_microsynteny(micro$features, micro$links,
                       bin_order = c("ZONMW-30", "ZONMW-20", "ZONMW-10"))
} # }
```
