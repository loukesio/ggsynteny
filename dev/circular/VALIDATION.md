# Validation — 2026-09-16

- `R CMD build` succeeds, including the existing package vignette.
- `R CMD check --no-manual`: **0 errors, 0 warnings, 0 notes**.
- Installed test suite: **322 passing expectations**, no failures, warnings or
  skips (223 baseline expectations plus 99 circular-view expectations).
- The circular article renders independently and as part of the full pkgdown
  site. Both new functions have generated reference pages and runnable examples.
- After relocation and the README update, the package build/check and full
  pkgdown build were rerun successfully. All three circular README code blocks
  ran against the package's private installed copy, including `system.file()`
  access to the new bacterial tables.
- PDF downloads and image links in the local gallery and generated homepage
  resolve. The three mirrored PDF assets match their source PDFs byte for byte.
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

All artifacts are now in this permanent worktree. Logs and local build products
are under `dev/circular/validation/`; the generated documentation is under
`docs/`. Vector PDFs and README PNGs are under `man/figures/`. None of the
rendering scripts require a temporary directory.

The three-bacterium example adds 21 prepared gene records, four contigs and
nine input links (four ZONMW-30–ZONMW-20; five ZONMW-20–HI1). Its reproducible
script checks unique feature IDs, exactly one feature per link endpoint, and
agreement between input and plotted record counts. The original CSV inputs
are unchanged. No biological inference is made from matching names alone.
