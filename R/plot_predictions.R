#' Fitted relationships and interactions with binned observations
#'
#' Fits a line separately for each group/subgroup using all observations, with
#' a confidence band and optional binned means and confidence intervals. Bins
#' are for display only. Defaults are linear fits, five equal-width bins and
#' 95% intervals, following the lab's regression figures. Quantile bins are
#' also available. For predictions from a previously fitted model, supply a
#' prediction data frame instead of refitting.
#'
#' @inheritParams plot_bars
#' @param group Optional primary-condition column. Factor levels select the
#'   primary colours; `subgroup` selects shades within each colour.
#' @param palette Palette name from [kiyonaga_palettes]; defaults to `"accent"`.
#' @param x Name of the numeric predictor column.
#' @param method Fit method accepted by [ggplot2::geom_smooth()], e.g. `"lm"`,
#'   `"loess"`, or `"glm"`. Separate fits are made per displayed group.
#' @param formula Formula for the fit, expressed in `x` and `y`.
#' @param method_args Named list passed to the fitting method.
#' @param predictions Optional data frame containing `x`, `y` (predicted
#'   outcomes), and the same group/subgroup columns as `data`. It must include
#'   `lower` and `upper` columns when `confidence = TRUE`. These predictions
#'   and intervals are drawn unchanged, allowing mixed-effects or other models.
#' @param lower,upper Names of lower and upper confidence-limit columns in
#'   `predictions`. Defaults are `"lower"` and `"upper"`.
#' @param error Uncertainty for binned means: `"ci"` (default), `"se"`, `"sd"`,
#'   or `"none"`. `"none"` keeps the binned points without error bars. This
#'   setting does not affect the fitted confidence band.
#' @param confidence Logical; show the fitted confidence band?
#' @param conf Confidence level for fitted bands and for binned intervals
#'   when `error = "ci"`. Does not alter supplied prediction intervals.
#' @param bins Positive number of bins; `NULL` hides binned observations.
#' @param bin_method `"width"` for equal-width bins or `"quantile"` for
#'   approximately equal-count bins, calculated within each group and facet.
#'   Tied quantiles can produce fewer bins.
#' @param ribbon_alpha Confidence-band opacity.
#' @param linewidth Fitted line width.
#' @param point_size Binned mean point size.
#' @param preset Panel ratio preset; defaults to `"scatter"`.
#' @details Binned error bars summarize the supplied rows: mean +/- SE or SD,
#'   or a t-based confidence interval. They do not account for repeated
#'   measurements. Supply independent-unit summaries when appropriate, or use
#'   model-derived intervals through
#'   `predictions`. Separate group fits visualize interactions; they do not
#'   test an interaction or automatically fit a joint interaction model.
#' @return A ggplot object. Use [plot_legend()] for a separate legend.
#' @export
#' @examples
#' plot_predictions(mtcars, "wt", "mpg", group = "am")
#' plot_predictions(mtcars, "wt", "mpg", error = "se")
#' plot_predictions(mtcars, "wt", "mpg", error = "none", confidence = TRUE)
#' fit <- lm(mpg ~ wt, mtcars)
#' pred <- data.frame(wt = seq(min(mtcars$wt), max(mtcars$wt), length.out = 50))
#' ci <- predict(fit, pred, interval = "confidence")
#' pred$mpg <- ci[, "fit"]
#' pred$lower <- ci[, "lwr"]
#' pred$upper <- ci[, "upr"]
#' plot_predictions(mtcars, "wt", "mpg", predictions = pred)
plot_predictions <- function(data, x, y, group = NULL, palette = "accent",
                             method = "lm", formula = y ~ x, method_args = list(),
                             predictions = NULL, lower = "lower", upper = "upper",
                             confidence = TRUE, conf = 0.95, bins = 5,
                             bin_method = c("width", "quantile"), ribbon_alpha = 0.2,
                             linewidth = 0.6, point_size = 1.5, ..., subgroup = NULL,
                             condition_groups = NULL, preset = "scatter",
                             legend = c("inside", "separate", "none"),
                             error = c("ci", "se", "sd", "none")) {
  error <- match.arg(error)
  legend <- match.arg(legend)
  bin_method <- match.arg(bin_method)
  check_columns(data, c(x, y, group, subgroup), numeric = c(x, y))
  check_confidence(conf)
  check_opacity(ribbon_alpha, "ribbon_alpha")
  if (!is.null(bins)) check_positive(bins, "bins", integer = TRUE)
  grouping <- prepare_plot_groups(data, group, subgroup, palette, condition_groups)
  p <- ggplot2::ggplot(grouping$data, plot_mapping(x, y, grouping$group))
  if (is.null(predictions)) {
    p <- p + do.call(ggplot2::geom_smooth,
                      c(list(method = method, formula = formula, method.args = method_args,
                             se = confidence, level = conf, linewidth = linewidth,
                             alpha = ribbon_alpha, na.rm = TRUE),
                        plot_colour(grouping, fill = TRUE)))
  } else {
    columns <- c(x, y, group, subgroup, if (confidence) c(lower, upper))
    check_columns(predictions, columns, numeric = c(x, y, if (confidence) c(lower, upper)))
    for (col in c(group, subgroup)) {
      source <- grouping$data[[col]]
      unknown <- setdiff(as.character(predictions[[col]]), c(levels(source), NA_character_))
      if (length(unknown)) stop("Unknown prediction categories in `", col, "`.", call. = FALSE)
      predictions[[col]] <- factor(predictions[[col]], levels = levels(source))
    }
    predicted <- prepare_plot_groups(predictions, group, subgroup, palette, condition_groups)
    mapping <- plot_mapping(x, y, predicted$group)
    if (confidence) {
      interval <- ggplot2::aes(ymin = .data[[lower]], ymax = .data[[upper]])
      band_mapping <- mapping
      band_mapping[names(interval)] <- interval
      p <- p + do.call(ggplot2::geom_ribbon,
                        c(list(data = predicted$data, mapping = band_mapping,
                               inherit.aes = FALSE, alpha = ribbon_alpha,
                               colour = NA, na.rm = TRUE),
                          if (is.null(group)) list(fill = kiyonaga_colors$GREY_LIGHT) else list()))
    }
    mapping$fill <- NULL
    p <- p + do.call(ggplot2::geom_line,
                      c(list(data = predicted$data, mapping = mapping, inherit.aes = FALSE,
                             linewidth = linewidth, na.rm = TRUE), plot_colour(grouping)))
  }
  if (!is.null(bins)) {
    params <- list(bins = bins, bin_method = bin_method, conf = conf,
                   error = error, na.rm = TRUE)
    if (error != "none") {
      p <- p + ggplot2::layer(stat = StatKiyonagaBins, geom = "linerange",
                              position = "identity",
                              params = c(params, list(linewidth = 0.5), plot_colour(grouping)))
    }
    p <- p + ggplot2::layer(stat = StatKiyonagaBins, geom = "point", position = "identity",
                            params = c(params, list(size = point_size), plot_colour(grouping)))
  }
  p <- p + plot_scales(grouping, palette) + theme_kiyonaga(..., preset = preset)
  finish_plot(p, legend)
}

