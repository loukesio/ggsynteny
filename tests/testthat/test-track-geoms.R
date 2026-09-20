track_geometry_fixture <- function(circular = FALSE, clockwise = TRUE) {
  features <- data.frame(bin_id = "A", seq_id = "one", start = 100, end = 900,
                          feat_id = "gene", name = "gene", strand = "+")
  links <- data.frame(feat_id_a = character(), feat_id_b = character())
  if (circular) plot_circular_microsynteny(features, links, clockwise = clockwise)
  else plot_microsynteny(features, links)
}

track_geometry_values <- function(values = c(0, 50, 100)) {
  data.frame(group = "A", seq_id = "one", start = c(100, 200, 300),
               end = c(200, 300, 400), value = values)
}

track_value_layers <- function(p, number = 1) {
  aesthetic <- paste0("syn_track_key", number)
  Filter(function(layer) aesthetic %in% names(layer$mapping), p$layers)
}

test_that("line values map to genomic midpoints and exact local heights", {
  p <- track_geometry_fixture()
  d <- track_geometry_values()
  q <- p + syn_track(d[c(3, 1, 2), ], geom = "line", reference = 50)
  trace <- track_value_layers(q)[[1]]$data
  lane <- attr(q, "synteny_tracks")[[1]]
  expect_equal(trace$x, c(50, 150, 150, 250))
  expect_equal(trace$y, lane$lower + c(0, 0.5, 0.5, 1) * (lane$upper - lane$lower))
  expect_no_warning(track_test_render(q))
  expect_identical(attr(q, "synteny_tracks")[[1]]$geom, "line")
})

test_that("circular lines interpolate within the lane in both directions", {
  for (clockwise in c(TRUE, FALSE)) {
    p <- track_geometry_fixture(TRUE, clockwise)
    d <- track_geometry_values()
    q <- p + syn_track(d, geom = "line", height = 0.2)
    trace <- track_value_layers(q)[[1]]$data
    lane <- attr(q, "synteny_tracks")[[1]]
    radius <- sqrt(trace$x^2 + trace$y^2)
    expect_equal(range(radius), c(lane$lower, lane$upper))
    angle <- p$data$theta_start + 50 / 800 * (p$data$theta_end - p$data$theta_start)
    expect_equal(c(trace$x[1], trace$y[1]), lane$lower * c(cos(angle), sin(angle)))
    angle_end <- p$data$theta_start + 250 / 800 * (p$data$theta_end - p$data$theta_start)
    expect_equal(c(tail(trace$x, 1), tail(trace$y, 1)), lane$upper * c(cos(angle_end), sin(angle_end)))
    # A constant-radius sparse line must follow an arc, not cut across it.
    d$value <- 0
    constant <- track_value_layers(p + syn_track(d, geom = "line"))[[1]]$data
    expect_equal(sqrt(constant$x^2 + constant$y^2), rep(1.03, nrow(constant)))
    expect_gt(nrow(constant), 4)
    expect_no_warning(track_test_render(q))
  }
})

test_that("lines break at missing values, sequence boundaries and uncovered gaps", {
  p <- track_geometry_fixture()
  d <- data.frame(group = "A", seq_id = "one", start = seq(100, 700, by = 100),
                  end = seq(200, 800, by = 100), value = c(10, 20, NA, 40, 50, NA, 70))
  q <- p + syn_track(d, geom = "line")
  layers <- track_value_layers(q)
  expect_length(layers, 2)
  expect_equal(length(unique(layers[[1]]$data$track_interval)), 2)
  expect_equal(nrow(layers[[2]]$data), 1)
  expect_no_warning(track_test_render(q))
  missing_row <- d[-3, ]
  q <- p + syn_track(missing_row, geom = "line")
  expect_equal(length(unique(track_value_layers(q)[[1]]$data$track_interval)), 2)
  d$value <- NA_real_
  q <- p + syn_track(d, geom = "line")
  expect_length(track_value_layers(q), 0)
  expect_no_warning(track_test_render(q))
  expect_error(p + syn_track(rbind(d[1, ], d[1, ]), geom = "line"), "distinct window midpoints")
  overlap <- track_geometry_values()
  overlap$end <- overlap$end + 50
  expect_no_warning(track_test_render(p + syn_track(overlap, geom = "line")))
})

test_that("bars span source intervals and support signed values and nonzero baselines", {
  d <- track_geometry_values(c(-1, 0, 1))
  for (circular in c(FALSE, TRUE)) {
    p <- track_geometry_fixture(circular)
    q <- p + syn_track(d, geom = "bar", limits = c(-1, 1), baseline = 0)
    bars <- track_value_layers(q)[[1]]$data
    lane <- attr(q, "synteny_tracks")[[1]]
    mid <- mean(c(lane$lower, lane$upper))
    for (i in 1:3) {
      xy <- bars[bars$track_interval == i, ]
      h <- if (circular) sqrt(xy$x^2 + xy$y^2) else xy$y
      expected <- sort(c(mid, c(lane$lower, mid, lane$upper)[i]))
      expect_equal(range(h), expected)
      if (!circular) expect_equal(range(xy$x), c(d$start[i], d$end[i]) - 100)
    }
    expect_no_warning(track_test_render(q))
    d_missing <- d; d_missing$value[2] <- NA_real_
    q_missing <- p + syn_track(d_missing, geom = "bar", limits = c(-1, 1))
    expect_equal(unique(track_value_layers(q_missing)[[1]]$data$track_interval), c(1L, 3L))
  }
})

