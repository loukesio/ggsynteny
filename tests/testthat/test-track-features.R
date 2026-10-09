chloroplast <- function() {
  dir <- system.file("extdata", "chloroplast", package = "ggsynteny")
  key <- function(d) cbind(species = "Arabidopsis", chr = "plastid", d, stringsAsFactors = FALSE)
  regions <- read.csv(file.path(dir, "regions.csv"))
  genes <- read.csv(file.path(dir, "genes.csv"))
  gc <- read.csv(file.path(dir, "gc_windows.csv"))
  pairs <- read.csv(file.path(dir, "ir_pairs.csv"))
  list(
    syn = list(chromosomes = data.frame(species = "Arabidopsis", chr = "plastid", size = 154478),
               blocks = data.frame(species1 = "Arabidopsis", chr1 = "plastid", start1 = pairs$b_start,
                                   end1 = pairs$b_end, species2 = "Arabidopsis", chr2 = "plastid",
                                   start2 = pairs$a_start, end2 = pairs$a_end, class = pairs$class)),
    regions = key(regions), genes = key(genes),
    gc = key(data.frame(start = gc$start, end = gc$start + 999, value = 100 * gc$gc)))
}

radius_of <- function(d) sqrt(d$x^2 + d$y^2)
last_layer <- function(p) p$layers[[length(p$layers)]]
layer_with <- function(p, column) {
  hits <- Filter(function(l) is.data.frame(l$data) && column %in% names(l$data), p$layers)
  hits[[length(hits)]]
}

test_that("feature tracks colour categories through a private discrete scale", {
  d <- chloroplast()
  p <- plot_circular_synteny(d$syn, "Arabidopsis", ribbon_fill = "uniform", label_size = 0)
  before <- ggplot2::ggplot_build(p)$data
  pal <- c("Other genes" = "#999999", "ATP synthase" = "#E69F00")
  q <- p + syn_track_feature(d$genes, fill = "class", palette = pal, height = 0.1, gap = 0.02)
  expect_equal(ggplot2::ggplot_build(p)$data, before)
  poly <- layer_with(q, "track_key")
  expect_true("syn_feature1" %in% names(poly$mapping))
  expect_equal(length(unique(poly$data$track_interval)), nrow(d$genes))
  expect_equal(range(radius_of(poly$data)), c(1.02, 1.12), tolerance = 1e-8)
  scale <- q$scales$get_scales("syn_feature1")
  expect_s3_class(scale, "ScaleDiscrete")
  values <- scale$palette(length(unique(d$genes$class)))
  expect_equal(unname(values[match(names(pal), unique(d$genes$class))]), unname(pal))
  expect_true(all(values[!unique(d$genes$class) %in% names(pal)] == "#BDBDBD"))
  expect_equal(scale$name, "class")
  hidden <- p + syn_track_feature(d$genes, fill = "class", show.legend = FALSE)
  expect_identical(hidden$scales$get_scales("syn_feature1")$guide, "none")
  expect_equal(attr(q, "synteny_layout")$used, 0.12)
  expect_equal(q$coordinates$limits$x, c(-1.52, 1.52))
  expect_s3_class(track_test_render(q), "gtable")
  fixed <- p + syn_track_feature(d$genes, fill = "#112233", name = "genes")
  expect_equal(last_layer(fixed)$aes_params$fill, "#112233")
  expect_null(fixed$scales$get_scales("syn_feature1"))
  expect_s3_class(track_test_render(p + syn_track_feature(d$genes, palette = "casa_natal")), "gtable")
})

