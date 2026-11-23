#' Kiyonaga Lab colour and fill scales for ggplot2
#'
#' @param palette Name of a palette in [kiyonaga_palettes], or a character
#'   vector of hex colours.
#' @param discrete Logical; discrete (default) or continuous scale?
#' @param reverse Logical; reverse the palette order?
#' @param ... Passed to [ggplot2::discrete_scale()] or
#'   [ggplot2::scale_colour_gradientn()].
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
#'   scale_color_kiyonaga("sunset", discrete = FALSE) +
#'   theme_kiyonaga()
scale_fill_kiyonaga <- function(palette = "sunset", discrete = TRUE,
                                reverse = FALSE, ...) {
  kiyonaga_scale("fill", palette, discrete, reverse, ...)
}

#' @rdname scale_fill_kiyonaga
#' @export
scale_color_kiyonaga <- function(palette = "sunset", discrete = TRUE,
                                 reverse = FALSE, ...) {
  kiyonaga_scale("colour", palette, discrete, reverse, ...)
}

#' @rdname scale_fill_kiyonaga
#' @export
scale_colour_kiyonaga <- scale_color_kiyonaga

#' Build a discrete or continuous scale for one aesthetic
#' @noRd
kiyonaga_scale <- function(aesthetics, palette, discrete, reverse, ...) {
  if (discrete) {
    pal_fun <- make_kiyonaga_palette(palette, reverse)
    return(ggplot2::discrete_scale(aesthetics, palette = pal_fun, ...))
  }
  pal <- get_kiyonaga_palette(palette, reverse)
  ggplot2::scale_colour_gradientn(
    colours = grDevices::colorRampPalette(pal)(256),
    aesthetics = aesthetics,
    ...
  )
}
