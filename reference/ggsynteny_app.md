# Launch the ggsynteny Shiny app

Preview existing synteny results, choose a linear or circular layout,
and download figures, displayed tables, pair summaries and reproducible
R code. The app reads MCScanX, GENESPACE, native chromosome/block
tables, and native gene/link tables. It does not run alignment or
synteny analysis software.

## Usage

``` r
ggsynteny_app(host = "127.0.0.1", port = NULL, launch.browser = interactive())
```

## Arguments

- host:

  Address to listen on; defaults to the local computer.

- port:

  Optional port passed to
  [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html).

- launch.browser:

  Open the app in a browser?

## Value

Runs a Shiny app until interrupted.

## Examples

``` r
if (FALSE) { # \dontrun{
ggsynteny_app()
} # }
```
