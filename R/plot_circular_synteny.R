#' Plot chromosome-level synteny around a circle
#'
#' Arrange chromosomes as proportional arcs grouped by species, and connect
#' syntenic intervals with ribbons inside the circle. Returns an ordinary
#' ggplot2 object with polygon and text layers.
#'
#' @param syn_data List containing `chromosomes` and `blocks`, in the same format
#'   as [plot_synteny()]. All sizes and coordinates must use the same unit.
#' @param species_order Species in circular display order. Defaults to first
#'   appearance in `chromosomes`; may select a subset.
#' @param palette Built-in ltc name (e.g. `"casa_natal"`), `"Okabe-Ito"`, HCL
#'   palette name, or color vector. See [syn_palettes()].
#' @param chr_fill Chromosome coloring: `"uniform"`, `"per_species"`,
#'   `"per_chr"`, or `"custom"`.
#' @param chr_palette Overrides `palette` for chromosomes. Named vectors map
#'   species, chromosome labels, or `"species__chr"` keys in custom mode.
#' @param chr_color Chromosome outline color.
#' @param ribbon_fill Ribbon coloring: `"source_chr"`, `"target_chr"`,
#'   `"species_pair"`, `"uniform"`, or `"custom"`. Source is the earlier species
#'   in `species_order` (input order for within-species blocks).
#' @param ribbon_palette Overrides `palette` for ribbons. In custom mode, provide
#'   one color or one color per row of the original `blocks` table.
#' @param ribbon_alpha Ribbon transparency, between 0 and 1.
#' @param gap Gap between chromosomes within a species, in degrees.
#' @param group_gap Gap between species, in degrees.
#' @param start_angle Angle where the first sector starts, in degrees; 90 is top.
#' @param clockwise Draw increasing genomic coordinates clockwise?
#' @param curvature Pull of ribbon control points toward the center (0 to 1).
#' @param track_width Radial thickness of chromosomes; the outer radius is 1.
#' @param label_size Chromosome label size in mm. Set to 0 to hide labels.
#' @param species_label_size Species label size in mm. Set to 0 to hide labels.
#' @param show_orientation Connect genomic endpoints according to the
#'   `orientation` column (`"plus"` or `"minus"`)? Default `FALSE` draws coverage
#'   ribbons. Around a circle, a twist alone does not identify an inversion:
#'   the direction in which both chromosomes are drawn also matters.
#' @param interactive Build ggiraph layers for rendering with [syn_girafe()]?
#' @param title Optional title.
#' @return A ggplot object. Its `data` contains the sector layout, including
#'   genomic bounds and angles in radians. The `circular_links` attribute records
#'   the displayed block rows and their angular endpoints.
#' @details Sector widths are proportional to chromosome lengths across all
#'   displayed species. Ribbons attach at the supplied genomic coordinates;
#'   all available pairs among displayed species are shown, including
#'   non-adjacent species and within-species blocks. This is a genomic-coordinate
#'   view, not an aggregation of link counts or an estimate of unique coverage.
#'
#'   The circular presentation does not imply that the chromosomes are
#'   biologically circular. Duplicate chromosome keys, unmatched chromosome
#'   references, and invalid or out-of-bounds intervals are rejected.
#' @examples
#' data(rice_sorghum)
#' p <- plot_circular_synteny(rice_sorghum, c("Rice", "Sorghum"),
#'                            palette = "casa_natal", chr_fill = "per_species")
#' p + ggplot2::labs(caption = "Rice and sorghum syntenic intervals")
#' @export
plot_circular_synteny <- function(syn_data, species_order = NULL, palette = NULL,
                                  chr_fill = "uniform", chr_palette = NULL, chr_color = "white",
                                  ribbon_fill = "source_chr", ribbon_palette = NULL,
                                  ribbon_alpha = 0.3, gap = 1, group_gap = 10,
                                  start_angle = 90, clockwise = TRUE, curvature = 0.65,
                                  track_width = 0.055, label_size = 2.5, species_label_size = 4,
                                  show_orientation = FALSE, interactive = FALSE, title = NULL) {
  chr_fill <- match.arg(chr_fill, c("uniform", "per_species", "per_chr", "custom"))
  ribbon_fill <- match.arg(ribbon_fill, c("source_chr", "target_chr", "species_pair", "uniform", "custom"))
  .circ_interactive(interactive)
  .circ_logical(show_orientation, "show_orientation")
  .circ_scalar(ribbon_alpha, "ribbon_alpha", 0, 1)
  .circ_scalar(curvature, "curvature", 0, 1)
  .circ_scalar(track_width, "track_width", 0.001, 0.4)
  .circ_scalar(label_size, "label_size", 0, 20)
  .circ_scalar(species_label_size, "species_label_size", 0, 20)
  chrs <- .circ_columns(syn_data$chromosomes, c("species", "chr", "size"), "chromosomes")
  blocks <- .circ_columns(syn_data$blocks,
                          c("species1", "chr1", "start1", "end1", "species2", "chr2", "start2", "end2"),
                          "blocks")
  chrs$species <- .circ_text(chrs$species, "chromosomes$species")
  chrs$chr <- .circ_text(chrs$chr, "chromosomes$chr")
  chrs$size <- .circ_numbers(chrs$size, "chromosomes$size")
  if (any(chrs$size <= 0)) stop("Chromosome sizes must be positive.", call. = FALSE)
  if (anyDuplicated(.circ_key(chrs$species, chrs$chr))) stop("Duplicate species/chromosome keys.", call. = FALSE)
  species_order <- .circ_order(species_order, chrs$species, "species_order")
  sectors <- data.frame(group_name = chrs$species, sector_name = chrs$chr, start = 0, end = chrs$size)
  layout <- .circ_layout(sectors, species_order, gap, group_gap, start_angle, clockwise)
  for (name in c("species1", "chr1", "species2", "chr2")) blocks[[name]] <- .circ_text(blocks[[name]], name)
  blocks$block_id <- seq_len(nrow(blocks))
  input_count <- nrow(blocks)
  blocks <- blocks[blocks$species1 %in% species_order & blocks$species2 %in% species_order, , drop = FALSE]
  for (name in c("start1", "end1", "start2", "end2")) blocks[[name]] <- .circ_numbers(blocks[[name]], name)
  ia <- match(.circ_key(blocks$species1, blocks$chr1), layout$sector_id)
  ib <- match(.circ_key(blocks$species2, blocks$chr2), layout$sector_id)
  if (anyNA(ia) || anyNA(ib)) stop("Blocks reference chromosomes absent from the chromosome table.", call. = FALSE)
  for (side in 1:2) {
    index <- if (side == 1) ia else ib
    if (any(blocks[[paste0("start", side)]] < 0 |
            blocks[[paste0("end", side)]] <= blocks[[paste0("start", side)]] |
            blocks[[paste0("end", side)]] > layout$end[index]))
      stop("Block intervals must have positive width and lie within chromosome bounds.", call. = FALSE)
  }
  if (show_orientation && (!"orientation" %in% names(blocks) ||
                           any(!blocks$orientation %in% c("plus", "minus"))))
    stop("show_orientation requires blocks$orientation containing 'plus' or 'minus'.", call. = FALSE)

  # Canonicalize species pairs without dropping non-adjacent or self comparisons.
  swap <- match(blocks$species1, species_order) > match(blocks$species2, species_order)
  for (field in c("species", "chr", "start", "end")) {
    a <- paste0(field, "1"); b <- paste0(field, "2")
    old <- blocks[[a]][swap]
    blocks[[a]][swap] <- blocks[[b]][swap]
    blocks[[b]][swap] <- old
  }
  ia <- match(.circ_key(blocks$species1, blocks$chr1), layout$sector_id)
  ib <- match(.circ_key(blocks$species2, blocks$chr2), layout$sector_id)
  blocks$a0 <- .circ_position(layout, ia, blocks$start1)
  blocks$a1 <- .circ_position(layout, ia, blocks$end1)
  blocks$b0 <- .circ_position(layout, ib, blocks$start2)
  blocks$b1 <- .circ_position(layout, ib, blocks$end2)

  chr_spec <- chr_palette %||% palette
  if (chr_fill == "uniform") {
    layout$fill_color <- unname(syn_pal(chr_spec %||% "#333333", 1))
  } else {
    keys <- switch(chr_fill, per_species = layout$group_name, per_chr = layout$sector_name,
                   custom = paste0(layout$group_name, "__", layout$sector_name))
    if (chr_fill == "custom" && is.null(names(chr_spec)))
      stop("Custom chromosome colors require a named chr_palette.", call. = FALSE)
    chr_colors <- keyed_colors(chr_spec, unique(keys))
    layout$fill_color <- unname(chr_colors[keys])
    layout$fill_color[is.na(layout$fill_color)] <- "#D4CBC3"
  }
  ribbon_spec <- ribbon_palette %||% palette
  if (ribbon_fill == "uniform") {
    blocks$fill_color <- rep(unname(syn_pal(ribbon_spec %||% "#6688AA", 1)), nrow(blocks))
  } else if (ribbon_fill == "custom") {
    if (!length(ribbon_spec) %in% c(1L, input_count))
      stop("Custom ribbons require one color or one color per input block.", call. = FALSE)
    blocks$fill_color <- rep_len(ribbon_spec, input_count)[blocks$block_id]
  } else {
    keys <- switch(ribbon_fill, source_chr = blocks$chr1, target_chr = blocks$chr2,
                   species_pair = paste0(blocks$species1, "_", blocks$species2))
    if (chr_fill == "per_chr" && ribbon_fill %in% c("source_chr", "target_chr") &&
        identical(keyed_colors(ribbon_spec, unique(layout$sector_name)), chr_colors)) {
      pal <- chr_colors
    } else pal <- keyed_colors(ribbon_spec, unique(keys))
    blocks$fill_color <- unname(pal[keys])
  }
  blocks$fill_color[is.na(blocks$fill_color)] <- "#888888"
  radius <- 1 - track_width
  ribbons <- dplyr::bind_rows(lapply(seq_len(nrow(blocks)), function(i) {
    b <- blocks[i, ]
    poly <- .circ_ribbon(b$a0, b$a1, b$b0, b$b1, radius, curvature,
                         same_direction = show_orientation && b$orientation == "plus")
    tooltip <- paste0(b$species1, " ", b$chr1, ": ", b$start1, "\u2013", b$end1,
                      " \u2194 ", b$species2, " ", b$chr2, ": ", b$start2, "\u2013", b$end2)
    if ("orientation" %in% names(b)) tooltip <- paste0(tooltip, "\nOrientation: ", b$orientation)
    .circ_tag(poly, paste0("block_", b$block_id), b$fill_color, tooltip)
  }))
  chromosomes <- dplyr::bind_rows(lapply(seq_len(nrow(layout)), function(i) {
    r <- layout[i, ]
    .circ_tag(.circ_ring(r$theta_start, r$theta_end, radius, 1), paste0("chr_", r$sector_id),
              r$fill_color, paste0(r$group_name, " \u00b7 ", r$sector_name, " (", r$end, ")"))
  }))
  p <- .circ_canvas(layout, title)
  p <- .circ_add_polygons(p, ribbons, ribbon_alpha, interactive = interactive)
  p <- .circ_add_polygons(p, chromosomes, color = chr_color, interactive = interactive)
  if (label_size > 0) p <- .circ_add_labels(p, .circ_labels((layout$theta_start + layout$theta_end) / 2,
                                                           1.06, layout$sector_name), label_size)
  if (species_label_size > 0) p <- .circ_add_labels(p, .circ_group_labels(layout), species_label_size, "bold.italic")
  attr(p, "circular_links") <- blocks
  p
}
