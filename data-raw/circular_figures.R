# Rebuild circular examples from the package root.
devtools::load_all(".", quiet = TRUE)
data(rice_sorghum)
micro <- demo_microsynteny_data()
macro <- plot_circular_synteny(rice_sorghum, c("Rice", "Sorghum"),
                               palette = "casa_natal", chr_fill = "per_species")
genes <- plot_circular_microsynteny(micro$features, micro$links,
                                    palette = "casa_natal", ribbon_fill = "per_name")
dir.create("dev/circular", recursive = TRUE, showWarnings = FALSE)
for (name in c("macro", "micro")) {
  plot <- if (name == "macro") macro else genes
  ggplot2::ggsave(paste0("man/figures/README-circular-", name, ".png"), plot,
                  width = 8, height = 8, dpi = 180, bg = "white")
  ggplot2::ggsave(paste0("dev/circular/circular-", name, ".pdf"), plot,
                  width = 8, height = 8)
}
