#' Average a timecourse within a time window
#'
#' Averages `value` over all time points inside `window` (inclusive), giving
#' one row per combination of the `by` columns, e.g. one mean pupil size per
#' subject and load for a bar plot or scatter plot.
#'
#' @param data A data frame in long format (one row per time point).
#' @param window Numeric `c(start, end)` of the window, in the units of `time`.
#' @param value Name of the column to average.
#' @param by Names of the columns that define the groups to average within.
#' @param time Name of the time column.
#'
#' @return A data frame with the `by` columns and the averaged `value` column.
#' @export
#'
#' @examples
#' sim <- simulate_lab_data()
#' average_window(sim$timecourse, window = c(3, 5))
average_window <- function(data, window = c(3, 5), value = "pupil",
                           by = c("subject", "load"), time = "time") {
  check_columns(data, c(value, by, time), numeric = c(value, time))
  check_window(window)
  in_window <- data[[time]] >= window[1] & data[[time]] <= window[2]
  if (!any(in_window)) {
    stop("No time points fall inside `window`.", call. = FALSE)
  }
  stats::aggregate(data[in_window, value, drop = FALSE],
                   by = data[in_window, by, drop = FALSE], FUN = mean)
}
