# Run after devtools::load_all() to regenerate the README ratio/layout comparison.
sim <- simulate_lab_data(n_subjects = 12)
heatmap <- expand.grid(x = 1:7, y = 1:7)
heatmap$value <- with(heatmap, sin(x / 2) * cos(y / 2))
scatter_example <- data.frame(time = seq(0, 1, length.out = 24),
                               condition = factor(rep("A", 24)))
scatter_example$value <- with(scatter_example,
  1 + 0.8 * time + 0.15 * sin(seq_len(nrow(scatter_example)) * 1.7))

preset_examples <- list(
  timecourse = plot_timecourse(sim$timecourse, "time", "pupil", group = "load",
                               palette = "skyblue_orange") +
    ggplot2::labs(x = "Time (s)", y = "Pupil size (mm)", colour = "WM load", fill = "WM load"),
  scatter = plot_scatter(scatter_example, "time", "value", group = "condition", fit = TRUE,
                           palette = "skyblue_orange", point_preset = "colour_outlined",
                           legend = "none") +
    ggplot2::labs(x = "Time", y = "Value"),
  distribution = ggplot2::ggplot(iris, ggplot2::aes(Sepal.Length, fill = Species)) +
    ggplot2::geom_density(alpha = 0.4, linewidth = 0.3) + scale_fill_kiyonaga("accent_2") +
    ggplot2::labs(x = "Value", y = "Density") +
    theme_kiyonaga(preset = "distribution", legend_position = "none"),
  heatmap = plot_heatmap(heatmap, "x", "y", "value", show_axes = FALSE) +
    ggplot2::labs(fill = "Signal")
)
layout_example <- plot_timecourse(
  sim$timecourse, "time", "pupil", group = "load", palette = "skyblue_orange",
  aspect_ratio = 0.6, legend_position = "none"
) + ggplot2::labs(x = "Time (s)", y = "Pupil size (mm)")

example_frame <- function(p, layout) {
  size <- kiyonaga_plot_presets[[layout]]$font_size
  if (!is.null(size)) p <- resize_text(p, size)
  c(list(plot = ggplot2::ggplotGrob(p)), figure_dims(p, layout, NULL))
}

# All plot-ratio examples share one panel height; ratio determines width.
ratio_example_frame <- function(p, panel_height) {
  extra <- non_panel_size(p)
  list(plot = ggplot2::ggplotGrob(p),
       width = panel_height / p$theme$aspect.ratio + extra$w,
       height = panel_height + extra$h)
}

preset_bar_example <- function(n, preset) {
  d <- expand.grid(condition = factor(seq_len(n)), subject = 1:8)
  d$value <- 0.1 + 0.02 * as.integer(d$condition) + 0.02 * sin(d$subject)
  plot_bars(d, "condition", "value", group = "condition", preset = preset,
             palette = "sunset", legend_position = "none") +
    ggplot2::labs(x = "Condition", y = "Value")
}

comparison_label <- function(text, left, top, size = 10, bold = FALSE) {
  grid::grid.text(text, x = grid::unit(left, "in"), y = grid::unit(1, "npc") - grid::unit(top, "in"),
                   just = "left", gp = grid::gpar(fontsize = size,
                     fontface = if (bold) "bold" else "plain",
                     col = if (bold) "#262626" else "#595959"))
}

comparison_frame <- function(frame, left, top) {
  grid::pushViewport(grid::viewport(
    x = grid::unit(left, "in"), y = grid::unit(1, "npc") - grid::unit(top, "in"),
    width = grid::unit(frame$width, "in"), height = grid::unit(frame$height, "in"),
    just = c("left", "top")
  ))
  grid::grid.draw(frame$plot)
  grid::popViewport()
}

# Position each row from the bottom of its tallest example. A single gap
# controls whitespace between rows, including the stacked half-col/tiny pair.
row_gap <- 0.35
panel_height <- 1.25
bar_frames <- lapply(c("bars", "bars_tall"), function(preset) {
  lapply(c(2, 4, 6), function(n) {
    ratio_example_frame(preset_bar_example(n, preset), panel_height)
  })
})
names(bar_frames) <- c("bars", "bars_tall")
ratio_frames <- lapply(preset_examples, ratio_example_frame, panel_height = panel_height)
# Measure space below each panel so the x axes align even if label heights differ.
timecourse_row_frames <- ratio_frames[c("timecourse", "scatter")]
timecourse_row_below <- vapply(timecourse_row_frames, function(frame) {
  g <- frame$plot
  panel_bottom <- max(g$layout$b[grepl("^panel($|-)", g$layout$name)])
  rows <- seq.int(panel_bottom + 1, length(g$heights))
  sum(grid::convertHeight(g$heights[rows], "in", valueOnly = TRUE))
}, numeric(1))
timecourse_row_above <- vapply(timecourse_row_frames, function(frame) frame$height,
                                numeric(1)) - timecourse_row_below
