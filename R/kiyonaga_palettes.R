#' Kiyonaga Lab colour palettes
#'
#' A named list of hex colour vectors built from [kiyonaga_colors].
#'
#' - Lab palettes: `sunset` (yellow to periwinkle), `sunset_light` (sage to
#'   salmon), `greys` (light, medium, dark), and `accent` (green, blue, magenta).
#'   Requesting two colours from `greys` selects light and dark.
#' - `accent_2`: coral, teal, purple; `accent_3`: burgundy, green, rose.
#' - `green_purple`: green, purple; `green_purple_2`: teal, purple;
#'   `green_purple_3`: green, purple in a darker set of shades.
#' - `skyblue_orange`: sky blue, orange; `blue_yellow`: blue, yellow;
#'   `blue_yellow_2`: muted blue, gold.
#' - Each of these eight main palettes has a `_light` variant. `accent_3`
#'   also has an intermediate `accent_3_med` variant.
#' - `blue_yellow_continuous`: navy through grey and olive to yellow.
#' - `blue_red_continuous`: blue through a pale neutral centre to red.
#'
#' @details
#' Use with [scale_fill_kiyonaga()], [scale_colour_kiyonaga()] or
#' [make_kiyonaga_palette()]. Use `discrete = FALSE` in the scales for gradients.
#' To combine primary colours with secondary-condition shades, use
#' `condition_groups = 2`, or `3` for `accent_3`; see [kiyonaga_palette_groups].
#' Built-in shades are fully opaque. Each shade palette is also available
#' individually. Use [preview_kiyonaga_palettes()] to view the colours.
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
  ),
  accent_2 = c(
    kiyonaga_colors$OCULAR_CORAL, kiyonaga_colors$OCULAR_TEAL,
    kiyonaga_colors$OCULAR_PURPLE
  ),
  accent_2_light = c(
    kiyonaga_colors$OCULAR_CORAL_LIGHT, kiyonaga_colors$OCULAR_TEAL_LIGHT,
    kiyonaga_colors$OCULAR_PURPLE_LIGHT
  ),
  accent_3 = c(
    kiyonaga_colors$IMAGERY_BURGUNDY, kiyonaga_colors$IMAGERY_GREEN,
    kiyonaga_colors$IMAGERY_ROSE
  ),
  accent_3_med = c(
    kiyonaga_colors$IMAGERY_BURGUNDY_MID, kiyonaga_colors$IMAGERY_GREEN_MID,
    kiyonaga_colors$IMAGERY_ROSE_MID
  ),
  accent_3_light = c(
    kiyonaga_colors$IMAGERY_BURGUNDY_LIGHT, kiyonaga_colors$IMAGERY_GREEN_LIGHT,
    kiyonaga_colors$IMAGERY_ROSE_LIGHT
  ),
  green_purple = c(
    kiyonaga_colors$SENSORIMOTOR_GREEN, kiyonaga_colors$SENSORIMOTOR_PURPLE
  ),
  green_purple_light = c(
    kiyonaga_colors$SENSORIMOTOR_GREEN_LIGHT, kiyonaga_colors$SENSORIMOTOR_PURPLE_LIGHT
  ),
  green_purple_2 = c(
    kiyonaga_colors$GAZE_TEAL, kiyonaga_colors$GAZE_PURPLE
  ),
  green_purple_2_light = c(
    kiyonaga_colors$GAZE_TEAL_LIGHT, kiyonaga_colors$GAZE_PURPLE_LIGHT
  ),
  green_purple_3 = c(
    kiyonaga_colors$SCENE_GREEN, kiyonaga_colors$SCENE_PURPLE
  ),
  green_purple_3_light = c(
    kiyonaga_colors$SCENE_GREEN_LIGHT, kiyonaga_colors$SCENE_PURPLE_LIGHT
  ),
  skyblue_orange = c(
    kiyonaga_colors$SENSORIMOTOR_BLUE_ERROR, kiyonaga_colors$SENSORIMOTOR_CORAL_ERROR
  ),
  skyblue_orange_light = c(
    kiyonaga_colors$SENSORIMOTOR_BLUE_ERROR_LIGHT,
    kiyonaga_colors$SENSORIMOTOR_CORAL_ERROR_LIGHT
  ),
  blue_yellow = c(
    kiyonaga_colors$GAZE_BLUE, kiyonaga_colors$GAZE_ORANGE
  ),
  blue_yellow_light = c(
    kiyonaga_colors$GAZE_BLUE_LIGHT, kiyonaga_colors$GAZE_ORANGE_LIGHT
  ),
  blue_yellow_2 = c(
    kiyonaga_colors$IMAGERY_BLUE, kiyonaga_colors$IMAGERY_GOLD
  ),
  blue_yellow_2_light = c(
    kiyonaga_colors$IMAGERY_BLUE_LIGHT, kiyonaga_colors$IMAGERY_GOLD_LIGHT
  ),
  blue_yellow_continuous = c(
    kiyonaga_colors$SENSORIMOTOR_HEATMAP_NAVY,
    kiyonaga_colors$SENSORIMOTOR_HEATMAP_SLATE,
    kiyonaga_colors$SENSORIMOTOR_HEATMAP_GREY,
    kiyonaga_colors$SENSORIMOTOR_HEATMAP_OLIVE,
    kiyonaga_colors$SENSORIMOTOR_HEATMAP_SAND,
    kiyonaga_colors$SENSORIMOTOR_HEATMAP_GOLD,
    kiyonaga_colors$SENSORIMOTOR_HEATMAP_YELLOW
  ),
  blue_red_continuous = c(
    kiyonaga_colors$GAZE_SIMILARITY_BLUE,
    kiyonaga_colors$GAZE_SIMILARITY_SKY,
    kiyonaga_colors$GAZE_SIMILARITY_PALE_BLUE,
    kiyonaga_colors$GAZE_SIMILARITY_WHITE,
    kiyonaga_colors$GAZE_SIMILARITY_PEACH,
    kiyonaga_colors$GAZE_SIMILARITY_RED,
    kiyonaga_colors$GAZE_SIMILARITY_BURGUNDY
  )
)
