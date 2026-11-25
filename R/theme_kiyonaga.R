#' Kiyonaga Lab ggplot2 theme
#'
#' A clean theme following the PI's figure style: light grey axis lines without
#' ticks, grey tick labels, bold titles, and the legend on top with its bold
#' title centred above the keys.
#'
#' @details
#' Default sizes follow the lab's published figures: titles and axis titles at
#' `font_size` (8 pt), tick and legend labels at 85% of it (~7 pt).
#' All text sizes are relative to `font_size`, so
#' `theme(text = element_text(size = 14))` resizes all text at once;
#' [nice_save()] uses this for the `"slides"` and `"tiny"` layouts.
#' Fonts other than "sans", "serif" or "mono" must be installed on your system.
#'
#' @param font_size Base font size in pt (titles, axis titles, legend title).
#' @param font Font family. Defaults to `"sans"` (Arial/Helvetica).
#' @param thickness Line width of the axis lines (and ticks).
#' @param aspect_ratio Panel aspect ratio (y / x). `NULL` lets the panel fill
#'   the available space.
#' @param grid Logical; add light grey major grid lines?
#' @param ticks Tick direction: `"inside"`, `"outside"`, or `"off"` (AK style).
#'   Logical values are also supported: `FALSE` (default) means `"off"`, and
#'   `TRUE` means `"outside"`.
#' @param tick_length Positive tick length in points, default 2. Ignored when
#'   ticks are off. Inside ticks extend into the panel; labels stay outside.
#' @param legend_position Legend position, e.g. `"top"` (default), `"right"`,
#'   `"none"`.
#' @param tiny_margins Logical; minimise margins around the panel.
#' @param debug_area Logical; outline the full plot area in red.
#' @param preset Optional name in [kiyonaga_plot_presets]. Plot-type presets
#'   set only height / width ratio. Whole-figure presets `"slides"` and
#'   `"tiny"` select 14 pt and 6 pt text. Explicit `font_size` and
#'   `aspect_ratio` override preset defaults. Export size comes from
#'   [nice_save()]'s `layout`, rather than from the plot-type preset.
#' @param n_bars Bar count for `preset = "bars"` or `"bars_tall"`.
#'   Used only for bar ratios; [plot_bars()] supplies it automatically.
#'
#' @return A ggplot2 theme.
#' @export
#'
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(wt, mpg)) +
#'   geom_point(colour = kiyonaga_colors$ACCENT_GREEN) +
#'   theme_kiyonaga()
#' theme_kiyonaga(ticks = "inside", tick_length = 2)
theme_kiyonaga <- function(font_size = 8, font = "sans", thickness = 0.5,
                           aspect_ratio = 1, grid = FALSE, ticks = FALSE,
                           legend_position = "top", tiny_margins = FALSE,
                           debug_area = FALSE, preset = NULL, n_bars = 2,
                           tick_length = 2) {
  if (is.logical(ticks) && length(ticks) == 1L && !is.na(ticks)) {
    ticks <- if (ticks) "outside" else "off"
  } else if (!is.character(ticks) || length(ticks) != 1L || is.na(ticks) ||
             !ticks %in% c("inside", "outside", "off")) {
    stop("`ticks` must be 'inside', 'outside', 'off', TRUE or FALSE.", call. = FALSE)
  }
  check_positive(tick_length, "tick_length")
  settings <- get_plot_preset(preset)
  if (!is.null(settings)) {
    if (missing(font_size) && !is.null(settings$font_size)) font_size <- settings$font_size
    if (missing(aspect_ratio) && settings$size_type == "ratio") {
      aspect_ratio <- preset_aspect_ratio(settings, n_bars)
    }
  }
  font <- check_font(font)
  s <- theme_sizes(font_size, tiny_margins)
  theme <- ggplot2::theme_classic(base_size = font_size, base_family = font) +
    theme_text_elements(s) +
    theme_axis_elements(s, thickness, ticks, tick_length) +
    theme_legend_elements(s, legend_position) +
    theme_panel_elements(s, grid, aspect_ratio, thickness) +
    theme_debug(debug_area)
  theme
}

#' Fall back to "sans" if a font is not installed
#' @noRd
check_font <- function(font) {
  generic <- c("sans", "serif", "mono")
  if (font %in% generic || font %in% systemfonts::system_fonts()$family) {
    return(font)
  }
  warning("Font '", font, "' is not installed. Using 'sans' instead.",
          call. = FALSE)
  "sans"
}

#' Size of tick labels, legend labels and captions relative to `font_size`
#' @noRd
small_text_ratio <- 0.85

