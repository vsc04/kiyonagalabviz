#' Scatterplots with optional fitted relationships
#'
#' Plots individual observations without binning or jitter, using the lab
#' theme and scatter panel ratio. Default markers use `colour_outlined`: 1.5 mm
#' circles with mapped group fills, grey outlines and alpha 0.8. Optional
#' fits use 0.6 mm lines and 95% confidence bands. Point appearance can instead
#' follow one of the paper-based styles in [kiyonaga_point_presets].
#'
#' @inheritParams plot_predictions
#' @inheritParams plot_bars
#' @param x,y Names of numeric coordinate columns. Rows with missing or
#'   non-finite coordinates are omitted. Each remaining row is one point;
#'   supply subject-level summaries first if each dot should represent a subject.
#' @param fit Logical; draw a fitted relationship? Defaults to `FALSE`.
#'   With `TRUE`, fit each group/subgroup separately using all its observations.
#' @param confidence Logical; show the fitted confidence band when `fit = TRUE`?
#' @param conf Confidence level for the fitted band. Defaults to 0.95.
#' @param point_preset Name in [kiyonaga_point_presets]; defaults to
#'   `"colour_outlined"`. Use `"charite"` for the original white-filled
#'   package style. `point_style` overrides individual fields.
#' @param point_size Optional point size in mm, overriding the default or
#'   preset size. An explicit `point_style$size` takes precedence.
#' @param point_style Named overrides for `size`, `shape`, `fill`, `colour`,
#'   `alpha` and `stroke`. `NULL` fill/colour settings inherit mapped colours.
#'   With shape 16, `colour = NULL` inherits group colours. Styles apply to
#'   observations only, leaving fit colours and bands unchanged.
#' @param preset Panel ratio preset; defaults to `"scatter"` (height/width 0.92).
#' @details Fits are descriptive and treat input rows as independent
#'   observations. For predictions and intervals from an existing mixed-effects
#'   or other model, use [plot_predictions()] with `predictions`.
#' @return A ggplot object. Use [plot_legend()] for a separate legend.
#' @export
#' @examples
#' sim <- simulate_lab_data()
#' d <- merge(average_window(sim$timecourse), sim$behavior,
#'            by = c("subject", "load"))
#' plot_scatter(d, "pupil", "accuracy", group = "load")
#' plot_scatter(d, "pupil", "accuracy", group = "load", fit = TRUE,
#'              palette = "skyblue_orange", point_style = list(size = 1.5))
#' plot_scatter(d, "pupil", "accuracy", group = "load", fit = TRUE,
#'              point_preset = "colour_outlined", confidence = FALSE)
plot_scatter <- function(data, x, y, group = NULL, palette = "accent", fit = FALSE,
                         confidence = TRUE, conf = 0.95, method = "lm", formula = y ~ x,
                         method_args = list(), point_size = NULL, point_style = list(),
                         ribbon_alpha = 0.2, linewidth = 0.6, ..., subgroup = NULL,
                         condition_groups = NULL, point_preset = "colour_outlined", preset = "scatter",
                         legend = c("inside", "separate", "none")) {
  legend <- match.arg(legend)
  if (!is.logical(fit) || length(fit) != 1L || is.na(fit)) {
    stop("`fit` must be TRUE or FALSE.", call. = FALSE)
  }
  check_columns(data, c(x, y, group, subgroup), numeric = c(x, y))
  if (any(c(group, subgroup) %in% c(x, y))) {
    stop("Scatter coordinates and condition columns must be distinct.", call. = FALSE)
  }
  check_confidence(conf)
  check_opacity(ribbon_alpha, "ribbon_alpha")
  if (!is.null(point_size)) check_positive(point_size, "point_size")
  grouping <- prepare_plot_groups(data, group, subgroup, palette, condition_groups)
  data <- grouping$data[is.finite(grouping$data[[x]]) & is.finite(grouping$data[[y]]), , drop = FALSE]
  style <- resolve_point_style(point_preset, point_style)
  if (is.null(grouping$group) && is.null(style$colour)) style$colour <- kiyonaga_colors$GREY_DARK
  if (!is.null(point_size) && !"size" %in% names(point_style)) style$size <- point_size
  point_args <- style[!vapply(style, is.null, logical(1))]
  p <- ggplot2::ggplot(data, plot_mapping(x, y, grouping$group))
  if (fit) {
    p <- p + do.call(ggplot2::geom_smooth,
                      c(list(method = method, formula = formula, method.args = method_args,
                             se = confidence, level = conf, linewidth = linewidth,
                             alpha = ribbon_alpha, na.rm = TRUE),
                        plot_colour(grouping, fill = TRUE)))
  }
  p <- p + do.call(ggplot2::geom_point, c(list(na.rm = TRUE), point_args)) +
    plot_scales(grouping, palette, aesthetics = if (fit) c("colour", "fill") else
                  c(if (is.null(style$colour)) "colour", if (is.null(style$fill)) "fill")) +
    theme_kiyonaga(..., preset = preset)
  finish_plot(p, legend)
}
