# Run after devtools::load_all() to regenerate the complete palette reference.
draw_color_palettes <- function() {
  grid::grid.newpage()
  label <- function(text, x, y, size = 10, bold = FALSE, colour = "#595959") {
    grid::grid.text(text, x = grid::unit(x, "in"), y = grid::unit(y, "in"),
                     just = "left", gp = grid::gpar(fontsize = size,
                       fontface = if (bold) "bold" else "plain", col = colour))
  }
  swatches <- function(pal, y, gradient = FALSE) {
    n <- length(pal)
    x <- seq(2.75, 8.25, length.out = n + 1)
    if (gradient) {
      ramp <- make_kiyonaga_palette(pal)(256)
      gx <- seq(2.75, 8.25, length.out = length(ramp) + 1)
      grid::grid.rect(x = grid::unit(gx[-length(gx)], "in"),
                       y = grid::unit(y, "in"), just = c("left", "top"),
                       width = grid::unit(diff(gx), "in"), height = grid::unit(0.18, "in"),
                       gp = grid::gpar(fill = ramp, col = NA))
      y <- y - 0.22
    }
    grid::grid.rect(x = grid::unit(x[-length(x)], "in"), y = grid::unit(y, "in"),
                     just = c("left", "top"), width = grid::unit(diff(x), "in"),
                     height = grid::unit(0.28, "in"), gp = grid::gpar(fill = pal, col = NA))
    grid::grid.text(pal, x = grid::unit((x[-1] + x[-length(x)]) / 2, "in"),
                     y = grid::unit(y - 0.4, "in"),
                     gp = grid::gpar(fontsize = 6.5, col = "#595959", fontfamily = "mono"))
  }

  label("Color palettes and graded conditions", 0.25, 17.6, 14, TRUE, "#262626")
  label("Lab palettes", 0.25, 16.9, 11, TRUE, "#262626")
  y <- 16.55
  for (name in c("sunset", "sunset_light", "greys", "accent")) {
    label(name, 0.25, y - 0.14, 9, TRUE, "#262626")
    swatches(kiyonaga_palettes[[name]], y)
    y <- y - 0.55
  }
  y <- y - 0.15
  label("2 condition palettes", 0.25, y, 11, TRUE, "#262626")
  y <- y - 0.35
  for (name in names(kiyonaga_palette_groups)) {
    settings <- kiyonaga_palette_groups[[name]]
    label(name, 0.25, y - 0.14, 9, TRUE, "#262626")
    swatches(kiyonaga_palettes[[name]], y)
    secondary_y <- y - 0.65
    label(paste("condition_groups =", settings$condition_groups),
            0.25, secondary_y - 0.08, 7, TRUE, "#262626")
    for (i in seq_along(settings$palettes)) {
      label(settings$palettes[i], 0.25, secondary_y - 0.23 - (i - 1) * 0.12, 6.5)
    }
    count <- length(kiyonaga_palettes[[name]]) * settings$condition_groups
    pal <- make_kiyonaga_palette(name, condition_groups = settings$condition_groups)(count)
    swatches(pal, secondary_y)
    y <- y - 1.45
  }
  label("Continuous palettes: gradient and original stops", 0.25, y - 0.05,
          11, TRUE, "#262626")
  y <- y - 0.4
  for (name in c("blue_yellow_continuous", "blue_red_continuous")) {
    label(name, 0.25, y - 0.14, 9, TRUE, "#262626")
    swatches(kiyonaga_palettes[[name]], y, gradient = TRUE)
    y <- y - 0.8
  }
}

svglite::svglite("man/figures/color-palettes.svg", width = 8.5, height = 18)
draw_color_palettes()
invisible(grDevices::dev.off())
