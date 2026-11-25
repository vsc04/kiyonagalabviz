# Run after devtools::load_all() to regenerate the heatmap reference.
source("tools/heatmap_examples.R", local = TRUE)
svglite::svglite("man/figures/heatmaps.svg", width = 8.5, height = 6.5)
draw_heatmaps()
invisible(grDevices::dev.off())
