#' Connected subject-level observations
#'
#' Averages repeated observations within each subject, x, group and subgroup
#' combination, then connects each subject's available conditions in x-factor
#' order. Subject lines and points use the same palette; lines are lighter to
#' keep individual trajectories visible. Missing conditions are skipped.
#'
#' @inheritParams plot_bars
#' @param group Optional primary-condition column. Factor levels select the
#'   primary colours; `subgroup` selects shades within each colour.
#' @param palette Palette name from [kiyonaga_palettes]; defaults to `"accent"`.
#' @param subject Name of the subject identifier column.
#' @param linewidth Width of the subject lines.
#' @param line_alpha Opacity of the subject lines.
#' @param point_size Size of the subject points.
#' @param preset Panel ratio preset; defaults to `"scatter"`.
#' @return A ggplot object. Use [plot_legend()] for a separate legend.
#' @export
#' @examples
#' d <- average_window(simulate_lab_data()$timecourse)
#' plot_paired(d, "load", "pupil", subject = "subject")
plot_paired <- function(data, x, y, subject, group = NULL, palette = "accent",
                        linewidth = 0.5, line_alpha = 0.4, point_size = 1, ...,
                        subgroup = NULL, condition_groups = NULL, preset = "scatter",
                        legend = c("inside", "separate", "none")) {
  legend <- match.arg(legend)
  check_columns(data, c(x, y, subject, group, subgroup), numeric = y)
  check_opacity(line_alpha, "line_alpha")
  grouping <- prepare_plot_groups(data, group, subgroup, palette, condition_groups)
  data <- as_factors(grouping$data, c(x, subject))
  mapping <- plot_mapping(x, y, grouping$group)
  # A primary group that is also x must not break a subject's connection.
  trace <- setdiff(c(group, subgroup), x)
  trace <- unique(c(subject, trace))
  column <- ".kiyonaga_subject"
  while (column %in% names(data)) column <- paste0(column, "_")
  data[[column]] <- do.call(interaction, c(data[trace], list(drop = TRUE)))
  mapping$group <- ggplot2::aes(group = .data[[column]])$group
  p <- ggplot2::ggplot(data, mapping) +
    do.call(ggplot2::stat_summary,
            c(list(fun = mean, geom = "line", linewidth = linewidth, alpha = line_alpha, na.rm = TRUE),
              plot_colour(grouping))) +
    do.call(ggplot2::stat_summary,
            c(list(fun = mean, geom = "point", size = point_size, na.rm = TRUE), plot_colour(grouping))) +
    plot_scales(grouping, palette) + theme_kiyonaga(..., preset = preset)
  finish_plot(p, legend)
}
