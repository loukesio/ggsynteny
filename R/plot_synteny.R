# ═══════════════════════════════════════════════════════════════════════════
# Main Synteny Plotting Function
# ═══════════════════════════════════════════════════════════════════════════

#' Plot macro-synteny across multiple species
#'
#' Creates publication-quality synteny plots showing chromosomal relationships
#' across multiple species with flexible coloring options.
#'
#' @param syn_data List containing `chromosomes` and `blocks` data frames.
#'   See \code{\link{example_synteny_data}} for format.
#' @param species_order Character vector specifying species display order (top to bottom)
#' @param palette A palette for the whole plot: the name of a built-in palette
#'   (all 32 ltc palettes, e.g. `"casa_natal"` or `"minou"`; list them with
#'   \code{\link{syn_palettes}}), `"Okabe-Ito"`, or a vector of colors. Used
#'   for both chromosomes and ribbons unless `chr_palette` / `ribbon_palette`
#'   override it.
#' @param tier_spacing Numeric, vertical spacing between species tiers (default 18)
#' @param chr_fill Chromosome coloring mode: "per_species", "uniform", "per_chr", or "custom"
#' @param chr_palette Color palette for chromosomes: a built-in palette name,
#'   an unnamed color vector, or a named vector mapping keys to colors (see Details)
#' @param ribbon_fill Ribbon coloring mode: "source_chr", "target_chr", "species_pair", "uniform", or "custom"
#' @param ribbon_palette Color palette for ribbons: a built-in palette name,
#'   an unnamed color vector, or a named vector mapping keys to colors (see Details)
#' @param ribbon_alpha Ribbon transparency (0-1, default 0.30)
#' @param curvature Ribbon curve strength (0-1, default 0.55)
#' @param chr_radius Corner radius of the chromosome boxes in millimetres
#'   (default 0 = square corners). Try 1-2 mm for gently rounded
#'   chromosomes; rounding uses \pkg{ggforce}, so it looks right at any
#'   figure size. Not available together with `interactive = TRUE`
#'   (square corners are drawn instead, with a warning).
#' @param label_size Chromosome label size (default 2.5)
#' @param species_label_size Species label size (default 4.5)
#' @param interactive Logical; make chromosomes and ribbons interactive
#'   (hover highlight and tooltips) using \pkg{ggiraph}? Render the result
#'   with [syn_girafe()]. Default `FALSE`.
#' @param title Optional plot title
#'
#' @return A ggplot2 object (pass to [syn_girafe()] to render an interactive
#'   widget when `interactive = TRUE`)
#'
#' @details
#' \strong{Chromosome Coloring (chr_fill):}
#' \itemize{
#'   \item "per_species" — one color per species. chr_palette = "casa_natal" or c("Human" = "#4477AA", ...)
#'   \item "uniform" — all chromosomes same color. chr_palette = "#E8E4DF"
#'   \item "per_chr" — one color per chromosome label. chr_palette = "casa_natal" or c("1" = "#4477AA", ...)
#'   \item "custom" — full control. chr_palette as named vector with "species__chr" keys
#' }
#'
#' \strong{Ribbon Coloring (ribbon_fill):}
#' \itemize{
#'   \item "source_chr" — colored by the source (top) chromosome
#'   \item "target_chr" — colored by the target (bottom) chromosome
#'   \item "species_pair" — one color per tier gap. ribbon_palette = c("At_Vv" = "#3A6EA5", ...)
#'   \item "uniform" — all same color. ribbon_palette = "#6688AA"
#'   \item "custom" — per-block. ribbon_palette = vector of colors
#' }
#'
#' Wherever a palette is expected, a single unnamed string is first matched
#' against the built-in palette names (case-insensitively, ignoring spaces,
#' underscores and dashes) — so `"casa_natal"`, `"Casa Natal"` and
#' `"casanatal"` all find the same palette. Named vectors are used as
#' explicit key-to-color mappings, exactly as before.
#'
#' @examples
#' # Load example data
#' syn <- example_synteny_data()
#' sp_order <- c("Arabidopsis", "Grape", "Rice")
#'
#' # Default: per-species chromosomes + source-chr ribbons
#' p <- plot_synteny(syn, sp_order)
#'
#' # One ltc palette for the whole plot
#' p <- plot_synteny(syn, sp_order, palette = "casa_natal")
#'
#' # Custom colors
#' p <- plot_synteny(syn, sp_order,
#'                   chr_fill = "uniform",
#'                   chr_palette = "#E8E4DF",
#'                   ribbon_fill = "species_pair",
#'                   ribbon_palette = c("Arabidopsis_Grape" = "#3A6EA5",
#'                                      "Grape_Rice" = "#E8573A"))
#'
#' @export
#' @import ggplot2
#' @importFrom dplyr filter arrange group_by mutate ungroup left_join select summarise first bind_rows
plot_synteny <- function(syn_data, species_order,
                         palette = NULL,
                         tier_spacing = 18,
                         # Chromosome coloring
                         chr_fill = "per_species",
                         chr_palette = NULL,
                         # Ribbon coloring
                         ribbon_fill = "source_chr",
                         ribbon_palette = NULL,
                         ribbon_alpha = 0.30,
                         # Layout
                         curvature = 0.55,
                         chr_radius = 0,
                         label_size = 2.5,
                         species_label_size = 4.5,
                         interactive = FALSE,
                         title = NULL) {

  chr_fill    <- match.arg(chr_fill, c("per_species", "uniform", "per_chr", "custom"))
  ribbon_fill <- match.arg(ribbon_fill,
                           c("source_chr", "target_chr", "species_pair", "uniform", "custom"))

  if (interactive && !requireNamespace("ggiraph", quietly = TRUE)) {
    stop("interactive = TRUE requires the 'ggiraph' package. ",
         "Install it with install.packages('ggiraph').", call. = FALSE)
  }
  if (chr_radius > 0 && interactive) {
    warning("chr_radius is not available for interactive layers; ",
            "drawing square corners.", call. = FALSE)
    chr_radius <- 0
  }
  if (chr_radius > 0 && !requireNamespace("ggforce", quietly = TRUE)) {
    stop("chr_radius > 0 requires the 'ggforce' package. ",
         "Install it with install.packages('ggforce').", call. = FALSE)
  }

  CHR_HEIGHT <- 0.9
  LABEL_OFF <- 1.5

  chrs   <- syn_data$chromosomes
  blocks <- syn_data$blocks
  h      <- CHR_HEIGHT

  # ── Y positions ──
  species_y <- stats::setNames(
    rev(seq(0, by = tier_spacing, length.out = length(species_order))),
    species_order
  )

  # ── Chromosome layout ──
  # Sort chromosomes numerically when the labels are numbers, alphabetically
  # otherwise (so "contig_2" style names don't produce NA warnings).
  chr_layout <- chrs %>%
    filter(species %in% species_order) %>%
    mutate(.chr_num = suppressWarnings(as.numeric(chr))) %>%
    arrange(factor(species, levels = species_order), .chr_num, chr) %>%
    select(-.chr_num) %>%
    group_by(species) %>%
    mutate(
      cumstart = cumsum(dplyr::lag(size, default = 0) + 0.8),
      xmin = cumstart,
      xmax = cumstart + size,
      y = species_y[first(species)]
    ) %>%
    ungroup()

  # ── Center chromosomes per species ──
  species_widths <- chr_layout %>%
    group_by(species) %>%
    summarise(total_width = max(xmax), .groups = "drop")

  max_width <- max(species_widths$total_width)

  chr_layout <- chr_layout %>%
    left_join(species_widths, by = "species") %>%
    mutate(
      offset = (max_width - total_width) / 2,
      xmin   = xmin + offset,
      xmax   = xmax + offset
    ) %>%
    select(-total_width, -offset)

  # ── Resolve chromosome colors ──
  chr_spec <- chr_palette %||% palette

  if (chr_fill == "uniform") {
    fill_val <- if (is.null(chr_spec)) "#E8E4DF"
                else if (is_palette_name(chr_spec)) syn_pal(chr_spec, 1)
                else chr_spec
    chr_layout$fill_color <- fill_val

  } else if (chr_fill == "per_species") {
    if (is.null(chr_spec)) {
      pal <- stats::setNames(
        grDevices::hcl(h = seq(15, 375, length.out = length(species_order) + 1)[1:length(species_order)],
            c = 30, l = 80),
        species_order
      )
    } else {
      pal <- keyed_colors(chr_spec, species_order)
    }
    chr_layout$fill_color <- pal[chr_layout$species]

  } else if (chr_fill == "per_chr") {
    all_labels <- sort(unique(chr_layout$chr))
    pal <- keyed_colors(chr_spec, all_labels)
    chr_layout$fill_color <- pal[chr_layout$chr]

  } else if (chr_fill == "custom") {
    chr_layout$fill_color <- chr_spec[paste0(chr_layout$species, "__", chr_layout$chr)]
  }

  chr_layout$fill_color[is.na(chr_layout$fill_color)] <- "#D4CBC3"

  # ── Build connections ──
  conn_list <- list()
  for (i in seq_len(length(species_order) - 1)) {
    sp_top <- species_order[i]
    sp_bot <- species_order[i + 1]

    tier_blocks <- blocks %>%
      filter(
        (species1 == sp_top & species2 == sp_bot) |
        (species1 == sp_bot & species2 == sp_top)
      ) %>%
      mutate(
        sp_a = ifelse(species1 == sp_top, species1, species2),
        sp_b = ifelse(species1 == sp_top, species2, species1),
        chr_a = ifelse(species1 == sp_top, chr1, chr2),
        chr_b = ifelse(species1 == sp_top, chr2, chr1),
        s_a = ifelse(species1 == sp_top, start1, start2),
        e_a = ifelse(species1 == sp_top, end1, end2),
        s_b = ifelse(species1 == sp_top, start2, start1),
        e_b = ifelse(species1 == sp_top, end2, end1)
      )

    for (j in seq_len(nrow(tier_blocks))) {
      row <- tier_blocks[j, ]
      top_chr <- chr_layout %>% filter(species == row$sp_a, chr == row$chr_a)
      bot_chr <- chr_layout %>% filter(species == row$sp_b, chr == row$chr_b)
      if (nrow(top_chr) == 0 || nrow(bot_chr) == 0) next

      pair_key <- paste0(row$sp_a, "_", row$sp_b)

      conn_list[[length(conn_list) + 1]] <- data.frame(
        sx0 = top_chr$xmin + row$s_a,
        sx1 = top_chr$xmin + row$e_a,
        sy  = top_chr$y,
        tx0 = bot_chr$xmin + row$s_b,
        tx1 = bot_chr$xmin + row$e_b,
        ty  = bot_chr$y,
        chr_a = row$chr_a,
        chr_b = row$chr_b,
        pair  = pair_key,
        tooltip = paste0(row$sp_a, " ", row$chr_a, ": ", row$s_a, "\u2013", row$e_a,
                         " \u2194 ",
                         row$sp_b, " ", row$chr_b, ": ", row$s_b, "\u2013", row$e_b),
        stringsAsFactors = FALSE
      )
    }
  }
  connections <- bind_rows(conn_list)

  # ── Resolve ribbon colors ──
  ribbon_spec <- ribbon_palette %||% palette

  if (nrow(connections) > 0) {
    connections$conn_id <- seq_len(nrow(connections))

    if (ribbon_fill == "uniform") {
      fill_val <- if (is.null(ribbon_spec)) "#6688AA"
                  else if (is_palette_name(ribbon_spec)) syn_pal(ribbon_spec, 1)
                  else ribbon_spec
      connections$ribbon_color <- fill_val

    } else if (ribbon_fill == "source_chr") {
      all_src <- sort(unique(connections$chr_a))
      pal <- keyed_colors(ribbon_spec, all_src)
      connections$ribbon_color <- pal[connections$chr_a]

    } else if (ribbon_fill == "target_chr") {
      all_tgt <- sort(unique(connections$chr_b))
      pal <- keyed_colors(ribbon_spec, all_tgt)
      connections$ribbon_color <- pal[connections$chr_b]

    } else if (ribbon_fill == "species_pair") {
      pair_keys <- unique(connections$pair)
      pal <- keyed_colors(ribbon_spec, pair_keys)
      connections$ribbon_color <- pal[connections$pair]

    } else if (ribbon_fill == "custom") {
      connections$ribbon_color <- ribbon_spec
    }
    connections$ribbon_color[is.na(connections$ribbon_color)] <- "#888888"
  }

  # ── Build ribbon polygons ──
  ribbon_df <- NULL
  if (nrow(connections) > 0) {
    ribbon_list <- lapply(seq_len(nrow(connections)), function(i) {
      row <- connections[i, ]
      poly <- bezier_ribbon(row$sx0, row$sx1, row$sy - h,
                            row$tx0, row$tx1, row$ty + h,
                            curvature = curvature)
      poly$conn_id <- i
      poly$ribbon_color <- row$ribbon_color
      poly$tooltip <- row$tooltip
      poly
    })
    ribbon_df <- bind_rows(ribbon_list)
  }

  # ── Labels ──
  min_y <- min(chr_layout$y)
  label_df <- chr_layout %>%
    mutate(
      lx = xmin + size / 2,
      ly = ifelse(y == min_y, y - h - LABEL_OFF, y + h + LABEL_OFF)
    )

  name_df <- data.frame(
    x = -4, y = species_y,
    label = names(species_y),
    stringsAsFactors = FALSE
  )

  # ── PLOT ──
  p <- ggplot()

  # Layer 1: ribbons (background)
  if (!is.null(ribbon_df)) {
    if (interactive) {
      p <- p + ggiraph::geom_polygon_interactive(
        data = ribbon_df,
        aes(x = x, y = y, group = conn_id,
            tooltip = tooltip, data_id = paste0("block_", conn_id)),
        fill = ribbon_df$ribbon_color, alpha = ribbon_alpha,
        color = NA
      )
    } else {
      p <- p + geom_polygon(
        data = ribbon_df,
        aes(x = x, y = y, group = conn_id),
        fill = ribbon_df$ribbon_color, alpha = ribbon_alpha,
        color = NA
      )
    }
  }

  # Layer 2: chromosomes (foreground)
  if (interactive) {
    chr_layout$tooltip <- paste0(chr_layout$species, " \u2014 chr ", chr_layout$chr,
                                 " (", chr_layout$size, ")")
    p <- p + ggiraph::geom_rect_interactive(
      data = chr_layout,
      aes(xmin = xmin, xmax = xmax, ymin = y - h, ymax = y + h,
          tooltip = tooltip, data_id = paste0(species, "__", chr)),
      fill = chr_layout$fill_color, color = "black",
      linewidth = 0.4, alpha = 0.95
    )
  } else if (chr_radius > 0) {
    # Rounded corners via ggforce::geom_shape (radius in absolute mm, so the
    # rounding is consistent whatever the data scales are)
    chr_poly <- data.frame(
      x = as.vector(rbind(chr_layout$xmin, chr_layout$xmax,
                          chr_layout$xmax, chr_layout$xmin)),
      y = as.vector(rbind(chr_layout$y - h, chr_layout$y - h,
                          chr_layout$y + h, chr_layout$y + h)),
      chr_id = rep(seq_len(nrow(chr_layout)), each = 4)
    )
    p <- p + ggforce::geom_shape(
      data = chr_poly,
      aes(x = x, y = y, group = chr_id),
      fill = rep(chr_layout$fill_color, each = 4), color = "black",
      linewidth = 0.4, alpha = 0.95,
      radius = grid::unit(chr_radius, "mm")
    )
  } else {
    p <- p + geom_rect(
      data = chr_layout,
      aes(xmin = xmin, xmax = xmax, ymin = y - h, ymax = y + h),
      fill = chr_layout$fill_color, color = "black",
      linewidth = 0.4, alpha = 0.95
    )
  }

  # Layer 3: labels
  max_label_chars <- max(nchar(names(species_y)))
  left_bound      <- -(max_label_chars * 1.8 + 6)

  p <- p +
    geom_text(
      data = label_df,
      aes(x = lx, y = ly, label = chr),
      size = label_size, fontface = "bold"
    ) +
    geom_text(
      data = name_df,
      aes(x = x, y = y, label = label),
      hjust = 1, size = species_label_size,
      fontface = "bold.italic"
    ) +
    coord_cartesian(
      xlim = c(left_bound, max(chr_layout$xmax) + 5),
      ylim = c(min(chr_layout$y) - 6, max(chr_layout$y) + 6),
      clip = "off"
    ) +
    theme_void() +
    theme(plot.margin = margin(10, 30, 10, max_label_chars * 3))

  if (!is.null(title)) {
    p <- p + ggtitle(title)
  }

  return(p)
}
