# Contributing to ggsynteny

Thanks for your interest! Contributions are welcome — bug reports,
feature ideas, and pull requests alike.

## Reporting problems and asking for help

- **Bugs and feature requests:** open an issue at
  <https://github.com/loukesio/ggsynteny/issues>. For bugs, a minimal
  reproducible example (input data frames plus the plotting call) makes
  a fix far more likely.
- **Parser issues:** if
  [`read_mcscanx()`](https://loukesio.github.io/ggsynteny/reference/read_mcscanx.md),
  [`read_genespace()`](https://loukesio.github.io/ggsynteny/reference/read_genespace.md),
  or
  [`read_synteny_tsv()`](https://loukesio.github.io/ggsynteny/reference/read_synteny_tsv.md)
  mishandles a file, please attach (or excerpt) the offending file —
  real tool output is exactly what the parsers are tested against.

## Ground rules for pull requests

- **Light dependencies.** Hard Imports stay as they are; optional
  niceties go in `Suggests` behind
  [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html) guards
  (see how ggiraph and ggforce are handled).
- **Keep sources ASCII.** Non-ASCII characters in R code strings are
  written as `\uXXXX` escapes (roxygen comments may use UTF-8).
- Every new argument gets roxygen docs, a `NEWS.md` entry, and a test.
- `devtools::check()` must be clean (no errors, warnings, or notes) and
  `devtools::test()` fully passing before a PR.
- **README figures are generated.** They come from
  `data-raw/readme_figures.R`; the hex logo from `data-raw/hex_logo.R`;
  the bundled `rice_sorghum` dataset from `data-raw/rice_sorghum.R`
  (provenance documented in the script). Regenerate rather than editing
  images by hand.
- Palette changes belong upstream in
  [ltc](https://github.com/loukesio/ltc-color-palettes); ggsynteny
  vendors the curated versions used by ggvmap so the ecosystem stays in
  sync.
