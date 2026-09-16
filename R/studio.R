#' Launch the ggsynteny Shiny app
#'
#' Preview existing synteny results, choose a linear or circular layout, and
#' download figures, displayed tables, pair summaries and reproducible R code.
#' The app reads MCScanX, GENESPACE, native chromosome/block tables, and native
#' gene/link tables. It does not run alignment or synteny analysis software.
#'
#' @param host Address to listen on; defaults to the local computer.
#' @param port Optional port passed to [shiny::runApp()].
#' @param launch.browser Open the app in a browser?
#' @return Runs a Shiny app until interrupted.
#' @examples
#' \dontrun{
#' ggsynteny_app()
#' }
#' @export
ggsynteny_app <- function(host = "127.0.0.1", port = NULL,
                          launch.browser = interactive()) {
  if (!requireNamespace("shiny", quietly = TRUE))
    stop("Install the optional app dependency with install.packages('shiny').", call. = FALSE)
  shiny::runApp(system.file("shiny", package = "ggsynteny"), host = host,
                port = port, launch.browser = launch.browser)
}

.studio_formats <- c("Native chromosome tables" = "native", "MCScanX" = "mcscanx",
                      "GENESPACE" = "genespace", "Gene / link tables" = "genes")

.studio_schema <- function(format) {
  switch(format,
    native = c("Chromosomes: species, chr, size",
               "Blocks: species1, chr1, start1, end1, species2, chr2, start2, end2"),
    mcscanx = c("MCScanX .collinearity output", "MCScanX GFF: four tab-separated fields, without a header: chromosome, gene ID, start, end. Not a standard nine-column GFF3."),
    genespace = "synHits: genome1, chr1, start1, end1, genome2, chr2, start2, end2",
    genes = c("Genes: bin_id, seq_id, start, end, strand (+/-), unique feat_id, name",
              "Links: feat_id_a, feat_id_b; optional identity (0-100)"),
    stop("Choose a supported input format.", call. = FALSE))
}

.studio_table <- function(path) {
  header <- readLines(path, n = 1, warn = FALSE)
  if (!length(header)) stop("The uploaded table is empty.", call. = FALSE)
  sep <- if (grepl("\t", header, fixed = TRUE)) "\t" else ","
  x <- readr::read_delim(path, delim = sep, col_types = readr::cols(.default = "c"),
                         name_repair = "minimal", show_col_types = FALSE, progress = FALSE)
  if (nrow(readr::problems(x))) stop("The table contains malformed rows. Check its delimiter and columns.", call. = FALSE)
  if (anyDuplicated(names(x)) || any(!nzchar(names(x))))
    stop("Table column names must be unique and non-empty.", call. = FALSE)
  as.data.frame(x, stringsAsFactors = FALSE)
}

.studio_columns <- function(x, columns, label) {
  missing <- setdiff(columns, names(x))
  if (length(missing)) stop(label, " missing: ", paste(missing, collapse = ", "), call. = FALSE)
  x
}

.studio_validate <- function(d) {
  if (d$type == "macro") {
    d$first <- .studio_columns(d$first, c("species", "chr", "size"), "Chromosomes")
    d$second <- .studio_columns(d$second, c("species1", "chr1", "start1", "end1",
                                          "species2", "chr2", "start2", "end2"), "Blocks")
    ids <- list(c("species", "chr"), c("species1", "chr1", "species2", "chr2"))
    numeric <- list("size", c("start1", "end1", "start2", "end2"))
  } else {
    d$first <- .studio_columns(d$first, c("bin_id", "seq_id", "start", "end", "strand", "feat_id", "name"), "Genes")
    d$second <- .studio_columns(d$second, c("feat_id_a", "feat_id_b"), "Links")
    ids <- list(c("bin_id", "seq_id", "strand", "feat_id", "name"), c("feat_id_a", "feat_id_b"))
    numeric <- list(c("start", "end"), intersect("identity", names(d$second)))
  }
  for (i in 1:2) {
    name <- c("first", "second")[i]
    for (key in ids[[i]]) d[[name]][[key]] <- .circ_text(d[[name]][[key]], key)
    for (key in numeric[[i]]) {
      value <- suppressWarnings(as.numeric(d[[name]][[key]]))
      allowed_na <- key == "identity" & (is.na(d[[name]][[key]]) | d[[name]][[key]] %in% c("", "NA"))
      if (any(!is.finite(value) & !allowed_na)) stop(key, " must contain valid numeric values.", call. = FALSE)
      d[[name]][[key]] <- value
    }
  }
  if (!nrow(d$first)) stop("No chromosome or gene records were found.", call. = FALSE)
  a <- d$first; b <- d$second
  if (d$type == "macro") {
    keys <- .circ_key(a$species, a$chr)
    if (anyDuplicated(keys) || any(a$size <= 0))
      stop("Chromosome keys must be unique and lengths positive.", call. = FALSE)
    for (side in 1:2) {
      index <- match(.circ_key(b[[paste0("species", side)]], b[[paste0("chr", side)]]), keys)
      if (anyNA(index)) stop("A block references an unknown chromosome.", call. = FALSE)
      start <- b[[paste0("start", side)]]; end <- b[[paste0("end", side)]]
      if (any(start < 0 | end <= start | end > a$size[index]))
        stop("Block intervals must have positive widths within chromosome bounds.", call. = FALSE)
    }
  } else {
    if (anyDuplicated(a$feat_id)) stop("Gene feat_id values must be unique across all bins and contigs.", call. = FALSE)
    if (any(a$start < 0 | a$end <= a$start) || any(!a$strand %in% c("+", "-")))
      stop("Genes need positive-width intervals and strand '+' or '-'.", call. = FALSE)
    if (any(!b$feat_id_a %in% a$feat_id | !b$feat_id_b %in% a$feat_id))
      stop("A link references an unknown gene ID.", call. = FALSE)
    if ("identity" %in% names(b) && any(b$identity < 0 | b$identity > 100, na.rm = TRUE))
      stop("Identity must be a percentage from 0 to 100.", call. = FALSE)
  }
  d$organisms <- unique(a[[if (d$type == "macro") "species" else "bin_id"]])
  d
}

