#' Bar plot of means with error bars and optional individual data points
#'
#' Draws one bar per condition (mean of `y`), thin error bars without caps in
#' the PI's mid grey, and, optionally, every individual observation as a
#' jittered point on top of its bar. Styled with [theme_kiyonaga()].
#'
#' @param data A data frame in long format (one row per observation).
#' @param x Name of the column on the x axis (converted to a factor).
#' @param y Name of the numeric outcome column.
#' @param group Optional name of a grouping column; bars are dodged and filled
#'   by group (converted to a factor).
#' @param error Error bar type: `"se"` (default), `"sd"`, `"ci"` (95% t-based)
#'   or `"none"`.
#' @param show_points Logical; plot the individual data points?
#' @param palette Fill palette for `group`, see [kiyonaga_palettes]. Defaults
#'   to the PI's `"greys"` (light/dark for two groups).
#' @param point_style Named list overriding the point defaults:
#'   `size = 1`, `fill = "white"`, `colour = kiyonaga_colors$GREY_DARK`,
#'   `alpha = 0.8`, `stroke = 0.3`.
#' @param bar_width Width of the bars.
#' @param dodge_width Dodging width between groups.
#' @param jitter_width Horizontal spread of the points (passed to
#'   [ggplot2::position_jitterdodge()]; scaled the same way without `group`).
#' @param seed Random seed for the jitter, so points do not move between runs.
#' @param ... Passed to [theme_kiyonaga()], e.g. `font_size = 12`.
#'
#' @return A ggplot object; add layers, scales or labels as usual.
#' @export
#'
#' @examples
#' sim <- simulate_lab_data()
#' d <- average_window(sim$timecourse, window = c(3, 5))
#' plot_bars(d, x = "load", y = "pupil")
#' plot_bars(d, x = "load", y = "pupil", group = "load", error = "ci")
plot_bars <- function(data, x, y, group = NULL,
                      error = c("se", "sd", "ci", "none"),
                      show_points = TRUE, palette = "greys",
                      point_style = list(), bar_width = 0.7,
                      dodge_width = 0.8, jitter_width = 0.4, seed = 1, ...) {
  error <- match.arg(error)
  check_columns(data, c(x, y, group), numeric = y)
  data <- as_factors(data, c(x, group))

  p <- ggplot2::ggplot(data, bar_mapping(x, y, group)) +
    bar_layer(group, bar_width, dodge_width)
  if (show_points) {
    style <- utils::modifyList(default_point_style(), point_style)
    p <- p + point_layer(group, style, dodge_width, jitter_width, seed)
  }
  if (error != "none") {
    p <- p + error_layer(error, dodge_width)
  }
  p + bar_scales(group, palette) +
    theme_kiyonaga(...) +
    ggplot2::theme(axis.title.x = ggplot2::element_text(face = "bold"))
}

#' Aesthetic mapping with or without a grouping variable
#' @noRd
bar_mapping <- function(x, y, group) {
  if (is.null(group)) {
    return(ggplot2::aes(x = .data[[x]], y = .data[[y]]))
  }
  ggplot2::aes(x = .data[[x]], y = .data[[y]],
               fill = .data[[group]], group = .data[[group]])
}

#' Bars showing the mean
#' @noRd
bar_layer <- function(group, bar_width, dodge_width) {
  args <- list(
    fun = mean, geom = "col", width = bar_width,
    position = ggplot2::position_dodge(width = dodge_width)
  )
  if (is.null(group)) args$fill <- kiyonaga_colors$GREY_LIGHT
  do.call(ggplot2::stat_summary, args)
}

#' Default look of the individual data points
#' @noRd
default_point_style <- function() {
  list(size = 1, fill = "white", colour = kiyonaga_colors$GREY_DARK,
       alpha = 0.8, stroke = 0.3)
}

#' Jittered individual data points, dodged like the bars
#' @noRd
point_layer <- function(group, style, dodge_width, jitter_width, seed) {
  position <- if (is.null(group)) {
    ggplot2::position_jitter(width = jitter_width / 3, height = 0, seed = seed)
  } else {
    ggplot2::position_jitterdodge(
      jitter.width = jitter_width, jitter.height = 0,
      dodge.width = dodge_width, seed = seed
    )
  }
  ggplot2::geom_point(
    position = position, shape = 21, size = style$size, fill = style$fill,
    colour = style$colour, alpha = style$alpha, stroke = style$stroke,
    show.legend = FALSE
  )
}

#' Error bars without caps in the PI's mid grey
#' @noRd
error_layer <- function(error, dodge_width) {
  ggplot2::stat_summary(
    fun.data = error_function(error), geom = "linerange",
    colour = kiyonaga_colors$GREY_MID, linewidth = 0.5,
    position = ggplot2::position_dodge(width = dodge_width)
  )
}

#' Bars start at the axis; fill palette only when grouped
#' @noRd
bar_scales <- function(group, palette) {
  y_scale <- ggplot2::scale_y_continuous(
    expand = ggplot2::expansion(mult = c(0, 0.05))
  )
  if (is.null(group)) return(list(y_scale))
  list(y_scale, scale_fill_kiyonaga(palette))
}
