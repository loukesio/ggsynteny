# Run from the package root after preparing the manifest and connecting Posit.
# Rscript dev/app/deploy_connect_cloud.R [account-name]
lib <- "dev/app/validation/hosting-library"
if (dir.exists(lib)) .libPaths(c(normalizePath(lib), .libPaths()))
if (!requireNamespace("rsconnect", quietly = TRUE))
  stop("Run Rscript dev/app/prepare_connect_cloud.R first.")
accounts <- rsconnect::accounts(server = "connect.posit.cloud")
args <- commandArgs(trailingOnly = TRUE)
account <- if (length(args)) args[[1]] else if (nrow(accounts) == 1L) accounts$name[[1]] else NULL
if (is.null(account) || !account %in% accounts$name)
  stop("Connect your Posit account using rsconnect::connectCloudUser(), then supply its name if more than one is connected.")
rsconnect::deployApp(appDir = "deploy/posit-connect-cloud", manifestPath = "manifest.json",
                     appPrimaryDoc = "app.R", appName = "ggsynteny-studio", appTitle = "ggsynteny Studio",
                     account = account, server = "connect.posit.cloud", launch.browser = FALSE,
                     appVisibility = "public")
