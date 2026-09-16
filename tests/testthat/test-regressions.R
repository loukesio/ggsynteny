# Keep graphics devices inside each rendering check so tests create no Rplots.pdf.
render_regression_plot <- function(p) {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  ggplot2::ggplotGrob(p)
}

test_that("casa_natal colors and plotted aliases remain stable", {
  expect_identical(syn_palettes()$casa_natal,
                   c("#245E55", "#ED773C", "#808BC5", "#C63F3E", "#EAC119",
                     "#EAA7C7", "#9ED6DF"))
  syn <- example_synteny_data()
  species <- c("Arabidopsis", "Grape", "Rice")
  reference <- ggplot2::ggplot_build(plot_synteny(syn, species, palette = "casa_natal"))$data
  for (alias in c("Casa Natal", "casanatal", "CASA-NATAL")) {
    expect_equal(ggplot2::ggplot_build(plot_synteny(syn, species, palette = alias))$data,
                 reference)
  }
})

test_that("uniform fills resolve color vectors and HCL palette names", {
  syn <- example_synteny_data()
  species <- c("Arabidopsis", "Grape", "Rice")
  micro <- demo_microsynteny_data()
  for (spec in list(c("#FF0000", "#0000FF"), "Viridis", "#FF0000")) {
    expected <- if (identical(spec, "Viridis")) grDevices::hcl.colors(1, "Viridis") else spec[1]
    p <- plot_synteny(syn, species, palette = spec, ribbon_fill = "uniform")
    expect_equal(unique(p$layers[[1]]$aes_params$fill), expected)
    expect_equal(unique(p$layers[[2]]$aes_params$fill), expected)
    expect_no_error(render_regression_plot(p))
    pm <- plot_microsynteny(micro$features, micro$links, palette = spec,
                            gene_fill = "uniform", ribbon_fill = "uniform")
    expect_equal(unique(pm$layers[[1]]$aes_params$fill), expected)
    expect_equal(unique(pm$layers[[2]]$aes_params$fill), expected)
    expect_no_error(render_regression_plot(pm))
  }
  expect_no_error(render_regression_plot(plot_synteny(syn, species, palette = c("red", "blue"))))
})

test_that("an explicit HCL identity ramp is applied", {
  micro <- demo_microsynteny_data()
  micro$links$identity <- rep(c(0, 50, 100), length.out = nrow(micro$links))
  p <- plot_microsynteny(micro$features, micro$links, ribbon_palette = "Viridis")
  d <- p$layers[[1]]$data
  actual <- d$ribbon_color[match(seq_len(nrow(micro$links)), d$link_id)]
  expect_equal(actual, grDevices::hcl.colors(101, "Viridis")[micro$links$identity + 1])
  expect_no_error(render_regression_plot(p))
})

test_that("numeric chromosome labels use named color keys", {
  syn <- list(
    chromosomes = data.frame(species = c("A", "B"), chr = c(5, 5), size = c(10, 10)),
    blocks = data.frame(species1 = "A", chr1 = 5, start1 = 1, end1 = 2,
                        species2 = "B", chr2 = 5, start2 = 1, end2 = 2))
  for (mode in c("source_chr", "target_chr")) {
    p <- plot_synteny(syn, c("A", "B"), chr_fill = "per_chr",
                      chr_palette = c("5" = "red"), ribbon_fill = mode,
                      ribbon_palette = c("5" = "blue"))
    expect_equal(unname(unique(p$layers[[2]]$aes_params$fill)), "red")
    expect_equal(unname(unique(p$layers[[1]]$aes_params$fill)), "blue")
    expect_no_error(render_regression_plot(p))
  }
})

test_that("genes and per-name ribbons share a palette mapping", {
  micro <- demo_microsynteny_data()
  for (spec in list(NULL, "casa_natal", c("red", "blue"))) {
    p <- plot_microsynteny(micro$features, micro$links, palette = spec,
                           ribbon_fill = "per_name")
    arrows <- p$layers[[2]]$data
    ribbons <- p$layers[[1]]$data
    expect_equal(unname(ribbons$ribbon_color[match(seq_len(nrow(micro$links)), ribbons$link_id)]),
                 unname(arrows$fill_color[match(micro$links$feat_id_a, arrows$feat_id)]))
  }
  p <- plot_microsynteny(micro$features, micro$links, gene_palette = "Casa Natal",
                         ribbon_palette = "casa_natal", ribbon_fill = "per_name")
  expect_equal(unname(p$layers[[1]]$data$ribbon_color[1]),
               unname(p$layers[[2]]$data$fill_color[match(micro$links$feat_id_a[1],
                                                       p$layers[[2]]$data$feat_id)]))
  p <- plot_microsynteny(micro$features, micro$links, palette = "casa_natal",
                         ribbon_palette = c(moaE = "red", moaC2 = "blue", moaA = "green",
                                            moeA = "orange", mobA = "purple"),
                         ribbon_fill = "per_name")
  expect_equal(p$layers[[1]]$data$ribbon_color[1], "red", ignore_attr = TRUE)
})

