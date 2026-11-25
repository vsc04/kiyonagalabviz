#' Kiyonaga Lab colour and fill scales for ggplot2
#'
#' @param palette Name of a palette in [kiyonaga_palettes], or a character
#'   vector of hex colours, including `#RRGGBBAA` for transparency.
#' @param discrete Logical; discrete (default) or continuous scale?
#' @param reverse Logical; reverse the palette order?
#' @param alpha Optional opacity multiplier, either one number between 0 and 1
#'   or one per full resolved palette colour. Applied before reversal; see
#'   [make_kiyonaga_palette()]. Leave geom `alpha` unset to preserve it.
#' @param condition_groups Optional secondary-condition count for discrete
#'   scales, using the recorded opaque shades in [kiyonaga_palette_groups].
#'   Use `2` for the paired families or `3` for `accent_3`. Factor levels
#'   or `limits` must follow primary category, then secondary category.
#' @param ... Passed to [ggplot2::discrete_scale()] or
#'   [ggplot2::scale_colour_gradientn()].
#'
#' @details
#' Grouped scales order primary colours first, then shades from dark to light.
#' For example, `blue_yellow_2` with `condition_groups = 2` gives dark blue,
#' light blue, dark yellow, light yellow. Map combined conditions to one
#' aesthetic and use factor levels or `limits` in this order.
#'
#' @return A ggplot2 scale.
#' @export
#'
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(factor(cyl), fill = factor(cyl))) +
#'   geom_bar() +
#'   scale_fill_kiyonaga("sunset") +
#'   theme_kiyonaga()
#'
#' ggplot(mtcars, aes(wt, mpg, colour = hp)) +
#'   geom_point() +
#'   scale_color_kiyonaga("blue_red_continuous", discrete = FALSE) +
#'   theme_kiyonaga()
scale_fill_kiyonaga <- function(palette = "sunset", discrete = TRUE,
                                reverse = FALSE, ..., alpha = NULL,
                                condition_groups = NULL) {
  kiyonaga_scale("fill", palette, discrete, reverse, ..., alpha = alpha,
                 condition_groups = condition_groups)
}

#' @rdname scale_fill_kiyonaga
#' @export
scale_color_kiyonaga <- function(palette = "sunset", discrete = TRUE,
                                 reverse = FALSE, ..., alpha = NULL,
                                 condition_groups = NULL) {
  kiyonaga_scale("colour", palette, discrete, reverse, ..., alpha = alpha,
                 condition_groups = condition_groups)
}

#' @rdname scale_fill_kiyonaga
#' @export
scale_colour_kiyonaga <- scale_color_kiyonaga

#' Build a discrete or continuous scale for one aesthetic
#' @noRd
kiyonaga_scale <- function(aesthetics, palette, discrete, reverse, ...,
                           alpha = NULL, condition_groups = NULL) {
  if (discrete) {
    pal_fun <- make_kiyonaga_palette(palette, reverse, alpha, condition_groups)
    return(ggplot2::discrete_scale(aesthetics, palette = pal_fun, ...))
  }
  if (!is.null(condition_groups)) {
    stop("`condition_groups` is only available for discrete scales.", call. = FALSE)
  }
  pal <- get_kiyonaga_palette(palette, reverse, alpha)
  ggplot2::scale_colour_gradientn(
    colours = interpolate_palette(pal, 256),
    aesthetics = aesthetics,
    ...
  )
}
