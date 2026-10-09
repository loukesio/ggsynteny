> Implemented on 10 October 2026 from Claude Design's handout (`Handout.dc.html`, seven pages: four steps, tokens). The screenshots below show the app *before* that work.

# ggsynteny Studio: design brief

A hand-off package for a visual and interaction redesign of ggsynteny Studio,
the Shiny app bundled with the R package ggsynteny
(https://github.com/loukesio/ggsynteny). Everything in this folder is the
current state on 10 October 2026: six screenshots, every input file format
with a real sample, and the two style sheets in use today.

## What the app is for

ggsynteny draws comparative-genomics figures in R. Studio exists for people
who have results from a synteny tool (MCScanX, GENESPACE) or plain tables and
want the figure without writing R. They upload files, see the figure, adjust
a few things, and download PDF/PNG plus an R script that reproduces it.

Three jobs, today three tabs:

| Job | Input | Output |
|---|---|---|
| **Synteny**: compare genomes with each other | chromosome + block tables, or gene + link tables, or MCScanX / GENESPACE output | one of four figures: chromosome-level or gene-level, linear tiers or ring |
| **Annotation tracks**: add rings or lanes to that figure | interval tables: `start`, `end`, plus a numeric `value` or a category column | the same figure with GC lines, gene boxes, heatmaps, bars, a coordinate axis |
| **Reference comparison**: compare genomes to one reference | a variant-call table and an optional identity-window table | concentric rings around the reference with variant marks and identity shading |

Users: biologists and bioinformaticians, often first-time visitors arriving
from the README or a paper. They know their data; they do not know this app.

## What is wrong today (see screenshots/)

1. **No onboarding.** The app opens on a sidebar of controls. Nothing says
   "here is what you need to bring" before the user meets a file picker.
   `06-synteny-upload-mode.png`: switching to "Upload results" shows the same
   warning three times and no sample file to download.
2. **Input instructions are hidden or absent.** Column requirements are a
   small grey box in the sidebar (`06`). The Annotation tracks tab has a
   paragraph of prose (`03`). The Reference comparison tab hides its upload
   controls in a collapsed section at the very bottom of a long page
   (`05-reference-comparison-upload-mode.png`): a user switching to "Upload
   variant table" sees a heading and an empty area.
3. **Three tabs, two visual languages.** Synteny and Annotation tracks share
   one shell (`studio.css`: green accents, cards, a left control panel).
   Reference comparison was designed separately (`reference.css`: IBM Plex
   fonts, mono kickers, a full-width workbench). They do not feel like one app.
4. **No sense of progress.** The natural flow is choose data → check it →
   shape the figure → export. Today the controls for all four stages sit in
   one column with numbered kickers ("01 / YOUR DATA", "02 / YOUR FIGURE").
5. **The Annotation tracks tab is a control dump.** Three identical upload
   slots are always visible, with per-track options appearing below each
   file picker. There is no way to see at a glance what each ring is or to
   reorder rings.
6. **Validation feedback is a yellow banner.** Errors are correct but terse
   ("A block references an unknown chromosome"); they do not point at the
   column or row, and there is no preview of what was read.

## What we want from the redesign

- **One shell for all three jobs**, with a first screen that explains the
  three jobs in a sentence each and lets the user pick one, or start from an
  example.
- **A data-input step that teaches.** For every format: the required
  columns, a sample file to download, and after upload a short readout
  ("2 genomes, 14 chromosomes, 240 blocks; 3 blocks skipped: unknown
  chromosome in row 12"). Drag-and-drop, with the file picker as fallback.
- **Figure controls grouped by what they change** (layout, colours, ribbons,
  labels), with the figure always visible. Secondary options collapsed.
- **Tracks as a list** you add to, reorder, and switch off, each row showing
  its type, its table and a few key options, rather than three fixed slots.
- **Export as a clear last step**: PDF, PNG, the tables, the R script.
- **Keep**: the ltc colour palettes as the colour system (32 named palettes,
  `casa_natal` is the default), the IBM Plex fonts already bundled for the
  reference view, the quiet paper-coloured background, and the figure styles
  themselves (the plots are fixed R output and should not be restyled).
- **Mobile is not a target**; laptops and wide monitors are.

## Constraints for implementation

The app is R Shiny without a component framework: plain `shiny::*` inputs
styled by CSS (`current-styles/`). A design delivered as HTML/CSS with simple
component structure (cards, lists, tabs, steppers, inputs) translates well.
Heavy client-side state (React) does not; interactions are server round
trips. Figures are static PNGs rendered by R, or an interactive SVG widget
(ggiraph) when the "Interactive" switch is on.

Every design decision that implies a new control must map to an existing
function argument; `samples/` and the package README show what exists.

## Files

- `screenshots/01` to `06`: the three tabs, each in example and upload mode.
- `samples/`: one real or clearly simulated file per input format.
  `chromosomes.tsv` + `synteny_blocks.tsv` (native), `mcscanx_output.*`,
  `genespace_synHits.tsv`, `circular_bacterial_features.tsv` +
  `circular_bacterial_links.tsv` (gene tables), `chloroplast_*_track.csv`
  (annotation tracks), `variants_five_genomes.tsv` +
  `identity_five_genomes.tsv` (reference comparison, invented).
- `current-styles/`: `studio.css` (Synteny and Annotation tracks tabs) and
  `reference.css` (Reference comparison tab).
- `PROMPT.md`: the text to give Claude Design with this folder.
