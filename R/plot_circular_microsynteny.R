#' Plot gene-level synteny around a circle
#'
#' Draw strand-aware curved gene arrows on contig arcs, grouped by genome/bin,
#' with homology ribbons inside the circle. Uses ordinary ggplot2 layers and
#' the same feature/link tables as [plot_microsynteny()].
#'
#' @param features Data frame with `bin_id`, `seq_id`, `start`, `end`, `strand`
#'   (`"+"` or `"-"`), unique `feat_id`, and `name` columns.
#' @param links Data frame with `feat_id_a`, `feat_id_b`, and optional percent
#'   `identity` (0 to 100; `NA` means unknown). Empty links are supported.
#' @param bin_order Bins in circular display order. Defaults to first appearance
#'   in `features`; may select a subset. Links to excluded bins are omitted.
#' @param palette Built-in ltc name, HCL palette name, `"Okabe-Ito"`, or color
#'   vector for genes and categorical ribbons. Identity keeps the default blue
#'   ramp unless `ribbon_palette` is supplied explicitly.
#' @param gene_fill Gene coloring: `"per_name"`, `"per_feat"`, or `"uniform"`.
#' @param gene_palette Overrides `palette`; named vectors map gene names or IDs.
#' @param gene_color Gene outline color.
#' @param gene_alpha Gene opacity, between 0 and 1.
#' @param ribbon_fill Ribbon coloring: `"identity"`, `"per_name"`, or `"uniform"`.
#' @param ribbon_palette Overrides the categorical palette or sets an identity
#'   color ramp. Named mappings are supported for per-name ribbons.
#' @param ribbon_alpha Ribbon opacity, between 0 and 1.
#' @param ribbon_anchor `"body"` keeps arrowheads clear; `"full"` spans the
#'   complete gene interval.
#' @param identity_low,identity_high Colors at 0 and 100 percent identity when
#'   no explicit ribbon palette is supplied.
#' @param gap Gap between contigs within a bin, in degrees.
#' @param group_gap Gap between bins, in degrees.
#' @param start_angle First sector's starting angle in degrees; 90 is top.
#' @param clockwise Draw increasing genomic coordinates clockwise?
#' @param curvature Pull of ribbon control points toward the center (0 to 1).
#' @param track_width Radial thickness of the gene arrows; outer radius is 1.
#' @param arrowhead_frac Fraction of gene length used for the arrowhead (0 to
#'   0.5), capped at 6 degrees to keep very long arrows readable.
#' @param label_genes Show gene names outside the ring?
#' @param label_size Gene label size in mm.
#' @param bin_label_size Bin label size in mm. Set to 0 to hide labels.
#' @param interactive Build ggiraph layers for rendering with [syn_girafe()]?
#' @param title Optional title.
#' @return A ggplot object whose `data` contains the contig layout. Attributes
#'   `circular_features` and `circular_links` contain displayed features and links
#'   with angular coordinates in radians.
#' @details Each contig spans its first feature start through its last feature
#'   end; unannotated flanks are not inferred. Arc widths are proportional to
#'   these observed spans across bins, using a shared coordinate unit. The
#'   circular presentation does not imply biologically circular sequences.
#'   Features that cross a circular genome origin must be split before plotting.
#'
#'   Gene strand controls arrow direction. Ribbons represent homology between
#'   intervals, not alignment orientation; no inversion is inferred from strand.
#'   Links can connect any displayed bins or contigs, including the same bin.
#'   Unknown feature identifiers, duplicate feature IDs and invalid intervals
#'   are rejected to avoid ambiguous links.
#' @examples
#' micro <- demo_microsynteny_data()
#' p <- plot_circular_microsynteny(micro$features, micro$links,
#'                                palette = "casa_natal")
#' p + ggplot2::labs(caption = "Gene arrows indicate strand")
#' @seealso [syn_track()] for optional GC-content and numeric annotation tracks.
#' @export
plot_circular_microsynteny <- function(features, links, bin_order = NULL, palette = NULL,
                                       gene_fill = "per_name", gene_palette = NULL,
                                       gene_color = "#333333", gene_alpha = 0.95,
                                       ribbon_fill = "identity", ribbon_palette = NULL,
                                       ribbon_alpha = 0.35, ribbon_anchor = "body",
                                       identity_low = "#DCEEFF", identity_high = "#08519C",
                                       gap = 2, group_gap = 10, start_angle = 90,
                                       clockwise = TRUE, curvature = 0.65, track_width = 0.065,
                                       arrowhead_frac = 0.18, label_genes = TRUE,
                                       label_size = 2.5, bin_label_size = 4,
                                       interactive = FALSE, title = NULL) {
  gene_fill <- match.arg(gene_fill, c("per_name", "per_feat", "uniform"))
  ribbon_fill <- match.arg(ribbon_fill, c("identity", "per_name", "uniform"))
  ribbon_anchor <- match.arg(ribbon_anchor, c("body", "full"))
  .circ_interactive(interactive)
  .circ_logical(label_genes, "label_genes")
  .circ_scalar(gene_alpha, "gene_alpha", 0, 1)
  .circ_scalar(ribbon_alpha, "ribbon_alpha", 0, 1)
  .circ_scalar(curvature, "curvature", 0, 1)
  .circ_scalar(track_width, "track_width", 0.001, 0.4)
  .circ_scalar(arrowhead_frac, "arrowhead_frac", 0, 0.5)
  .circ_scalar(label_size, "label_size", 0, 20)
  .circ_scalar(bin_label_size, "bin_label_size", 0, 20)
  features <- .circ_columns(features, c("bin_id", "seq_id", "start", "end", "strand", "feat_id", "name"), "features")
  links <- .circ_columns(links, c("feat_id_a", "feat_id_b"), "links")
  for (name in c("bin_id", "seq_id", "strand", "feat_id", "name"))
    features[[name]] <- .circ_text(features[[name]], paste0("features$", name))
  for (name in c("start", "end")) features[[name]] <- .circ_numbers(features[[name]], name)
  if (any(features$start < 0 | features$end <= features$start))
    stop("Feature intervals must have non-negative starts and positive widths.", call. = FALSE)
  if (any(!features$strand %in% c("+", "-"))) stop("strand must be '+' or '-'.", call. = FALSE)
  if (anyDuplicated(features$feat_id)) stop("feat_id must be unique across all bins.", call. = FALSE)
  for (name in c("feat_id_a", "feat_id_b")) {
    links[[name]] <- .circ_text(links[[name]], name)
    if (any(!links[[name]] %in% features$feat_id)) stop("Links reference unknown feature IDs.", call. = FALSE)
  }
  has_identity <- "identity" %in% names(links)
  if (!has_identity) links$identity <- rep(80, nrow(links))
  if (!is.numeric(links$identity) || any(!is.na(links$identity) &
                                       (!is.finite(links$identity) | links$identity < 0 | links$identity > 100)))
    stop("identity must be numeric percentages from 0 to 100, or NA.", call. = FALSE)
  links$link_id <- seq_len(nrow(links))
  bin_order <- .circ_order(bin_order, features$bin_id, "bin_order")
  features <- features[features$bin_id %in% bin_order, , drop = FALSE]
  features$sector_id <- .circ_key(features$bin_id, features$seq_id)
  sectors <- dplyr::bind_rows(lapply(unique(features$sector_id), function(id) {
    rows <- features[features$sector_id == id, ]
    data.frame(group_name = rows$bin_id[1], sector_name = rows$seq_id[1],
                start = min(rows$start), end = max(rows$end))
  }))
  layout <- .circ_layout(sectors, bin_order, gap, group_gap, start_angle, clockwise)
  features <- features[order(match(features$sector_id, layout$sector_id), features$start, features$end), ]
  rownames(features) <- NULL
  index <- match(features$sector_id, layout$sector_id)
  features$theta_start <- .circ_position(layout, index, features$start)
  features$theta_end <- .circ_position(layout, index, features$end)
  delta <- features$theta_end - features$theta_start
  head <- sign(delta) * pmin(abs(delta) * arrowhead_frac, 6 * pi / 180)
  features$body_start <- features$theta_start
  features$body_end <- features$theta_end
  if (ribbon_anchor == "body") {
    features$body_start <- features$theta_start + ifelse(features$strand == "-", head, 0)
    features$body_end <- features$theta_end - ifelse(features$strand == "+", head, 0)
  }
  gene_spec <- gene_palette %||% palette
  if (gene_fill == "uniform") {
    features$fill_color <- unname(syn_pal(gene_spec %||% "#AEC6CF", 1))
  } else {
    keys <- if (gene_fill == "per_name") features$name else features$feat_id
    gene_colors <- keyed_colors(gene_spec, unique(keys))
    features$fill_color <- unname(gene_colors[keys])
    features$fill_color[is.na(features$fill_color)] <- "#CCCCCC"
  }
  links <- links[links$feat_id_a %in% features$feat_id & links$feat_id_b %in% features$feat_id, , drop = FALSE]
  ia <- match(links$feat_id_a, features$feat_id)
  ib <- match(links$feat_id_b, features$feat_id)
  links$a0 <- features$body_start[ia]; links$a1 <- features$body_end[ia]
  links$b0 <- features$body_start[ib]; links$b1 <- features$body_end[ib]
  ribbon_spec <- ribbon_palette %||% palette
  if (ribbon_fill == "identity") {
    ramp <- if (is.null(ribbon_palette)) grDevices::colorRampPalette(c(identity_low, identity_high))(101)
            else syn_pal(ribbon_palette, 101, continuous = TRUE)
    links$fill_color <- ramp[round(links$identity) + 1]
  } else if (ribbon_fill == "per_name") {
    keys <- features$name[ia]
    if (gene_fill == "per_name" && identical(keyed_colors(ribbon_spec, unique(features$name)), gene_colors)) {
      pal <- gene_colors
    } else pal <- keyed_colors(ribbon_spec, unique(keys))
    links$fill_color <- unname(pal[keys])
  } else links$fill_color <- rep(unname(syn_pal(ribbon_spec %||% "#6688AA", 1)), nrow(links))
  links$fill_color[is.na(links$fill_color)] <- "#888888"
  radius <- 1 - track_width
  ribbons <- dplyr::bind_rows(lapply(seq_len(nrow(links)), function(i) {
    b <- links[i, ]
    tooltip <- paste0(b$feat_id_a, " \u2194 ", b$feat_id_b)
    if (has_identity) tooltip <- paste0(tooltip, "\n", b$identity, "% identity")
    .circ_tag(.circ_ribbon(b$a0, b$a1, b$b0, b$b1, radius, curvature),
              paste0("link_", b$link_id), b$fill_color, tooltip)
  }))
  backbones <- dplyr::bind_rows(lapply(seq_len(nrow(layout)), function(i) {
    r <- layout[i, ]
    middle <- 1 - track_width / 2
    .circ_tag(.circ_ring(r$theta_start, r$theta_end, middle - 0.002, middle + 0.002),
              paste0("contig_", r$sector_id), "#B8B8B8",
              paste0(r$group_name, " \u00b7 ", r$sector_name, ": ", r$start, "\u2013", r$end))
  }))
  arrows <- dplyr::bind_rows(lapply(seq_len(nrow(features)), function(i) {
    f <- features[i, ]
    .circ_tag(.circ_arrow(f$theta_start, f$theta_end, f$strand, radius, 1, head[i]),
              paste0("gene_", f$feat_id), f$fill_color,
              paste0(f$name, "\n", f$bin_id, " \u00b7 ", f$seq_id, ": ", f$start, "\u2013", f$end,
                     " (", f$strand, ")"))
  }))
  p <- .circ_canvas(layout, title)
  p <- .circ_add_polygons(p, ribbons, ribbon_alpha, interactive = interactive)
  p <- .circ_add_polygons(p, backbones, interactive = interactive)
  p <- .circ_add_polygons(p, arrows, gene_alpha, gene_color, interactive)
  if (label_genes && label_size > 0)
    p <- .circ_add_labels(p, .circ_labels((features$theta_start + features$theta_end) / 2,
                                          1.08, features$name), label_size, "italic")
  if (bin_label_size > 0) p <- .circ_add_labels(p, .circ_group_labels(layout), bin_label_size, "bold")
  attr(p, "circular_features") <- features
  attr(p, "circular_links") <- links
  attr(p, "synteny_layout") <- .track_circular_layout(layout)
  p
}
