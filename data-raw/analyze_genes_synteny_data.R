# ═══════════════════════════════════════════════════════════════════════════
# Analyze and Plot Real Genes Synteny Data with ggsynteny Package
# ═══════════════════════════════════════════════════════════════════════════
#
# This script takes the real bacterial genome synteny data from the
# genes_synteny project and plots it using the ggsynteny package.
#
# Data source: /Users/theodosiou/Documents/Projects/genes_synteny
# Data type: Microsynteny of moa/moe gene clusters in 8 bacterial species
# ═══════════════════════════════════════════════════════════════════════════

library(ggsynteny)
library(ggplot2)
library(dplyr)
library(readr)

# ── Load Data ──────────────────────────────────────────────────────────────

# Gene features (coordinates, strand, names)
features <- read_csv("/Users/theodosiou/Documents/Projects/genes_synteny/objects/alv_genes3.csv",
                     show_col_types = FALSE)

# Protein homology links
links <- read_csv("/Users/theodosiou/Documents/Projects/genes_synteny/objects/alv_prot_ava2.csv",
                  show_col_types = FALSE)

# ── Data Inspection ────────────────────────────────────────────────────────

cat("=== Features Data ===\n")
print(head(features))
cat("\nNumber of features:", nrow(features), "\n")
cat("Unique genomes:", paste(unique(features$bin_id), collapse = ", "), "\n")
cat("Unique genes:", paste(unique(features$name[features$name != "z_spacer"]), collapse = ", "), "\n")

cat("\n=== Links Data ===\n")
print(head(links))
cat("\nNumber of links:", nrow(links), "\n")

# ── Prepare Data for ggsynteny ─────────────────────────────────────────────

# The data is already in the correct format!
# features has: bin_id, seq_id, start, end, strand, feat_id, name
# links has: bin_id, feat_id, bin_id2, feat_id2

# We need to rename columns for ggsynteny compatibility:
# bin_id → bin_id (already correct)
# feat_id → feat_id (already correct)
# We need to add identity column to links (we'll use a default value)

links_formatted <- links %>%
  rename(feat_id_a = feat_id,
         feat_id_b = feat_id2) %>%
  select(feat_id_a, feat_id_b) %>%
  mutate(identity = 90)  # Default identity score since not provided

# ── Define Species Order ───────────────────────────────────────────────────

# Define the order of genomes (top to bottom)
bin_order <- c("ZONMW-30", "ZONMW-20", "HI1", "DSM1208",
               "DSM15718", "DD5b", "UW101", "IR1")

# ── Create Custom Gene Color Palette ──────────────────────────────────────

# Define colors for specific genes (similar to the original paper)
gene_palette <- c(
  moaE   = "#E06C75",  # Red
  moaC2  = "#61AFEF",  # Blue
  moaC   = "#56B6C2",  # Cyan
  moaA   = "#98C379",  # Green
  moeA   = "#E5C07B",  # Yellow
  mobA   = "#C678DD",  # Purple
  moeZ   = "#D19A66",  # Orange
  moaD   = "#ABB2BF",  # Light gray
  moaB   = "#5C6370",  # Dark gray
  sumT   = "#BE5046",  # Dark red
  z_spacer = "#FFFFFF" # White (invisible)
)

# ── Plot 1: Full Synteny Across All 8 Species ─────────────────────────────

p1 <- plot_microsynteny(
  features,
  links_formatted,
  bin_order = bin_order,
  tier_spacing = 6,
  gene_fill = "per_name",
  gene_palette = gene_palette,
  ribbon_fill = "per_name",
  ribbon_palette = gene_palette,
  ribbon_alpha = 0.35,
  label_genes = TRUE,
  label_size = 2.2,
  bin_label_size = 4,
  title = "Microsynteny: moa/moe Gene Cluster Across 8 Bacterial Species"
)

print(p1)

# Save high-resolution version
ggsave("/Users/theodosiou/Documents/Projects/ggsynteny/ggsynteny_pkg/data-raw/bacterial_synteny_full.png",
       p1, width = 16, height = 12, dpi = 300, bg = "white")

# ── Plot 2: Subset - Focus on ZONMW Genomes ───────────────────────────────

# Filter for specific genomes
zonmw_features <- features %>%
  filter(bin_id %in% c("ZONMW-30", "ZONMW-20", "HI1"))

zonmw_links <- links_formatted %>%
  filter(feat_id_a %in% zonmw_features$feat_id,
         feat_id_b %in% zonmw_features$feat_id)

