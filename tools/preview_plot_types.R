# Run from the package root after devtools::load_all().
if (!requireNamespace("svglite", quietly = TRUE)) stop("Install svglite first.")
set.seed(24)
d <- expand.grid(subject = factor(1:12), task = factor(c("A", "B")),
                 session = factor(c("1", "2")), time = seq(0, 1, length.out = 21))
d$value <- as.integer(d$task) + as.integer(d$session) * 0.4 +
  sin(d$time * 4) + as.integer(d$subject) * 0.07 + rnorm(nrow(d), sd = 0.35)
plots <- list(
  "Mean bars" = plot_bars(d, "task", "value", group = "task", subgroup = "session",
                           palette = "blue_yellow_2", show_points = FALSE),
  "Mean points" = plot_means(d, "task", "value", group = "task", subgroup = "session",
                             palette = "blue_yellow_2", error = "ci"),
  "Fits and binned means" = plot_predictions(d, "time", "value", group = "task",
                                             subgroup = "session", palette = "blue_yellow_2"),
  "Histogram and density" = plot_histogram(d, "value", group = "task", density = TRUE),
  "Density distributions" = plot_density(d, "value", group = "task"),
  "Boxplots" = plot_boxplots(d[d$time == 0, ], "task", "value", group = "task"),
  "Connected subjects" = plot_paired(d, "task", "value", subject = "subject"),
  "Rolling means" = plot_lines(d, "time", "value", subject = "subject", group = "task",
                                rolling_window = 0.15),
  "Timecourse" = plot_timecourse(d, "time", "value", group = "task", window = c(0.6, 0.8))
)
svglite::svglite("man/figures/plot-types.svg", width = 9, height = 9)
draw_plot_types <- function() {
  grid::grid.newpage()
  grid::pushViewport(grid::viewport(layout = grid::grid.layout(3, 3)))
  for (i in seq_along(plots)) {
    p <- plots[[i]] + ggplot2::labs(title = names(plots)[i]) +
      ggplot2::theme(plot.margin = ggplot2::margin(8, 12, 8, 8))
    print(p, newpage = FALSE,
          vp = grid::viewport(layout.pos.row = (i - 1) %/% 3 + 1,
                               layout.pos.col = (i - 1) %% 3 + 1))
  }
  grid::popViewport()
}
draw_plot_types()
grDevices::dev.off()
