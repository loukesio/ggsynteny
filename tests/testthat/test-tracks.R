test_that("GC counts use exact half-open intervals and exclude ambiguous bases", {
  dna <- data.frame(group = c("A", "B", "C"), seq_id = "1",
                    sequence = c("acgtGGccNNAT", "RYSWKMBDHVN", NA_character_))
  intervals <- data.frame(group = c("A", "A", "A", "B", "C"), seq_id = "1",
                           start = c(0, 4, 8, 0, 0), end = c(4, 8, 12, 11, 7))
  gc <- gc_content(dna, intervals)
  expect_equal(gc$value, c(50, 100, 0, NA, NA))
  expect_equal(gc$n_called, c(4, 4, 2, 0, NA))
  expect_equal(gc$n_ambiguous, c(0, 0, 2, 11, NA))
  sliding <- gc_content(dna[1, ], window = 5, step = 3)
  expect_equal(sliding$start, c(0, 3, 6, 9))
  expect_equal(sliding$end, c(5, 8, 11, 12))
  expect_equal(sliding$value, c(60, 80, 200/3, 0))
  expect_equal(gc_content(dna[1, ], window = 100)$value, 60)
  dna$sequence[1] <- "A C\nGT"
  expect_equal(gc_content(dna[1, ], window = 4)$value, 50)
  dna$sequence[1] <- ""
  expect_equal(nrow(gc_content(dna[1, ])), 0)
  expect_equal(nrow(gc_content(dna[FALSE, ])), 0)
})

test_that("GC calculation rejects ambiguous inputs and preserves feature identifiers", {
  dna <- data.frame(bin_id = "A", seq_id = "1", sequence = "ACGT")
  f <- data.frame(bin_id = "A", seq_id = "1", start = 0, end = 4, feat_id = "gene1")
  expect_identical(gc_content(dna, f)$feat_id, "gene1")
  expect_error(gc_content(rbind(dna, dna)), "unique")
  bad <- dna; bad$sequence <- "AC-T"
  expect_error(gc_content(bad), "IUPAC")
  bad$sequence <- NA_character_
  expect_error(gc_content(bad), "explicit intervals")
  expect_true(is.na(gc_content(bad, f)$value))
  badf <- f; badf$seq_id <- "missing"
  expect_error(gc_content(dna, badf), "unknown sequence")
  badf <- f; badf$end <- 5
  expect_error(gc_content(dna, badf), "bounds")
  badf$end <- 3.5
  expect_error(gc_content(dna, badf), "integer")
  expect_error(gc_content(dna, window = 0), "window")
  expect_error(gc_content(dna, step = 1.2), "integer")
})

test_that("linear gene tracks follow shifted contigs and reordered bins", {
  m <- demo_microsynteny_data()
  d <- m$features
  d$value <- rep(c(0, 50, 100, NA), length.out = nrow(d))
  p <- plot_microsynteny(m$features, m$links, bin_order = rev(unique(d$bin_id)),
                         palette = "casa_natal")
  before <- ggplot2::ggplot_build(p)$data
  q <- p + syn_track(d)
  expect_s3_class(q, "ggplot")
  expect_equal(ggplot2::ggplot_build(p)$data, before)
  arrows <- p$layers[[2]]$data
  tiles <- q$layers[[length(q$layers)]]$data
  for (i in seq_len(nrow(d))) {
    expect_equal(range(tiles$x[tiles$track_interval == i]),
                  range(arrows$x[arrows$feat_id == d$feat_id[i]]))
  }
  expect_equal(q$layers[[1]]$data, p$layers[[1]]$data)
  expect_equal(q$layers[[2]]$data, p$layers[[2]]$data)
  expect_no_warning(track_test_render(q + ggplot2::labs(title = "GC content")))
  expect_equal(ggplot2::ggplot_build(p)$data, before)
})

test_that("macro tracks align with chromosome bounds in both layouts", {
  syn <- example_synteny_data()
  d <- syn$chromosomes
  d$start <- 0; d$end <- d$size; d$value <- 50
  order <- rev(unique(d$species))
  p <- plot_synteny(syn, order, palette = "casa_natal")
  q <- p + syn_track(d)
  rects <- p$layers[[2]]$data
  tiles <- q$layers[[length(q$layers)]]$data
  for (i in seq_len(nrow(d))) {
    j <- which(rects$species == d$species[i] & rects$chr == d$chr[i])
    expect_equal(range(tiles$x[tiles$track_interval == i]), c(rects$xmin[j], rects$xmax[j]))
  }
  expect_no_warning(track_test_render(q))
  for (clockwise in c(TRUE, FALSE)) {
    p <- plot_circular_synteny(syn, order, start_angle = 25, clockwise = clockwise)
    q <- p + syn_track(d)
    tiles <- q$layers[[length(q$layers)]]$data
    for (i in seq_len(nrow(d))) {
      j <- which(p$data$group_name == d$species[i] & p$data$sector_name == d$chr[i])
      tile <- tiles[tiles$track_interval == i, ]
      expect_equal(c(tile$x[1], tile$y[1]), 1.13 * c(cos(p$data$theta_start[j]), sin(p$data$theta_start[j])))
      expect_equal(range(sqrt(tile$x^2 + tile$y^2)), c(1.03, 1.13))
    }
    expect_no_warning(track_test_render(q))
  }
})

