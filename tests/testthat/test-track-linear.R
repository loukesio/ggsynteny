test_that("linear lanes expand rows and ribbons never cross track bundles", {
  m <- demo_microsynteny_data()
  s <- example_synteny_data()
  f <- m$features; f$value <- 50
  c <- s$chromosomes; c$start <- 0; c$end <- c$size; c$value <- 50
  plots <- list(plot_microsynteny(m$features, m$links, label_genes = FALSE),
                plot_microsynteny(m$features, m$links, bin_order = rev(unique(f$bin_id))),
                plot_synteny(s, rev(unique(c$species)), chr_radius = 0),
                plot_synteny(s, unique(c$species), chr_radius = 1))
  for (i in seq_along(plots)) {
    p <- plots[[i]]
    d <- if (i <= 2) f else c
    original <- ggplot2::ggplot_build(p)$data
    q <- p + list(syn_track(d, height = 0.2), syn_track(d, geom = "line", height = 0.4),
                  syn_track(d, geom = "bar", height = 0.5))
    layout <- attr(q, "synteny_layout")
    rows <- sort(unique(layout$sectors$y), decreasing = TRUE)
    expect_equal(unname(-diff(rows)), rep(layout$unit + layout$used, length(rows) - 1L))
    lanes <- attr(q, "synteny_tracks")
    expect_true(all(vapply(lanes, function(lane) lane$lower < lane$upper && lane$upper < -layout$edge, logical(1))))
    expect_lt(lanes[[2]]$upper, lanes[[1]]$lower)
    expect_lt(lanes[[3]]$upper, lanes[[2]]$lower)
    ribbons <- q$layers[[1]]$data
    for (piece in unique(ribbons$.track_piece)) {
      r <- ribbons[ribbons$.track_piece == piece, ]
      j <- r$.track_row[1]
      expect_gte(min(r$y), rows[j + 1L] + layout$edge - 1e-8)
      expect_lte(max(r$y), rows[j] - layout$edge - layout$used + 1e-8)
    }
    for (layer in q$layers) {
      data <- layer$data
      if (is.data.frame(data) && "ly" %in% names(data)) expect_true(all(data$ly > data$y))
    }
    expect_no_warning(track_test_render(q))
    expect_equal(ggplot2::ggplot_build(p)$data, original)
  }
})

test_that("skipped-row links split into separate gaps without losing identity", {
  f <- data.frame(bin_id = c("A", "B", "C"), seq_id = "one", start = 0, end = 100,
                  feat_id = c("a", "b", "c"), name = "gene", strand = "+", value = 50)
  # Include both directions and an intra-row link.
  links <- data.frame(feat_id_a = c("a", "c", "b"), feat_id_b = c("c", "a", "b"))
  p <- plot_microsynteny(f, links, label_genes = FALSE)
  q <- p + syn_track(f) + syn_track(f, geom = "bar")
  d <- q$layers[[1]]$data
  expect_equal(sort(unique(d$link_id)), 1:3)
  expect_length(unique(d$.track_piece[d$link_id == 1]), 2)
  expect_length(unique(d$.track_piece[d$link_id == 2]), 2)
  expect_length(unique(d$.track_piece[d$link_id == 3]), 1)
  expect_equal(unique(d$tooltip), unique(p$layers[[1]]$data$tooltip))
  expect_equal(q$layers[[1]]$aes_params$fill, d$ribbon_color)
  expect_no_warning(track_test_render(q))
})

test_that("ggplot2 elements style or remove each part independently", {
  f <- data.frame(bin_id = "A", seq_id = "one", start = c(0, 50), end = c(50, 100),
                  feat_id = c("a", "b"), name = "gene", strand = "+", value = c(25, 75))
  links <- data.frame(feat_id_a = character(), feat_id_b = character())
  for (fun in list(plot_microsynteny, plot_circular_microsynteny)) {
    p <- fun(f, links)
    for (geom in c("line", "bar", "heatmap")) {
      q <- p + syn_track(f, geom = geom, colour = "purple", reference = 50,
        background = ggplot2::element_rect(fill = "ivory", colour = "brown", linewidth = 0.8),
        border = ggplot2::element_line(colour = "orange", linewidth = 0.6),
        reference_line = ggplot2::element_line(colour = "red", linetype = "dotted", linewidth = 0.9))
      layers <- tail(q$layers, length(q$layers) - length(p$layers))
      expect_true(any(vapply(layers, function(l) identical(l$aes_params$fill, "ivory"), logical(1))))
      expect_true(any(vapply(layers, function(l) identical(l$aes_params$colour, "orange"), logical(1))))
      if (geom != "heatmap") {
        ref <- Filter(function(l) is.data.frame(l$data) && "is_reference" %in% names(l$data) &&
                        all(l$data$is_reference), layers)[[1]]
        expect_equal(ref$aes_params[c("colour", "linetype", "linewidth")],
                     list(colour = "red", linetype = "dotted", linewidth = 0.9))
      }
      expect_no_warning(track_test_render(q))
      blank <- p + syn_track(f, geom = geom, axis = FALSE, reference = 50,
        background = ggplot2::element_blank(), border = ggplot2::element_blank(),
        reference_line = ggplot2::element_blank())
      expect_length(blank$layers, length(p$layers) + 1L)
      expect_no_warning(track_test_render(blank))
      if (geom != "heatmap") expect_false(grepl("50", blank$scales$get_scales("syn_track_key1")$labels))
    }
    # Hiding a reference at a limit must not also remove the boundary.
    q <- p + syn_track(f, geom = "line", reference = 0, reference_line = ggplot2::element_blank())
    guides <- Filter(function(l) is.data.frame(l$data) && "is_reference" %in% names(l$data), q$layers)
    expect_length(unique(guides[[1]]$data$track_interval), 2)
    q <- p + syn_track(f, geom = "line", reference = NULL)
    expect_false(any(vapply(q$layers, function(l) is.data.frame(l$data) &&
      "is_reference" %in% names(l$data) && any(l$data$is_reference), logical(1))))
  }
  expect_error(syn_track(f, background = "red"), "element_rect")
  expect_error(syn_track(f, border = ggplot2::element_rect()), "element_line")
})
