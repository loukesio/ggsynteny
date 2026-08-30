# Pre-rendered figures for README.md — run from the package root:
#   Rscript data-raw/readme_figures.R

devtools::load_all(".", quiet = TRUE)
library(ggplot2)

dir.create("man/figures", recursive = TRUE, showWarnings = FALSE)

syn      <- example_synteny_data()
sp_order <- c("Arabidopsis", "Grape", "Rice")
micro    <- demo_microsynteny_data()
bins     <- c("ZONMW-30", "ZONMW-20", "ZONMW-10")

save_fig <- function(name, p, width = 2600, height = 1500, dpi = 300) {
  ggsave(file.path("man/figures", name), p,
         width = width, height = height, units = "px", dpi = dpi,
         bg = "white")
}

# ── Hero: one ltc palette drives the whole plot ──
save_fig("README-hero.png",
         plot_synteny(syn, sp_order, palette = "casa_natal"))

# ── Macro default ──
save_fig("README-macro-default.png", plot_synteny(syn, sp_order))

# ── Macro: per-chromosome colors from an ltc palette ──
save_fig("README-macro-perchr.png",
         plot_synteny(syn, sp_order,
                      chr_fill = "per_chr", ribbon_fill = "source_chr",
                      palette = "minou"))

# ── Macro: uniform chromosomes + species-pair ribbons ──
save_fig("README-macro-pairs.png",
         plot_synteny(syn, sp_order,
                      chr_fill = "uniform", chr_palette = "#E8E4DF",
                      ribbon_fill = "species_pair", ribbon_palette = "trio1",
                      ribbon_alpha = 0.35))

# ── Micro: genes from an ltc palette, ribbons by identity ──
save_fig("README-micro.png",
         plot_microsynteny(micro$features, micro$links, bin_order = bins,
                           palette = "casa_natal",
                           ribbon_fill = "identity"),
         height = 1400)

# ── Micro: identity ramp from a heatmap palette ──
save_fig("README-micro-ramp.png",
         plot_microsynteny(micro$features, micro$links, bin_order = bins,
                           gene_fill = "per_name", gene_palette = "casa_natal",
                           ribbon_fill = "identity", ribbon_palette = "heatmap0"),
         height = 1400)

# ── Palette gallery ──
pals <- syn_palettes()
gal <- do.call(rbind, lapply(seq_along(pals), function(i) {
  data.frame(pal = names(pals)[i], row = i,
             col = seq_along(pals[[i]]), hex = pals[[i]])
}))
gal$pal <- factor(gal$pal, levels = rev(names(pals)))

p_gal <- ggplot(gal, aes(x = col, y = pal, fill = hex)) +
  geom_tile(color = "white", linewidth = 0.6, width = 0.95, height = 0.72) +
  scale_fill_identity() +
  scale_y_discrete(expand = expansion(add = 0.4)) +
  labs(title = "ggsynteny built-in palettes (from the ltc package)") +
  theme_void() +
  theme(axis.text.y = element_text(size = 8, hjust = 1,
                                   margin = margin(r = 4), family = "mono"),
        plot.title = element_text(hjust = 0.5, size = 11, face = "bold",
                                  margin = margin(b = 8)),
        plot.margin = margin(10, 14, 10, 10))

ggsave("man/figures/README-palettes.png", p_gal,
       width = 1700, height = 2400, units = "px", dpi = 300, bg = "white")

cat("Figures written to man/figures/\n")
