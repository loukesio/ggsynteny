# Hex logo for ggsynteny — run from the package root:
#   Rscript data-raw/hex_logo.R

devtools::load_all(".", quiet = TRUE)
library(ggplot2)

# ── Hexagon (pointy-top, standard hex-sticker orientation) ──
hex_pts <- function(r, cx = 0, cy = 0) {
  a <- seq(90, 450, by = 60) * pi / 180
  data.frame(x = cx + r * cos(a), y = cy + r * sin(a))
}
hex_outer <- hex_pts(1.00)
hex_inner <- hex_pts(0.94)

pal <- syn_palettes()$casa_natal
# green, orange, periwinkle, red, yellow, pink, sky
bg     <- "#173B35"   # darkened casa_natal green
border <- pal[5]      # yellow rim

# ── Mini synteny: two tiers of chromosomes joined by ribbons ──
top_chr <- data.frame(
  xmin = c(-0.52, -0.10, 0.28),
  xmax = c(-0.16,  0.22, 0.56),
  y    = 0.42
)
bot_chr <- data.frame(
  xmin = c(-0.56, -0.02, 0.34),
  xmax = c(-0.08,  0.28, 0.58),
  y    = -0.18
)
chr_h <- 0.045

# ribbons: (top chr index, x-fractions) -> (bottom chr index, x-fractions)
links <- list(
  list(t = 1, tf = c(0.05, 0.95), b = 2, bf = c(0.05, 0.80), col = pal[2]),
  list(t = 2, tf = c(0.10, 0.90), b = 1, bf = c(0.15, 0.95), col = pal[3]),
  list(t = 3, tf = c(0.05, 0.60), b = 3, bf = c(0.10, 0.95), col = pal[7]),
  list(t = 3, tf = c(0.65, 1.00), b = 2, bf = c(0.82, 1.00), col = pal[6])
)

ribbons <- do.call(rbind, lapply(seq_along(links), function(i) {
  l  <- links[[i]]
  tc <- top_chr[l$t, ]; bc <- bot_chr[l$b, ]
  tw <- tc$xmax - tc$xmin; bw <- bc$xmax - bc$xmin
  poly <- bezier_ribbon(tc$xmin + l$tf[1] * tw, tc$xmin + l$tf[2] * tw,
                        tc$y - chr_h,
                        bc$xmin + l$bf[1] * bw, bc$xmin + l$bf[2] * bw,
                        bc$y + chr_h, curvature = 0.55)
  poly$id  <- i
  poly$col <- l$col
  poly
}))

p <- ggplot() +
  geom_polygon(data = hex_outer, aes(x, y), fill = border) +
  geom_polygon(data = hex_inner, aes(x, y), fill = bg) +
  geom_polygon(data = ribbons, aes(x, y, group = id),
               fill = ribbons$col, alpha = 0.82, color = NA) +
  geom_rect(data = top_chr,
            aes(xmin = xmin, xmax = xmax, ymin = y - chr_h, ymax = y + chr_h),
            fill = pal[5], color = bg, linewidth = 0.25) +
  geom_rect(data = bot_chr,
            aes(xmin = xmin, xmax = xmax, ymin = y - chr_h, ymax = y + chr_h),
            fill = pal[2], color = bg, linewidth = 0.25) +
  annotate("text", x = 0, y = -0.52, label = "ggsynteny",
           color = "#FDF6E3", size = 12.5, fontface = "bold",
           family = "Helvetica") +
  coord_fixed(xlim = c(-1.05, 1.05), ylim = c(-1.05, 1.05), expand = FALSE) +
  theme_void()

ggsave("man/figures/logo.png", p, width = 1200, height = 1200,
       units = "px", dpi = 300, bg = "transparent")
cat("Logo written to man/figures/logo.png\n")
