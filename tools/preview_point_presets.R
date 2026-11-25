# Run after devtools::load_all() to regenerate the individual-dot reference.
d <- expand.grid(subject = 1:24, condition = factor(c("Draw", "Wheel")))
d$value <- 8 + as.integer(d$condition) * 2 + sin(d$subject * 1.8) * 3 +
  cos(d$subject * 0.9)
point_examples <- lapply(names(kiyonaga_point_presets), function(name) {
  plot_means(d, "condition", "value", group = "condition", show_points = TRUE,
              palette = "skyblue_orange", point_preset = name, mean_line = TRUE,
              error = "ci", legend = "none") +
    ggplot2::labs(title = name, x = NULL, y = "Value") +
    ggplot2::theme(plot.margin = ggplot2::margin(10, 14, 10, 10))
})
draw_point_presets <- function() {
  grid::grid.newpage()
  grid::pushViewport(grid::viewport(layout = grid::grid.layout(2, 2)))
  for (i in seq_along(point_examples)) {
    print(point_examples[[i]], newpage = FALSE,
          vp = grid::viewport(layout.pos.row = (i - 1) %/% 2 + 1,
                               layout.pos.col = (i - 1) %% 2 + 1))
  }
  grid::popViewport()
}
svglite::svglite("man/figures/point-presets.svg", width = 8.5, height = 5.5)
draw_point_presets()
invisible(grDevices::dev.off())
