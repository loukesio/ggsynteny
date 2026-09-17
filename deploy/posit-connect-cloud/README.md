# ggsynteny Studio on Posit Connect Cloud

This directory hosts the existing package app. `app.R` loads ggsynteny,
Shiny and ggiraph, then returns the app bundled with the installed package.
The generated `manifest.json` records R and all package dependencies,
including the exact GitHub commit of ggsynteny. Core plotting code and
palettes are used directly from that package.

## Prepare an update

From the repository root, after pushing the package changes to GitHub:

```sh
Rscript dev/app/prepare_connect_cloud.R
```

The script defaults to the current commit, or accepts a full commit SHA as
its first argument. Deployment tools and the pinned ggsynteny package are
installed in the ignored `dev/app/validation/hosting-library/` directory.
The manifest contains only the app entry point and its package dependencies.
Commit the updated manifest before publishing from GitHub.

## Publish from R

Connect your account once in a local R session, using Posit's browser login:

```r
.libPaths(c(normalizePath("dev/app/validation/hosting-library"), .libPaths()))
rsconnect::connectCloudUser()
```

Select or create a free personal account in Posit, then run:

```sh
Rscript dev/app/deploy_connect_cloud.R
```

Supply the account name as an argument if more than one account is connected.
The deployment is public and titled **ggsynteny Studio**. Posit's deployment
record lets subsequent runs update the same app. Authentication is stored
by rsconnect in the local user configuration, outside this repository.

## Publish from GitHub

In [Posit Connect Cloud](https://connect.posit.cloud/), select **Publish →
Shiny**, repository `loukesio/ggsynteny`, branch `main`, and primary file
`deploy/posit-connect-cloud/app.R`. The manifest lives beside the entry point.
This is an alternative to publishing from R; use one route consistently
to maintain the same hosted app.

See Posit's [Shiny deployment guide](https://docs.posit.co/connect-cloud/how-to/r/shiny-r.html)
and [manifest documentation](https://rstudio.github.io/rsconnect/reference/writeManifest.html).
