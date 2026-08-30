# ═══════════════════════════════════════════════════════════════════════════
# Demo Script: Macro-Synteny Plotting Examples
# ═══════════════════════════════════════════════════════════════════════════

library(ggsynteny)
library(ggplot2)

# Load example data
syn <- example_synteny_data()
sp_order <- c("Arabidopsis", "Grape", "Rice")

# ── Example 1: Default styling ──────────────────────────────────────────────
p1 <- plot_synteny(syn, sp_order,
                   chr_fill = "per_species",
                   ribbon_fill = "source_chr",
                   title = "A) Default: per-species chromosomes | source-chr ribbons")
print(p1)

# ── Example 2: Uniform chromosomes + species-pair ribbons ──────────────────
p2 <- plot_synteny(syn, sp_order,
                   chr_fill = "uniform",
                   chr_palette = "#E8E4DF",
                   ribbon_fill = "species_pair",
                   ribbon_palette = c(
                     "Arabidopsis_Grape" = "#3A6EA5",
                     "Grape_Rice"        = "#E8573A"
                   ),
                   title = "B) Uniform chromosomes | species-pair ribbons")
print(p2)

# ── Example 3: Per-chromosome coloring ─────────────────────────────────────
chr_pal <- c("1"="#1B3A8C","2"="#3B7DD8","3"="#00BCD4","4"="#4CAF50",
             "5"="#8BC34A","6"="#CDDC39","7"="#9C27B0","8"="#E91E63",
             "9"="#FF5722","10"="#FF9800","11"="#795548","12"="#F44336")

p3 <- plot_synteny(syn, sp_order,
                   chr_fill = "per_chr",
                   chr_palette = chr_pal,
                   ribbon_fill = "source_chr",
                   ribbon_palette = chr_pal,
                   title = "C) Per-chromosome coloring with matching ribbons")
print(p3)

# ── Example 4: Custom species colors + uniform ribbons ─────────────────────
p4 <- plot_synteny(syn, sp_order,
                   chr_fill = "per_species",
                   chr_palette = c(
                     "Arabidopsis" = "#B8D4E3",
                     "Grape"       = "#C5B4E3",
                     "Rice"        = "#B8E3C5"
                   ),
                   ribbon_fill = "uniform",
                   ribbon_palette = "#50B88E",
                   ribbon_alpha = 0.25,
                   title = "D) Custom species colors | uniform teal ribbons")
print(p4)

# ── Save plots ──────────────────────────────────────────────────────────────
# Uncomment to save:
# ggsave("macro_demo_A.png", p1, width = 20, height = 10, dpi = 300, bg = "white")
# ggsave("macro_demo_B.png", p2, width = 20, height = 10, dpi = 300, bg = "white")
# ggsave("macro_demo_C.png", p3, width = 20, height = 10, dpi = 300, bg = "white")
# ggsave("macro_demo_D.png", p4, width = 20, height = 10, dpi = 300, bg = "white")