#' Binned means calculated after faceting, without using bins for the fit
#' @noRd
StatKiyonagaBins <- ggplot2::ggproto("StatKiyonagaBins", ggplot2::Stat,
  required_aes = c("x", "y"),
  compute_group = function(data, scales, bins = 5, bin_method = "width", conf = 0.95,
                           error = "ci") {
    data <- data[is.finite(data$x) & is.finite(data$y), , drop = FALSE]
    if (!nrow(data)) return(data.frame())
    edges <- if (bin_method == "quantile") {
      unique(as.numeric(stats::quantile(data$x, probs = seq(0, 1, length.out = bins + 1))))
    } else seq(min(data$x), max(data$x), length.out = bins + 1)
    bin <- if (length(unique(edges)) == 1L) rep(1L, nrow(data)) else
      cut(data$x, breaks = unique(edges), include.lowest = TRUE, labels = FALSE)
    rows <- lapply(split(data, bin), function(d) {
      cbind(x = mean(d$x), plot_summary(d$y, error, conf))
    })
    do.call(rbind, rows)
  }
)

#' Validate a confidence level
#' @noRd
check_confidence <- function(conf) {
  if (!is.numeric(conf) || length(conf) != 1L || !is.finite(conf) || conf <= 0 || conf >= 1) {
    stop("`conf` must be between 0 and 1, exclusively.", call. = FALSE)
  }
}
