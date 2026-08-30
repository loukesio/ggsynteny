# ═══════════════════════════════════════════════════════════════════════════
# Interactive rendering via ggiraph
# ═══════════════════════════════════════════════════════════════════════════

#' Render an interactive synteny plot
#'
#' Wraps a plot built with `interactive = TRUE` (see [plot_synteny()] /
#' [plot_microsynteny()]) into a \pkg{ggiraph} widget with hover highlighting
#' and tooltips, for HTML output (R Markdown, Quarto, Shiny, pkgdown).
#'
#' @param p A ggplot built with `interactive = TRUE`.
#' @param width_svg,height_svg Width and height of the underlying SVG, in
#'   inches. Synteny plots are usually wide: the defaults are 10 x 6.
#' @param hover_css CSS applied to the hovered element.
#' @param opts A list of additional `ggiraph::opts_*()` options.
#' @param ... Passed on to [ggiraph::girafe()].
#' @return A `girafe` htmlwidget.
#' @examples
#' \dontrun{
#' syn <- example_synteny_data()
#' p <- plot_synteny(syn, c("Arabidopsis", "Grape", "Rice"),
#'                   palette = "casa_natal", interactive = TRUE)
#' syn_girafe(p)
#' }
#' @export
syn_girafe <- function(p, width_svg = 10, height_svg = 6,
                       hover_css = "fill-opacity:0.9;stroke:#333333;stroke-width:1.2px;",
                       opts = NULL, ...) {
  if (!requireNamespace("ggiraph", quietly = TRUE)) {
    stop("syn_girafe() requires the 'ggiraph' package. ",
         "Install it with install.packages('ggiraph').", call. = FALSE)
  }
  options <- c(
    list(
      ggiraph::opts_hover(css = hover_css),
      ggiraph::opts_hover_inv(css = "opacity:0.25;"),
      ggiraph::opts_tooltip(
        css = paste0("background:rgba(255,255,255,0.95);color:#222;",
                     "padding:5px 8px;border-radius:4px;",
                     "font-family:sans-serif;font-size:12px;",
                     "box-shadow:0 1px 4px rgba(0,0,0,0.25);")),
      ggiraph::opts_zoom(max = 4)
    ),
    opts
  )
  ggiraph::girafe(ggobj = p, width_svg = width_svg, height_svg = height_svg,
                  options = options, ...)
}
