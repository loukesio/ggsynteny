# ═══════════════════════════════════════════════════════════════════════════
# Demo Script: Micro-Synteny Plotting Examples
# ═══════════════════════════════════════════════════════════════════════════

library(ggsynteny)
library(ggplot2)

# Load example microsynteny data
micro <- demo_microsynteny_data()

# ── Example 1: Default identity-based coloring ─────────────────────────────
p1 <- plot_microsynteny(micro$features,
                        micro$links,
                        bin_order = c("ZONMW-30", "ZONMW-20", "ZONMW-10"),
                        gene_fill = "per_name",
                        ribbon_fill = "identity",
                        title = "A) Per-name gene colors | Identity-based ribbons")
print(p1)

# ── Example 2: Custom gene colors ──────────────────────────────────────────
gene_pal <- c(
  moaE   = "#E06C75",
  moaC2  = "#61AFEF",
  moaA   = "#98C379",
  moeA   = "#E5C07B",
  mobA   = "#C678DD",
  spacer = "#DDDDDD"
)

p2 <- plot_microsynteny(micro$features,
                        micro$links,
                        bin_order = c("ZONMW-30", "ZONMW-20", "ZONMW-10"),
                        gene_fill = "per_name",
                        gene_palette = gene_pal,
                        ribbon_fill = "identity",
                        ribbon_alpha = 0.40,
                        title = "B) Custom gene palette | Identity ribbons")
print(p2)

# ── Example 3: Uniform gene colors with name-based ribbons ────────────────
p3 <- plot_microsynteny(micro$features,
                        micro$links,
                        bin_order = c("ZONMW-30", "ZONMW-20", "ZONMW-10"),
                        gene_fill = "uniform",
                        gene_palette = "#AEC6CF",
                        ribbon_fill = "per_name",
                        title = "C) Uniform gene colors | Per-name ribbons")
print(p3)

# ── Example 4: Compact spacing ─────────────────────────────────────────────
p4 <- plot_microsynteny(micro$features,
                        micro$links,
                        bin_order = c("ZONMW-30", "ZONMW-20", "ZONMW-10"),
                        tier_spacing = 4,
                        gene_height = 0.3,
                        gene_fill = "per_name",
                        gene_palette = gene_pal,
                        ribbon_fill = "identity",
                        label_genes = TRUE,
                        label_size = 2,
                        title = "D) Compact layout")
print(p4)

# ── Example 5: No gene labels ──────────────────────────────────────────────
p5 <- plot_microsynteny(micro$features,
                        micro$links,
                        bin_order = c("ZONMW-30", "ZONMW-20", "ZONMW-10"),
                        gene_fill = "per_name",
                        gene_palette = gene_pal,
                        ribbon_fill = "identity",
                        label_genes = FALSE,
                        title = "E) Without gene labels")
print(p5)

# ── Save plots ──────────────────────────────────────────────────────────────
# Uncomment to save:
# ggsave("micro_demo_A.png", p1, width = 14, height = 8, dpi = 300, bg = "white")
# ggsave("micro_demo_B.png", p2, width = 14, height = 8, dpi = 300, bg = "white")
# ggsave("micro_demo_C.png", p3, width = 14, height = 8, dpi = 300, bg = "white")
# ggsave("micro_demo_D.png", p4, width = 14, height = 6, dpi = 300, bg = "white")
# ggsave("micro_demo_E.png", p5, width = 14, height = 8, dpi = 300, bg = "white")
