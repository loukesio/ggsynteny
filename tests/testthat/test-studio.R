test_that("all app examples validate and draw in both layouts", {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())
  for (format in unname(.studio_formats)) {
    d <- .studio_load(format)
    expect_gt(nrow(d$first), 0)
    for (layout in c("linear", "circular")) {
      view <- .studio_select(d, d$organisms, layout = layout)
      p <- .studio_plot(view, layout = layout)
      expect_s3_class(p, "ggplot")
      expect_silent(ggplot2::ggplot_build(p))
    }
  }
})

test_that("larger simulated examples retain all pairs, bounds and orientation", {
  truth <- read.delim(system.file("extdata", "studio_simulated_chromosomes.tsv", package = "ggsynteny"))
  for (format in c("mcscanx", "genespace")) {
    d <- .studio_load(format)
    total <- if (format == "mcscanx") 240L else 384L
    expect_equal(length(d$organisms), 4)
    expect_equal(nrow(d$first), 32)
    expect_equal(nrow(d$second), total)
    view <- .studio_select(d, d$organisms)
    expect_equal(nrow(.studio_pairs(view)), 6)
    expect_equal(.studio_pairs(view)$links, rep(total / 6, 6))
    linear <- .studio_select(d, d$organisms, layout = "linear")
    expect_equal(nrow(linear$second), total / 2)
    expect_equal(linear$layout_omitted, total / 2)
    expect_true(any(d$second$chr1 != d$second$chr2))
    sizes <- truth$size[match(.circ_key(d$first$species, d$first$chr), .circ_key(truth$species, truth$chr))] / 1e6
    expect_true(all(d$first$size <= sizes))
    if (format == "mcscanx") {
      expect_equal(sum(d$second$n_genes), 2644)
      expect_equal(sum(d$second$orientation == "minus"), 60)
      expect_equal(sum(d$second$orientation == "plus"), 180)
    }
  }
})

test_that("interactive Studio views keep data and exports reproducible", {
  skip_if_not_installed("ggiraph")
  for (format in c("native", "genes")) {
    d <- .studio_load(format); d <- .studio_select(d, d$organisms, 4)
    for (layout in c("circular", "linear")) {
      p <- .studio_plot(d, layout = layout, interactive = TRUE)
      expect_s3_class(p, "ggplot")
      widget <- syn_girafe(p)
      expect_s3_class(widget, "girafe")
      expect_match(widget$x$html, "data-id=")
      settings <- list(layout = layout, palette = "casa_natal", alpha = 0.35,
        labels = TRUE, orientation = FALSE, identity = FALSE, anchor = "body", gap = 10, title = NULL)
      code <- .studio_code(d, settings, interactive = TRUE)
      expect_match(code, "interactive = TRUE", fixed = TRUE)
      expect_match(code, "syn_girafe(p_interactive", fixed = TRUE)
      expect_silent(parse(text = code))
    }
  }
})

test_that("app validation rejects ambiguous, malformed, and unmatched data", {
  d <- .studio_load("genes")
  bad <- d; bad$first$feat_id[2] <- bad$first$feat_id[1]
  expect_error(.studio_validate(bad), "must be unique")
  bad <- d; bad$second$feat_id_a[1] <- "missing"
  expect_error(.studio_validate(bad), "unknown gene")
  bad <- d; bad$first$start[1] <- "oops"
  expect_error(.studio_validate(bad), "numeric")
  bad <- d; bad$first$strand[1] <- "?"
  expect_error(.studio_validate(bad), "strand")
  bad <- d; bad$second$identity <- 120
  expect_error(.studio_validate(bad), "percentage")
  bad$second$identity <- NA_real_
  expect_true(all(is.na(.studio_validate(bad)$second$identity)))
  expect_error(.studio_plot(d, identity = TRUE), "no identity")
  expect_error(.studio_load("genes", FALSE), "Upload")
  expect_error(.studio_load("other"), "supported")
  expect_error(.studio_select(d, character()), "Select")
  expect_error(.studio_select(d, d$organisms, 0), "limit")
  m <- .studio_load("native")
  bad <- m; bad$second$end1[1] <- 1e20
  expect_error(.studio_validate(bad), "bounds")
  bad <- m; bad$second$chr1[1] <- "unknown"
  expect_error(.studio_validate(bad), "unknown chromosome")
})

test_that("uploads preserve text IDs and optional metadata", {
  path <- tempfile(fileext = ".csv")
  writeLines(c("species,chr,size", "001,01,2.5"), path)
  table <- .studio_table(path)
  expect_identical(table$species, "001")
  expect_identical(table$chr, "01")
  path2 <- tempfile(fileext = ".tsv")
  writeLines("species1\tchr1\tstart1\tend1\tspecies2\tchr2\tstart2\tend2\torientation", path2)
  d <- .studio_load("native", FALSE, list(path, path2))
  expect_equal(nrow(d$second), 0)
  expect_true("orientation" %in% names(d$second))
  grDevices::pdf(NULL); on.exit(grDevices::dev.off())
  expect_silent(ggplot2::ggplot_build(.studio_plot(.studio_select(d, d$organisms))))
  for (layout in c("linear", "circular")) {
    expect_silent(ggplot2::ggplot_build(.studio_plot(.studio_select(d, d$organisms), layout)))
  }
})