test_that("feature tracks split or arrow by strand and label intervals", {
  d <- chloroplast()
  p <- plot_circular_synteny(d$syn, "Arabidopsis", ribbon_fill = "uniform", label_size = 0)
  g <- d$genes[1:12, ]
  g$strand <- c("+", "-", "plus", "minus", "1", "-1", ".", "+", "-", "+", "-", NA)
  split <- p + syn_track_feature(g, fill = "class", strand = "split", height = 0.1, gap = 0)
  poly <- layer_with(split, "track_key")$data
  norm <- .track_strand(g$strand)
  for (i in seq_len(nrow(g))) {
    r <- range(radius_of(poly[poly$track_interval == i, ]))
    expected <- if (is.na(norm[i])) c(1, 1.1) else if (norm[i] == "+") c(1.055, 1.1) else c(1, 1.045)
    expect_equal(r, expected, tolerance = 1e-8)
  }
  arrow <- p + syn_track_feature(g, fill = "class", strand = "arrow", height = 0.1, gap = 0)
  poly <- layer_with(arrow, "track_key")$data
  layout <- syn_layout(arrow)$sectors
  angle <- function(pos) layout$theta_start + (pos - layout$start) / (layout$end - layout$start) *
    (layout$theta_end - layout$theta_start)
  for (i in which(!is.na(norm))) {
    piece <- poly[poly$track_interval == i, ]
    tip <- piece[abs(radius_of(piece) - 1.05) < 1e-8, ]
    expect_equal(nrow(tip), 1L)
    expect_equal(atan2(tip$y, tip$x), angle(if (norm[i] == "+") g$end[i] else g$start[i]), tolerance = 1e-8)
  }
  unstranded <- poly[poly$track_interval == 7, ]
  expect_true(all(abs(radius_of(unstranded) - 1) < 1e-8 | abs(radius_of(unstranded) - 1.1) < 1e-8))
  labelled <- p + syn_track_feature(d$regions, fill = "region", label = "region", height = 0.08)
  text <- last_layer(labelled)
  expect_s3_class(text$geom, "GeomText")
  expect_setequal(text$data$label, d$regions$region)
  expect_true(all(text$data$track_axis))
  expect_equal(radius_of(text$data), rep(1.06, 4), tolerance = 1e-8)
  # Labels inside lanes stay put when later rings are added; sector labels move.
  stacked <- labelled + syn_track(d$gc, limits = c(0, 100), out_of_bounds = "clip")
  expect_equal(radius_of(layer_with(stacked, "track_axis")$data)[1:4], rep(1.06, 4), tolerance = 1e-8)
  expect_s3_class(track_test_render(stacked), "gtable")
  expect_error(syn_track_feature(d$genes[setdiff(names(d$genes), "strand")], strand = "split"), "strand column")
  bad <- d$genes; bad$strand <- "?"
  expect_error(syn_track_feature(bad, strand = "arrow"), "recognised")
  expect_error(syn_track_feature(d$genes, fill = "not a colour or column"), "valid color")
  expect_error(syn_track_feature(d$genes, label = "missing"), "label must name")
  bad <- d$genes; bad$class[1] <- NA
  expect_error(syn_track_feature(bad, fill = "class"), "NA")
})

test_that("out_of_bounds clips, drops or rejects intervals beyond a sequence", {
  d <- chloroplast()
  p <- plot_circular_synteny(d$syn, "Arabidopsis", ribbon_fill = "uniform")
  expect_error(p + syn_track(d$gc, limits = c(0, 100)), "out_of_bounds")
  clipped <- p + syn_track(d$gc, limits = c(0, 100), out_of_bounds = "clip")
  kept <- attr(clipped, "synteny_tracks")[[1]]$data
  expect_equal(nrow(kept), nrow(d$gc))
  expect_equal(max(kept$end), 154478)
  dropped <- p + syn_track(d$gc, limits = c(0, 100), out_of_bounds = "drop")
  expect_equal(nrow(attr(dropped, "synteny_tracks")[[1]]$data), sum(d$gc$end <= 154478))
  expect_s3_class(track_test_render(clipped), "gtable")
  only_outside <- d$gc[d$gc$end > 154478, ]
  untouched <- p + syn_track(only_outside, limits = c(0, 100), out_of_bounds = "drop")
  expect_equal(length(untouched$layers), length(p$layers))
  expect_null(attr(untouched, "synteny_tracks"))
  expect_equal(ggplot2::ggplot_build(untouched)$data, ggplot2::ggplot_build(p)$data)
})

