# ═══════════════════════════════════════════════════════════════════════════
# Utility Functions for ggsynteny
# ═══════════════════════════════════════════════════════════════════════════

#' Null-coalescing operator
#' @noRd
`%||%` <- function(a, b) if (is.null(a)) b else a

#' Auto-generate color palette
#'
#' @param n Number of colors to generate
#' @return Character vector of hex color codes
#' @keywords internal
auto_palette <- function(n) {
  grDevices::hcl(h = seq(15, 375, length.out = n + 1)[1:n], c = 70, l = 60)
}

#' Create bezier curve ribbon polygon
#'
#' Generates coordinates for a curved ribbon connecting two horizontal segments
#' using cubic Bezier curves.
#'
#' @param sx0 Source x start
#' @param sx1 Source x end
#' @param sy Source y position
#' @param tx0 Target x start
#' @param tx1 Target x end
#' @param ty Target y position
#' @param curvature Curve strength (0-1), default 0.55
#' @param n Number of points for smoothness, default 250
#' @return Data frame with x, y coordinates for polygon
#' @keywords internal
bezier_ribbon <- function(sx0, sx1, sy, tx0, tx1, ty,
                          curvature = 0.55, n = 250) {
  t   <- seq(0, 1, length.out = n)
  yc1 <- sy - curvature * (sy - ty)
  yc2 <- ty + curvature * (sy - ty)

  top_x <- (1-t)^3*sx0 + 3*(1-t)^2*t*sx0 + 3*(1-t)*t^2*tx0 + t^3*tx0
  top_y <- (1-t)^3*sy  + 3*(1-t)^2*t*yc1  + 3*(1-t)*t^2*yc2  + t^3*ty
  bot_x <- (1-t)^3*sx1 + 3*(1-t)^2*t*sx1 + 3*(1-t)*t^2*tx1 + t^3*tx1
  bot_y <- (1-t)^3*sy  + 3*(1-t)^2*t*yc1  + 3*(1-t)*t^2*yc2  + t^3*ty

  data.frame(x = c(top_x, rev(bot_x)), y = c(top_y, rev(bot_y)))
}

#' Create gene arrow polygon
#'
#' Generates coordinates for a gene arrow showing directionality.
#'
#' @param x0 Gene start position
#' @param x1 Gene end position
#' @param y Y coordinate (center)
#' @param h Half-height of gene
#' @param frac Fraction of gene length for arrowhead (default 0.20)
#' @param strand Strand orientation ("+" or "-")
#' @return Data frame with x, y coordinates for polygon
#' @keywords internal
arrow_poly <- function(x0, x1, y, h, frac = 0.20, strand = "+") {
  head <- (x1 - x0) * frac

  if (strand == "+") {
    bx <- x1 - head
    data.frame(
      x = c(x0, bx,   x1, bx,   x0),
      y = c(y-h, y-h,  y,  y+h,  y+h)
    )
  } else {
    bx <- x0 + head
    data.frame(
      x = c(x1, bx,   x0, bx,   x1),
      y = c(y-h, y-h,  y,  y+h,  y+h)
    )
  }
}

#' Map identity values to colors
#'
#' @param values Numeric vector of identity percentages (0-100)
#' @param low Color for low identity (default light blue)
#' @param high Color for high identity (default dark blue)
#' @return Character vector of hex colors
#' @keywords internal
identity_color <- function(values, low = "#DCEEFF", high = "#08519C") {
  ramp <- grDevices::colorRampPalette(c(low, high))
  cols <- ramp(101)
  cols[round(pmin(pmax(values, 0), 100)) + 1]
}