test_that("displayed tables and summaries reflect subsetting and link caps", {
  d <- .studio_load("genes")
  view <- .studio_select(d, d$organisms, 3)
  expect_equal(view$matching_links, 9)
  expect_equal(nrow(view$second), 3)
  expect_equal(sum(.studio_pairs(view)$links), 3)
  only <- .studio_select(d, d$organisms[1])
  expect_equal(nrow(only$second), 0)
  expect_equal(nrow(.studio_pairs(only)), 0)
  m <- example_synteny_data()
  d <- .studio_validate(list(type = "macro", first = m$chromosomes, second = m$blocks))
  extra <- d$second[1, ]; extra$species2 <- d$organisms[3]
  extra$chr2 <- d$first$chr[d$first$species == d$organisms[3]][1]
  extra$start2 <- 0; extra$end2 <- 0.1
  d$second <- rbind(d$second, extra)
  view <- .studio_select(d, d$organisms, layout = "linear")
  expect_gt(view$layout_omitted, 0)
  expect_true(all(abs(match(view$second$species1, d$organisms) - match(view$second$species2, d$organisms)) == 1))
})

test_that("downloaded R scripts reproduce the displayed records", {
  grDevices::pdf(NULL); on.exit(grDevices::dev.off())
  dir <- tempfile(); dir.create(dir)
  old <- setwd(dir); on.exit(setwd(old), add = TRUE)
  settings <- list(layout = "circular", palette = "casa_natal", alpha = 0.35,
                    labels = TRUE, orientation = FALSE, identity = FALSE,
                    anchor = "body", gap = 10, title = "Title with \"quotes\"")
  for (format in c("native", "genes")) {
    d <- .studio_load(format); d <- .studio_select(d, d$organisms, 5)
    files <- if (d$type == "macro") c("chromosomes.tsv", "blocks.tsv") else c("features.tsv", "links.tsv")
    write.table(d$first, files[1], sep = "\t", row.names = FALSE)
    write.table(d$second, files[2], sep = "\t", row.names = FALSE)
    for (layout in c("linear", "circular")) {
      settings$layout <- layout
      writeLines(.studio_code(d, settings), "reproduce.R")
      e <- new.env()
      expect_silent(sys.source("reproduce.R", envir = e))
      expect_s3_class(e$p, "ggplot")
      expect_true(file.exists("synteny.pdf"))
    }
  }
})

test_that("the shell walks a job through its steps and reports skipped rows", {
  skip_if_not_installed("shiny")
  grDevices::pdf(NULL); on.exit(grDevices::dev.off())
  shiny::testServer(.studio_server, {
    expect_null(job())
    session$setInputs(start_synteny_example = 1)
    expect_equal(job(), "synteny"); expect_true(example()); expect_equal(state$step, "data")
    session$setInputs(format = "genes", layout = "circular", palette = "casa_natal", alpha = 0.35,
                      labels = TRUE, gap = 10, limit = 1000, title = "")
    expect_equal(nrow(dataset()$first), 21)
    expect_true(ready())
    expect_s3_class(current_plot(), "ggplot")
    expect_equal(selected_data()$organisms, c("ZONMW-30", "ZONMW-20", "HI1"))
    session$setInputs(organisms = c("ZONMW-30", "ZONMW-20"))
    expect_equal(nrow(selected_data()$first), 12)
    session$setInputs(to_figure = 1); expect_equal(state$step, "figure")
    session$setInputs(to_export = 1); expect_equal(state$step, "export")
    expect_match(script(), "plot_circular_microsynteny", fixed = TRUE)
    if (requireNamespace("ggiraph", quietly = TRUE)) {
      session$setInputs(interactive = TRUE)
      expect_s3_class(current_interactive_plot(), "ggplot")
      session$setInputs(interactive = FALSE)
    }
    # Upload mode: nothing until files arrive, then lenient validation reports skipped rows.
    session$setInputs(go_home = 1, start_synteny_upload = 1)
    expect_false(example()); expect_match(dataset()$problem, "Upload")
    expect_false(ready())
    genes <- read.delim(system.file("extdata", "circular_bacterial_features.tsv", package = "ggsynteny"))
    links <- read.delim(system.file("extdata", "circular_bacterial_links.tsv", package = "ggsynteny"))
    links$feat_id_a[1] <- "missing"
    f1 <- tempfile(fileext = ".tsv"); f2 <- tempfile(fileext = ".tsv")
    write.table(genes, f1, sep = "\t", row.names = FALSE, quote = FALSE)
    write.table(links, f2, sep = "\t", row.names = FALSE, quote = FALSE)
    session$setInputs(file_genes_1 = list(datapath = f1), file_genes_2 = list(datapath = f2))
    d <- dataset()
    expect_null(d$problem)
    expect_equal(nrow(d$skipped), 1)
    expect_equal(d$skipped$reason, "A link references an unknown gene ID.")
    expect_equal(nrow(d$second), 8)
    expect_true(ready())
    # Tracks job on the chloroplast example drives the same figure through the tracks module.
    session$setInputs(go_home = 1, start_tracks_example = 1)
    expect_equal(dataset()$first$chr, "plastid")
    expect_equal(settings()$ribbon_by, "class")
    expect_equal(length(attr(figure(), "synteny_tracks")), 5)
    # Reference job.
    session$setInputs(go_home = 1, start_reference_example = 1)
    expect_true(ready())
    expect_match(script(), "plot_reference_comparison", fixed = TRUE)
  })
})