test_that("inside tracks stack inward and shrink ribbons without moving outer labels", {
  d <- chloroplast()
  p <- plot_circular_synteny(d$syn, "Arabidopsis", ribbon_fill = "uniform", track_width = 0.05)
  inner <- 0.95
  ribbons <- p$layers[[1]]$data
  expect_equal(max(radius_of(ribbons)), inner, tolerance = 1e-8)
  q <- p + syn_track_feature(d$genes, fill = "class", position = "inside", height = 0.1, gap = 0.02)
  expect_equal(syn_layout(q)$inner_edge, inner - 0.12)
  expect_equal(syn_layout(q)$outer_edge, 1)
  poly <- layer_with(q, "track_key")$data
  expect_equal(range(radius_of(poly)), c(inner - 0.12, inner - 0.02), tolerance = 1e-8)
  expect_equal(max(radius_of(q$layers[[1]]$data)), inner - 0.12, tolerance = 1e-8)
  expect_equal(q$layers[[1]]$data$circular_id, ribbons$circular_id)
  expect_equal(q$coordinates$limits, p$coordinates$limits)
  labels <- Filter(function(l) inherits(l$geom, "GeomText"), p$layers)
  labels2 <- Filter(function(l) inherits(l$geom, "GeomText") && !"track_axis" %in% names(l$data), q$layers)
  expect_equal(labels2[[1]]$data, labels[[1]]$data)
  r <- q + syn_track(d$gc, geom = "line", limits = c(20, 60), position = "inside", height = 0.15,
                     gap = 0.03, out_of_bounds = "clip")
  expect_equal(syn_layout(r)$inner_edge, inner - 0.30)
  expect_equal(max(radius_of(r$layers[[1]]$data)), inner - 0.30, tolerance = 1e-8)
  expect_equal(attr(r, "synteny_tracks")[[2]]$position, "inside")
  expect_s3_class(track_test_render(r), "gtable")
  expect_error(r + syn_track(d$gc, position = "inside", height = 0.9, out_of_bounds = "clip"), "No room")
  # Position is ignored in linear layouts, where lanes always stack below.
  m <- example_microsynteny_data()
  lin <- plot_microsynteny(m$features, m$links)
  expect_equal(ggplot2::ggplot_build(lin + syn_track_feature(m$features, fill = "name", position = "inside"))$data,
               ggplot2::ggplot_build(lin + syn_track_feature(m$features, fill = "name"))$data)
  expect_s3_class(track_test_render(lin + syn_track_feature(m$features, fill = "name", strand = "arrow",
                                                              label = "name")), "gtable")
  s <- example_synteny_data()
  mac <- plot_synteny(s, unique(s$chromosomes$species))
  regions <- data.frame(species = s$chromosomes$species[1], chr = s$chromosomes$chr[1],
                        start = c(0, 10), end = c(10, 20), region = c("a", "b"))
  expect_s3_class(track_test_render(mac + syn_track_feature(regions, fill = "region", label = "region") +
                                      syn_axis(by = 5)), "gtable")
})