.studio_load <- function(format, demo = TRUE, paths = list()) {
  .studio_schema(format)
  ext <- function(name) system.file("extdata", name, package = "ggsynteny")
  if (demo && format == "native") {
    e <- new.env(parent = emptyenv())
    utils::data("rice_sorghum", package = "ggsynteny", envir = e)
    syn <- e$rice_sorghum
  } else {
    if (demo) paths <- switch(format,
      mcscanx = list(ext("mcscanx_output.collinearity"), ext("mcscanx_output.gff")),
      genespace = list(ext("genespace_synHits.tsv")),
      genes = list(ext("circular_bacterial_features.tsv"), ext("circular_bacterial_links.tsv")))
    expected <- if (format == "genespace") 1L else 2L
    if (length(paths) != expected || any(!vapply(paths, function(p) length(p) == 1L && file.exists(p), logical(1))))
      stop("Upload the required files to preview your data.", call. = FALSE)
    if (format == "mcscanx") {
      gff <- readr::read_tsv(paths[[2]], col_names = FALSE, col_types = "c", comment = "#",
                             show_col_types = FALSE, progress = FALSE)
      if (ncol(gff) != 4L || !nrow(gff)) stop("MCScanX requires its four-column GFF gene-position table.", call. = FALSE)
      if (anyDuplicated(gff[[2]])) stop("MCScanX GFF gene IDs must be unique.", call. = FALSE)
      rows <- trimws(readLines(paths[[1]], warn = FALSE))
      genes <- rows[grepl("^\\d+-", rows)]
      refs <- unlist(lapply(strsplit(trimws(sub("^\\d+-\\s*\\d+:", "", genes)), "\\s+"), function(x) x[1:2]))
      if (anyNA(refs) || any(!refs %in% gff[[2]])) stop("Collinearity gene IDs are missing from the supplied GFF.", call. = FALSE)
      syn <- read_mcscanx(paths[[1]], paths[[2]])
      if (!nrow(syn$blocks)) stop("No MCScanX alignment blocks were found.", call. = FALSE)
    } else if (format == "genespace") {
      .studio_columns(.studio_table(paths[[1]]), c("genome1", "chr1", "start1", "end1",
                       "genome2", "chr2", "start2", "end2"), "GENESPACE synHits")
      syn <- read_genespace(paths[[1]])
    } else if (format == "native") {
      syn <- list(chromosomes = .studio_table(paths[[1]]), blocks = .studio_table(paths[[2]]))
    } else {
      return(.studio_validate(list(type = "micro", first = .studio_table(paths[[1]]),
                                   second = .studio_table(paths[[2]]), format = format)))
    }
  }
  .studio_validate(list(type = "macro", first = as.data.frame(syn$chromosomes),
                        second = as.data.frame(syn$blocks), format = format))
}

.studio_select <- function(d, organisms, limit = 1000L, layout = "circular") {
  if (!length(organisms)) stop("Select at least one genome or bin.", call. = FALSE)
  if (length(limit) != 1L || !is.finite(limit) || limit < 1 || limit > 10000)
    stop("Choose a link limit between 1 and 10000.", call. = FALSE)
  a <- d$first; b <- d$second
  if (d$type == "macro") {
    a <- a[a$species %in% organisms, , drop = FALSE]
    b <- b[b$species1 %in% organisms & b$species2 %in% organisms, , drop = FALSE]
  } else {
    a <- a[a$bin_id %in% organisms, , drop = FALSE]
    b <- b[b$feat_id_a %in% a$feat_id & b$feat_id_b %in% a$feat_id, , drop = FALSE]
  }
  d$layout_omitted <- 0L
  if (d$type == "macro" && layout == "linear") {
    adjacent <- abs(match(b$species1, organisms) - match(b$species2, organisms)) == 1L
    d$layout_omitted <- sum(!adjacent)
    b <- b[adjacent, , drop = FALSE]
  }
  d$matching_links <- nrow(b)
  d$first <- a; d$second <- utils::head(b, as.integer(limit)); d$organisms <- organisms
  d
}

