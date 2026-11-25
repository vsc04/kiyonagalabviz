#' Kiyonaga Lab colour definitions
#'
#' A named list of hex colour codes, sampled from the lab's visual material:
#'
#' - `SUNSET_*`: the "About the lab" brain logo (background `SLATE`).
#' - `PAPERS_*`: the "Papers" artwork (background `CREAM`, text `CHARCOAL`).
#' - `GREY_*` and `TEXT`: the PI's grey tones used in figures
#'   (light/dark bars, error bars, axis lines, tick labels).
#' - `ACCENT_*`: point and overlay colours from the lab's brain-behaviour figure.
#' - `OCULAR_*`, `SENSORIMOTOR_*`, `GAZE_*`, `SCENE_*`, `IMAGERY_*`:
#'   representative figure colours sampled from lab papers. See
#'   [kiyonaga_palettes] for sources and condition order.
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
  ACCENT_MAGENTA    = "#E486E1",
  # Dong & Kiyonaga (2024), Fig. 3: cue reliability, high to low
  OCULAR_CORAL      = "#D54925",
  OCULAR_TEAL       = "#14757E",
  OCULAR_PURPLE     = "#533746",
  OCULAR_CORAL_LIGHT = "#FAAF9C",
  OCULAR_TEAL_LIGHT  = "#92C9CE",
  OCULAR_PURPLE_LIGHT = "#AA9AA7",
  # Yang et al. (2026), Figs. 1-3: response, stimulus and error conditions
  SENSORIMOTOR_BLUE = "#87CEEB",
  SENSORIMOTOR_CORAL = "#FF7F50",
  SENSORIMOTOR_PURPLE = "#A96FAE",
  SENSORIMOTOR_GREEN = "#83B174",
  SENSORIMOTOR_PURPLE_LIGHT = "#C29AC6",
  SENSORIMOTOR_GREEN_LIGHT = "#A8C89D",
  SENSORIMOTOR_BLUE_ERROR = "#75C9EB",
  SENSORIMOTOR_BLUE_ERROR_LIGHT = "#BBD9E6",
  SENSORIMOTOR_CORAL_ERROR = "#FA703E",
  SENSORIMOTOR_CORAL_ERROR_LIGHT = "#E6C6BA",
  # Gaze reinstatement (2026), Figs. 2-3: cue timing and task feature
  GAZE_BLUE         = "#4D6DB6",
  GAZE_ORANGE       = "#EAB375",
  GAZE_BLUE_LIGHT   = "#82A0D3",
  GAZE_ORANGE_LIGHT = "#DBCBB5",
  GAZE_TEAL         = "#65AA9E",
  GAZE_PURPLE       = "#A06BB9",
  GAZE_TEAL_LIGHT   = "#B4D9D3",
  GAZE_PURPLE_LIGHT = "#D7C1E1",
  # Dong et al. (2026), Fig. 2: task and scene brightness
  SCENE_GREEN       = "#1E681F",
  SCENE_PURPLE      = "#5C1486",
  SCENE_GREEN_LIGHT = "#60D062",
  SCENE_PURPLE_LIGHT = "#BA88E9",
  # Chkhaidze et al. preprint, Figs. 1-5: imagery and memorability
  IMAGERY_BLUE      = "#506488",
  IMAGERY_GOLD      = "#B08B27",
  IMAGERY_BLUE_LIGHT = "#8BA4C0",
  IMAGERY_GOLD_LIGHT = "#D4BC73",
  IMAGERY_BURGUNDY  = "#6A0136",
  IMAGERY_BURGUNDY_MID = "#9E597C",
  IMAGERY_BURGUNDY_LIGHT = "#C399AE",
  IMAGERY_GREEN     = "#60A27D",
  IMAGERY_GREEN_MID = "#97C2AA",
  IMAGERY_GREEN_LIGHT = "#BFD9CB",
  IMAGERY_ROSE      = "#CB8589",
  IMAGERY_ROSE_MID  = "#DDAFB2",
  IMAGERY_ROSE_LIGHT = "#EACECF",
  # Yang et al. (2026), Fig. 2A: sampled heatmap colour bar, low to high
  SENSORIMOTOR_HEATMAP_NAVY = "#002757",
  SENSORIMOTOR_HEATMAP_SLATE = "#2E426D",
  SENSORIMOTOR_HEATMAP_GREY = "#5A5F6E",
  SENSORIMOTOR_HEATMAP_OLIVE = "#7C7C78",
  SENSORIMOTOR_HEATMAP_SAND = "#A59C74",
  SENSORIMOTOR_HEATMAP_GOLD = "#D0BE62",
  SENSORIMOTOR_HEATMAP_YELLOW = "#FEE434",
  # Gaze reinstatement (2026), Fig. 4B: similarity colour bar, low to high
  GAZE_SIMILARITY_BLUE = "#124782",
  GAZE_SIMILARITY_SKY = "#4494C4",
  GAZE_SIMILARITY_PALE_BLUE = "#B6D7E8",
  GAZE_SIMILARITY_WHITE = "#F8F3F0",
  GAZE_SIMILARITY_PEACH = "#F7B596",
  GAZE_SIMILARITY_RED = "#CC4C44",
  GAZE_SIMILARITY_BURGUNDY = "#730421"
)
