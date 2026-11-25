#' Matched colour and fill scales for plotting helpers
#' @noRd
plot_scales <- function(grouping, palette, aesthetics = c("colour", "fill")) {
  if (is.null(grouping$group)) return(NULL)
  scales <- lapply(aesthetics, function(aesthetic) {
    scale <- if (aesthetic == "fill") scale_fill_kiyonaga else scale_colour_kiyonaga
    scale(palette, condition_groups = grouping$condition_groups, limits = grouping$limits)
  })
  titles <- stats::setNames(rep(list(grouping$title), length(aesthetics)), aesthetics)
  c(scales, list(do.call(ggplot2::labs, titles)))
}

#' Add group colour and fill to an x/y mapping
#' @noRd
plot_mapping <- function(x, y = NULL, group = NULL) {
  mapping <- ggplot2::aes(x = .data[[x]])
  if (!is.null(y)) mapping$y <- ggplot2::aes(y = .data[[y]])$y
  if (!is.null(group)) {
    grouped <- ggplot2::aes(colour = .data[[group]], fill = .data[[group]],
                            group = .data[[group]])
    mapping[names(grouped)] <- grouped
  }
  mapping
}

#' Fixed default colour only for ungrouped geoms
#' @noRd
plot_colour <- function(grouping, fill = FALSE) {
  if (!is.null(grouping$group)) return(list())
  settings <- list(colour = kiyonaga_colors$GREY_DARK)
  if (fill) settings$fill <- kiyonaga_colors$GREY_LIGHT
  settings
}

#' Validate a positive scalar parameter
#' @noRd
check_positive <- function(value, name, integer = FALSE) {
  if (!is.numeric(value) || length(value) != 1L || !is.finite(value) ||
      value <= 0 || (integer && value != floor(value))) {
    stop("`", name, "` must be a positive ",
         if (integer) "whole number." else "number.", call. = FALSE)
  }
}

#' Mean and uncertainty, allowing singleton bins without inventing an interval
#' @noRd
plot_summary <- function(values, error = "ci", conf = 0.95) {
  values <- values[is.finite(values)]
  if (length(values) < 2 || error == "none") {
    return(data.frame(y = mean(values), ymin = NA_real_, ymax = NA_real_))
  }
  if (error == "ci") return(mean_ci(values, conf))
  error_function(error)(values)
}
