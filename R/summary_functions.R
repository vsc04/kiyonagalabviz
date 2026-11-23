#' Summary functions for error bars
#'
#' Return the mean with lower and upper bounds as a data frame with columns
#' `y`, `ymin` and `ymax`, for use in [ggplot2::stat_summary()] via
#' `fun.data`. `mean_sd()` gives mean +/- 1 SD; `mean_ci()` gives the
#' t-based confidence interval. For mean +/- SE use [ggplot2::mean_se()].
#'
#' @param x Numeric vector. Missing values are removed.
#' @param conf Confidence level for `mean_ci()`.
#'
#' @return A one-row data frame with `y`, `ymin`, `ymax`.
#' @export
#'
#' @examples
#' mean_sd(c(1, 2, 3, 4))
#' mean_ci(c(1, 2, 3, 4))
mean_sd <- function(x) {
  x <- x[!is.na(x)]
  summary_frame(mean(x), stats::sd(x))
}

#' @rdname mean_sd
#' @export
mean_ci <- function(x, conf = 0.95) {
  x <- x[!is.na(x)]
  half_width <- stats::qt((1 + conf) / 2, df = length(x) - 1) *
    stats::sd(x) / sqrt(length(x))
  summary_frame(mean(x), half_width)
}

#' Mean +/- a half-width as a data frame
#' @noRd
summary_frame <- function(m, half_width) {
  data.frame(y = m, ymin = m - half_width, ymax = m + half_width)
}

#' Look up the summary function for an error type
#' @noRd
error_function <- function(error) {
  switch(error,
         se = ggplot2::mean_se,
         sd = mean_sd,
         ci = mean_ci)
}