.studio_plot <- function(d, layout = "circular", palette = "casa_natal", alpha = 0.35,
                          labels = TRUE, orientation = FALSE, identity = FALSE,
                          anchor = "body", gap = 10, title = NULL) {
  circular <- identical(layout, "circular")
  if (d$type == "macro") {
    args <- list(syn_data = list(chromosomes = d$first, blocks = d$second),
                 species_order = d$organisms, palette = palette, chr_fill = "per_species",
                 ribbon_fill = "species_pair", ribbon_alpha = alpha, title = title,
                 label_size = if (labels) 2.5 else 0)
    args[[if (circular) "show_orientation" else "show_inversions"]] <- orientation
    if (circular) args$group_gap <- gap
    do.call(if (circular) plot_circular_synteny else plot_synteny, args)
  } else {
    if (identity && !"identity" %in% names(d$second))
      stop("The uploaded links have no identity scores. Choose gene-name colours.", call. = FALSE)
    args <- list(features = d$first, links = d$second, bin_order = d$organisms,
                 palette = palette, ribbon_fill = if (identity) "identity" else "per_name",
                 ribbon_alpha = alpha, label_genes = labels, ribbon_anchor = anchor, title = title)
    if (circular) args$group_gap <- gap
    do.call(if (circular) plot_circular_microsynteny else plot_microsynteny, args)
  }
}

.studio_pairs <- function(d) {
  b <- d$second
  if (d$type == "macro") { a <- b$species1; z <- b$species2 } else {
    a <- d$first$bin_id[match(b$feat_id_a, d$first$feat_id)]
    z <- d$first$bin_id[match(b$feat_id_b, d$first$feat_id)]
  }
  if (!length(a)) return(data.frame(genome_a = character(), genome_b = character(), links = integer()))
  swap <- match(a, d$organisms) > match(z, d$organisms)
  key <- data.frame(genome_a = ifelse(swap, z, a), genome_b = ifelse(swap, a, z), stringsAsFactors = FALSE)
  stats::aggregate(list(links = rep(1L, nrow(key))), key, sum)
}

.studio_code <- function(d, settings) {
  quote_r <- function(x) paste(utils::capture.output(dput(x)), collapse = "\n")
  args <- list()
  if (d$type == "macro") {
    start <- c('chromosomes <- read.delim("chromosomes.tsv", colClasses = c(species = "character", chr = "character"))',
               'blocks <- read.delim("blocks.tsv", colClasses = c(species1 = "character", chr1 = "character", species2 = "character", chr2 = "character"))')
    args <- list(syn_data = "list(chromosomes = chromosomes, blocks = blocks)",
                 species_order = quote_r(d$organisms), chr_fill = '"per_species"', ribbon_fill = '"species_pair"')
    args[[if (settings$layout == "circular") "show_orientation" else "show_inversions"]] <- quote_r(settings$orientation)
    args$label_size <- quote_r(if (settings$labels) 2.5 else 0)
    fun <- if (settings$layout == "circular") "plot_circular_synteny" else "plot_synteny"
  } else {
    start <- c('features <- read.delim("features.tsv", colClasses = c(bin_id = "character", seq_id = "character", feat_id = "character", name = "character"))',
               'links <- read.delim("links.tsv", colClasses = c(feat_id_a = "character", feat_id_b = "character"))')
    args <- list(features = "features", links = "links", bin_order = quote_r(d$organisms),
                 ribbon_fill = quote_r(if (settings$identity) "identity" else "per_name"),
                 label_genes = quote_r(settings$labels), ribbon_anchor = quote_r(settings$anchor))
    fun <- if (settings$layout == "circular") "plot_circular_microsynteny" else "plot_microsynteny"
  }
  args$palette <- quote_r(settings$palette); args$ribbon_alpha <- quote_r(settings$alpha)
  args$title <- quote_r(settings$title)
  if (settings$layout == "circular") args$group_gap <- quote_r(settings$gap)
  paste(c('# Save the two displayed-table downloads beside this script.',
          '# The tables contain exactly the records displayed in the app.',
          'library(ggsynteny)', start, '',
          paste0('p <- ', fun, '(\n  ', paste(paste(names(args), unlist(args), sep = " = "), collapse = ",\n  "), '\n)'),
          'print(p)', 'ggplot2::ggsave("synteny.pdf", p, width = 10, height = 8)'), collapse = "\n")
}