test_that("axes draw ticks and labels in every layout", {
  d <- chloroplast()
  p <- plot_circular_synteny(d$syn, "Arabidopsis", ribbon_fill = "uniform")
  q <- p + syn_axis(by = 10000, unit = "kb", height = 0.06, gap = 0)
  text <- last_layer(q)$data
  expect_equal(text$label, paste(1:15 * 10, "kb"))
  expect_true(all(text$track_axis))
  ticks <- q$layers[[length(q$layers) - 1]]$data
  expect_equal(length(unique(ticks$track_interval)), 16L)
  expect_equal(range(radius_of(ticks)), c(1, 1.024), tolerance = 1e-8)
  expect_equal(syn_layout(q)$outer_edge, 1.06)
  with_start <- p + syn_axis(by = 50000, label_start = TRUE)
  expect_equal(last_layer(with_start)$data$label, c("0", "50,000", "100,000", "150,000"))
  auto <- p + syn_axis()
  expect_equal(length(unique(auto$layers[[length(auto$layers) - 1]]$data$track_interval)), 8L)
  inside <- p + syn_axis(by = 10000, position = "inside", height = 0.06, gap = 0)
  expect_equal(range(radius_of(inside$layers[[length(inside$layers) - 1]]$data)),
               c(0.945 - 0.024, 0.945), tolerance = 1e-8)
  expect_s3_class(track_test_render(q + inside$layers[0]), "gtable")
  s <- example_synteny_data()
  mac <- plot_synteny(s, unique(s$chromosomes$species))
  lin <- mac + syn_axis(by = 10, unit = NULL)
  layout <- syn_layout(lin)
  text <- last_layer(lin)$data
  expect_true(all(text$y < max(layout$sectors$y)))
  expect_true(all(grepl("^[0-9,]+$", text$label)))
  expect_s3_class(track_test_render(lin), "gtable")
  no_labels <- mac + syn_axis(by = 10, labels = FALSE, line = FALSE)
  expect_false(inherits(last_layer(no_labels)$geom, "GeomText"))
  expect_error(syn_axis(unit = "parsec"), "unit")
  expect_error(syn_axis(by = 0), "by")
  data(rice_sorghum)
  expect_s3_class(track_test_render(plot_circular_synteny(rice_sorghum, c("Rice", "Sorghum")) +
                                      syn_axis(by = 10)), "gtable")
})

test_that("chromosome order follows factors, input order or explicit vectors", {
  chrs <- data.frame(species = "A", chr = c("LSC", "IRb", "SSC", "IRa"), size = c(84, 26, 18, 26))
  blocks <- data.frame(species1 = "A", chr1 = "IRb", start1 = 1, end1 = 2,
                       species2 = "A", chr2 = "IRa", start2 = 1, end2 = 2)
  order_of <- function(p) syn_layout(p)$sectors$seq_id
  expect_equal(order_of(plot_circular_synteny(list(chromosomes = chrs, blocks = blocks))),
               c("IRa", "IRb", "LSC", "SSC"))
  expect_equal(order_of(plot_circular_synteny(list(chromosomes = chrs, blocks = blocks), chr_order = "input")),
               chrs$chr)
  expect_equal(order_of(plot_circular_synteny(list(chromosomes = chrs, blocks = blocks),
                                              chr_order = c("SSC", "IRa", "LSC", "IRb"))),
               c("SSC", "IRa", "LSC", "IRb"))
  expect_equal(order_of(plot_circular_synteny(list(chromosomes = chrs, blocks = blocks),
                                              chr_order = list(A = rev(chrs$chr)))), rev(chrs$chr))
  factored <- chrs; factored$chr <- factor(factored$chr, levels = chrs$chr)
  expect_equal(order_of(plot_circular_synteny(list(chromosomes = factored, blocks = blocks))), chrs$chr)
  expect_error(plot_circular_synteny(list(chromosomes = chrs, blocks = blocks), chr_order = c("LSC", "IRb")),
               "every displayed sequence")
  expect_error(plot_circular_synteny(list(chromosomes = chrs, blocks = blocks), chr_order = list(rev(chrs$chr))),
               "named")
  numeric <- data.frame(species = "A", chr = c("10", "2", "1"), size = 5)
  expect_equal(order_of(plot_circular_synteny(list(chromosomes = numeric, blocks = blocks[0, ]))),
               c("1", "2", "10"))
  two <- rbind(chrs, data.frame(species = "B", chr = c("y", "x"), size = 10))
  expect_equal(order_of(plot_circular_synteny(list(chromosomes = two, blocks = blocks),
                                              chr_order = list(B = c("y", "x")))),
               c("IRa", "IRb", "LSC", "SSC", "y", "x"))
})

