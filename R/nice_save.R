#' High-resolution figure export for publications and slides
#'
#' A wrapper around [ggplot2::ggsave()] that sizes the figure to a layout
#' profile and keeps the panel aspect ratio set in the theme. Adapted from
#' `charite::nice_save()` by Johannes Julius Mohn (MIT licence).
#'
#' @details
#' Layouts (width in inches; height follows from the panel aspect ratio):
#' - `"full col"` (3.6), `"half col"` (1.8), `"tiny"` (1), `"full page"` (7.2)
#' - `"slides"`: 4.4 in high, width follows from the aspect ratio.
#'
#' Text size: `"slides"` sets all text to 14 pt and `"tiny"` to 6 pt (tick
#' and legend labels at 85% of that); other layouts keep the plot's own sizes
#' (8 pt with [theme_kiyonaga()]). Pass `font_size` to choose any size. This
#' rescales text defined relative to the base size, as in [theme_kiyonaga()];
#' point sizes, line widths and `geom_text()` labels are not changed.
#'
#' Backgrounds are transparent; pass
#' `bg = "white"` to override. `.pdf` is the preferred vector format; `.svg`
#' requires the svglite package.
#'
#' @param filename File name ending in `.pdf`, `.png`, `.tiff`, `.svg`, `.eps`, ...
#' @param plot A ggplot object. Defaults to the last plot.
#' @param layout One of `"full col"`, `"half col"`, `"tiny"`, `"full page"`,
#'   `"slides"`.
#' @param font_size Base font size in pt for the saved figure. `NULL`
#'   (default) uses 14 for `"slides"`, 6 for `"tiny"`, and leaves the plot's
#'   sizes unchanged otherwise.
#' @param custom Optional numeric `c(width, height)` in inches; overrides
#'   `layout`.
#' @param dpi Resolution for raster formats.
#' @param ... Passed to [ggplot2::ggsave()].
#'
#' @return The file name, invisibly.
#' @export
#'
#' @examples
#' \dontrun{
#' sim <- simulate_lab_data()
#' p <- plot_bars(average_window(sim$timecourse), "load", "pupil")
#' nice_save("pupil_bars.pdf", p, layout = "half col")
#' nice_save("pupil_bars_slide.png", p, layout = "slides")   # 14 pt text
#' nice_save("pupil_bars_talk.png", p, layout = "slides", font_size = 18)
#' }
nice_save <- function(filename, plot = ggplot2::last_plot(),
                      layout = c("full col", "half col", "tiny",
                                 "full page", "slides"),
                      font_size = NULL, custom = NULL, dpi = 600, ...) {
  layout <- match.arg(layout)
  if (is.null(font_size)) font_size <- layout_font_size(layout)
  if (!is.null(font_size)) plot <- resize_text(plot, font_size)
  dims <- figure_dims(plot, layout, custom)
  message("Saving a ", round(dims$width, 2), " x ", round(dims$height, 2),
          " in figure.")
  warn_pdf_font(filename, plot)
  do.call(
    ggplot2::ggsave,
    c(list(filename = filename, plot = plot, width = dims$width,
           height = dims$height, dpi = dpi, units = "in"),
      device_args(filename), list(...))
  )
  invisible(filename)
}

#' Default base font size per layout (NULL = keep the plot's sizes)
#' @noRd
layout_font_size <- function(layout) {
  sizes <- c("slides" = 14, "tiny" = 6)
  if (layout %in% names(sizes)) sizes[[layout]] else NULL
}

#' Set the base text size; relative sizes in the theme follow
#' @noRd
resize_text <- function(plot, font_size) {
  if (!is.numeric(font_size) || length(font_size) != 1 || font_size <= 0) {
    stop("`font_size` must be a single positive number.", call. = FALSE)
  }
  plot + ggplot2::theme(
    text = ggplot2::element_text(size = font_size),
    legend.key.size = ggplot2::unit(font_size * small_text_ratio, "pt")
  )
}

#' Width and height in inches for a layout
#' @noRd
figure_dims <- function(plot, layout, custom) {
  if (!is.null(custom)) {
    if (!is.numeric(custom) || length(custom) != 2) {
      stop("`custom` must be a numeric vector c(width, height).", call. = FALSE)
    }
    return(list(width = custom[1], height = custom[2]))
  }
  extra <- non_panel_size(plot)
  ar <- panel_aspect_ratio(plot)
  if (layout == "slides") {
    return(list(width = (4.4 - extra$h) / ar + extra$w, height = 4.4))
  }
  width <- c("full col" = 3.6, "half col" = 1.8, "tiny" = 1,
             "full page" = 7.2)[[layout]]
  list(width = width, height = (width - extra$w) * ar + extra$h)
}

#' Space (in) taken by titles, labels and legends outside the panel
#' @noRd
non_panel_size <- function(plot) {
  g <- ggplot2::ggplotGrob(plot)
  list(
    w = sum(grid::convertWidth(g$widths, "in", valueOnly = TRUE)),
    h = sum(grid::convertHeight(g$heights, "in", valueOnly = TRUE))
  )
}

#' Panel aspect ratio from the plot theme (1 if unset)
#' @noRd
panel_aspect_ratio <- function(plot) {
  ar <- plot$theme$aspect.ratio
  if (is.null(ar)) {
    message("No aspect ratio set in the theme; assuming 1:1.")
    return(1)
  }
  ar
}

#' Device settings per file type
#' @noRd
device_args <- function(filename) {
  ext <- tolower(tools::file_ext(filename))
  if (ext == "pdf") return(list(device = grDevices::pdf, useDingbats = FALSE))
  if (ext == "svg") return(list(device = svg_device()))
  if (ext == "eps") {
    if (!capabilities("cairo")) stop("Saving .eps requires Cairo.", call. = FALSE)
    return(list(device = grDevices::cairo_ps, fallback_resolution = 600))
  }
  list()
}

#' svglite device, with a helpful error if it is missing
#' @noRd
svg_device <- function() {
  if (!requireNamespace("svglite", quietly = TRUE)) {
    stop("Saving .svg requires the 'svglite' package: ",
         "install.packages('svglite')", call. = FALSE)
  }
  svglite::svglite
}

#' Warn if a non-standard font is saved with the base PDF device
#' @noRd
warn_pdf_font <- function(filename, plot) {
  if (tolower(tools::file_ext(filename)) != "pdf") return(invisible(NULL))
  font <- plot$theme$text$family
  standard <- c("", "sans", "serif", "mono", "Helvetica", "Times", "Courier")
  if (!is.null(font) && !font %in% standard) {
    warning("The base PDF device reliably supports only standard fonts; ",
            "your plot uses '", font, "'. Consider ",
            "`device = grDevices::cairo_pdf`.", call. = FALSE)
  }
  invisible(NULL)
}
