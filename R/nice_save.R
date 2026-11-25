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
#' Text size: `"slides"` uses 14 pt base text and `"tiny"` uses 6 pt;
#' other layouts preserve the plot's text sizes (8 pt in the default lab theme).
#' Tick and legend labels are 85% of the base size. Pass `font_size` to override.
#' Point sizes, line widths and `geom_text()` labels are not rescaled.
#'
#' Plot-type presets in [kiyonaga_plot_presets] set only panel height / width
#' ratio. The selected whole-figure `layout` determines physical panel size
#' after accounting for axes, legends, margins and facet spacing. Bar presets
#' adapt to the number of displayed bars; faceted plots use the largest bar
#' count per panel. [plot_bars()] ratios are refreshed automatically on export
#' after faceting, unless the ratio or bar count was explicitly overridden.
#' Whole-figure presets can also be passed as `preset`, as an alias for `layout`.
#' An explicit `layout` takes precedence over a whole-figure `preset`.
#'
#' Backgrounds are transparent; pass
#' `bg = "white"` to override. `.pdf` is the preferred vector format; `.svg`
#' requires the svglite package.
#'
#' @param filename File name ending in `.pdf`, `.png`, `.tiff`, `.svg`, `.eps`, ...
#' @param plot A ggplot object, or a legend grob from [plot_legend()]. Legends
#'   use their intrinsic dimensions unless `custom` is supplied; `layout` is
#'   ignored. Set their font size on the source plot before extraction.
#'   Defaults to the last plot.
#' @param layout One of `"full col"`, `"half col"`, `"tiny"`, `"full page"`,
#'   `"slides"`.
#' @param font_size Base font size in pt for the saved figure. `NULL`
#'   (default) uses 14 for `"slides"`, 6 for `"tiny"`, and leaves the plot's
#'   sizes unchanged otherwise.
#' @param custom Optional numeric `c(width, height)` in inches; overrides
#'   `layout`.
#' @param dpi Resolution for raster formats.
#' @param ... Passed to [ggplot2::ggsave()].
#' @param preset Optional ratio or whole-figure name in [kiyonaga_plot_presets].
#'   A ratio preset changes panel shape without changing text or figure width.
#' @param n_bars Optional manual bar count for a bar ratio preset. By default,
#'   infer it from built bar layers, taking the largest count across panels.
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
#' nice_save("pupil_bars_tiny.svg", p, layout = "tiny")     # 1 in wide, 6 pt
#' nice_save("pupil_bars_tall.pdf", p, preset = "bars_tall", layout = "half col")
#' }
nice_save <- function(filename, plot = ggplot2::last_plot(),
                      layout = c("full col", "half col", "tiny",
                                 "full page", "slides"),
                      font_size = NULL, custom = NULL, dpi = 600, ...,
                      preset = NULL, n_bars = NULL) {
  if (inherits(plot, "grob")) {
    if (!is.null(font_size) || !is.null(preset)) {
      stop("Set legend fonts and presets on the source plot before extraction.", call. = FALSE)
    }
    dims <- if (is.null(custom)) {
      c(sum(grid::convertWidth(plot$widths, "in", valueOnly = TRUE)),
        sum(grid::convertHeight(plot$heights, "in", valueOnly = TRUE)))
    } else custom
    if (!is.numeric(dims) || length(dims) != 2 || any(!is.finite(dims)) || any(dims <= 0)) {
      stop("Legend dimensions must be positive; supply `custom = c(width, height)`.", call. = FALSE)
    }
    do.call(ggplot2::ggsave,
            c(list(filename = filename, plot = plot, width = dims[1],
                   height = dims[2], units = "in", dpi = dpi),
              device_args(filename), list(...)))
    return(invisible(filename))
  }
  settings <- get_plot_preset(preset)
  if (!is.null(settings) && settings$size_type == "figure" && missing(layout)) {
    layout <- preset
  }
  ratio_settings <- if (!is.null(settings) && settings$size_type == "ratio") settings else NULL
  if (is.null(ratio_settings) &&
      identical(plot$theme$aspect.ratio, attr(plot, "kiyonaga_bar_aspect")) &&
      !is.null(attr(plot, "kiyonaga_bar_preset"))) {
    ratio_settings <- get_plot_preset(attr(plot, "kiyonaga_bar_preset"))
  }
  if (!is.null(ratio_settings)) {
    if (!is.null(ratio_settings$reference_bars) && is.null(n_bars)) {
      n_bars <- count_plot_bars(plot)
    }
    plot <- plot + ggplot2::theme(
      aspect.ratio = preset_aspect_ratio(ratio_settings, n_bars)
    )
  }
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
  get_plot_preset(layout)$font_size
}

#' Set the base text size; relative sizes in the theme follow
#' @noRd
resize_text <- function(plot, font_size) {
  if (!is.numeric(font_size) || length(font_size) != 1 || font_size <= 0) {
    stop("`font_size` must be a single positive number.", call. = FALSE)
  }
  plot <- plot + ggplot2::theme(text = ggplot2::element_text(size = font_size))
  legend_size <- ggplot2::calc_element("legend.text", plot$theme)$size
  if (is.null(legend_size)) legend_size <- font_size * small_text_ratio
  plot + ggplot2::theme(legend.key.size = ggplot2::unit(legend_size, "pt"))
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
  geometry <- plot_geometry(plot)
  extra <- geometry$extra
  ar <- panel_aspect_ratio(plot)
  settings <- get_plot_preset(layout)
  if (is.null(settings$figure_width)) {
    height <- settings$figure_height
    width <- (height - extra$h) / ar * geometry$cols / geometry$rows + extra$w
  } else {
    width <- settings$figure_width
    height <- (width - extra$w) * ar * geometry$rows / geometry$cols + extra$h
  }
  list(width = width, height = height)
}

#' Fixed space and panel grid dimensions for an exported figure
#' @noRd
plot_geometry <- function(plot) {
  g <- ggplot2::ggplotGrob(plot)
  panels <- g$layout[grepl("^panel($|-)", g$layout$name), ]
  list(
    extra = list(
      w = sum(grid::convertWidth(g$widths, "in", valueOnly = TRUE)),
      h = sum(grid::convertHeight(g$heights, "in", valueOnly = TRUE))
    ),
    cols = length(unique(panels$l)), rows = length(unique(panels$t))
  )
}

#' Space (in) taken by titles, labels and legends outside the panels
#' @noRd
non_panel_size <- function(plot) plot_geometry(plot)$extra

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
