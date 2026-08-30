# Create bezier curve ribbon polygon

Generates coordinates for a curved ribbon connecting two horizontal
segments using cubic Bezier curves.

## Usage

``` r
bezier_ribbon(sx0, sx1, sy, tx0, tx1, ty, curvature = 0.55, n = 250)
```

## Arguments

- sx0:

  Source x start

- sx1:

  Source x end

- sy:

  Source y position

- tx0:

  Target x start

- tx1:

  Target x end

- ty:

  Target y position

- curvature:

  Curve strength (0-1), default 0.55

- n:

  Number of points for smoothness, default 250

## Value

Data frame with x, y coordinates for polygon