p2 <- plot_microsynteny(
  zonmw_features,
  zonmw_links,
  bin_order = c("ZONMW-30", "ZONMW-20", "HI1"),
  tier_spacing = 8,
  gene_fill = "per_name",
  gene_palette = gene_palette,
  ribbon_fill = "identity",  # Use identity-based coloring
  ribbon_alpha = 0.4,
  label_genes = TRUE,
  label_size = 2.8,
  bin_label_size = 5,
  title = "Microsynteny: ZONMW-30, ZONMW-20, and HI1"
)

print(p2)

ggsave("/Users/theodosiou/Documents/Projects/ggsynteny/ggsynteny_pkg/data-raw/bacterial_synteny_zonmw.png",
       p2, width = 14, height = 8, dpi = 300, bg = "white")

# ── Plot 3: Compact Version Without Labels ────────────────────────────────

p3 <- plot_microsynteny(
  features,
  links_formatted,
  bin_order = bin_order,
  tier_spacing = 4,
  gene_height = 0.3,
  gene_fill = "per_name",
  gene_palette = gene_palette,
  ribbon_fill = "per_name",
  ribbon_palette = gene_palette,
  ribbon_alpha = 0.3,
  label_genes = FALSE,  # Hide gene labels for compact view
  bin_label_size = 3.5,
  title = "Compact View: Gene Synteny Without Labels"
)

print(p3)

ggsave("/Users/theodosiou/Documents/Projects/ggsynteny/ggsynteny_pkg/data-raw/bacterial_synteny_compact.png",
       p3, width = 14, height = 10, dpi = 300, bg = "white")

# ── Plot 4: Uniform Gene Colors with Identity-Based Ribbons ───────────────

p4 <- plot_microsynteny(
  features,
  links_formatted,
  bin_order = bin_order,
  tier_spacing = 6,
  gene_fill = "uniform",
  gene_palette = "#AEC6CF",  # Light blue for all genes
  ribbon_fill = "identity",
  identity_low = "#FEF5E7",   # Light yellow
  identity_high = "#E74C3C",  # Red
  ribbon_alpha = 0.5,
  label_genes = TRUE,
  label_size = 2,
  title = "Identity-Based Ribbon Colors"
)

print(p4)

ggsave("/Users/theodosiou/Documents/Projects/ggsynteny/ggsynteny_pkg/data-raw/bacterial_synteny_identity.png",
       p4, width = 14, height = 12, dpi = 300, bg = "white")

# ── Summary Statistics ─────────────────────────────────────────────────────

cat("\n=== Summary Statistics ===\n")
cat("Total genomes analyzed:", length(unique(features$bin_id)), "\n")
cat("Total genes plotted:", nrow(features[features$name != "z_spacer", ]), "\n")
cat("Total homology links:", nrow(links_formatted), "\n")

# Count genes per genome
gene_counts <- features %>%
  filter(name != "z_spacer") %>%
  group_by(bin_id, name) %>%
  summarise(count = n(), .groups = "drop") %>%
  tidyr::pivot_wider(names_from = name, values_from = count, values_fill = 0)

cat("\nGene presence across genomes:\n")
print(as.data.frame(gene_counts))

# ── Export Data Summary ────────────────────────────────────────────────────

# Save a summary table
summary_table <- features %>%
  filter(name != "z_spacer") %>%
  group_by(bin_id) %>%
  summarise(
    n_contigs = n_distinct(seq_id),
    n_genes = n(),
    genes = paste(unique(name), collapse = ", ")
  )

write_csv(summary_table,
          "/Users/theodosiou/Documents/Projects/ggsynteny/ggsynteny_pkg/data-raw/bacterial_synteny_summary.csv")

cat("\nSummary saved to: bacterial_synteny_summary.csv\n")

# ── Comparison with Original gggenomes Plot ───────────────────────────────

cat("\n=== Comparison Notes ===\n")
cat("This data was originally plotted with gggenomes.\n")
cat("Our ggsynteny package provides:\n")
cat("  - Similar visualization capabilities\n")
cat("  - More flexible color control\n")
cat("  - Simpler interface for common tasks\n")
cat("  - Better integration with standard ggplot2 workflows\n")
cat("\nOriginal script: /Users/theodosiou/Documents/Projects/genes_synteny/scripts/synteny.r\n")
cat("Original figure: /Users/theodosiou/Documents/Projects/genes_synteny/figures/synteny.png\n")
