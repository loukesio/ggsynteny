test_that("read_mcscanx keeps back-to-back alignment blocks", {
  # Real MCScanX output writes blocks with NO blank line between them;
  # every block except the last used to be dropped.
  gff <- "aa1\tgeneA1\t100\t2000\naa1\tgeneA2\t3000\t5000\nbb2\tgeneB1\t200\t1500\nbb2\tgeneB2\t4000\t6000\n"
  coll <- paste(
    "############### Parameters ###############",
    "# MATCH_SCORE: 50",
    "## Alignment 0: score=100.0 e_value=0 N=2 aa1&bb2 plus",
    "  0-  0:\tgeneA1\tgeneB1\t0",
    "  0-  1:\tgeneA2\tgeneB2\t0",
    "## Alignment 1: score=90.0 e_value=0 N=1 bb2&aa1 minus",
    "  1-  0:\tgeneB1\tgeneA2\t0",
    sep = "\n"
  )
  gff_file  <- tempfile(fileext = ".gff")
  coll_file <- tempfile(fileext = ".collinearity")
  writeLines(gff, gff_file)
  writeLines(coll, coll_file)

  syn <- read_mcscanx(coll_file, gff_file)

  expect_equal(nrow(syn$blocks), 2)
  expect_equal(syn$blocks$species1, c("aa", "bb"))
  expect_equal(syn$blocks$n_genes, c(2, 1))
  # header chromosome pair is trusted for coordinates
  expect_equal(syn$blocks$chr1, c("1", "2"))
  expect_equal(syn$blocks$chr2, c("2", "1"))
})

test_that("rice_sorghum dataset is plottable real data", {
  data(rice_sorghum, envir = environment())

  expect_named(rice_sorghum, c("chromosomes", "blocks"))
  expect_setequal(unique(rice_sorghum$chromosomes$species), c("Rice", "Sorghum"))
  expect_true(all(rice_sorghum$blocks$n_genes >= 20))
  expect_true(all(rice_sorghum$blocks$species1 != rice_sorghum$blocks$species2))

  p <- plot_synteny(rice_sorghum, c("Rice", "Sorghum"), palette = "casa_natal")
  expect_s3_class(p, "ggplot")
})

test_that("ribbon_anchor accepts body and full, rejects typos", {
  micro <- demo_microsynteny_data()
  bins <- c("ZONMW-30", "ZONMW-20", "ZONMW-10")

  p1 <- plot_microsynteny(micro$features, micro$links, bins,
                          ribbon_anchor = "body")
  p2 <- plot_microsynteny(micro$features, micro$links, bins,
                          ribbon_anchor = "full")
  expect_s3_class(p1, "ggplot")
  expect_s3_class(p2, "ggplot")
  expect_error(plot_microsynteny(micro$features, micro$links, bins,
                                 ribbon_anchor = "tip"))
})

test_that("interactive = TRUE builds ggiraph layers", {
  skip_if_not_installed("ggiraph")

  syn <- example_synteny_data()
  p <- plot_synteny(syn, c("Arabidopsis", "Grape", "Rice"),
                    interactive = TRUE)
  expect_s3_class(p, "ggplot")

  micro <- demo_microsynteny_data()
  pm <- plot_microsynteny(micro$features, micro$links,
                          c("ZONMW-30", "ZONMW-20", "ZONMW-10"),
                          interactive = TRUE)
  expect_s3_class(pm, "ggplot")

  w <- syn_girafe(p)
  expect_s3_class(w, "girafe")
})

test_that("top-level palette does not hijack the identity ramp", {
  micro <- demo_microsynteny_data()
  bins <- c("ZONMW-30", "ZONMW-20", "ZONMW-10")

  # identity ribbons keep the default blue ramp under a qualitative palette
  p_pal  <- plot_microsynteny(micro$features, micro$links, bins,
                              palette = "casa_natal", ribbon_fill = "identity")
  p_none <- plot_microsynteny(micro$features, micro$links, bins,
                              ribbon_fill = "identity")
  expect_identical(p_pal$layers[[1]]$aes_params$fill,
                   p_none$layers[[1]]$aes_params$fill)

  # ...but an explicit ribbon_palette does restyle it
  p_ramp <- plot_microsynteny(micro$features, micro$links, bins,
                              ribbon_fill = "identity",
                              ribbon_palette = "heatmap0")
  expect_false(identical(p_ramp$layers[[1]]$aes_params$fill,
                         p_none$layers[[1]]$aes_params$fill))
})

test_that("chr_radius and gene_radius round corners via ggforce", {
  skip_if_not_installed("ggforce")

  syn <- example_synteny_data()
  p <- plot_synteny(syn, c("Arabidopsis", "Grape", "Rice"), chr_radius = 1.5)
  expect_s3_class(p, "ggplot")

  micro <- demo_microsynteny_data()
  pm <- plot_microsynteny(micro$features, micro$links,
                          c("ZONMW-30", "ZONMW-20", "ZONMW-10"),
                          gene_radius = 0.8)
  expect_s3_class(pm, "ggplot")

  # rounding falls back to square with a warning when interactive
  skip_if_not_installed("ggiraph")
  expect_warning(
    plot_synteny(syn, c("Arabidopsis", "Grape", "Rice"),
                 chr_radius = 1.5, interactive = TRUE),
    "square corners"
  )
})
