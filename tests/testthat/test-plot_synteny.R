test_that("plot_synteny creates ggplot object", {
  syn <- example_synteny_data()
  p <- plot_synteny(syn, species_order = c("Arabidopsis", "Grape", "Rice"))

  expect_s3_class(p, "ggplot")
})

test_that("plot_synteny handles different color schemes", {
  syn <- example_synteny_data()
  sp_order <- c("Arabidopsis", "Grape", "Rice")

  # Uniform coloring
  p1 <- plot_synteny(syn, sp_order, chr_fill = "uniform")
  expect_s3_class(p1, "ggplot")

  # Per-species coloring
  p2 <- plot_synteny(syn, sp_order, chr_fill = "per_species")
  expect_s3_class(p2, "ggplot")

  # Per-chr coloring
  p3 <- plot_synteny(syn, sp_order, chr_fill = "per_chr")
  expect_s3_class(p3, "ggplot")
})

test_that("example_synteny_data returns correct structure", {
  syn <- example_synteny_data()

  expect_type(syn, "list")
  expect_named(syn, c("chromosomes", "blocks"))
  expect_s3_class(syn$chromosomes, "data.frame")
  expect_s3_class(syn$blocks, "data.frame")
  expect_true(all(c("species", "chr", "size") %in% names(syn$chromosomes)))
  expect_true(all(c("species1", "chr1", "start1", "end1", "species2", "chr2", "start2", "end2") %in% names(syn$blocks)))
})