test_that("micro plots retain genes when no links remain", {
  micro <- demo_microsynteny_data()
  unmatched <- micro$links
  unmatched$feat_id_a <- "absent"
  for (links in list(micro$links[FALSE, ], micro$links[FALSE, c("feat_id_a", "feat_id_b")],
                     unmatched)) {
    for (mode in c("identity", "per_name", "uniform")) {
      p <- plot_microsynteny(micro$features, links, ribbon_fill = mode)
      expect_setequal(unique(p$layers[[1]]$data$feat_id), micro$features$feat_id)
      expect_no_error(render_regression_plot(p))
    }
  }
  p <- plot_microsynteny(micro$features, micro$links, bin_order = "ZONMW-30")
  expect_setequal(unique(p$layers[[1]]$data$feat_id),
                   micro$features$feat_id[micro$features$bin_id == "ZONMW-30"])
  expect_no_error(render_regression_plot(p))
})

test_that("micro ribbons meet facing gene edges after reordering", {
  micro <- demo_microsynteny_data()
  bins <- c("ZONMW-30", "ZONMW-20", "ZONMW-10")
  for (order in list(bins, rev(bins))) {
    for (anchor in c("body", "full")) {
      p <- plot_microsynteny(micro$features, micro$links, bin_order = order,
                             ribbon_anchor = anchor)
      ribbons <- p$layers[[1]]$data
      arrows <- p$layers[[2]]$data
      for (i in seq_len(nrow(micro$links))) {
        r <- ribbons[ribbons$link_id == i, ]
        a <- range(arrows$y[arrows$feat_id == micro$links$feat_id_a[i]])
        b <- range(arrows$y[arrows$feat_id == micro$links$feat_id_b[i]])
        expect_equal(r$y[1], if (mean(a) > mean(b)) min(a) else max(a))
        expect_equal(r$y[nrow(r) / 2], if (mean(a) > mean(b)) max(b) else min(b))
      }
      expect_no_error(render_regression_plot(p))
    }
  }
})

test_that("MCScanX preserves orientation and inversion rendering is opt-in", {
  gf <- tempfile(fileext = ".gff")
  cf <- tempfile(fileext = ".collinearity")
  writeLines(c("aa1\ta1\t100\t200", "aa1\ta2\t300\t400",
               "bb1\tb1\t500\t600", "bb1\tb2\t700\t800"), gf)
  writeLines(c("## Alignment 0: score=100.0 e_value=0 N=2 aa1&bb1 plus",
               "0- 0:\ta1\tb1\t0", "0- 1:\ta2\tb2\t0",
               "## Alignment 1: score=100.0 e_value=0 N=2 aa1&bb1 minus",
               "1- 0:\ta1\tb2\t0", "1- 1:\ta2\tb1\t0"), cf)
  syn <- read_mcscanx(cf, gf)
  expect_identical(syn$blocks$orientation, c("plus", "minus"))
  for (species in list(c("aa", "bb"), c("bb", "aa"))) {
    flat <- plot_synteny(syn, species)$layers[[1]]$data
    expect_equal(flat$x[flat$conn_id == 1], flat$x[flat$conn_id == 2])
    p <- plot_synteny(syn, species, show_inversions = TRUE)
    d <- p$layers[[1]]$data
    forward <- d[d$conn_id == 1, ]
    inverse <- d[d$conn_id == 2, ]
    half <- nrow(forward) / 2
    expect_equal(inverse$x[c(1, nrow(inverse))], forward$x[c(1, nrow(forward))])
    expect_equal(inverse$x[c(half, half + 1)], forward$x[c(half + 1, half)])
    expect_no_error(render_regression_plot(p))
  }
  syn$blocks$orientation <- NULL
  expect_error(plot_synteny(syn, c("aa", "bb"), show_inversions = TRUE), "orientation")
  syn$blocks$orientation <- c("plus", NA_character_)
  expect_error(plot_synteny(syn, c("aa", "bb"), show_inversions = TRUE), "orientation")
})
