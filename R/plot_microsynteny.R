# ═══════════════════════════════════════════════════════════════════════════
# Microsynteny Plotting Function
# ═══════════════════════════════════════════════════════════════════════════

#' Plot micro-synteny across multiple genomes/bins
#'
#' Draws gene-level synteny (microsynteny) showing individual genes as arrows
#' with ribbons connecting homologous genes across genomes.
#'
#' @param features Data frame with columns: bin_id, seq_id, start, end, strand, feat_id, name
#' @param links Data frame with columns: feat_id_a, feat_id_b, identity (optional)
#' @param bin_order Character vector, top to bottom display order
#' @param palette A palette for the whole plot: the name of a built-in palette
#'   (all 32 ltc palettes, e.g. `"casa_natal"` or `"minou"`; list them with
#'   \code{\link{syn_palettes}}), `"Okabe-Ito"`, or a vector of colors. Used
#'   for genes and ribbons unless `gene_palette` / `ribbon_palette` override
#'   it. With `ribbon_fill = "identity"`, it becomes the identity color ramp
#'   (try an ordered palette such as `"heatmap0"`).
#' @param tier_spacing Numeric, vertical spacing between bins (default 6)
#' @param gene_height Numeric, gene arrow half-height (default 0.35)
#' @param arrowhead_frac Numeric, arrowhead size as fraction of gene length (default 0.18)
#' @param contig_gap_frac Numeric, gap between contigs as fraction of max gene size (default 0.04)
#' @param curvature Numeric, ribbon curve strength 0-1 (default 0.5)
#' @param gene_fill Gene coloring mode: "per_name", "per_feat", or "uniform"
#' @param gene_palette Named vector of colors for genes
#' @param gene_color Gene outline color (default "#333333")
#' @param gene_alpha Gene transparency 0-1 (default 0.95)
#' @param ribbon_fill Ribbon coloring mode: "identity", "per_name", or "uniform"
#' @param ribbon_palette Named vector of colors for ribbons
#' @param ribbon_alpha Ribbon transparency 0-1 (default 0.35)
#' @param identity_low Color for low identity ribbons (default "#DCEEFF")
#' @param identity_high Color for high identity ribbons (default "#08519C")
#' @param label_genes Logical, show gene name labels (default TRUE)
#' @param label_size Gene label size (default 2.5)
#' @param bin_label_size Bin label size (default 4.5)
#' @param label_offset Vertical offset for gene labels (default 0.25)
#' @param title Optional plot title
#'
#' @return A ggplot2 object
#'
#' @details
#' \strong{Input Requirements:}
#'
#' The \code{features} data frame must contain:
#' \itemize{
#'   \item bin_id: genome/bin name (used as row label)
#'   \item seq_id: contig/chromosome (for grouping)
#'   \item start: gene start position (bp)
#'   \item end: gene end position (bp)
#'   \item strand: "+" or "-"
#'   \item feat_id: unique gene identifier
#'   \item name: gene name (for labels and coloring)
#' }
#'
#' The \code{links} data frame must contain:
#' \itemize{
#'   \item feat_id_a: gene in top genome
#'   \item feat_id_b: gene in bottom genome
#'   \item identity: optional 0-100 (for ribbon color intensity)
#' }
#'
#' @examples
#' \dontrun{
#' # See demo_microsynteny() for example data
#' p <- plot_microsynteny(features, links,
#'                        bin_order = c("ZONMW-30", "ZONMW-20", "ZONMW-10"),
#'                        gene_fill = "per_name",
#'                        ribbon_fill = "identity")
#' }
#'
#' @export
#' @import ggplot2
#' @importFrom dplyr filter arrange group_by mutate ungroup left_join select summarise first bind_rows rename
plot_microsynteny <- function(features,
                              links,
                              bin_order       = NULL,
                              palette         = NULL,

                              # Layout
                              tier_spacing    = 6,
                              gene_height     = 0.35,
                              arrowhead_frac  = 0.18,
                              contig_gap_frac = 0.04,
                              curvature       = 0.5,

                              # Gene coloring
                              gene_fill       = "per_name",
                              gene_palette    = NULL,
                              gene_color      = "#333333",
                              gene_alpha      = 0.95,

                              # Ribbon coloring
                              ribbon_fill     = "identity",
                              ribbon_palette  = NULL,
                              ribbon_alpha    = 0.35,
                              identity_low    = "#DCEEFF",
                              identity_high   = "#08519C",

                              # Labels
                              label_genes     = TRUE,
                              label_size      = 2.5,
                              bin_label_size  = 4.5,
                              label_offset    = 0.25,

                              title           = NULL) {

  # ── Validate ──
  gene_fill   <- match.arg(gene_fill, c("per_name", "per_feat", "uniform"))
  ribbon_fill <- match.arg(ribbon_fill, c("identity", "per_name", "uniform"))

  req_f <- c("bin_id","seq_id","start","end","strand","feat_id","name")
  req_l <- c("feat_id_a","feat_id_b")
  miss_f <- setdiff(req_f, names(features))
  miss_l <- setdiff(req_l, names(links))
  if (length(miss_f) > 0) stop("features missing: ", paste(miss_f, collapse=", "))
  if (length(miss_l) > 0) stop("links missing: ",    paste(miss_l, collapse=", "))

  if (is.null(bin_order)) bin_order <- unique(features$bin_id)
  if (!"identity" %in% names(links)) links$identity <- 80

  h <- gene_height

  # ── Y positions ──
  bin_y <- stats::setNames(
    rev(seq(0, by = tier_spacing, length.out = length(bin_order))),
    bin_order
  )

  # ── Build gene layout ──
  max_gene  <- max(features$end - features$start, na.rm = TRUE)
  contig_gap <- max_gene * contig_gap_frac

  layout_list <- list()

  for (bin in bin_order) {
    bin_feats  <- features %>% filter(bin_id == bin) %>% arrange(seq_id, start)
    contigs    <- unique(bin_feats$seq_id)
    cum_offset <- 0

    for (cid in contigs) {
      cf      <- bin_feats %>% filter(seq_id == cid)
      min_pos <- min(cf$start)

      layout_list[[length(layout_list) + 1]] <- cf %>%
        mutate(
          x0 = start - min_pos + cum_offset,
          x1 = end   - min_pos + cum_offset,
          y  = bin_y[[bin]]
        )

      cum_offset <- cum_offset + (max(cf$end) - min_pos) + contig_gap
    }
  }

  layout <- bind_rows(layout_list)

  # ── Center bins ──
  bin_widths <- layout %>%
    group_by(bin_id) %>%
    summarise(bw = max(x1), .groups = "drop")

  max_w <- max(bin_widths$bw)

  layout <- layout %>%
    left_join(bin_widths, by = "bin_id") %>%
    mutate(
      x0 = x0 + (max_w - bw) / 2,
      x1 = x1 + (max_w - bw) / 2
    ) %>%
    select(-bw)

  # ── Gene fill colors ──
  gene_spec <- gene_palette %||% palette

  if (gene_fill == "uniform") {
    layout$fill_color <- if (is.null(gene_spec)) "#AEC6CF"
                         else if (is_palette_name(gene_spec)) syn_pal(gene_spec, 1)
                         else gene_spec

  } else if (gene_fill == "per_name") {
    keys <- unique(layout$name)
    pal <- keyed_colors(gene_spec, keys)
    layout$fill_color <- pal[layout$name]

  } else {
    keys <- unique(layout$feat_id)
    pal <- keyed_colors(gene_spec, keys)
    layout$fill_color <- pal[layout$feat_id]
  }

  layout$fill_color[is.na(layout$fill_color)] <- "#CCCCCC"

  # ── Body coordinates (ribbon anchors exclude the arrowhead) ──
  layout <- layout %>%
    mutate(
      head_w  = (x1 - x0) * arrowhead_frac,
      body_x0 = ifelse(strand == "+", x0,          x0 + head_w),
      body_x1 = ifelse(strand == "+", x1 - head_w, x1)
    )

  # ── Ribbon colors ──
  feat_pos <- layout %>% select(feat_id, body_x0, body_x1, y)

  links_xy <- links %>%
    left_join(feat_pos, by = c("feat_id_a" = "feat_id")) %>%
    rename(xa0 = body_x0, xa1 = body_x1, ya = y) %>%
    left_join(feat_pos, by = c("feat_id_b" = "feat_id")) %>%
    rename(xb0 = body_x0, xb1 = body_x1, yb = y) %>%
    filter(!is.na(xa0), !is.na(xb0))

  ribbon_spec <- ribbon_palette %||% palette

  if (ribbon_fill == "identity") {
    if (!is.null(ribbon_spec) && (is_palette_name(ribbon_spec) || length(ribbon_spec) > 1)) {
      # Use the palette as the identity ramp (interpolated end-to-end)
      ramp <- syn_pal(ribbon_spec, 101, continuous = TRUE)
      idx  <- round(pmin(pmax(links_xy$identity, 0), 100)) + 1
      links_xy$ribbon_color <- ramp[idx]
    } else {
      links_xy$ribbon_color <- identity_color(links_xy$identity, identity_low, identity_high)
    }

  } else if (ribbon_fill == "per_name") {
    name_lu <- layout %>% select(feat_id, name)
    links_xy <- links_xy %>% left_join(name_lu, by = c("feat_id_a" = "feat_id"))
    keys <- unique(links_xy$name)
    pal <- keyed_colors(ribbon_spec, keys)
    links_xy$ribbon_color <- pal[links_xy$name]

  } else {
    links_xy$ribbon_color <- if (is.null(ribbon_spec)) "#6688AA"
                             else if (is_palette_name(ribbon_spec)) syn_pal(ribbon_spec, 1)
                             else ribbon_spec
  }

  links_xy$ribbon_color[is.na(links_xy$ribbon_color)] <- "#888888"

  # ── Build ribbon polygons ──
  ribbon_df <- lapply(seq_len(nrow(links_xy)), function(i) {
    row  <- links_xy[i, ]
    poly <- bezier_ribbon(row$xa0, row$xa1, row$ya - h,
                           row$xb0, row$xb1, row$yb + h,
                           curvature = curvature)
    poly$link_id      <- i
    poly$ribbon_color <- row$ribbon_color
    poly
  }) %>% bind_rows()

  # ── Build gene arrow polygons ──
  arrow_df <- lapply(seq_len(nrow(layout)), function(i) {
    row  <- layout[i, ]
    poly <- arrow_poly(row$x0, row$x1, row$y, h,
                        frac   = arrowhead_frac,
                        strand = row$strand)
    poly$feat_id    <- row$feat_id
    poly$fill_color <- row$fill_color
    poly
  }) %>% bind_rows()

  # ── Contig separators ──
  sep_df <- layout %>%
    group_by(bin_id, seq_id) %>%
    summarise(x_right = max(x1), y = first(y), .groups = "drop") %>%
    group_by(bin_id) %>%
    filter(dplyr::n() > 1, x_right < max(x_right)) %>%
    ungroup() %>%
    mutate(x_sep = x_right + contig_gap / 2)

  # ── Labels ──
  min_y    <- min(layout$y)
  label_df <- layout %>%
    mutate(
      lx    = (x0 + x1) / 2,
      ly    = ifelse(y == min_y, y - h - label_offset, y + h + label_offset),
      vjust = ifelse(y == min_y, 1, 0)
    )

  max_chars <- max(nchar(bin_order))
  name_df   <- data.frame(
    x     = -contig_gap * 2,
    y     = unname(bin_y[bin_order]),
    label = bin_order,
    stringsAsFactors = FALSE
  )

  left_bound <- -(max_chars * 1.8 + contig_gap * 4)

  # ── PLOT ──
  p <- ggplot()

  # Layer 1: ribbons
  if (nrow(ribbon_df) > 0) {
    p <- p + geom_polygon(data  = ribbon_df,
                          aes(x = x, y = y, group = link_id),
                          fill  = ribbon_df$ribbon_color,
                          alpha = ribbon_alpha,
                          color = NA)
  }

  # Layer 2: gene arrows
  p <- p + geom_polygon(data      = arrow_df,
                        aes(x = x, y = y, group = feat_id),
                        fill      = arrow_df$fill_color,
                        color     = gene_color,
                        linewidth = 0.3,
                        alpha     = gene_alpha)

  # Layer 3: contig separators
  if (nrow(sep_df) > 0) {
    p <- p + geom_segment(
      data      = sep_df,
      aes(x = x_sep, xend = x_sep,
          y = y - h * 1.4, yend = y + h * 1.4),
      linetype  = "dashed",
      color     = "#AAAAAA",
      linewidth = 0.4
    )
  }

  # Layer 4: gene labels
  if (label_genes) {
    p <- p + geom_text(
      data     = label_df,
      aes(x = lx, y = ly, label = name, vjust = vjust),
      size     = label_size,
      fontface = "italic",
      color    = "#333333"
    )
  }

  # Layer 5: bin labels
  p <- p + geom_text(
    data     = name_df,
    aes(x = x, y = y, label = label),
    hjust    = 1,
    size     = bin_label_size,
    fontface = "bold",
    color    = "#222222"
  )

  p <- p +
    coord_cartesian(
      xlim = c(left_bound, max_w + contig_gap),
      ylim = c(min(layout$y) - tier_spacing * 0.65,
               max(layout$y) + tier_spacing * 0.65),
      clip = "off"
    ) +
    theme_void() +
    theme(plot.margin = margin(10, 20, 10, max_chars * 5))

  if (!is.null(title)) p <- p + ggtitle(title)

  return(p)
}
