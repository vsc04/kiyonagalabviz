#' Boxplots with optional individual observations
#'
#' Boxes show medians and interquartile ranges; whiskers extend to observations
#' within 1.5 IQR. Outliers are shown only when individual points are hidden,
#' avoiding duplicate points.
#'
#' @inheritParams plot_bars
#' @param group Optional primary-condition column. Factor levels select the
#'   primary colours; `subgroup` selects shades within each colour.
#' @param palette Palette name from [kiyonaga_palettes]; defaults to `"accent"`.
#' @param box_width Width of the boxes.
#' @param linewidth Box and whisker line width.
#' @param preset Panel ratio preset; defaults to `"distribution"`.
#' @return A ggplot object. Use [plot_legend()] for a separate legend.
#' @export
#' @examples
#' plot_boxplots(mtcars, "cyl", "mpg", group = "am",
#'                point_style = list(size = 1.5))
plot_boxplots <- function(data, x, y, group = NULL, show_points = TRUE,
                          palette = "accent", box_width = 0.6, linewidth = 0.5,
                          dodge_width = 0.8, jitter_width = 0.4, seed = 1,
                          point_style = list(), ..., subgroup = NULL,
                          condition_groups = NULL, preset = "distribution",
                          legend = c("inside", "separate", "none"), point_preset = "grey_filled") {
  legend <- match.arg(legend)
  check_columns(data, c(x, y, group, subgroup), numeric = y)
  grouping <- prepare_plot_groups(data, group, subgroup, palette, condition_groups)
  data <- as_factors(grouping$data, x)
  p <- ggplot2::ggplot(data, bar_mapping(x, y, grouping$group)) +
    ggplot2::geom_boxplot(width = box_width, linewidth = linewidth,
                          position = ggplot2::position_dodge(width = dodge_width),
                          colour = kiyonaga_colors$GREY_DARK,
                          outlier.shape = if (show_points) NA else 19,
                          outlier.size = 1, na.rm = TRUE)
  if (is.null(grouping$group)) {
    p$layers[[1]]$aes_params$fill <- kiyonaga_colors$GREY_LIGHT
  }
  aesthetics <- "fill"
  if (show_points) {
    style <- resolve_point_style(point_preset, point_style)
    if (!is.null(grouping$group) && is.null(style$colour)) aesthetics <- c(aesthetics, "colour")
    p <- p + point_layer(grouping$group, style,
                         dodge_width, jitter_width, seed)
  }
  p <- p + plot_scales(grouping, palette, aesthetics = aesthetics) + theme_kiyonaga(..., preset = preset)
  finish_plot(p, legend)
}