test_that("circular gene tracks retain endpoints and support independent stacked scales", {
  m <- demo_microsynteny_data()
  d <- m$features; d$value <- rep(c(25, 75), length.out = nrow(d))
  for (clockwise in c(TRUE, FALSE)) {
    p <- plot_circular_microsynteny(m$features, m$links, clockwise = clockwise)
    before <- ggplot2::ggplot_build(p)$data
    q <- p + syn_track(d)
    f <- attr(p, "circular_features")
    tiles <- q$layers[[length(q$layers)]]$data
    for (i in seq_len(nrow(d))) {
      j <- match(d$feat_id[i], f$feat_id)
      tile <- tiles[tiles$track_interval == i, ]
      expect_equal(c(tile$x[1], tile$y[1]), 1.13 * c(cos(f$theta_start[j]), sin(f$theta_start[j])))
      endpoint <- nrow(tile) / 2
      expect_equal(c(tile$x[endpoint], tile$y[endpoint]), 1.13 * c(cos(f$theta_end[j]), sin(f$theta_end[j])))
      expect_equal(c(tail(tile$x, 1), tail(tile$y, 1)), 1.03 * c(cos(f$theta_start[j]), sin(f$theta_start[j])))
    }
    q2 <- q + syn_track(d, name = "Second measurement", palette = "casa_natal")
    expect_length(attr(q2, "synteny_tracks"), 2)
    expect_length(attr(q, "synteny_tracks"), 1)
    expect_equal(attr(q2, "synteny_tracks")[[2]]$lower, 1.16)
    expect_false(is.null(q2$scales$get_scales("syn_track2")))
    expect_false(is.null(q2$scales$get_scales("fill")))
    expect_no_warning(track_test_render(q2))
    expect_equal(ggplot2::ggplot_build(p)$data, before)
    expect_equal(q$coordinates$limits$x, c(-1.53, 1.53))
    expect_equal(p$coordinates$limits$x, c(-1.4, 1.4))
  }
})

test_that("missing values, empty tracks, exclusions and invalid intervals are explicit", {
  m <- demo_microsynteny_data()
  d <- m$features; d$value <- rep(NA_real_, nrow(d))
  p <- plot_circular_microsynteny(m$features, m$links)
  q <- p + syn_track(d, na.value = "orange")
  built <- ggplot2::ggplot_build(q)$data
  expect_equal(unique(tail(built, 1)[[1]]$syn_track1), "orange")
  expect_no_warning(track_test_render(q))
  empty <- p + syn_track(d[FALSE, ])
  expect_equal(ggplot2::ggplot_build(empty)$data, ggplot2::ggplot_build(p)$data)
  expect_null(attr(empty, "synteny_tracks"))
  one <- plot_circular_microsynteny(m$features, m$links, bin_order = d$bin_id[1])
  expect_warning(one + syn_track(d), "omitted")
  bad <- d; bad$seq_id[1] <- "unknown"
  expect_error(p + syn_track(bad), "unknown sequence")
  bad <- d; bad$end[1] <- 1e9
  expect_error(p + syn_track(bad), "bounds")
  bad <- d; bad$start[1] <- -1
  expect_error(syn_track(bad), "non-negative")
  bad <- d; bad$value[1] <- 101
  expect_error(syn_track(bad), "outside limits")
  bad$value[1] <- Inf
  expect_error(syn_track(bad), "finite")
  expect_error(syn_track(d, limits = c(1, 1)), "increasing")
  expect_error(ggplot2::ggplot() + syn_track(d), "ggsynteny")
  expect_error(plot_microsynteny(m$features, m$links) + syn_track(d, height = 1), "space")
  expect_no_warning(track_test_render(p + syn_track(d, show.legend = FALSE)))
  expect_error((p + ggplot2::facet_wrap(~group_name)) + syn_track(d), "faceting")
  flipped <- suppressMessages(p + ggplot2::coord_flip())
  expect_error(flipped + syn_track(d), "original Cartesian")
})

test_that("track scales can be replaced and legends can be hidden", {
  m <- demo_microsynteny_data()
  d <- m$features; d$value <- 50
  p <- plot_microsynteny(m$features, m$links) + syn_track(d)
  replacement <- scale_fill_syn_track(palette = c("red", "blue"), breaks = c(0, 50, 100))
  q <- suppressMessages(p + replacement)
  expect_equal(q$scales$get_scales("syn_track1")$breaks, c(0, 50, 100))
  expect_no_warning(track_test_render(q + ggplot2::theme(legend.position = "bottom")))
  expect_error(scale_fill_syn_track(track = 1.5), "integer")
  hidden <- plot_microsynteny(m$features, m$links) + syn_track(d, show.legend = FALSE)
  g <- track_test_render(hidden)
  guides <- g$grobs[grepl("guide-box", g$layout$name)]
  expect_true(all(vapply(guides, inherits, logical(1), "zeroGrob")))
})

test_that("track colors do not interfere with existing interactive layers", {
  skip_if_not_installed("ggiraph")
  m <- demo_microsynteny_data()
  d <- m$features; d$value <- 50
  for (fun in list(plot_microsynteny, plot_circular_microsynteny)) {
    p <- fun(m$features, m$links, interactive = TRUE) + syn_track(d)
    expect_s3_class(syn_girafe(p), "girafe")
  }
})
