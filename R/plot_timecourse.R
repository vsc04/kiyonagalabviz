#' Timecourse plot with mean lines and error ribbons
#'
#' Plots the mean of `y` over `time` per condition as a line, with a shaded
#' ribbon for the error (mean +/- SE by default) and, optionally, the analysis
#' window shaded in light grey. Styled with [theme_kiyonaga()].
#'
#' @param data A data frame in long format (one row per subject and time point).
#' @param time Name of the numeric time column.
#' @param y Name of the numeric outcome column.
#' @param group Optional name of the primary-condition column (converted to a
#'   factor). With `subgroup`, selects the primary colour while subgroup
#'   selects its shade.
#' @param window Optional numeric `c(start, end)` to shade, e.g. the window
#'   used in [average_window()].
#' @param error Ribbon type: `"se"` (default), `"sd"` or `"ci"` (95%).
#' @param palette Line and ribbon palette for `group`, see [kiyonaga_palettes].
#' @param ribbon_alpha Transparency of the ribbons. Set to `NULL` to preserve
#'   alpha embedded in the palette colours; a number overrides that alpha.
#' @param linewidth Width of the mean lines.
#' @param ... Passed to [theme_kiyonaga()], e.g. `aspect_ratio = 0.6`.
#' @param preset Plot ratio preset, default `"timecourse"` (height / width
#'   0.68). `NULL` uses the theme's default. See [kiyonaga_plot_presets].
#' @param subgroup Optional name of a secondary-condition column. Requires
#'   `group` and a main palette from [kiyonaga_palette_groups]. Primary group
#'   levels select colours; subgroup levels select shades from dark to light.
#'   Factor levels control order; other columns use alphabetical/numeric order.
#'   Two subgroup levels are supported, or three with `accent_3`. All group-by-
#'   subgroup combinations retain their colours even when some are missing;
#'   the legend includes the complete set of combinations.
#' @param condition_groups Optional shade count for a combined condition column
#'   supplied as `group`, with levels in primary-then-shade order. With
#'   `subgroup`, this count is inferred and any supplied value must match it.
#'   See [kiyonaga_palette_groups].
#'
#' @param legend `"inside"` keeps the legend in the plot (at the theme's
#'   position); `"separate"` hides it for export with [plot_legend()]; `"none"`
#'   hides it. Separate export does not write a file until [nice_save()] is called.
#'
#' @return A ggplot object.
#' @export
#'
#' @examples
#' sim <- simulate_lab_data()
#' plot_timecourse(sim$timecourse, time = "time", y = "pupil",
#'                 group = "load", window = c(3, 5))
#' d2 <- expand.grid(task = c("A", "B"), session = c("first", "second"),
#'                   time = 1:3, subject = 1:4)
#' d2$value <- seq_len(nrow(d2))
#' plot_timecourse(d2, "time", "value", group = "task", subgroup = "session",
#'                 palette = "blue_yellow_2")
plot_timecourse <- function(data, time, y, group = NULL, window = NULL,
                            error = c("se", "sd", "ci"), palette = "accent",
                            ribbon_alpha = 0.4, linewidth = 0.6, ...,
                            condition_groups = NULL, preset = "timecourse",
                            subgroup = NULL, legend = c("inside", "separate", "none")) {
  legend <- match.arg(legend)
  error <- match.arg(error)
  check_columns(data, c(time, y, group, subgroup), numeric = c(time, y))
  grouping <- prepare_plot_groups(data, group, subgroup, palette, condition_groups)
  data <- grouping$data
  group <- grouping$group
  condition_groups <- grouping$condition_groups

  p <- ggplot2::ggplot(data, timecourse_mapping(time, y, group))
  if (!is.null(window)) {
    check_window(window)
    p <- p + window_layer(window)
  }
  p <- p + ribbon_layer(error, group, ribbon_alpha) +
    line_layer(group, linewidth) +
    timecourse_scales(group, palette, condition_groups, grouping$limits) +
    ggplot2::labs(colour = grouping$title, fill = grouping$title) +
    theme_kiyonaga(..., preset = preset)
  finish_plot(p, legend)
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
               colour = NA)
  if (!is.null(alpha)) args$alpha <- alpha
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
timecourse_scales <- function(group, palette, condition_groups = NULL, limits = NULL) {
  x_scale <- ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = 0))
  if (is.null(group)) return(list(x_scale))
  list(x_scale, scale_colour_kiyonaga(palette, condition_groups = condition_groups, limits = limits),
       scale_fill_kiyonaga(palette, condition_groups = condition_groups, limits = limits))
}