test_that("mixed tracks compose across all plot types and axes stay with their genome", {
  m <- demo_microsynteny_data()
  f <- m$features; f$value <- 40
  syn <- example_synteny_data()
  c <- syn$chromosomes; c$start <- 0; c$end <- c$size; c$value <- 40
  plots <- list(plot_microsynteny(m$features, m$links),
                plot_circular_microsynteny(m$features, m$links),
                plot_synteny(syn, rev(unique(c$species))), plot_circular_synteny(syn))
  for (i in seq_along(plots)) {
    p <- plots[[i]]
    before <- ggplot2::ggplot_build(p)$data
    d <- if (i <= 2) f else c
    one <- p + syn_track(d, geom = "line", height = 0.13)
    axis_layers <- which(vapply(one$layers, function(l) is.data.frame(l$data) &&
      "track_axis" %in% names(l$data), logical(1)))
    mixed <- one + list(syn_track(d, height = 0.06), syn_track(d, geom = "bar", height = 0.10))
    for (j in axis_layers) {
      expected <- one$layers[[j]]$data
      if (attr(p, "synteny_layout")$type == "linear")
        expected$y <- expected$y - expected$.track_row * 0.22 * attr(p, "synteny_layout")$unit
      expect_equal(mixed$layers[[j]]$data, expected)
    }
    expect_equal(vapply(attr(mixed, "synteny_tracks"), `[[`, character(1), "geom"), c("line", "heatmap", "bar"))
    expect_false(is.null(mixed$scales$get_scales("syn_track2")))
    expect_false(is.null(mixed$scales$get_scales("syn_track_key1")))
    expect_false(is.null(mixed$scales$get_scales("syn_track_key3")))
    expect_no_warning(track_test_render(mixed))
    expect_equal(ggplot2::ggplot_build(p)$data, before)
    segments <- unique(unlist(lapply(track_value_layers(one), function(l) l$data$track_interval)))
    expect_gte(length(segments), length(unique(paste(d[[if (i <= 2) "bin_id" else "species"]],
                                          d[[if (i <= 2) "seq_id" else "chr"]]))))
  }
})

test_that("new style options are validated and hidden legends remain hidden", {
  d <- track_geometry_values()
  expect_error(syn_track(d, geom = "unknown"), "arg")
  expect_error(syn_track(d, linewidth = 0), "linewidth")
  expect_error(syn_track(d, reference = 101), "reference")
  expect_error(syn_track(d, baseline = -1), "baseline")
  expect_error(syn_track(d, colour = c("red", "blue")), "one non-missing")
  expect_error(syn_track(d, axis = NA), "axis")
  for (geom in c("line", "bar")) {
    q <- track_geometry_fixture() + syn_track(d, geom = geom, axis = FALSE, show.legend = FALSE)
    g <- track_test_render(q)
    expect_true(all(vapply(g$grobs[grepl("guide-box", g$layout$name)], inherits, logical(1), "zeroGrob")))
  }
})

test_that("line runs never join separate contigs and work with interactive plots", {
  features <- data.frame(bin_id = "A", seq_id = c("one", "two"), start = 100, end = 900,
                          feat_id = c("gene1", "gene2"), name = "gene", strand = "+")
  links <- data.frame(feat_id_a = character(), feat_id_b = character())
  d <- track_geometry_values()
  d2 <- d; d2$seq_id <- "two"
  d <- rbind(d, d2)
  for (fun in list(plot_microsynteny, plot_circular_microsynteny)) {
    p <- fun(features, links) + syn_track(d, geom = "line")
    expect_equal(unique(track_value_layers(p)[[1]]$data$track_interval), 1:2)
    expect_no_warning(track_test_render(p))
    if (requireNamespace("ggiraph", quietly = TRUE)) {
      interactive <- fun(features, links, interactive = TRUE) +
        syn_track(d, geom = "line") + syn_track(d, geom = "bar")
      expect_s3_class(syn_girafe(interactive), "girafe")
    }
  }
})

test_that("unrelated track layers cannot paint over another track's legend key", {
  p <- track_geometry_fixture() + list(
    syn_track(track_geometry_values()),
    syn_track(track_geometry_values(), geom = "line"),
    syn_track(track_geometry_values(), geom = "bar"))
  line <- track_value_layers(p, 2)[[1]]
  key <- data.frame(syn_track_key2 = "#176D81", linewidth = 0.6, linetype = 1, alpha = 1)
  grob <- line$geom$draw_key(key, list(), 5)
  expect_match(grob$gp$col, "176D81", ignore.case = TRUE)
  bar <- track_value_layers(p, 3)[[1]]
  expect_true(inherits(bar$geom$draw_key(key, list(), 5), "zeroGrob"))
  heat <- Filter(function(l) "syn_track1" %in% names(l$mapping), p$layers)[[1]]
  expect_true(inherits(heat$geom$draw_key(key, list(), 5), "zeroGrob"))
})