test_that("ribbons colour by a blocks column with an optional legend", {
  d <- chloroplast()
  pal <- c("Ribosomal proteins" = "#0072B2", "tRNA and rRNA" = "#D55E00", "Other genes" = "#999999",
           "NADH dehydrogenase" = "#CC79A7")
  p <- plot_circular_synteny(d$syn, "Arabidopsis", ribbon_fill = "class", ribbon_palette = pal,
                             ribbon_alpha = 0.5)
  links <- attr(p, "circular_links")
  expect_equal(links$fill_color, unname(pal[links$class]))
  key <- Filter(function(l) "track_key" %in% names(l$data), p$layers)[[1]]
  expect_setequal(key$data$track_key, unique(d$syn$blocks$class))
  expect_true("syn_ribbon" %in% names(key$mapping))
  scale <- p$scales$get_scales("syn_ribbon")
  expect_equal(scale$name, "class")
  expect_s3_class(track_test_render(p), "gtable")
  q <- plot_circular_synteny(d$syn, "Arabidopsis", ribbon_fill = "class", ribbon_legend = FALSE)
  expect_false(any(vapply(q$layers, function(l) "track_key" %in% names(l$data), logical(1))))
  expect_equal(length(unique(attr(q, "circular_links")$fill_color)), length(unique(d$syn$blocks$class)))
  bad <- d$syn; bad$blocks$class[1] <- NA
  expect_error(plot_circular_synteny(bad, "Arabidopsis", ribbon_fill = "class"), "NA")
  expect_error(plot_circular_synteny(d$syn, "Arabidopsis", ribbon_fill = "nonsense"), "should be one of")
  # Tracks after a ribbon legend keep independent numbering and legends.
  r <- p + syn_track_feature(d$genes, fill = "class", palette = pal)
  expect_s3_class(r$scales$get_scales("syn_feature1"), "ScaleDiscrete")
  expect_s3_class(track_test_render(r), "gtable")
})

test_that("syn_layout and syn_project expose the drawing geometry", {
  d <- chloroplast()
  p <- plot_circular_synteny(d$syn, "Arabidopsis", ribbon_fill = "uniform", track_width = 0.05)
  layout <- syn_layout(p)
  expect_equal(layout$type, "circular")
  expect_equal(layout$band, c(inner = 0.95, outer = 1))
  expect_equal(layout$sectors$seq_id, "plastid")
  xy <- syn_project(p, "Arabidopsis", "plastid", c(0, 154478 / 2), offset = c(1, 1.2))
  expect_equal(radius_of(xy), c(1, 1.2))
  s <- layout$sectors
  expect_equal(atan2(xy$y[1], xy$x[1]), s$theta_start)
  expect_equal(atan2(xy$y[2], xy$x[2]) %% (2 * pi), ((s$theta_start + s$theta_end) / 2) %% (2 * pi))
  expect_error(syn_project(p, "Arabidopsis", "nope", 1), "Unknown sequence")
  expect_error(syn_layout(ggplot2::ggplot()), "ggsynteny")
  q <- p + syn_track(d$gc, limits = c(0, 100), out_of_bounds = "clip", height = 0.1, gap = 0.02) +
    syn_axis(position = "inside", height = 0.04, gap = 0)
  expect_equal(syn_layout(q)$outer_edge, 1.12)
  expect_equal(syn_layout(q)$inner_edge, 0.91)
  m <- example_microsynteny_data()
  lin <- plot_microsynteny(m$features, m$links)
  ll <- syn_layout(lin)
  expect_equal(ll$type, "linear")
  first <- ll$sectors[1, ]
  xy <- syn_project(lin, first$group, first$seq_id, first$start, offset = 0.5)
  expect_equal(xy$x, first$x)
  expect_equal(xy$y, first$y + 0.5)
})

