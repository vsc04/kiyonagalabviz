# Run after devtools::load_all() to regenerate the README palette preview.
draw_paper_palettes <- function() {
  paper_names <- setdiff(names(kiyonaga_palettes),
                         c("sunset", "sunset_light", "greys", "accent"))
  n <- length(paper_names)
  graphics::par(mar = c(1, 1, 2, 1), family = "sans", xpd = NA)
  graphics::plot.new()
  graphics::plot.window(xlim = c(0, 10), ylim = c(0, n + 4),
                         xaxs = "i", yaxs = "i")
  graphics::text(0, n + 3.5, "Palettes from lab figures", adj = 0,
                 font = 2, cex = 1.2)
  graphics::text(0, n + 2.7,
                 "Representative publication RGB samples; see README for sources and condition order.",
                 adj = 0, cex = 0.7, col = "#595959")
  for (i in seq_along(paper_names)) {
    name <- paper_names[i]
    pal <- kiyonaga_palettes[[name]]
    y <- n + 2 - i
    graphics::text(0, y + 0.35, name, adj = 0, cex = 0.8)
    if (name %in% c("blue_yellow_continuous", "blue_red_continuous")) {
      pal <- make_kiyonaga_palette(pal)(128)
    }
    x <- seq(3.5, 10, length.out = length(pal) + 1)
    graphics::rect(x[-length(x)], y, x[-1], y + 0.7,
                    col = pal, border = NA)
  }
  for (i in 1:2) {
    family <- c("skyblue_orange", "accent_3")[i]
    groups <- c(2, 3)[i]
    y <- if (i == 1) 1 else 0
    graphics::text(0, y + 0.35, paste0(family, " (", groups, " levels)"),
                   adj = 0, cex = 0.7)
    count <- length(kiyonaga_palettes[[family]]) * groups
    pal <- make_kiyonaga_palette(family, condition_groups = groups)(count)
    x <- seq(3.5, 10, length.out = length(pal) + 1)
    graphics::rect(x[-length(x)], y, x[-1], y + 0.7, col = pal, border = NA)
  }
}

svglite::svglite("man/figures/palette-papers.svg", width = 8, height = 9)
draw_paper_palettes()
invisible(grDevices::dev.off())
