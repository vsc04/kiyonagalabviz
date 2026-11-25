#' Histograms and density distributions
#'
#' Histograms use common equal-width bins across groups. An optional density
#' curve uses the density scale, so its height is comparable to the histogram.
#' Density plots use Gaussian kernel density estimation. Groups are overlaid;
#' fill opacity controls overlap, independently of the opaque condition shades.
#'
#' @inheritParams plot_bars
#' @param group Optional primary-condition column. Factor levels select the
#'   primary colours; `subgroup` selects shades within each colour.
#' @param palette Palette name from [kiyonaga_palettes]; defaults to `"accent"`.
#' @param x Name of the numeric variable.
#' @param bins Number of histogram bins. Ignored when `binwidth` is supplied.
#' @param binwidth Optional histogram bin width in x units.
#' @param density Logical; overlay a kernel density curve on the histogram?
#' @param adjust Density bandwidth multiplier.
#' @param fill_alpha Fill opacity between 0 and 1.
#' @param linewidth Histogram outline or density line width.
#' @param preset Panel ratio preset; defaults to `"distribution"`.
#' @return A ggplot object. Use [plot_legend()] for a separate legend.
#' @export
#' @examples
#' plot_histogram(mtcars, "mpg", bins = 10, density = TRUE)
#' plot_density(mtcars, "mpg", group = "am")
plot_histogram <- function(data, x, group = NULL, bins = 30, binwidth = NULL,
                           density = FALSE, palette = "accent", fill_alpha = 0.4,
                           linewidth = 0.5, adjust = 1, ..., subgroup = NULL,
                           condition_groups = NULL, preset = "distribution",
                           legend = c("inside", "separate", "none")) {
  legend <- match.arg(legend)
  check_columns(data, c(x, group, subgroup), numeric = x)
  if (is.null(binwidth)) check_positive(bins, "bins", integer = TRUE)
  else check_positive(binwidth, "binwidth")
  check_positive(adjust, "adjust")
  check_opacity(fill_alpha, "fill_alpha")
  grouping <- prepare_plot_groups(data, group, subgroup, palette, condition_groups)
  mapping <- plot_mapping(x, group = grouping$group)
  if (density) mapping$y <- ggplot2::aes(y = ggplot2::after_stat(.data$density))$y
  p <- ggplot2::ggplot(grouping$data, mapping) +
    do.call(ggplot2::geom_histogram,
            c(list(bins = bins, binwidth = binwidth, position = "identity",
                   alpha = fill_alpha, linewidth = linewidth, na.rm = TRUE),
              plot_colour(grouping, fill = TRUE)))
  if (density) {
    p <- p + do.call(ggplot2::geom_density,
                      c(list(adjust = adjust, linewidth = 0.6, fill = NA, na.rm = TRUE),
                        plot_colour(grouping)))
  }
  p <- p + plot_scales(grouping, palette) + theme_kiyonaga(..., preset = preset)
  finish_plot(p, legend)
}

#' @rdname plot_histogram
#' @export
plot_density <- function(data, x, group = NULL, palette = "accent", adjust = 1,
                         fill_alpha = 0.2, linewidth = 0.6, ..., subgroup = NULL,
                         condition_groups = NULL, preset = "distribution",
                         legend = c("inside", "separate", "none")) {
  legend <- match.arg(legend)
  check_columns(data, c(x, group, subgroup), numeric = x)
  check_positive(adjust, "adjust")
  check_opacity(fill_alpha, "fill_alpha")
  grouping <- prepare_plot_groups(data, group, subgroup, palette, condition_groups)
  p <- ggplot2::ggplot(grouping$data, plot_mapping(x, group = grouping$group)) +
    do.call(ggplot2::geom_density,
            c(list(adjust = adjust, linewidth = linewidth, alpha = fill_alpha,
                   na.rm = TRUE), plot_colour(grouping, fill = TRUE))) +
    plot_scales(grouping, palette) + theme_kiyonaga(..., preset = preset)
  finish_plot(p, legend)
}

#' Validate an opacity parameter
#' @noRd
check_opacity <- function(value, name) {
  if (!is.numeric(value) || length(value) != 1L || !is.finite(value) ||
      value < 0 || value > 1) {
    stop("`", name, "` must be between 0 and 1.", call. = FALSE)
  }
}
