circular_test_render <- function(p) {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  ggplot2::ggplotGrob(p + ggplot2::labs(caption = "Added through ggplot2") +
                      ggplot2::theme(plot.background = ggplot2::element_rect(fill = "white")))
}

circular_test_data <- function() {
  list(chromosomes = data.frame(species = c("A", "B", "C"), chr = c(5, 5, 5), size = c(100, 100, 200)),
       blocks = data.frame(species1 = c("A", "A", "B"), chr1 = 5, start1 = c(0, 10, 20), end1 = c(50, 40, 60),
                            species2 = c("B", "C", "C"), chr2 = 5, start2 = c(20, 30, 50), end2 = c(60, 90, 100)))
}

test_that("circular macro uses native ggplot2 layers and retains all pairs", {
  syn <- circular_test_data()
  original <- syn
  p <- plot_circular_synteny(syn, palette = "casa_natal")
  expect_s3_class(p, "ggplot")
  expect_equal(nrow(p$data), 3)
  expect_equal(nrow(attr(p, "circular_links")), 3)
  expect_true(all(vapply(p$layers, function(layer) inherits(layer$geom, "GeomPolygon") ||
                          inherits(layer$geom, "GeomText"), logical(1))))
  expect_equal(p$coordinates$aspect(ggplot2::ggplot_build(p)$layout$panel_params[[1]]), 1)
  expect_no_error(circular_test_render(p))
  expect_identical(syn, original)
  data(rice_sorghum, envir = environment())
  pr <- plot_circular_synteny(rice_sorghum, c("Rice", "Sorghum"), palette = "casa_natal", chr_fill = "per_species")
  expect_equal(nrow(pr$data), 22)
  expect_equal(nrow(attr(pr, "circular_links")), 100)
  expect_no_error(circular_test_render(pr))
})

test_that("sector widths preserve a common genomic scale and coordinate endpoints", {
  p <- plot_circular_synteny(circular_test_data(), gap = 0, group_gap = 0)
  widths <- abs(p$data$theta_end - p$data$theta_start)
  expect_equal(widths, c(pi / 2, pi / 2, pi))
  expect_equal(sum(widths), 2 * pi)
  b <- attr(p, "circular_links")
  expect_equal(b$a0[1], pi / 2)
  expect_equal(b$a1[1], pi / 4)
  expect_equal(b$b0[1], -pi / 10)
  expect_equal(b$b1[1], -3 * pi / 10)
  p2 <- plot_circular_synteny(circular_test_data(), species_order = c("C", "A"), clockwise = FALSE)
  expect_identical(p2$data$group_name, c("C", "A"))
  expect_true(all(p2$data$theta_end > p2$data$theta_start))
  expect_identical(attr(p2, "circular_links")$block_id, 2L)
  expect_identical(attr(p2, "circular_links")$species1, "C")
})

test_that("macro palette names, aliases and numeric color keys work", {
  syn <- circular_test_data()
  for (alias in c("casa_natal", "Casa Natal", "CASA-NATAL")) {
    p <- plot_circular_synteny(syn, palette = alias)
    expect_equal(unique(p$data$fill_color), syn_palettes()$casa_natal[1])
    expect_no_error(circular_test_render(p))
  }
  p <- plot_circular_synteny(syn, chr_fill = "per_chr", chr_palette = c("5" = "red"), ribbon_palette = c("5" = "blue"))
  expect_equal(unique(p$data$fill_color), "red")
  expect_equal(unique(attr(p, "circular_links")$fill_color), "blue")
  p <- plot_circular_synteny(syn, palette = c("red", "blue"), ribbon_fill = "uniform")
  expect_equal(unique(p$data$fill_color), "red")
  expect_equal(unique(attr(p, "circular_links")$fill_color), "red")
  expect_no_error(circular_test_render(plot_circular_synteny(syn, palette = "Viridis")))
  syn <- example_synteny_data()
  p <- plot_circular_synteny(syn, palette = "casa_natal", chr_fill = "per_chr")
  b <- attr(p, "circular_links")
  expect_equal(b$fill_color, p$data$fill_color[match(b$chr1, p$data$sector_name)])
})

test_that("custom block colors follow original rows after species selection", {
  p <- plot_circular_synteny(circular_test_data(), c("A", "C"), ribbon_fill = "custom",
                             ribbon_palette = c("red", "blue", "green"))
  expect_identical(attr(p, "circular_links")$block_id, 2L)
  expect_equal(attr(p, "circular_links")$fill_color, "blue")
  expect_no_error(circular_test_render(p))
})

test_that("orientation metadata controls endpoints only when requested", {
  syn <- circular_test_data()
  syn$blocks <- syn$blocks[c(1, 1), ]
  syn$blocks$orientation <- c("plus", "minus")
  p <- plot_circular_synteny(syn)
  d <- p$layers[[1]]$data
  expect_equal(d$x[d$circular_id == "block_1"], d$x[d$circular_id == "block_2"])
  p <- plot_circular_synteny(syn, show_orientation = TRUE)
  d <- p$layers[[1]]$data
  expect_false(identical(d$x[d$circular_id == "block_1"], d$x[d$circular_id == "block_2"]))
  expect_identical(attr(p, "circular_links")$orientation, c("plus", "minus"))
  expect_no_error(circular_test_render(p))
  syn$blocks$orientation <- NULL
  expect_error(plot_circular_synteny(syn, show_orientation = TRUE), "orientation")
})

