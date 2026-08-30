test_that("syn_palettes returns the 32 ltc palettes", {
  pals <- syn_palettes()
  expect_type(pals, "list")
  expect_length(pals, 32)
  expect_true("casa_natal" %in% names(pals))
  expect_true(all(grepl("^#", unlist(pals))))
})

test_that("palette names match case-insensitively, ignoring separators", {
  base <- syn_palettes()$casa_natal
  expect_identical(syn_pal("casa_natal", 5), base[1:5])
  expect_identical(syn_pal("Casa Natal", 5), base[1:5])
  expect_identical(syn_pal("casanatal", 5), base[1:5])
  expect_identical(syn_pal("CASA-NATAL", 5), base[1:5])
})

test_that("syn_pal interpolates when more colors are needed", {
  cols <- syn_pal("trio1", 7)
  expect_length(cols, 7)
  # heatmap palettes are ramps: always interpolated end-to-end
  ramp <- syn_pal("heatmap0", 3)
  expect_length(ramp, 3)
  expect_false(identical(ramp, syn_palettes()$heatmap0[1:3]))
})

test_that("syn_pal accepts Okabe-Ito, color vectors, and hcl.colors names", {
  expect_length(syn_pal("Okabe-Ito", 10), 10)
  expect_identical(syn_pal(c("#000000", "#FFFFFF"), 2), c("#000000", "#FFFFFF"))
  expect_length(syn_pal("Viridis", 4), 4)
  expect_error(syn_pal("no_such_palette", 3), "Unknown palette")
})

test_that("plot_synteny accepts palette = 'casa_natal'", {
  syn <- example_synteny_data()
  sp_order <- c("Arabidopsis", "Grape", "Rice")

  p <- plot_synteny(syn, sp_order, palette = "casa_natal")
  expect_s3_class(p, "ggplot")

  # per-chr chromosomes from a named ltc palette
  p2 <- plot_synteny(syn, sp_order, chr_fill = "per_chr",
                     chr_palette = "minou", palette = "casa_natal")
  expect_s3_class(p2, "ggplot")

  # invalid fill modes error early
  expect_error(plot_synteny(syn, sp_order, chr_fill = "rainbow"))
  expect_error(plot_synteny(syn, sp_order, ribbon_fill = "sparkles"))
})

test_that("plot_microsynteny accepts palette = 'casa_natal'", {
  micro <- demo_microsynteny_data()
  bin_order <- c("ZONMW-30", "ZONMW-20", "ZONMW-10")

  p <- plot_microsynteny(micro$features, micro$links, bin_order,
                         palette = "casa_natal")
  expect_s3_class(p, "ggplot")

  # a named ramp palette drives the identity coloring
  p2 <- plot_microsynteny(micro$features, micro$links, bin_order,
                          ribbon_fill = "identity", ribbon_palette = "heatmap0")
  expect_s3_class(p2, "ggplot")

  expect_error(plot_microsynteny(micro$features, micro$links, bin_order,
                                 gene_fill = "rainbow"))
})

test_that("named vectors still work as explicit key-to-color mappings", {
  syn <- example_synteny_data()
  sp_order <- c("Arabidopsis", "Grape", "Rice")

  p <- plot_synteny(syn, sp_order,
                    chr_fill = "per_species",
                    chr_palette = c("Arabidopsis" = "#B8D4E3",
                                    "Grape" = "#C5B4E3",
                                    "Rice" = "#B8E3C5"))
  expect_s3_class(p, "ggplot")
})
