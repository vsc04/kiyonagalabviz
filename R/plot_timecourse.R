#' Timecourse plot with mean lines and error ribbons
#'
#' Plots the mean of `y` over `time` per condition as a line, with a shaded
#' ribbon for the error (mean +/- SE by default) and, optionally, the analysis
#' window shaded in light grey. Styled with [theme_kiyonaga()].
#'
#' @param data A data frame in long format (one row per subject and time point).
#' @param time Name of the numeric time column.
#' @param y Name of the numeric outcome column.
#' @param group Optional name of the condition column (converted to a factor).
#' @param window Optional numeric `c(start, end)` to shade, e.g. the window
#'   used in [average_window()].
#' @param error Ribbon type: `"se"` (default), `"sd"` or `"ci"` (95%).
#' @param palette Line and ribbon palette for `group`, see [kiyonaga_palettes].
#' @param ribbon_alpha Transparency of the ribbons.
#' @param linewidth Width of the mean lines.
#' @param ... Passed to [theme_kiyonaga()], e.g. `aspect_ratio = 0.6`.
#'
#' @return A ggplot object.
#' @export
#'
#' @examples
#' sim <- simulate_lab_data()
#' plot_timecourse(sim$timecourse, time = "time", y = "pupil",
#'                 group = "load", window = c(3, 5))
plot_timecourse <- function(data, time, y, group = NULL, window = NULL,
                            error = c("se", "sd", "ci"), palette = "accent",
                            ribbon_alpha = 0.4, linewidth = 0.6, ...) {
  error <- match.arg(error)
  check_columns(data, c(time, y, group), numeric = c(time, y))
  data <- as_factors(data, group)

  p <- ggplot2::ggplot(data, timecourse_mapping(time, y, group))
  if (!is.null(window)) {
    check_window(window)
    p <- p + window_layer(window)
  }
  p + ribbon_layer(error, group, ribbon_alpha) +
    line_layer(group, linewidth) +
    timecourse_scales(group, palette) +
    theme_kiyonaga(...)
}

#' Aesthetic mapping with or without a condition column
#' @noRd
timecourse_mapping <- function(time, y, group) {
  if (is.null(group)) {
    return(ggplot2::aes(x = .data[[time]], y = .data[[y]]))
  }
  ggplot2::aes(x = .data[[time]], y = .data[[y]], colour = .data[[group]],
               fill = .data[[group]], group = .data[[group]])
}

#' Light grey shading of the analysis window, behind the data
#' @noRd
window_layer <- function(window) {
  ggplot2::annotate("rect", xmin = window[1], xmax = window[2],
                    ymin = -Inf, ymax = Inf,
                    fill = kiyonaga_colors$GREY_LIGHT, alpha = 0.5)
}

#' Error ribbons without outlines
#' @noRd
ribbon_layer <- function(error, group, alpha) {
  args <- list(fun.data = error_function(error), geom = "ribbon",
               alpha = alpha, colour = NA)
  if (is.null(group)) args$fill <- kiyonaga_colors$GREY_DARK
  do.call(ggplot2::stat_summary, args)
}

#' Mean lines
#' @noRd
line_layer <- function(group, linewidth) {
  args <- list(fun = mean, geom = "line", linewidth = linewidth)
  if (is.null(group)) args$colour <- kiyonaga_colors$GREY_DARK
  do.call(ggplot2::stat_summary, args)
}

#' Time axis without padding; matching colour and fill palettes
#' @noRd
timecourse_scales <- function(group, palette) {
  x_scale <- ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = 0))
  if (is.null(group)) return(list(x_scale))
  list(x_scale, scale_colour_kiyonaga(palette), scale_fill_kiyonaga(palette))
}