test_that("the chloroplast genome ring draws from exported functions only", {
  d <- chloroplast()
  pal <- c("Photosystems and electron transport" = "#009E73", "ATP synthase" = "#E69F00",
           "NADH dehydrogenase" = "#CC79A7", "Ribosomal proteins" = "#0072B2",
           "tRNA and rRNA" = "#D55E00", "Other genes" = "#9A9A9A")
  nokey <- function(x) x[setdiff(names(x), c("species", "chr"))]
  skew <- nokey(d$gc); skew$value <- rep(c(-0.2, 0, 0.2), length.out = nrow(skew))
  ring <- plot_circular_synteny(d$syn, "Arabidopsis", ribbon_fill = "class", ribbon_palette = pal,
                                ribbon_legend = FALSE, label_size = 0, species_label_size = 0) +
    syn_track_feature(nokey(d$regions), fill = "region", label = "region", height = 0.07, gap = 0,
                      show.legend = FALSE) +
    syn_axis(by = 10000, unit = "kb", gap = 0) +
    syn_track_feature(nokey(d$genes), fill = "class", strand = "split", palette = pal, position = "inside",
                      height = 0.14, out_of_bounds = "clip") +
    syn_track_line(nokey(d$gc), limits = c(20, 60), reference = 36.3, position = "inside",
                   height = 0.17, out_of_bounds = "clip") +
    syn_track_heatmap(skew, name = "GC skew", limits = c(-0.25, 0.25), position = "inside",
                      height = 0.05, out_of_bounds = "clip")
  tracks <- attr(ring, "synteny_tracks")
  expect_equal(vapply(tracks, `[[`, "", "geom"), c("feature", "axis", "feature", "line", "heatmap"))
  expect_equal(vapply(tracks, `[[`, "", "position"), c("outside", "outside", "inside", "inside", "inside"))
  expect_equal(nrow(tracks[[3]]$data), nrow(d$genes))
  expect_equal(unique(tracks[[5]]$data$seq_id), "plastid")
  expect_s3_class(ring$scales$get_scales("syn_track5"), "ScaleContinuous")
  expect_equal(length(unique(attr(ring, "circular_links")$fill_color)), 4L)
  expect_s3_class(track_test_render(ring), "gtable")
  interactive <- plot_circular_synteny(d$syn, "Arabidopsis", ribbon_fill = "class", interactive = TRUE) +
    syn_track_feature(d$genes, fill = "class", position = "inside")
  expect_s3_class(track_test_render(interactive), "gtable")
})

test_that("syn_track picks the geom from the table and the wrappers fix it", {
  d <- chloroplast()
  p <- plot_circular_synteny(d$syn, "Arabidopsis", ribbon_fill = "uniform")
  expect_equal(syn_track(d$gc)$geom, "heatmap")
  expect_equal(syn_track(d$genes)$geom, "feature")
  expect_equal(syn_track(d$genes, fill = "class")$geom, "feature")
  gc_class <- d$gc; gc_class$kind <- "window"
  expect_equal(syn_track(gc_class, fill = "kind")$geom, "feature")
  expect_equal(syn_track(gc_class, label = "kind")$geom, "feature")
  expect_equal(syn_track(d$genes, strand = "arrow")$geom, "feature")
  expect_equal(syn_track(d$gc, geom = "bar")$geom, "bar")
  expect_error(syn_track(d$gc, geom = "violin"), "should be one of")
  expect_error(syn_track(d$genes, geom = "line"), "value must be numeric")
  # Wrappers produce the same object as the long spelling.
  expect_equal(syn_track_feature(d$genes, fill = "class", strand = "split"),
               syn_track(d$genes, geom = "feature", fill = "class", strand = "split"))
  expect_equal(syn_track_heatmap(d$gc, name = "x"), syn_track(d$gc, geom = "heatmap", name = "x"))
  expect_equal(syn_track_line(d$gc, reference = 40), syn_track(d$gc, geom = "line", reference = 40))
  expect_equal(syn_track_bar(d$gc, baseline = 10), syn_track(d$gc, geom = "bar", baseline = 10))
  # Per-geom defaults.
  expect_equal(syn_track(d$gc)$name, "GC (%)")
  expect_equal(syn_track(d$gc)$height, 0.10)
  expect_equal(syn_track(d$genes, fill = "class")$name, "class")
  expect_equal(syn_track(d$genes)$height, 0.08)
  expect_true(is.na(syn_track(d$genes)$colour))
  expect_equal(syn_track(d$gc, geom = "line")$colour, "#246B78")
  expect_s3_class(track_test_render(p + syn_track_bar(d$gc, out_of_bounds = "clip") +
                                      syn_track_heatmap(d$gc, out_of_bounds = "clip", position = "inside")),
                  "gtable")
})