timecourse_row_height <- max(timecourse_row_above) + max(timecourse_row_below)

layout_frames <- lapply(c("full col", "half col", "tiny", "slides", "full page"),
                         function(name) example_frame(layout_example, name))
names(layout_frames) <- c("full col", "half col", "tiny", "slides", "full page")

row_tops <- c(bars = 1)
row_tops["bars_tall"] <- row_tops["bars"] + 0.8 +
  max(vapply(bar_frames$bars, function(frame) frame$height, numeric(1))) + row_gap
row_tops["timecourse"] <- row_tops["bars_tall"] + 0.8 +
  max(vapply(bar_frames$bars_tall, function(frame) frame$height, numeric(1))) + row_gap
row_tops["distribution"] <- row_tops["timecourse"] + 0.4 +
  timecourse_row_height + row_gap
layout_heading <- row_tops["distribution"] + 0.4 +
  max(ratio_frames$distribution$height, ratio_frames$heatmap$height) + row_gap
layout_top <- layout_heading + 0.8
tiny_top <- layout_top + 0.35 + layout_frames[["half col"]]$height + row_gap
slides_top <- max(layout_top + 0.35 + layout_frames[["full col"]]$height,
                   tiny_top + 0.35 + layout_frames$tiny$height) + row_gap
page_top <- slides_top + 0.35 + layout_frames$slides$height + row_gap
canvas_height <- unname(page_top + 0.35 + layout_frames[["full page"]]$height + 0.25)

draw_plot_presets <- function() {
  grid::grid.newpage()
  comparison_label("Plot ratios and whole-figure layouts", 0.25, 0.3, 14, TRUE)
  comparison_label("Plot types set shape only. Whole-figure layouts set export size and font defaults.",
                     0.25, 0.6, 8)
  for (preset in c("bars", "bars_tall")) {
    top <- row_tops[[preset]]
    coefficient <- if (preset == "bars") 3.10 else 6.16
    comparison_label(sprintf("%s: height / width = %.2f / n_bars", preset, coefficient),
                       0.25, top, 11, TRUE)
    left <- 0.25
    for (i in 1:3) {
      n <- c(2, 4, 6)[i]
      frame <- bar_frames[[preset]][[i]]
      ratio <- coefficient / n
      comparison_label(sprintf("%d bars | ratio %.3f", n, ratio),
                         left, top + 0.4, 9, TRUE)
      comparison_label(sprintf("Panel height %.2f in | base 8 pt", panel_height),
                         left, top + 0.6, 6.5)
      comparison_frame(frame, left, top + 0.8)
      left <- left + max(frame$width + 0.45, 1.5)
    }
  }
  positions <- list(timecourse = c(0.25, row_tops[["timecourse"]]),
                      scatter = c(4.4, row_tops[["timecourse"]]),
                      distribution = c(0.25, row_tops[["distribution"]]),
                      heatmap = c(4.4, row_tops[["distribution"]]))
  for (name in names(positions)) {
    p <- preset_examples[[name]]
    left <- positions[[name]][1]
    top <- positions[[name]][2]
    comparison_label(name, left, top, 10, TRUE)
    comparison_label(sprintf("Panel height %.2f in | ratio %.2f | base 8 pt",
                               panel_height, p$theme$aspect.ratio), left, top + 0.2, 7)
    frame_top <- top + 0.4
    if (name %in% c("timecourse", "scatter")) {
      # Keep headings aligned and put both panels' x axes on one baseline.
      frame_top <- frame_top + max(timecourse_row_above) - timecourse_row_above[[name]]
    }
    comparison_frame(ratio_frames[[name]], left, frame_top)
  }
  comparison_label("Whole-figure layouts", 0.25, layout_heading, 14, TRUE)
  comparison_label("Sizes include axes, labels and margins. These examples share a 0.6 panel ratio.",
                     0.25, layout_heading + 0.3, 8)
  positions <- list("full col" = c(0.25, layout_top), "half col" = c(4.4, layout_top),
                     tiny = c(4.4, tiny_top), slides = c(0.25, slides_top),
                     "full page" = c(0.25, page_top))
  for (name in names(positions)) {
    frame <- layout_frames[[name]]
    settings <- kiyonaga_plot_presets[[name]]
    left <- positions[[name]][1]
    top <- positions[[name]][2]
    text <- if (is.null(settings$font_size)) "keep text (8 pt shown)" else
      sprintf("base %g pt", settings$font_size)
    fixed <- if (is.null(settings$figure_width)) "fixed height" else "fixed width"
    comparison_label(name, left, top, 10, TRUE)
    comparison_label(sprintf("Figure %.2f x %.2f in | %s | %s", frame$width, frame$height,
                               fixed, text), left, top + 0.2, 7)
    comparison_frame(frame, left, top + 0.35)
  }
}

svglite::svglite("man/figures/plot-presets.svg", width = 8.5, height = canvas_height)
draw_plot_presets()
invisible(grDevices::dev.off())
