#' Create a palette function from a Kiyonaga Lab palette
#'
#' Returns a function that takes `n` and returns `n` colours. If `n` is not
#' larger than the palette, evenly spaced original colours are returned (so the
#' exact lab colours are used); otherwise colours are interpolated.
#'
#' @param palette Name of a palette in [kiyonaga_palettes], or a character
#'   vector of hex colours.
#' @param reverse Logical; reverse the palette order?
#'
#' @return A function of `n` returning a character vector of hex colours.
#' @export
#'
#' @examples
#' pal <- make_kiyonaga_palette("sunset")
#' pal(3)
#' make_kiyonaga_palette("greys")(2)
make_kiyonaga_palette <- function(palette = "sunset", reverse = FALSE) {
  pal <- get_kiyonaga_palette(palette, reverse)
  function(n) pick_colors(pal, n)
}

#' Look up (and optionally reverse) a palette
#' @noRd
get_kiyonaga_palette <- function(palette, reverse = FALSE) {
  pal <- resolve_palette(palette)
  if (reverse) pal <- rev(pal)
  unname(pal)
}

#' Resolve a palette name or a custom colour vector
#' @noRd
resolve_palette <- function(palette) {
  if (!is.character(palette) || length(palette) == 0) {
    stop("`palette` must be a palette name or a vector of hex colours.",
         call. = FALSE)
  }
  if (length(palette) > 1) return(palette)
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
  grDevices::colorRampPalette(pal)(n)
}
