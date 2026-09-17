# Studio / 0.5.0 validation — 2026-09-17

- `R CMD build` succeeds; `R CMD check --no-manual` reports **Status: OK**,
  with no check errors, warnings or notes.
- **387 passing test expectations**, no failures or skips. The local test
  log records one environment warning when Shiny attaches: the installed
  Shiny binary was built under R 4.5.2, while this computer runs R 4.5.1.
- Eleven browser scenarios pass in Chrome: all four demo formats in both
  layouts, all four upload formats, palette and subset changes, explicit link
  limits, invalid-file recovery, PDF/PNG/table/summary/R downloads, and mobile
  layout. No JavaScript errors or mobile page overflow were found.
- The R script downloaded through the browser runs against the installed
  0.5.0 source package and reproduces the figure from its downloaded tables.
- Full pkgdown documentation is built with the installed release package.
- The original nine R source files and all ltc definitions still match the
  reviewed baseline. Studio is additive; the only circular implementation
  repair handles species-pair colouring when zero blocks remain.

Browser artifacts are under `dev/app/validation/`. Release build, check and
documentation logs are under the original project's `dev/releases/0.5.0/`.
The original main source and local changes are preserved under
`dev/releases/0.3.0/` and tag `v0.3.0`.

## Larger examples and interactive previews — 2026-09-17

- `R CMD build` succeeds; `R CMD check --no-manual` reports **Status: OK**.
  **435 passing test expectations**, no failures or skips; the same local
  Shiny build-version warning described above remains in the test log.
- The deterministic generator reproduces all five simulated-data files
  byte-for-byte. Both datasets contain four genomes, 32 chromosomes and all
  six genome pairs. MCScanX has 240 blocks and 2,644 anchor pairs, including
  60 reversed blocks; GENESPACE has 384 compatible interval matches.
- Twelve Chrome scenarios pass, including static and interactive previews
  for every format in both layouts; hover tooltips, wheel zoom, drag pan and
  reset; uploads and recovery after invalid data; downloads; and mobile
  layout. There are no JavaScript errors or mobile page overflow.
- Invalid uploads remove the previous interactive plot and show the
  validation message. Enabling interaction also enables pan/zoom directly;
  the redundant ggiraph toolbar toggle is hidden, avoiding its click-handler
  error in the locally installed ggiraph 0.9.6.
  The optional dependency declares ggiraph >= 0.9.2, which introduced
  automatic zoom activation; older installations receive an update message.
- PDF/PNG downloads remain static while interaction is enabled. The
  downloaded R script reproduces both versions from the downloaded tables
  using the installed source package.
- Only the two Studio R files change. Plotting functions, parsers, palette
  definitions and original small fixtures match the published 0.5.0 source.
- Full pkgdown build succeeds, with the two pre-existing missing-alt-text
  notices for the linear anchor images.
- Logs, exported files and screenshots are in `dev/app/validation/`.
  The existing release tags and archives are preserved.

The interactive checkbox now appears as an animated Off/On switch. A focused
Chrome check verified mouse and keyboard operation, the two visual states,
reduced-motion support and mobile layout without JavaScript errors. The
README screenshot shows the updated control.

## Posit Connect Cloud deployment preparation — 2026-09-17

- The standalone entry point loads the installed ggsynteny app, Shiny and
  ggiraph. The generated manifest records R 4.5.1 and 75 package dependencies
  from CRAN/GitHub, with ggsynteny pinned to commit
  `d64538309689c66bb4091c005a5ac7e54583367b`.
- The installed entry point and interactive rendering of all eight
  format/layout combinations pass. A Chrome check of the deployment folder
  verifies startup, the switch, 240-block MCScanX and 384-match GENESPACE
  previews, interactive SVGs and a valid PDF download without JavaScript errors.
- The deployment bundle includes only `app.R` and its generated manifest.
  The hosting directory is excluded from R package builds. Package code,
  data, palettes and the existing releases are unchanged by this setup.
- The published app was subsequently verified in a fresh, signed-out Chrome
  session at
  `https://01a0ae1e-adb1-a4f8-1ced-261952037ebf.share.connect.posit.cloud/`.
  All twelve browser scenarios pass against the hosted app, including all
  formats/layouts, uploads, invalid-upload recovery, hover/zoom/pan/reset,
  PDF/PNG/table/R-script downloads and mobile layout. No JavaScript errors
  were recorded. Logs: `dev/app/validation/hosting-browser.log` and
  `hosting-browser-results.json`. The README screenshot now comes from the
  hosted app.