test_that("missing sequence keys are inferred when the plot is unambiguous", {
  d <- chloroplast()
  nokey <- function(x) x[setdiff(names(x), c("species", "chr"))]
  p <- plot_circular_synteny(d$syn, "Arabidopsis", ribbon_fill = "uniform")
  a <- p + syn_track_heatmap(nokey(d$gc), out_of_bounds = "clip")
  b <- p + syn_track_heatmap(d$gc, out_of_bounds = "clip")
  expect_equal(ggplot2::ggplot_build(a)$data, ggplot2::ggplot_build(b)$data)
  kept <- attr(a, "synteny_tracks")[[1]]$data
  expect_equal(unique(kept$group), "Arabidopsis")
  expect_equal(unique(kept$seq_id), "plastid")
  only_chr <- d$gc[setdiff(names(d$gc), "species")]
  expect_equal(ggplot2::ggplot_build(p + syn_track_heatmap(only_chr, out_of_bounds = "clip"))$data,
               ggplot2::ggplot_build(b)$data)
  wrong_chr <- only_chr; wrong_chr$chr <- "mito"
  expect_error(p + syn_track_heatmap(wrong_chr), "unknown sequence")
  # Several species: species is required; chr is required when a species has several sequences.
  s <- example_synteny_data()
  mac <- plot_synteny(s, unique(s$chromosomes$species))
  values <- data.frame(start = 0, end = 5, value = 50)
  expect_error(mac + syn_track(values), "needs a species/group column")
  values$species <- s$chromosomes$species[1]
  if (sum(s$chromosomes$species == values$species) > 1)
    expect_error(mac + syn_track(values), "needs a chr/seq_id column")
  # A sequence name unique across species identifies its species.
  chrs <- data.frame(species = c("A", "B"), chr = c("x", "y"), size = 10)
  blocks <- data.frame(species1 = "A", chr1 = "x", start1 = 1, end1 = 2,
                       species2 = "B", chr2 = "y", start2 = 1, end2 = 2)
  two <- plot_circular_synteny(list(chromosomes = chrs, blocks = blocks))
  by_chr <- two + syn_track(data.frame(chr = c("x", "y"), start = 0, end = 5, value = 50))
  expect_equal(attr(by_chr, "synteny_tracks")[[1]]$data$group, c("A", "B"))
  shared <- plot_circular_synteny(list(chromosomes = data.frame(species = c("A", "B"), chr = "x", size = 10),
                                       blocks = blocks[0, ]))
  expect_error(shared + syn_track(data.frame(chr = "x", start = 0, end = 5, value = 50)), "shared")
  expect_error(gc_content(data.frame(sequence = "ACGT")), "Supply group")
  # A species the plot does not show is omitted with the usual warning, even without chr.
  foreign <- data.frame(species = "Nicotiana", start = 0, end = 5, value = 50)
  expect_warning(q <- p + syn_track(foreign), "omitted")
  expect_equal(length(q$layers), length(p$layers))
  mixed <- rbind(foreign, data.frame(species = "Arabidopsis", start = 0, end = 5, value = 50))
  expect_warning(q <- p + syn_track(mixed), "1 track rows omitted")
  expect_equal(attr(q, "synteny_tracks")[[1]]$data$seq_id, "plastid")
})
