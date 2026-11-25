#' Create a palette function from a Kiyonaga Lab palette
#'
#' Returns a function that takes `n` and returns `n` colours. If `n` is not
#' larger than the palette, evenly spaced original colours are returned (so the
#' exact lab colours are used); otherwise colours are interpolated.
#'
#' @param palette Name of a palette in [kiyonaga_palettes], or a character
#'   vector of hex colours, including `#RRGGBBAA` for transparency.
#' @param reverse Logical; reverse the palette order?
#' @param alpha Optional opacity multiplier between 0 and 1, applied only when
#'   explicitly supplied. Use one number or one per full resolved palette colour
#'   (including secondary shades when grouped). Applied before reversal and
#'   selection; existing alpha is multiplied. `NULL` preserves source colours.
#' @param condition_groups Optional secondary-condition count, `2` for the
#'   paired main families or `3` for `accent_3`. Uses recorded opaque
#'   shade combinations from [kiyonaga_palette_groups]. `NULL` uses the main
#'   palette alone. The returned function's `n` is the total number of
#'   primary-by-secondary combinations and must be a multiple of this value.
#'   Colours are grouped by primary category, then secondary category, using
#'   dark-to-light shade order. `reverse` reverses primary blocks
#'   while preserving secondary order. Grouped colours are not interpolated
#'   beyond the recorded categories.
#'
#' @return A function of `n` returning a character vector of hex colours.
#' @export
#'
#' @examples
#' pal <- make_kiyonaga_palette("sunset")
#' pal(3)
#' make_kiyonaga_palette("greys")(2)
#' # Two primary categories, each with two recorded shades
#' make_kiyonaga_palette("blue_yellow_2", condition_groups = 2)(4)
#' # Three accents, each with dark, medium and light shades
#' make_kiyonaga_palette("accent_3", condition_groups = 3)(9)
make_kiyonaga_palette <- function(palette = "sunset", reverse = FALSE,
                                   alpha = NULL, condition_groups = NULL) {
  if (is.null(condition_groups)) {
    pal <- get_kiyonaga_palette(palette, reverse, alpha)
    return(function(n) pick_colors(pal, n))
  }
  pal <- palette_alpha(resolve_condition_palette(palette, condition_groups), alpha)
  if (reverse) {
    blocks <- matrix(pal, nrow = condition_groups)
    pal <- as.vector(blocks[, rev(seq_len(ncol(blocks))), drop = FALSE])
  }
  function(n) pick_condition_colors(pal, n, condition_groups)
}

#' Look up (and optionally reverse) a palette
#' @noRd
get_kiyonaga_palette <- function(palette, reverse = FALSE, alpha = NULL) {
  pal <- palette_alpha(resolve_palette(palette), alpha)
  if (reverse) pal <- rev(pal)
  unname(pal)
}

#' Apply opacity without discarding alpha already embedded in the colours
#' @noRd
palette_alpha <- function(pal, alpha) {
  if (is.null(alpha)) return(pal)
  if (!is.numeric(alpha) || !length(alpha) %in% c(1L, length(pal)) ||
      any(!is.finite(alpha)) || any(alpha < 0 | alpha > 1)) {
    stop("`alpha` must be a number between 0 and 1, or one per palette colour.",
         call. = FALSE)
  }
  rgba <- grDevices::col2rgb(pal, alpha = TRUE)
  grDevices::rgb(rgba[1, ], rgba[2, ], rgba[3, ],
                 alpha = round(rgba[4, ] * alpha), maxColorValue = 255)
}

#' Interpolate colours and retain embedded opacity when present
#' @noRd
interpolate_palette <- function(pal, n) {
  has_alpha <- any(grDevices::col2rgb(pal, alpha = TRUE)[4, ] != 255)
  grDevices::colorRampPalette(pal, alpha = has_alpha)(n)
}

#' Resolve a palette name or a custom colour vector
#' @noRd
resolve_palette <- function(palette) {
  if (!is.character(palette) || length(palette) == 0) {
    stop("`palette` must be a palette name or a vector of hex colours.",
         call. = FALSE)
  }
  if (length(palette) > 1 ||
      grepl("^#([[:xdigit:]]{6}|[[:xdigit:]]{8})$", palette)) return(palette)
  pal <- kiyonaga_palettes[[palette]]
  if (is.null(pal)) {
    stop("Palette '", palette, "' not found. Available palettes: ",
         paste(names(kiyonaga_palettes), collapse = ", "), call. = FALSE)
  }
  pal
}

#' Pick n evenly spaced colours, interpolating only when needed
#' @noRd
pick_colors <- function(pal, n) {
  if (n <= length(pal)) {
    return(pal[round(seq(1, length(pal), length.out = n))])
  }
  interpolate_palette(pal, n)
}
