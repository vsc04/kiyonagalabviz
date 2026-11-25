# Shared examples for the standalone heatmap reference and plot-type overview.
map <- expand.grid(x = seq(-2, 2, length.out = 31), y = seq(-2, 2, length.out = 31))
map$value <- with(map, exp(-((x + 0.35)^2 + y^2) / 0.5))
map$difference <- with(map, exp(-((x + 0.35)^2 + y^2) / 0.5) -
                             exp(-((x - 0.35)^2 + y^2) / 0.5))
matrix_data <- expand.grid(column = factor(c("A", "B", "C")),
                           row = factor(c("A", "B", "C")))
matrix_data$similarity <- c(1, 0.3, -0.2, 0.3, 1, 0.1, -0.2, 0.1, 1)
conditions <- rbind(transform(map, task = "Visual", session = "First"),
                    transform(map, task = "Visual", session = "Second", value = value * 0.6),
                    transform(map, task = "Semantic", session = "First", value = value * 0.4),
                    transform(map, task = "Semantic", session = "Second", value = value * 0.2))
heatmap_plots <- list(
  "Spatial map" = plot_heatmap(map, "x", "y", "value", show_axes = FALSE,
                                reference = c(0, 0), limits = c(0, 1)),
  "Signed difference" = plot_heatmap(map, "x", "y", "difference", show_axes = FALSE,
                                     palette = "blue_red_continuous", midpoint = 0,
                                     reference = c(0, 0)),
  "Categorical matrix" = plot_heatmap(matrix_data, "column", "row", "similarity",
                                      palette = "blue_red_continuous", midpoint = 0,
                                      limits = c(-1, 1), reverse_y = TRUE),
  "Condition panels" = plot_heatmap(conditions, "x", "y", "value", group = "task",
                                    subgroup = "session", limits = c(0, 1), show_axes = FALSE)
)
draw_heatmaps <- function(newpage = TRUE) {
  if (newpage) grid::grid.newpage()
  grid::pushViewport(grid::viewport(layout = grid::grid.layout(2, 2)))
  for (i in seq_along(heatmap_plots)) {
    p <- heatmap_plots[[i]] + ggplot2::labs(title = names(heatmap_plots)[i]) +
      ggplot2::theme(plot.margin = ggplot2::margin(10, 14, 10, 10))
    print(p, newpage = FALSE,
          vp = grid::viewport(layout.pos.row = (i - 1) %/% 2 + 1,
                               layout.pos.col = (i - 1) %% 2 + 1))
  }
  grid::popViewport()
}
