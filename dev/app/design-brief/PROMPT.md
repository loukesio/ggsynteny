# Prompt for Claude Design

Attach this whole folder (or at least BRIEF.md, the six screenshots and
current-styles/), then paste:

---

Redesign the web app described in BRIEF.md. It is "ggsynteny Studio", a
Shiny app for biologists who upload synteny results and get a publication
figure. The six screenshots show it as it is today; the brief lists what is
wrong and what we need.

Deliver a clickable prototype of the full flow for all three jobs (synteny,
annotation tracks, reference comparison) with one consistent shell:

1. a start screen that explains the three jobs and offers "start from an
   example" for each;
2. a data step with drag-and-drop upload, the required columns, a sample
   file download, and a readout of what was read (counts and any skipped rows
   with the reason);
3. a figure step with the figure always visible and controls grouped by what
   they change (layout, colours, ribbons, labels, tracks as a reorderable
   list);
4. an export step (PDF, PNG, tables, R script).

Keep the ltc palettes as the colour system (casa_natal default), the IBM Plex
fonts, the paper-coloured background, and treat the figures as fixed images.
Build it as plain HTML and CSS with simple components (cards, lists, tabs,
steppers, form inputs) so it can be implemented in Shiny; avoid client-side
state that a server round trip could not reproduce. Target laptops and wide
monitors.

Also give me a short tokens file (colours, type scale, spacing, radii) and
one annotated screen per step explaining the reasoning.
