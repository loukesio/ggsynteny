# Verify the published development branch in a temporary library, then run
# every non-installation R code block from the beginner tutorial.
# Run from the branch checkout: Rscript dev/gc-tracks/validate_install.R
repo <- normalizePath(".")
expected_sha <- system2("git", c("rev-parse", "HEAD"), stdout = TRUE)
check_dir <- tempfile("ggsynteny-branch-install-")
dir.create(check_dir)
lib <- file.path(check_dir, "library")
dir.create(lib)
.libPaths(c(lib, .libPaths()))
remotes::install_github("loukesio/ggsynteny", ref = "feature/gc-content-tracks",
                         lib = lib, upgrade = "never")
library(ggsynteny, lib.loc = lib)
desc <- utils::packageDescription("ggsynteny", lib.loc = lib)
stopifnot(desc$Version == "0.5.0.9000", desc$RemoteSha == expected_sha,
          desc$RemoteRef == "feature/gc-content-tracks")
lines <- readLines(file.path(repo, "dev/gc-tracks/tutorial/README.md"))
fences <- grep("^```", lines)
stopifnot(length(fences) %% 2 == 0)
setwd(check_dir)
grDevices::pdf("tutorial-all-plots.pdf", width = 13, height = 9)
count <- 0L
for (i in seq(1, length(fences), by = 2)) {
  code <- paste(lines[seq(fences[i] + 1, fences[i + 1] - 1)], collapse = "\n")
  if (grepl("install_github|install.packages", code)) next
  eval(parse(text = code), envir = globalenv())
  count <- count + 1L
}
grDevices::dev.off()
stopifnot(file.exists("my-linear-tracks.pdf"), file.exists("my-circular-tracks.pdf"))
result <- c(paste("PASS: installed GitHub branch at", expected_sha),
            paste("PASS:", count, "tutorial code blocks executed from installed package"),
            "PASS: linear and circular PDF exports created",
            paste("Temporary library and output:", check_dir))
writeLines(result, file.path(repo, "dev/gc-tracks/validation/github-install.txt"))
cat(paste(result, collapse = "\n"), "\n")
