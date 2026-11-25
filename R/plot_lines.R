#' General line plots with optional rolling means
#'
#' Draws mean lines over a numeric x variable, optionally with uncertainty
#' ribbons. A centred rolling window is specified in x-axis units. Smoothing
#' is applied within each subject and condition before summarizing subjects,
#' retaining equal subject weights at each x. Edge windows use available data.
#'
#' @inheritParams plot_timecourse
#' @param x Name of the numeric x column.
#' @param subject Optional subject identifier. Repeated rows within subject,
#'   x, group and subgroup are averaged before plotting. Supply this for
#'   replicated trajectories, so uncertainty is calculated across subjects.
#' @param rolling_window Optional positive window width in x units. For each
#'   observed x, average values within x +/- half this width. `NULL` performs
#'   no smoothing. Without `subject`, rolling requires one row per x and group.
#'   No interpolation is performed; irregular x spacing is allowed.
#' @param error Ribbon type: `"se"`, `"sd"`, `"ci"` or `"none"`.
#' @param preset Panel ratio preset; defaults to `"timecourse"`.
#' @details Without `subject`, uncertainty summarizes input rows at each x.
#'   Rolling windows overlap, and ribbons are pointwise descriptive intervals.
#'   They are not simultaneous confidence bands or a time-series model.
#' @return A ggplot object. Use [plot_legend()] for a separate legend.
#' @export
#' @examples
#' d <- simulate_lab_data(n_subjects = 6)$timecourse
#' plot_lines(d, "time", "pupil", subject = "subject", group = "load",
#'            rolling_window = 0.1)
plot_lines <- function(data, x, y, group = NULL, subject = NULL,
                       rolling_window = NULL, error = c("se", "sd", "ci", "none"),
                       palette = "accent", ribbon_alpha = 0.4, linewidth = 0.6, ...,
                       subgroup = NULL, condition_groups = NULL, preset = "timecourse",
                       legend = c("inside", "separate", "none")) {
  legend <- match.arg(legend)
  error <- match.arg(error)
  check_columns(data, c(x, y, subject, group, subgroup), numeric = c(x, y))
  grouping <- prepare_plot_groups(data, group, subgroup, palette, condition_groups)
  if (!is.null(rolling_window)) check_positive(rolling_window, "rolling_window")
  mapping <- plot_mapping(x, y, grouping$group)
  if (is.null(grouping$group)) mapping$group <- 1L
  if (!is.null(subject)) mapping$subject <- ggplot2::aes(subject = .data[[subject]])$subject
  params <- list(subject_aware = !is.null(subject), rolling_window = rolling_window,
                 error = error, na.rm = TRUE)
  p <- ggplot2::ggplot(grouping$data, mapping)
  if (error != "none") {
    p <- p + ggplot2::layer(stat = StatKiyonagaLines, geom = "ribbon", position = "identity",
                            params = c(params, list(colour = NA, alpha = ribbon_alpha),
                                       if (is.null(grouping$group))
                                         list(fill = kiyonaga_colors$GREY_DARK) else list()))
  }
  p <- p + ggplot2::layer(stat = StatKiyonagaLines, geom = "line", position = "identity",
                           params = c(params, list(linewidth = linewidth), plot_colour(grouping))) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0))) +
    plot_scales(grouping, palette) + theme_kiyonaga(..., preset = preset)
  finish_plot(p, legend)
}

#' Summarize and smooth within facets, then pool equally weighted subjects
#' @noRd
StatKiyonagaLines <- ggplot2::ggproto("StatKiyonagaLines", ggplot2::Stat,
  required_aes = c("x", "y"),
  optional_aes = "subject",
  dropped_aes = "subject",
  compute_group = function(data, scales, subject_aware = FALSE,
                           rolling_window = NULL, error = "se") {
    data <- data[is.finite(data$x) & is.finite(data$y), , drop = FALSE]
    if (!nrow(data)) return(data.frame())
    if (subject_aware) {
      data <- stats::aggregate(data["y"], data[c("subject", "x")], mean)
    }
    if (!is.null(rolling_window)) {
      if (!subject_aware && anyDuplicated(data$x)) {
        stop("Rolling replicated observations requires a `subject` column.", call. = FALSE)
      }
      traces <- if (subject_aware) data$subject else rep(1L, nrow(data))
      smoothed <- data$y
      for (rows in split(seq_len(nrow(data)), traces)) {
        values <- data$y[rows]
        positions <- data$x[rows]
        smoothed[rows] <- vapply(positions, function(at) {
          mean(values[abs(positions - at) <= rolling_window / 2])
        }, numeric(1))
      }
      data$y <- smoothed
    }
    output <- lapply(split(data$y, data$x), plot_summary, error = error)
    output <- do.call(rbind, output)
    output$x <- as.numeric(rownames(output))
    output <- output[order(output$x), ]
    rownames(output) <- NULL
    output
  }
)
