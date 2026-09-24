test_that("reference rings support pairwise, multiple and empty comparisons", {
  v <- .reference_demo()
  for (samples in list("Genome A", c("Genome C", "Genome A"), "No calls")) {
    p <- plot_reference_comparison(v, 4.8e6, sample_order = samples)
    expect_silent(ggplot2::ggplot_build(p))
    expect_equal(nrow(p$layers[[4]]$data), length(samples) + 1)
  }
  p <- plot_reference_comparison(v, 4.8e6, types = character())
  expect_silent(ggplot2::ggplot_build(p))
  expect_match(p$labels$caption, "no supplied identity scores")
  expect_error(plot_reference_comparison(v, 100), "coordinates")
  v$type[1] <- "unknown"
  expect_error(plot_reference_comparison(v, 4.8e6), "types")
})

test_that("reference intervals use shared angles and stable ltc colours", {
  v <- data.frame(sample = c("A", "B"), type = "INV", start = 100, end = 200)
  g <- .reference_geometry(v, 1000, c("A", "B"), .reference_palette("minou"))
  e <- g$polygons[g$polygons$role == "event", ]
  groups <- split(e, e$group)
  expect_equal(atan2(groups[[1]]$y, groups[[1]]$x), atan2(groups[[2]]$y, groups[[2]]$x))
  expect_equal(unique(e$fill), unname(syn_palettes()$minou[4]))
  g2 <- .reference_geometry(v[1, ], 1000, "A", .reference_palette("casa_natal"))
  expect_equal(unique(g2$polygons$fill[g2$polygons$role == "event"]), unname(syn_palettes()$casa_natal[4]))
  v$end[1] <- 99
  expect_error(plot_reference_comparison(v, 1000), "coordinates")
  v$end[1] <- NA
  expect_error(plot_reference_comparison(v, 1000), "finite")
})

test_that("optional insertion sizes and duplication sources are validated", {
  v <- data.frame(sample = "A", type = "DUP", start = 100, end = 200, source_start = 950)
  expect_error(plot_reference_comparison(v, 1000), "source spans")
  v$source_start <- 500
  with_source <- .reference_geometry(v, 1000, "A", .reference_colors)
  without_source <- .reference_geometry(v[setdiff(names(v), "source_start")], 1000, "A", .reference_colors)
  expect_gt(nrow(with_source$polygons), nrow(without_source$polygons))
  unknown <- v; unknown$source_start <- NA
  expect_silent(ggplot2::ggplot_build(plot_reference_comparison(unknown, 1000)))
  v$event_length <- -1
  expect_error(plot_reference_comparison(v, 1000), "event_length")
})

test_that("reference hover view builds and reports exact positions", {
  skip_if_not_installed("ggiraph")
  p <- plot_reference_comparison(.reference_demo(), 4.8e6, interactive = TRUE)
  widget <- syn_girafe(p)
  expect_s3_class(widget, "girafe")
  expect_match(widget$x$html, "612000")
})

test_that("reference app filters, selects events and clears invalid uploads", {
  skip_if_not_installed("shiny")
  shiny::testServer(.reference_server, args = list(id = "test"), {
    session$setInputs(source = "demo", length = 4.8e6, reference = "Ref", title = "", palette = "minou", types = .reference_types)
    session$setInputs(samples = "Genome A")
    expect_equal(nrow(selected()), 4)
    expect_s3_class(plot(), "ggplot")
    session$setInputs(types = "DEL")
    expect_equal(nrow(selected()), 1)
    expect_equal(selected_event()$start, 612000)
    session$setInputs(palette = "casa_natal")
    expect_equal(nrow(selected()), 1)
    expect_equal(unname(colors()), syn_palettes()$casa_natal[1:5])
    session$setInputs(types = character())
    expect_equal(nrow(selected()), 0)
    expect_null(selected_event())
    expect_silent(ggplot2::ggplot_build(plot()))
    session$setInputs(source = "upload")
    expect_error(selected(), "Upload")
  })
})

