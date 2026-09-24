# Run from the package root. Optionally supply an already-pushed commit SHA:
# Rscript dev/app/prepare_connect_cloud.R <40-character-commit-SHA>
# Deployment tools and the pinned package use an ignored, isolated library.
args <- commandArgs(trailingOnly = TRUE)
ref <- if (length(args)) args[[1]] else system2("git", c("rev-parse", "HEAD"), stdout = TRUE)
stopifnot(length(ref) == 1L, grepl("^[[:xdigit:]]{40}$", ref),
          file.exists("deploy/posit-connect-cloud/app.R"))
lib <- "dev/app/validation/hosting-library"
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(normalizePath(lib), .libPaths()))
options(repos = c(CRAN = "https://cloud.r-project.org"))
for (pkg in c("remotes", "rsconnect", "shiny", "ggiraph", "showtext", "sysfonts")) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg, lib = lib)
}
if (utils::packageVersion("ggiraph") < "0.9.2") install.packages("ggiraph", lib = lib)
remotes::install_github(paste0("loukesio/ggsynteny@", ref), lib = lib,
                       upgrade = "never", dependencies = NA, build_vignettes = FALSE)
# Declare optional export dependencies when regenerating the pinned bundle.
# Keep the existing hosted entry point and manifest in sync until this runs.
writeLines(c(
  "# The manifest pins ggsynteny and its dependencies for the hosted Studio.",
  "library(shiny)", "library(ggiraph)", "library(showtext)", "library(sysfonts)",
  "library(ggsynteny)", "",
  'source(system.file("shiny", "app.R", package = "ggsynteny"), local = TRUE)$value'
), "deploy/posit-connect-cloud/app.R")
rsconnect::writeManifest(appDir = "deploy/posit-connect-cloud", appFiles = "app.R",
                         appPrimaryDoc = "app.R", appMode = "shiny", quarto = FALSE)
manifest <- jsonlite::fromJSON("deploy/posit-connect-cloud/manifest.json", simplifyVector = FALSE)
stopifnot(identical(manifest$packages$ggsynteny$description$RemoteSha, ref),
          all(c("shiny", "ggiraph", "ggsynteny", "showtext", "sysfonts") %in% names(manifest$packages)))
cat("Prepared Studio using ggsynteny commit", ref, "\n")
