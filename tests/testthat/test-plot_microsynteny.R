test_that("plot_microsynteny creates ggplot object", {
  micro <- demo_microsynteny_data()
  p <- plot_microsynteny(micro$features, micro$links,
                         bin_order = c("ZONMW-30", "ZONMW-20", "ZONMW-10"))

  expect_s3_class(p, "ggplot")
})

test_that("plot_microsynteny handles different gene coloring", {
  micro <- demo_microsynteny_data()
  bin_order <- c("ZONMW-30", "ZONMW-20", "ZONMW-10")

  # Per-name coloring
  p1 <- plot_microsynteny(micro$features, micro$links, bin_order,
                          gene_fill = "per_name")
  expect_s3_class(p1, "ggplot")

  # Uniform coloring
  p2 <- plot_microsynteny(micro$features, micro$links, bin_order,
                          gene_fill = "uniform")
  expect_s3_class(p2, "ggplot")
})

test_that("demo_microsynteny_data returns correct structure", {
  micro <- demo_microsynteny_data()

  expect_type(micro, "list")
  expect_named(micro, c("features", "links"))
  expect_s3_class(micro$features, "data.frame")
  expect_s3_class(micro$links, "data.frame")
  expect_true(all(c("bin_id", "seq_id", "start", "end", "strand", "feat_id", "name") %in% names(micro$features)))
  expect_true(all(c("feat_id_a", "feat_id_b", "identity") %in% names(micro$links)))
})

test_that("plot_microsynteny validates input", {
  expect_error(
    plot_microsynteny(data.frame(), data.frame()),
    "features missing"
  )
})
