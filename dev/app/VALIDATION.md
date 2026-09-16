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
