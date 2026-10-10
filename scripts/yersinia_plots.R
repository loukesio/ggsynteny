# Draw the Yersinia comparison from the committed tables.
# Run from the root of this branch: Rscript scripts/yersinia_plots.R
library(ggsynteny)
library(ggplot2)

syn <- list(chromosomes = read.delim("data/yersinia/chromosomes.tsv", stringsAsFactors = FALSE),
            blocks = read.delim("data/yersinia/blocks.tsv", stringsAsFactors = FALSE))
order <- c("Y. pseudotuberculosis", "Y. pestis CO92", "Y. pestis KIM10+")
inverted <- sum(syn$blocks$orientation == "minus")
subtitle <- paste(nrow(syn$blocks), "alignment blocks of at least 10 kb ·",
                  inverted, "in reversed orientation · lengths in kb")

linear <- plot_synteny(syn, order, palette = "casa_natal", chr_fill = "per_species",
                       ribbon_fill = "species_pair", show_inversions = TRUE,
                       ribbon_alpha = 0.3, tier_spacing = 20) +
  scale_x_continuous(expand = expansion(mult = c(0.19, 0.02))) +
  labs(title = "Plague rearranged the genome it inherited",
       subtitle = subtitle,
       caption = paste("Yersinia pseudotuberculosis IP 32953 and Yersinia pestis CO92 and KIM10+, deposited complete genomes.",
                       "Crossed ribbons are reversed alignments. Block counts are local alignments, not inferred inversion events.",
                       sep = "\n")) +
  theme(plot.title = element_text(face = "bold", size = 16),
        plot.caption = element_text(hjust = 0, colour = "grey35"),
        plot.title.position = "plot", plot.caption.position = "plot",
        plot.margin = margin(14, 18, 12, 18))
ggsave("figures/yersinia-linear.png", linear, width = 13, height = 7.5, dpi = 150, bg = "white")
ggsave("figures/yersinia-linear.pdf", linear, width = 13, height = 7.5)

circular <- plot_circular_synteny(syn, order, palette = "casa_natal", chr_fill = "per_species",
                                  ribbon_fill = "species_pair", show_orientation = TRUE,
                                  ribbon_alpha = 0.28, group_gap = 8, label_size = 0) +
  labs(title = "Plague rearranged the genome it inherited", subtitle = subtitle) +
  theme(plot.title = element_text(face = "bold", size = 16),
        plot.title.position = "plot")
ggsave("figures/yersinia-circular.png", circular, width = 9.5, height = 10, dpi = 150, bg = "white")
ggsave("figures/yersinia-circular.pdf", circular, width = 9.5, height = 10)
cat("Wrote four Yersinia views;", nrow(syn$blocks), "blocks,", inverted, "reversed\n")
