#' Individual-dot styles for lab figures
#'
#' A named list of styles for `point_preset` in [plot_bars()], [plot_means()]
#' and [plot_boxplots()], and in [plot_scatter()]. `point_style` overrides
#' individual preset settings.
#'
#' - `charite`: the original package style, white-filled circles with dark grey outlines.
#' - `grey_filled` (default for bars, means and boxplots): grey solid dots, following Dong & Kiyonaga (2024), Fig. 3D.
#' - `colour_outlined` (scatterplot default): group-coloured circles with grey outlines,
#'   following Yang et al. (2026), Fig. 1D.
#' - `grey_small`: small, faint grey dots, following Dong et al. (2026), Fig. 1D-F.
#' - `colour_filled`: solid dots using mapped group colours, size 1, alpha 0.6.
#' - `colour_small`: small solid dots using mapped group
#'   colours, size 0.5, alpha 0.4.
#'
#' @details
#' Paper-based styles are visual approximations, not recovered plotting code.
#' Sizes are ggplot2 point sizes in mm; opacity is an explicit plotting choice
#' because the original alpha cannot be determined from flattened PDF colours.
#' Presets change individual dots only, not summary points, error bars or lines.
#' The `colour_outlined` fill inherits the mapped group palette; supply `group`
#' for coloured dots. Without grouping it uses the geom's unfilled default.
#' `colour_filled` and `colour_small` inherit the palette through `colour`;
#' without grouping they use dark grey. Their sizes and opacity match the
#' corresponding grey presets.
#'
#' @export
#' @examples
#' kiyonaga_point_presets$grey_filled
#' d <- average_window(simulate_lab_data()$timecourse)
#' plot_means(d, "load", "pupil", group = "load", show_points = TRUE,
#'            point_preset = "colour_outlined", mean_line = TRUE)
#' plot_bars(d, "load", "pupil", point_preset = "grey_filled",
#'           point_style = list(size = 1.5))
kiyonaga_point_presets <- list(
  charite = list(size = 1, shape = 21, fill = "white", colour = kiyonaga_colors$GREY_DARK,
                 alpha = 0.8, stroke = 0.3),
  grey_filled = list(size = 1, shape = 16, fill = NA, colour = kiyonaga_colors$GREY_DARK,
                     alpha = 0.6, stroke = 0),
  colour_outlined = list(size = 1.5, shape = 21, fill = NULL,
                         colour = kiyonaga_colors$GREY_MID, alpha = 0.8, stroke = 0.3),
  grey_small = list(size = 0.5, shape = 16, fill = NA, colour = kiyonaga_colors$GREY_MID,
                    alpha = 0.4, stroke = 0),
  colour_filled = list(size = 1, shape = 16, fill = NULL, colour = NULL,
                       alpha = 0.6, stroke = 0),
  colour_small = list(size = 0.5, shape = 16, fill = NULL, colour = NULL,
                      alpha = 0.4, stroke = 0)
)

#' Resolve a dot preset and explicit overrides
#' @noRd
resolve_point_style <- function(point_preset, point_style) {
  if (!is.null(point_preset) &&
      (!is.character(point_preset) || length(point_preset) != 1L || is.na(point_preset) ||
       !point_preset %in% names(kiyonaga_point_presets))) {
    stop("`point_preset` must be one of: ", paste(names(kiyonaga_point_presets), collapse = ", "),
         call. = FALSE)
  }
  if (!is.list(point_style) || (length(point_style) &&
      (is.null(names(point_style)) || anyNA(names(point_style)) || any(names(point_style) == "")))) {
    stop("`point_style` must be a named list.", call. = FALSE)
  }
  unknown <- setdiff(names(point_style), c("size", "shape", "fill", "colour", "alpha", "stroke"))
  if (length(unknown)) {
    stop("Unknown `point_style` setting(s): ", paste(unknown, collapse = ", "), call. = FALSE)
  }
  if (is.null(point_preset)) point_preset <- "grey_filled"
  style <- kiyonaga_point_presets[[point_preset]]
  utils::modifyList(style, point_style, keep.null = TRUE)
}
