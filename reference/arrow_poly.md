# Create gene arrow polygon

Generates coordinates for a gene arrow showing directionality.

## Usage

``` r
arrow_poly(x0, x1, y, h, frac = 0.2, strand = "+")
```

## Arguments

- x0:

  Gene start position

- x1:

  Gene end position

- y:

  Y coordinate (center)

- h:

  Half-height of gene

- frac:

  Fraction of gene length for arrowhead (default 0.20)

- strand:

  Strand orientation ("+" or "-")

## Value

Data frame with x, y coordinates for polygon
