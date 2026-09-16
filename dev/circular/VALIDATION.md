# Validation — 2026-09-16

- `R CMD build` succeeds, including the existing package vignette.
- `R CMD check --no-manual`: **0 errors, 0 warnings, 0 notes**.
- Installed test suite: **322 passing expectations**, no failures, warnings or
  skips (223 baseline expectations plus 99 circular-view expectations).
- The circular article renders independently and as part of the full pkgdown
  site. Both new functions have generated reference pages and runnable examples.
- The full pkgdown build finishes. It reports two existing missing-alt-text
  notices for the linear `README-anchor-body.png` / `README-anchor-full.png`
  images; those unrelated images were preserved.
- Real-data macro rendering preserves 22 rice/sorghum chromosomes and 100 block
  records. Micro rendering preserves 16 demo genes and 11 homology links.
- PNGs were visually inspected; vector PDFs are included beside the preview.
- Tests cover proportional arc widths, genomic endpoint mapping, strand-aware
  arrow tips, body/full anchoring, orientation metadata, non-adjacent pairs,
  subsetting, empty links, color keys/aliases, invalid coordinates and ggiraph
  widget generation. Browser hover gestures were not separately automated.
- All existing R source files, including palettes and linear plotting functions,
  match the reviewed baseline exactly. The main worktree's original changed
  files and status were verified against a saved content-hash manifest.
- No new package dependencies or global package installations were introduced.
  Documentation used the package check's private installation for child R
  sessions. R CMD check ran locally on macOS/R 4.5.1; the GitHub OS matrix was
  not run. Remote repository indices were unavailable during the package check;
  the installed dependencies were used.

External artifacts for this run are under `/tmp/ggsynteny-circular-qefiIw/`:
`check-final.log`, `ggsynteny.Rcheck/tests/testthat.Rout`, `tests.log`,
`pkgdown.log`, the generated `site/`, and `ggsynteny_0.3.0.tar.gz`.
