#' Kiyonaga Lab colour palettes
#'
#' A named list of palettes built from [kiyonaga_colors]:
#'
#' - `sunset`: the six stripes of the "About the lab" logo (yellow to periwinkle).
#' - `sunset_light`: the five stripes of the "Papers" artwork (sage to salmon).
#' - `greys`: the PI's grey tones (light, mid, dark). Two groups give light/dark.
#' - `accent`: green, blue and magenta from the brain-behaviour figure.
#'
#' Use with [scale_fill_kiyonaga()], [scale_color_kiyonaga()] or
#' [make_kiyonaga_palette()].
#'
#' @export
kiyonaga_palettes <- list(
  sunset = c(
    kiyonaga_colors$SUNSET_YELLOW,
    kiyonaga_colors$SUNSET_PEACH,
    kiyonaga_colors$SUNSET_SALMON,
    kiyonaga_colors$SUNSET_ROSE,
    kiyonaga_colors$SUNSET_SKY,
    kiyonaga_colors$SUNSET_PERIWINKLE
  ),
  sunset_light = c(
    kiyonaga_colors$PAPERS_SAGE,
    kiyonaga_colors$PAPERS_MINT,
    kiyonaga_colors$PAPERS_PALE,
    kiyonaga_colors$PAPERS_PEACH,
    kiyonaga_colors$PAPERS_SALMON
  ),
  greys = c(
    kiyonaga_colors$GREY_LIGHT,
    kiyonaga_colors$GREY_MID,
    kiyonaga_colors$GREY_DARK
  ),
  accent = c(
    kiyonaga_colors$ACCENT_GREEN,
    kiyonaga_colors$ACCENT_BLUE,
    kiyonaga_colors$ACCENT_MAGENTA
  )
)
