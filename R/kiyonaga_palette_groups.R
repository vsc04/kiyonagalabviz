#' Palettes for two conditions and their graded shades
#'
#' A named list defining eight palette families for two experimental conditions. Each entry
#' records the supported number of secondary categories (`condition_groups`),
#' their order (`levels`), the source `palettes`, and how those source vectors
#' are combined. All preset condition colours are fully opaque.
#'
#' Palettes are listed in display order: `accent_2`, `accent_3`,
#' `green_purple`, `green_purple_2`, `green_purple_3`, `skyblue_orange`,
#' `blue_yellow`, `blue_yellow_2`.
#'
#' @details
#' Output is grouped by primary colour, then dark-to-light shade. Paired
#' families use dark/light. `accent_3` uses dark/medium/light, combining
#' `accent_3`, `accent_3_med` and `accent_3_light`. `blue_yellow_2` combines
#' its dark blue/yellow pair with `blue_yellow_2_light`.
#'
#' Use `group` and `subgroup` columns in [plot_bars()] or [plot_timecourse()]
#' to select colours and shades automatically. Use `condition_groups` in
#' [make_kiyonaga_palette()] or the colour/fill scales. The requested colour count is the
#' total number of primary-by-secondary combinations. Factor levels or scale
#' `limits` should follow the same order. Colour vectors remain available
#' separately in [kiyonaga_palettes].
#'
#' @export
#' @examples
#' kiyonaga_palette_groups$blue_yellow_2
#' make_kiyonaga_palette("blue_yellow_2", condition_groups = 2)(4)
#' make_kiyonaga_palette("accent_3", condition_groups = 3)(9)
kiyonaga_palette_groups <- list(
  accent_2 = list(condition_groups = 2, levels = c("dark", "light"),
                   palettes = c("accent_2", "accent_2_light"), combine = "interleave"),
  accent_3 = list(condition_groups = 3, levels = c("dark", "medium", "light"),
                   palettes = c("accent_3", "accent_3_med", "accent_3_light"),
                   combine = "interleave"),
  green_purple = list(condition_groups = 2, levels = c("dark", "light"),
                       palettes = c("green_purple", "green_purple_light"), combine = "interleave"),
  green_purple_2 = list(condition_groups = 2, levels = c("dark", "light"),
                         palettes = c("green_purple_2", "green_purple_2_light"), combine = "interleave"),
  green_purple_3 = list(condition_groups = 2, levels = c("dark", "light"),
                         palettes = c("green_purple_3", "green_purple_3_light"), combine = "interleave"),
  skyblue_orange = list(condition_groups = 2, levels = c("dark", "light"),
                         palettes = c("skyblue_orange", "skyblue_orange_light"),
                         combine = "interleave"),
  blue_yellow = list(condition_groups = 2, levels = c("dark", "light"),
                      palettes = c("blue_yellow", "blue_yellow_light"), combine = "interleave"),
  blue_yellow_2 = list(condition_groups = 2, levels = c("dark", "light"),
                        palettes = c("blue_yellow_2", "blue_yellow_2_light"), combine = "interleave")
)

#' Resolve the recorded shade combinations for one main palette family
#' @noRd
resolve_condition_palette <- function(palette, condition_groups) {
  if (!is.numeric(condition_groups) || length(condition_groups) != 1L ||
      is.na(condition_groups) || !condition_groups %in% c(2, 3)) {
    stop("`condition_groups` must be 2, 3, or NULL.", call. = FALSE)
  }
  if (!is.character(palette) || length(palette) != 1L || is.na(palette) ||
      !palette %in% names(kiyonaga_palette_groups)) {
    stop("Graded condition colours require a main palette: ",
         paste(names(kiyonaga_palette_groups), collapse = ", "), call. = FALSE)
  }
  settings <- kiyonaga_palette_groups[[palette]]
  if (condition_groups != settings$condition_groups) {
    stop("Palette '", palette, "' supports `condition_groups = ",
         settings$condition_groups, "`.", call. = FALSE)
  }
  sources <- kiyonaga_palettes[settings$palettes]
  if (settings$combine == "interleave") {
    return(unname(as.vector(do.call(rbind, sources))))
  }
  unname(unlist(sources, use.names = FALSE))
}

#' Select complete secondary-colour blocks without interpolating categories
#' @noRd
pick_condition_colors <- function(pal, n, groups) {
  if (!is.numeric(n) || length(n) != 1L || !is.finite(n) ||
      n < 0 || n %% groups != 0) {
    stop("The number of colours must be a multiple of `condition_groups` (",
         groups, "). Set factor levels or scale limits for all conditions.",
         call. = FALSE)
  }
  if (n > length(pal)) {
    stop("This palette has graded colours for at most ", length(pal),
         " primary-by-secondary combinations.", call. = FALSE)
  }
  if (n == 0) return(character(0))
  blocks <- matrix(pal, nrow = groups)
  selected <- round(seq(1, ncol(blocks), length.out = n / groups))
  unname(as.vector(blocks[, selected, drop = FALSE]))
}
