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

#' Combine primary groups and subgroups in palette shade order
#' @noRd
prepare_plot_groups <- function(data, group, subgroup, palette, condition_groups) {
  if (is.null(subgroup)) {
    return(list(data = as_factors(data, group), group = group,
                condition_groups = condition_groups, limits = NULL,
                title = group))
  }
  if (is.null(group)) {
    stop("`subgroup` requires `group`.", call. = FALSE)
  }
  if (length(group) != 1L || length(subgroup) != 1L || identical(group, subgroup)) {
    stop("`group` and `subgroup` must name different single columns.", call. = FALSE)
  }
  check_columns(data, c(group, subgroup))
  data <- as_factors(data, c(group, subgroup))
  groups <- nlevels(data[[subgroup]])
  if (!is.null(condition_groups) &&
      (!is.numeric(condition_groups) || length(condition_groups) != 1L ||
       is.na(condition_groups) || condition_groups != groups)) {
    stop("`condition_groups` must match the number of `subgroup` levels.", call. = FALSE)
  }
  colours <- make_kiyonaga_palette(palette, condition_groups = groups)
  primary <- levels(data[[group]])
  secondary <- levels(data[[subgroup]])
  labels <- make.unique(paste(rep(primary, each = groups),
                             rep(secondary, times = length(primary)), sep = " / "))
  # Validate the complete design so missing combinations cannot shift colours.
  colours(length(labels))
  column <- ".kiyonaga_group"
  while (column %in% names(data)) column <- paste0(column, "_")
  index <- (as.integer(data[[group]]) - 1L) * groups + as.integer(data[[subgroup]])
  data[[column]] <- factor(index, levels = seq_along(labels), labels = labels)
  list(data = data, group = column, condition_groups = groups,
       limits = labels, title = paste(group, subgroup, sep = " / "))
}
