# Run after devtools::load_all() to regenerate the individual-dot reference.
d <- expand.grid(subject = 1:24, condition = factor(c("A", "B")))
d$value <- 8 + as.integer(d$condition) * 2 + sin(d$subject * 1.8) * 3 +
  cos(d$subject * 0.9)
point_preset_order <- c("charite", "grey_filled", "grey_small", "colour_outlined",
                         "colour_filled", "colour_small")
point_examples <- lapply(point_preset_order, function(name) {
  plot_means(d, "condition", "value", group = "condition", show_points = TRUE,
              palette = "skyblue_orange", point_preset = name, mean_line = TRUE,
              error = "ci", legend = "none") +
    ggplot2::labs(title = if (name == "grey_filled") paste(name, "(bars/means/boxes default)") else
      if (name == "colour_outlined") paste(name, "(scatter default)") else name,
                   x = NULL, y = "Value") +
    ggplot2::theme(plot.margin = ggplot2::margin(10, 14, 10, 10))
})
point_preset_rows <- ceiling(length(point_examples) / 2)
draw_point_presets <- function() {
  grid::grid.newpage()
  grid::pushViewport(grid::viewport(layout = grid::grid.layout(point_preset_rows, 2)))
  for (i in seq_along(point_examples)) {
    print(point_examples[[i]], newpage = FALSE,
          vp = grid::viewport(layout.pos.row = (i - 1) %/% 2 + 1,
                               layout.pos.col = (i - 1) %% 2 + 1))
  }
  grid::popViewport()
}
svglite::svglite("man/figures/point-presets.svg", width = 8.5, height = 2.75 * point_preset_rows)
draw_point_presets()
invisible(grDevices::dev.off())
