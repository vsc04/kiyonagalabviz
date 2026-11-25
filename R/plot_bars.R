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
#'   by group (converted to a factor). With `subgroup`, selects the primary
#'   colour while subgroup selects its shade.
#' @param error Error bar type: `"se"` (default), `"sd"`, `"ci"` (95% t-based)
#'   or `"none"`.
#' @param show_points Logical; plot the individual data points?
#' @param palette Fill palette for `group`, see [kiyonaga_palettes]. Defaults
#'   to the PI's `"greys"` (light/dark for two groups).
#' @param point_preset Individual-dot style from [kiyonaga_point_presets]:
#'   `"default"`, `"grey_filled"`, `"colour_outlined"`, or `"grey_small"`.
#'   The default preserves the original dot appearance.
#' @param point_style Named list overriding `point_preset`. Default settings:
#'   `size = 1`, `shape = 21` (filled circle with an outline), `fill = "white"`,
#'   `colour = kiyonaga_colors$GREY_DARK`, `alpha = 0.8`, `stroke = 0.3`.
#'   For larger individual dots use `point_style = list(size = 1.5)`.
#'   Set `fill = NULL` to inherit mapped group colours. Shape 16 is a solid
#'   circle using `colour`; shapes 21-25 use both `fill` and `colour`.
#' @param bar_width Width of the bars.
#' @param dodge_width Dodging width between groups.
#' @param jitter_width Horizontal spread of the points (passed to
#'   [ggplot2::position_jitterdodge()]; scaled the same way without `group`).
#' @param seed Random seed for the jitter, so points do not move between runs.
#' @param ... Passed to [theme_kiyonaga()], e.g. `font_size = 12` or an
#'   explicit `aspect_ratio` override.
#' @param preset Plot ratio preset, default `"bars"`; use `"bars_tall"` for
#'   taller bars. See [kiyonaga_plot_presets]. `NULL` uses the theme's default.
#' @param n_bars Optional manual bar count for the ratio. By default, count
#'   observed x/group/subgroup combinations with finite outcomes. [nice_save()] updates
#'   automatic counts after faceting, using the largest bar count per panel.
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
#' @return A ggplot object; add layers, scales or labels as usual.
#' @export
#'
#' @examples
#' sim <- simulate_lab_data()
#' d <- average_window(sim$timecourse, window = c(3, 5))
#' plot_bars(d, x = "load", y = "pupil")
#' plot_bars(d, x = "load", y = "pupil", group = "load", error = "ci")
#' d2 <- expand.grid(task = c("A", "B"), session = c("first", "second"),
#'                   subject = 1:4)
#' d2$value <- seq_len(nrow(d2))
#' plot_bars(d2, "task", "value", group = "task", subgroup = "session",
#'           palette = "blue_yellow_2")
#' plot_bars(d, "load", "pupil", group = "load",
#'           point_style = list(size = 1.5))
plot_bars <- function(data, x, y, group = NULL,
                      error = c("se", "sd", "ci", "none"),
                      show_points = TRUE, palette = "greys",
                      point_style = list(), bar_width = 0.7,
                      dodge_width = 0.8, jitter_width = 0.4, seed = 1, ...,
                      condition_groups = NULL, preset = "bars", n_bars = NULL,
                      subgroup = NULL, legend = c("inside", "separate", "none"), point_preset = "default") {
  legend <- match.arg(legend)
  error <- match.arg(error)
  check_columns(data, c(x, y, group, subgroup), numeric = y)
  grouping <- prepare_plot_groups(data, group, subgroup, palette, condition_groups)
  data <- as_factors(grouping$data, x)
  group <- grouping$group
  condition_groups <- grouping$condition_groups

  p <- ggplot2::ggplot(data, bar_mapping(x, y, group)) +
    bar_layer(group, bar_width, dodge_width)
  if (show_points) {
    style <- resolve_point_style(point_preset, point_style)
    p <- p + point_layer(group, style, dodge_width, jitter_width, seed)
  }
  if (error != "none") {
    p <- p + error_layer(error, dodge_width)
  }
  automatic <- is.null(n_bars)
  if (automatic) {
    n_bars <- nrow(unique(data[is.finite(data[[y]]), c(x, group), drop = FALSE]))
  }
  p <- p + bar_scales(group, palette, condition_groups, grouping$limits) +
    ggplot2::labs(fill = grouping$title) +
    theme_kiyonaga(..., preset = preset, n_bars = n_bars) +
    ggplot2::theme(axis.title.x = ggplot2::element_text(face = "bold"))
  if (automatic && !is.null(preset) &&
      !is.null(get_plot_preset(preset)$reference_bars) &&
      !"aspect_ratio" %in% names(list(...))) {
    attr(p, "kiyonaga_bar_preset") <- preset
    attr(p, "kiyonaga_bar_aspect") <- p$theme$aspect.ratio
  }
  finish_plot(p, legend)
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
  kiyonaga_point_presets$default
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
  args <- c(list(position = position, show.legend = FALSE),
              style[c("shape", "size", "fill", "colour", "alpha", "stroke")])
  # Omit NULL settings so a mapped colour/fill can be inherited.
  args <- args[!vapply(args, is.null, logical(1))]
  do.call(ggplot2::geom_point, args)
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
bar_scales <- function(group, palette, condition_groups = NULL, limits = NULL) {
  y_scale <- ggplot2::scale_y_continuous(
    expand = ggplot2::expansion(mult = c(0, 0.05))
  )
  if (is.null(group)) return(list(y_scale))
  list(y_scale, scale_fill_kiyonaga(palette, condition_groups = condition_groups,
                                    limits = limits))
}