#' Font sizes and margins derived from the base font size
#' @noRd
theme_sizes <- function(font_size, tiny_margins) {
  list(
    base = font_size,
    small = round(font_size * small_text_ratio, 1),
    margin = if (tiny_margins) 2 else 4,
    margin_title = if (tiny_margins) 4 else 8
  )
}

#' Titles and captions
#' @noRd
theme_text_elements <- function(s) {
  ggplot2::theme(
    text = ggplot2::element_text(colour = kiyonaga_colors$TEXT),
    plot.title = ggplot2::element_text(
      face = "bold", size = ggplot2::rel(1), hjust = 0.5,
      margin = ggplot2::margin(b = s$margin_title)
    ),
    plot.subtitle = ggplot2::element_text(
      size = ggplot2::rel(1), hjust = 0.5, colour = kiyonaga_colors$GREY_TEXT,
      margin = ggplot2::margin(b = s$margin_title)
    ),
    plot.caption = ggplot2::element_text(
      size = ggplot2::rel(small_text_ratio), colour = kiyonaga_colors$GREY_TEXT
    ),
    strip.text = ggplot2::element_text(face = "bold", size = ggplot2::rel(1)),
    strip.background = ggplot2::element_blank()
  )
}

#' Axis lines, ticks, titles and labels
#' @noRd
theme_axis_elements <- function(s, thickness, ticks, tick_length) {
  signed_length <- switch(ticks, inside = -tick_length, outside = tick_length, off = 0)
  axis_line <- ggplot2::element_line(
    colour = kiyonaga_colors$GREY_AXIS, linewidth = thickness,
    lineend = "square"
  )
  ggplot2::theme(
    axis.line = axis_line,
    axis.ticks = if (ticks == "off") ggplot2::element_blank() else axis_line,
    axis.ticks.length = ggplot2::unit(signed_length, "pt"),
    axis.title = ggplot2::element_text(size = ggplot2::rel(1)),
    axis.title.x = ggplot2::element_text(margin = ggplot2::margin(t = s$margin)),
    axis.title.y = ggplot2::element_text(margin = ggplot2::margin(r = s$margin)),
    axis.text = ggplot2::element_text(
      size = ggplot2::rel(small_text_ratio), colour = kiyonaga_colors$GREY_TEXT
    ),
    axis.text.x = ggplot2::element_text(margin = ggplot2::margin(t = 3)),
    axis.text.y = ggplot2::element_text(margin = ggplot2::margin(r = 3)),
    axis.text.x.top = ggplot2::element_text(margin = ggplot2::margin(b = 3),
                                           inherit.blank = TRUE),
    axis.text.y.right = ggplot2::element_text(margin = ggplot2::margin(l = 3),
                                             inherit.blank = TRUE)
  )
}

#' Legend on top with a bold, centred title above the keys
#' @noRd
theme_legend_elements <- function(s, legend_position) {
  ggplot2::theme(
    legend.position = legend_position,
    legend.title = ggplot2::element_text(face = "bold", size = ggplot2::rel(1),
                                         hjust = 0.5),
    legend.title.position = "top",
    legend.text = ggplot2::element_text(
      size = ggplot2::rel(small_text_ratio), colour = kiyonaga_colors$GREY_TEXT
    ),
    legend.key.size = ggplot2::unit(s$small, "pt"),
    legend.key.spacing.x = ggplot2::unit(s$margin, "pt"),
    legend.margin = ggplot2::margin(0, 0, 0, 0),
    legend.box.spacing = ggplot2::unit(s$margin, "pt"),
    legend.background = ggplot2::element_rect(fill = "transparent", colour = NA),
    legend.key = ggplot2::element_rect(fill = "transparent", colour = NA)
  )
}

#' Backgrounds, grid, spacing and aspect ratio
#' @noRd
theme_panel_elements <- function(s, grid, aspect_ratio, thickness) {
  grid_line <- if (grid) {
    ggplot2::element_line(colour = kiyonaga_colors$GREY_LIGHT,
                          linewidth = thickness / 2)
  } else {
    ggplot2::element_blank()
  }
  ggplot2::theme(
    panel.grid.major = grid_line,
    panel.grid.minor = ggplot2::element_blank(),
    panel.background = ggplot2::element_rect(fill = "transparent", colour = NA),
    plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
    panel.spacing = ggplot2::unit(s$margin * 2, "pt"),
    plot.margin = ggplot2::margin(s$margin, s$margin, s$margin, s$margin),
    aspect.ratio = aspect_ratio
  )
}

#' Optional red outline of the plot area
#' @noRd
theme_debug <- function(debug_area) {
  if (!debug_area) return(ggplot2::theme())
  ggplot2::theme(plot.background = ggplot2::element_rect(colour = "red"))
}
