#' Preview the Kiyonaga Lab colour palettes
#'
#' Draws every palette in [kiyonaga_palettes] as discrete swatches or
#' continuous gradients.
#'
#' @param type Either `"discrete"` (default) or `"continuous"`.
#'
#' @return Called for its side effect (a base R plot); returns `NULL` invisibly.
#' @export
#'
#' @examples
#' preview_kiyonaga_palettes()
#' preview_kiyonaga_palettes("continuous")
preview_kiyonaga_palettes <- function(type = c("discrete", "continuous")) {
  type <- match.arg(type)
  old_par <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(old_par))
  graphics::par(mar = c(0.5, 5, 0.5, 0.5))
  draw_palette_canvas(kiyonaga_palettes, type)
  for (i in seq_along(kiyonaga_palettes)) {
    draw_palette_row(kiyonaga_palettes[[i]], names(kiyonaga_palettes)[i],
                     row = length(kiyonaga_palettes) - i, type = type)
  }
  invisible(NULL)
}

#' Empty canvas sized to the palettes
#' @noRd
draw_palette_canvas <- function(palettes, type) {
  x_max <- if (type == "discrete") max(lengths(palettes)) else 1
  plot(NULL, xlim = c(0, x_max), ylim = c(0, length(palettes)),
       xaxt = "n", yaxt = "n", bty = "n", xlab = "", ylab = "")
}

#' Draw one palette row with its label
#' @noRd
draw_palette_row <- function(pal, label, row, type) {
  if (type == "discrete") {
    n <- length(pal)
    graphics::rect(0:(n - 1), row, 1:n, row + 0.8, col = pal, border = NA)
  } else {
    ramp <- grDevices::colorRampPalette(pal)(256)
    x <- seq(0, 1, length.out = 257)
    graphics::rect(x[-257], row, x[-1], row + 0.8, col = ramp, border = NA)
  }
  graphics::text(0, row + 0.4, label, pos = 2, xpd = TRUE, cex = 0.8)
}
