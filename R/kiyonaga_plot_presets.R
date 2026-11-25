#' Plot aspect ratios and whole-figure export presets
#'
#' A named list of plot ratios and export layouts. Plot-type entries have
#' `size_type = "ratio"` and store only the panel height / width ratio, not
#' physical dimensions or font sizes. Whole-figure entries have
#' `size_type = "figure"` and specify export dimensions and base text sizes.
#'
#' - `bars`: normal bars, reference ratio 1.55 for two bars.
#' - `bars_tall`: tall bars, reference ratio 3.08 for two bars.
#' - `timecourse`: ratio 0.68.
#' - `scatter`: ratio 0.92.
#' - `distribution`, `heatmap`: square panels, ratio 1.
#' - `"full col"`, `"half col"`, `"tiny"`, `"full page"`: whole-figure widths
#'   of 3.6, 1.8, 1 and 7.2 inches. Height follows the panel ratio.
#' - `"slides"`: whole-figure height 4.4 inches; width follows the panel ratio.
#'
#' @details
#' For bars, `aspect_ratio` is the reference height / width ratio for
#' `reference_bars = 2`. The applied ratio is
#' `aspect_ratio * reference_bars / n_bars`: normal bars use `3.10 / n_bars`
#' and tall bars use `6.16 / n_bars`. More bars therefore make a shorter
#' panel at the same export width. [plot_bars()] counts observed x/group
#' combinations with finite outcomes, rather than observations or unused levels.
#' At export, facet panels share the ratio based on the largest number of
#' displayed bars in any panel. Supply `n_bars` to override automatic counting.
#'
#' Use a plot-type `preset` with [theme_kiyonaga()], [plot_bars()] or
#' [plot_timecourse()], then select the complete figure size with the `layout`
#' argument of [nice_save()]. The available width, after axes, legends, margins
#' and facet spacing, determines panel width; the ratio determines panel height.
#' Plot ratios do not change fonts. The standard theme uses 8 pt base text
#' and tick/legend labels at 85% of it. Export layouts use 14 pt for `"slides"`,
#' 6 pt for `"tiny"`, and preserve plot text sizes for the column/page layouts.
#' Explicit `font_size` overrides these defaults. Whole-figure layouts may also
#' be passed as `preset` in [nice_save()] as an alias for `layout`.
#'
#' @export
#' @examples
#' kiyonaga_plot_presets$timecourse
#' theme_kiyonaga(preset = "scatter")
#' theme_kiyonaga(preset = "bars_tall", n_bars = 4)
kiyonaga_plot_presets <- list(
  bars = list(size_type = "ratio", aspect_ratio = 1.55, reference_bars = 2),
  bars_tall = list(size_type = "ratio", aspect_ratio = 3.08, reference_bars = 2),
  timecourse = list(size_type = "ratio", aspect_ratio = 0.68),
  scatter = list(size_type = "ratio", aspect_ratio = 0.92),
  distribution = list(size_type = "ratio", aspect_ratio = 1),
  heatmap = list(size_type = "ratio", aspect_ratio = 1),
  "full col" = list(size_type = "figure", figure_width = 3.6,
                    figure_height = NULL, font_size = NULL),
  "half col" = list(size_type = "figure", figure_width = 1.8,
                    figure_height = NULL, font_size = NULL),
  tiny = list(size_type = "figure", figure_width = 1,
               figure_height = NULL, font_size = 6),
  "full page" = list(size_type = "figure", figure_width = 7.2,
                     figure_height = NULL, font_size = NULL),
  slides = list(size_type = "figure", figure_width = NULL,
                 figure_height = 4.4, font_size = 14)
)

#' Resolve a preset name, with a useful error for typos
#' @noRd
get_plot_preset <- function(preset) {
  if (is.null(preset)) return(NULL)
  if (!is.character(preset) || length(preset) != 1L || is.na(preset) ||
      !preset %in% names(kiyonaga_plot_presets)) {
    stop("`preset` must be one of: ",
         paste(names(kiyonaga_plot_presets), collapse = ", "), call. = FALSE)
  }
  kiyonaga_plot_presets[[preset]]
}

#' Resolve a ratio, allowing bar count to determine panel shape
#' @noRd
preset_aspect_ratio <- function(settings, n_bars = 2) {
  if (settings$size_type != "ratio") return(NULL)
  ratio <- settings$aspect_ratio
  if (is.null(settings$reference_bars)) return(ratio)
  if (!is.numeric(n_bars) || length(n_bars) != 1L || !is.finite(n_bars) ||
      n_bars < 1 || n_bars != floor(n_bars)) {
    stop("`n_bars` must be a single positive whole number.", call. = FALSE)
  }
  ratio * settings$reference_bars / n_bars
}

#' Count physical bars per panel, without counting stacked segments twice
#' @noRd
count_plot_bars <- function(plot) {
  built <- ggplot2::ggplot_build(plot)
  layers <- which(vapply(plot$layers, function(layer) {
    inherits(layer$geom, "GeomBar") || inherits(layer$geom, "GeomCol")
  }, logical(1)))
  positions <- lapply(layers, function(i) {
    d <- built$data[[i]]
    if (!all(c("PANEL", "x", "y") %in% names(d))) return(NULL)
    d[is.finite(d$x) & is.finite(d$y), c("PANEL", "x"), drop = FALSE]
  })
  positions <- unique(do.call(rbind, positions))
  if (is.null(positions) || !nrow(positions)) {
    stop("Cannot infer a bar count from this plot; supply `n_bars`.", call. = FALSE)
  }
  max(as.integer(table(positions$PANEL)))
}
