#' Check that columns exist and that some of them are numeric
#' @noRd
check_columns <- function(data, cols, numeric = character(0)) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  missing <- setdiff(cols, names(data))
  if (length(missing) > 0) {
    stop("Column(s) not found in `data`: ", paste(missing, collapse = ", "),
         call. = FALSE)
  }
  not_numeric <- numeric[!vapply(data[numeric], is.numeric, logical(1))]
  if (length(not_numeric) > 0) {
    stop("Column(s) must be numeric: ", paste(not_numeric, collapse = ", "),
         call. = FALSE)
  }
  invisible(TRUE)
}

#' Convert columns to factors, keeping the level order of existing factors
#' @noRd
as_factors <- function(data, cols) {
  for (col in cols) {
    if (!is.factor(data[[col]])) data[[col]] <- factor(data[[col]])
  }
  data
}

#' Check a time window c(start, end)
#' @noRd
check_window <- function(window) {
  if (!is.numeric(window) || length(window) != 2 || window[1] >= window[2]) {
    stop("`window` must be c(start, end) with start < end.", call. = FALSE)
  }
  invisible(TRUE)
}
