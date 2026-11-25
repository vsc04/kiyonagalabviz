#' Mean points with error bars
#'
#' Draws a mean point and capless uncertainty interval per x/group/subgroup
#' combination. Optional individual points use the same jitter and dodge
#' settings as [plot_bars()].
#'
#' @inheritParams plot_bars
#' @param group Optional primary-condition column. Factor levels select the
#'   primary colours; `subgroup` selects shades within each colour.
#' @param palette Palette name from [kiyonaga_palettes]; defaults to `"accent"`.
#' @param point_size Size of the mean points.
#' @param linewidth Width of the uncertainty intervals and optional mean lines.
#' @param mean_line Logical; draw a horizontal line through each mean point?
#'   Useful when displaying individual dots. The line uses the mean colour
#'   and is drawn behind the mean point.
#' @param mean_line_width Horizontal mean-line width in x-axis units before
#'   dodging. `NULL` chooses `max(0.6, 2 * jitter_width)`, extending beyond the
#'   individual-dot column with the default jitter. Dodging divides the width
#'   among the groups at each x. Increase it for a longer marker.
#' @param preset Panel ratio preset; defaults to `"scatter"`.
#' @return A ggplot object. Use [plot_legend()] for a separate legend.
#' @export
#' @examples
#' d <- average_window(simulate_lab_data()$timecourse)
#' plot_means(d, "load", "pupil", group = "load")
#' plot_means(d, "load", "pupil", group = "load", show_points = TRUE,
#'            point_style = list(size = 1.5), mean_line = TRUE)
plot_means <- function(data, x, y, group = NULL, error = c("se", "sd", "ci", "none"),
                       show_points = FALSE, palette = "accent", point_size = 1.5,
                       linewidth = 0.5, dodge_width = 0.8, jitter_width = 0.4,
                       seed = 1, point_style = list(), ..., subgroup = NULL,
                       condition_groups = NULL, preset = "scatter",
                       legend = c("inside", "separate", "none"),
                       mean_line = FALSE, mean_line_width = NULL, point_preset = "grey_filled") {
  error <- match.arg(error)
  legend <- match.arg(legend)
  if (!is.logical(mean_line) || length(mean_line) != 1L || is.na(mean_line)) {
    stop("`mean_line` must be TRUE or FALSE.", call. = FALSE)
  }
  if (is.null(mean_line_width)) mean_line_width <- max(0.6, 2 * jitter_width)
  check_positive(mean_line_width, "mean_line_width")
  check_columns(data, c(x, y, group, subgroup), numeric = y)
  grouping <- prepare_plot_groups(data, group, subgroup, palette, condition_groups)
  data <- as_factors(grouping$data, x)
  group <- grouping$group
  p <- ggplot2::ggplot(data, plot_mapping(x, y, group))
  if (show_points) {
    p <- p + point_layer(group, resolve_point_style(point_preset, point_style),
                         dodge_width, jitter_width, seed)
  }
  position <- ggplot2::position_dodge(width = dodge_width)
  if (error != "none") {
    p <- p + ggplot2::stat_summary(fun.data = error_function(error), geom = "linerange",
                                   position = position, linewidth = linewidth,
                                   colour = kiyonaga_colors$GREY_MID, na.rm = TRUE)
  }
  if (mean_line) {
    p <- p + do.call(ggplot2::stat_summary,
                      c(list(fun.data = function(z) summary_frame(mean(z), 0),
                             geom = "errorbar", width = mean_line_width,
                             position = position, linewidth = linewidth, na.rm = TRUE),
                        plot_colour(grouping)))
  }
  p <- p + do.call(ggplot2::stat_summary,
                    c(list(fun = mean, geom = "point", position = position,
                           size = point_size, na.rm = TRUE), plot_colour(grouping))) +
    plot_scales(grouping, palette) + theme_kiyonaga(..., preset = preset)
  finish_plot(p, legend)
}