test_that("micro arrows preserve strand and keep ribbons on gene bodies", {
  micro <- demo_microsynteny_data()
  original <- micro
  for (clockwise in c(TRUE, FALSE)) {
    p <- plot_circular_microsynteny(micro$features, micro$links, palette = "casa_natal", clockwise = clockwise)
    expect_s3_class(p, "ggplot")
    f <- attr(p, "circular_features")
    b <- attr(p, "circular_links")
    expect_equal(nrow(f), 16)
    expect_equal(nrow(b), 11)
    arrows <- p$layers[[3]]$data
    for (strand in c("+", "-")) {
      row <- which(f$strand == strand)[1]
      theta <- if (strand == "+") f$theta_end[row] else f$theta_start[row]
      d <- arrows[arrows$circular_id == paste0("gene_", f$feat_id[row]), ]
      tip <- c(cos(theta), sin(theta)) * (1 - 0.065 / 2)
      expect_lt(min((d$x - tip[1])^2 + (d$y - tip[2])^2), 1e-20)
      expect_lt(abs(f$body_end[row] - f$body_start[row]), abs(f$theta_end[row] - f$theta_start[row]))
    }
    expect_equal(b$a0, f$body_start[match(b$feat_id_a, f$feat_id)])
    expect_equal(b$b1, f$body_end[match(b$feat_id_b, f$feat_id)])
    expect_no_error(circular_test_render(p))
  }
  expect_identical(micro, original)
  p <- plot_circular_microsynteny(micro$features, micro$links, ribbon_anchor = "full")
  f <- attr(p, "circular_features")
  expect_equal(f$body_start, f$theta_start)
  expect_equal(f$body_end, f$theta_end)
})

test_that("micro identity and per-name palettes retain their meaning", {
  micro <- demo_microsynteny_data()
  p <- plot_circular_microsynteny(micro$features, micro$links, palette = "casa_natal")
  expect_equal(attr(p, "circular_links")$fill_color, identity_color(micro$links$identity))
  p <- plot_circular_microsynteny(micro$features, micro$links, palette = "Casa Natal", ribbon_fill = "per_name")
  f <- attr(p, "circular_features")
  b <- attr(p, "circular_links")
  expect_equal(b$fill_color, f$fill_color[match(b$feat_id_a, f$feat_id)])
  micro$links$identity[1:3] <- c(0, 100, NA)
  p <- plot_circular_microsynteny(micro$features, micro$links, ribbon_palette = "Viridis")
  expect_equal(attr(p, "circular_links")$fill_color[1:3],
                c(grDevices::hcl.colors(101, "Viridis")[c(1, 101)], "#888888"))
  expect_no_error(circular_test_render(p))
})

test_that("empty links and subset views retain valid sectors and genes", {
  syn <- circular_test_data()
  syn$blocks <- syn$blocks[FALSE, ]
  expect_no_error(circular_test_render(plot_circular_synteny(syn)))
  micro <- demo_microsynteny_data()
  for (mode in c("identity", "per_name", "uniform")) {
    p <- plot_circular_microsynteny(micro$features, micro$links[FALSE, c("feat_id_a", "feat_id_b")], ribbon_fill = mode)
    expect_equal(nrow(attr(p, "circular_features")), 16)
    expect_equal(nrow(attr(p, "circular_links")), 0)
    expect_no_error(circular_test_render(p))
  }
  p <- plot_circular_microsynteny(micro$features, micro$links, "ZONMW-30")
  expect_equal(nrow(p$data), 2)
  expect_equal(nrow(attr(p, "circular_features")), 8)
  expect_equal(nrow(attr(p, "circular_links")), 0)
  expect_no_error(circular_test_render(p))
})

test_that("invalid circular coordinates, keys and parameters fail explicitly", {
  syn <- circular_test_data()
  expect_error(plot_circular_synteny(syn, c("A", "unknown")), "species_order")
  expect_error(plot_circular_synteny(syn, group_gap = 120), "gaps")
  expect_error(plot_circular_synteny(syn, clockwise = NA), "clockwise")
  bad <- syn; bad$chromosomes$size[1] <- NA_real_
  expect_error(plot_circular_synteny(bad), "finite")
  bad <- syn; bad$chromosomes <- rbind(bad$chromosomes, bad$chromosomes[1, ])
  expect_error(plot_circular_synteny(bad), "Duplicate")
  bad <- syn; bad$blocks$chr1[1] <- 99
  expect_error(plot_circular_synteny(bad), "absent")
  bad <- syn; bad$blocks$end1[1] <- 101
  expect_error(plot_circular_synteny(bad), "bounds")
  micro <- demo_microsynteny_data()
  bad <- micro; bad$features$feat_id[2] <- bad$features$feat_id[1]
  expect_error(plot_circular_microsynteny(bad$features, bad$links), "unique")
  bad <- micro; bad$links$feat_id_a[1] <- "unknown"
  expect_error(plot_circular_microsynteny(bad$features, bad$links), "unknown")
  bad <- micro; bad$features$strand[1] <- "?"
  expect_error(plot_circular_microsynteny(bad$features, bad$links), "strand")
  bad <- micro; bad$features$end[1] <- bad$features$start[1]
  expect_error(plot_circular_microsynteny(bad$features, bad$links), "positive")
  bad <- micro; bad$links$identity[1] <- 101
  expect_error(plot_circular_microsynteny(bad$features, bad$links), "identity")
})

test_that("circular interactive views use ggiraph through ordinary ggplots", {
  skip_if_not_installed("ggiraph")
  micro <- demo_microsynteny_data()
  plots <- list(plot_circular_synteny(circular_test_data(), interactive = TRUE),
                plot_circular_microsynteny(micro$features, micro$links, interactive = TRUE))
  for (p in plots) {
    expect_s3_class(p, "ggplot")
    widget <- syn_girafe(p, width_svg = 7, height_svg = 7)
    expect_s3_class(widget, "girafe")
    expect_true(nchar(widget$x$html) > 100)
  }
})
