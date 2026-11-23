#' Kiyonaga Lab colour definitions
#'
#' A named list of hex colour codes, sampled from the lab's visual material:
#'
#' - `SUNSET_*`: the "About the lab" brain logo (background `SLATE`).
#' - `PAPERS_*`: the "Papers" artwork (background `CREAM`, text `CHARCOAL`).
#' - `GREY_*` and `TEXT`: the PI's grey tones used in figures
#'   (light/dark bars, error bars, axis lines, tick labels).
#' - `ACCENT_*`: point and overlay colours from the lab's brain-behaviour figure.
#'
#' @return A named list of hex colour codes.
#' @export
#'
#' @examples
#' library(ggplot2)
#' ggplot(data.frame(x = 1, y = 1), aes(x, y)) +
#'   geom_point(size = 10, colour = kiyonaga_colors$SUNSET_ROSE) +
#'   theme_kiyonaga()
kiyonaga_colors <- list(
  # "About the lab" sunset logo
  SUNSET_YELLOW     = "#EBD898",
  SUNSET_PEACH      = "#E8C397",
  SUNSET_SALMON     = "#E4AB94",
  SUNSET_ROSE       = "#E29492",
  SUNSET_SKY        = "#A9BBEC",
  SUNSET_PERIWINKLE = "#8994C1",
  SLATE             = "#555A69",
  # "Papers" artwork
  PAPERS_SAGE       = "#BBC2B1",
  PAPERS_MINT       = "#B8CBBA",
  PAPERS_PALE       = "#D3D5C2",
  PAPERS_PEACH      = "#E6BDA1",
  PAPERS_SALMON     = "#EBAC99",
  CREAM             = "#F8F2E2",
  CHARCOAL          = "#363636",
  # PI grey tones
  GREY_LIGHT        = "#D9D9D9",
  GREY_AXIS         = "#BFBFBF",
  GREY_MID          = "#A6A6A6",
  GREY_TEXT         = "#595959",
  GREY_DARK         = "#404040",
  TEXT              = "#262626",
  # Accents from the brain-behaviour figure
  ACCENT_GREEN      = "#74B49B",
  ACCENT_BLUE       = "#7F8EC4",
  ACCENT_MAGENTA    = "#E486E1"
)