test_that("font exports preserve the plot and write PDF and PNG files", {
  skip_if_not_installed("showtext"); skip_if_not_installed("sysfonts")
  p <- plot_reference_comparison(.reference_demo(), 4.8e6)
  families <- lapply(p$layers, function(x) x$aes_params$family)
  for (ext in c("pdf", "png")) {
    file <- tempfile(fileext = paste0(".", ext)); on.exit(unlink(file), add = TRUE)
    expect_silent(save_reference_comparison(p, file, width = 11, height = 11, dpi = 72))
    expect_gt(file.info(file)$size, 1000)
  }
  expect_equal(lapply(p$layers, function(x) x$aes_params$family), families)
})

test_that("identity scores are independently validated without filling missing regions", {
  w <- data.frame(sample = c("A", "A"), start = c(0, 200), end = c(100, 300), identity = c(99, NA))
  expect_equal(.reference_identity_validate(w, 1000), w)
  expect_false(.reference_identity_color(NA_real_) == .reference_identity_color(90))
  expect_true(mean(grDevices::col2rgb(.reference_identity_color(99))) < mean(grDevices::col2rgb(.reference_identity_color(95))))
  expect_equal(.reference_identity_color(80), .reference_identity_color(90))
  bad <- w; bad$identity[1] <- 101
  expect_error(.reference_identity_validate(bad, 1000), "percentage")
  bad <- w; bad$start[2] <- 50
  expect_error(.reference_identity_validate(bad, 1000), "overlap")
  bad <- w; bad$end[2] <- 2000
  expect_error(.reference_identity_validate(bad, 1000), "bounds")
  g <- .reference_geometry(.reference_demo()[FALSE, ], 1000, "A", .reference_colors, w)
  windows <- unique(g$polygons[g$polygons$role == "identity", c("window_start", "window_end", "identity")])
  expect_equal(windows$window_start, c(0, 200))
  expect_equal(windows$window_end, c(100, 300))
  expect_equal(windows$identity, c(99, NA))
})

test_that("identity demo windows exclude deletions and use the same plotting data", {
  w <- .reference_identity_demo(); v <- .reference_demo()
  expect_silent(.reference_identity_validate(w, 4800000))
  for (i in which(v$type == "DEL")) {
    expect_false(any(w$sample == v$sample[i] & w$start < v$end[i] & w$end > v$start[i]))
  }
  p <- plot_reference_comparison(v, 4800000, sample_order = "Genome A", identity_windows = w)
  expect_silent(ggplot2::ggplot_build(p))
  expect_equal(unique(p$layers[[1]]$data$data_sample[p$layers[[1]]$data$role == "identity"]), "Genome A")
  expect_match(p$labels$caption, "500,000")
})

test_that("uploaded identity tables are used and invalid scores clear the view", {
  skip_if_not_installed("shiny")
  variants_file <- tempfile(fileext = ".tsv")
  identity_file <- tempfile(fileext = ".tsv")
  invalid_file <- tempfile(fileext = ".tsv")
  on.exit(unlink(c(variants_file, identity_file, invalid_file)))
  utils::write.table(data.frame(sample = "A", type = "SNP", start = 20, end = 21), variants_file, sep = "\t", row.names = FALSE)
  utils::write.table(data.frame(sample = "A", start = 0, end = 100, identity = 97.5), identity_file, sep = "\t", row.names = FALSE)
  utils::write.table(data.frame(sample = "A", start = 0, end = 100, identity = 150), invalid_file, sep = "\t", row.names = FALSE)
  shiny::testServer(.reference_server, args = list(id = "test"), {
    session$setInputs(source = "upload", length = 1000, reference = "Ref", title = "", palette = "minou", types = .reference_types,
      show_identity = TRUE, file = list(datapath = variants_file), identity_file = list(datapath = identity_file))
    session$setInputs(samples = "A")
    expect_equal(identity_selected()$identity, 97.5)
    expect_s3_class(plot(), "ggplot")
    session$setInputs(show_identity = FALSE)
    expect_equal(nrow(identity_selected()), 0)
    session$setInputs(show_identity = TRUE, identity_file = list(datapath = invalid_file))
    expect_error(identity_selected(), "percentage")
    expect_error(plot(), "percentage")
  })
})
