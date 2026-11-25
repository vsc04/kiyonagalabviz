heatmap_data <- function() {
  d <- expand.grid(x = -2:2, y = -2:2)
  d$value <- with(d, x + y / 2)
  d
}

test_that("heatmaps preserve supplied values and use borderless square panels", {
  d <- heatmap_data()
  p <- plot_heatmap(d, "x", "y", "value")
  built <- ggplot2::ggplot_build(p)
  tiles <- built$data[[1]]
  expect_equal(nrow(tiles), nrow(d))
  expect_equal(tiles$x, as.numeric(d$x))
  expect_equal(tiles$y, as.numeric(d$y))
  expect_equal(tiles$xmax - tiles$xmin, rep(1, nrow(d)))
  expect_true(all(is.na(tiles$colour)))
  expect_true(all(tiles$linewidth == 0))
  expect_equal(p$theme$aspect.ratio, 1)
  expect_equal(p$theme$legend.position, "right")
  scale <- built$plot$scales$get_scales("fill")
  expect_equal(scale$get_limits(), range(d$value))
  expect_equal(scale$map(range(d$value)), kiyonaga_palettes$blue_yellow_continuous[c(1, 7)])
  expect_equal(p$data$value, d$value)
  expect_equal(ggplot2::get_labs(p + ggplot2::labs(fill = "Signal"))$fill, "Signal")
  expect_no_warning(ggplot2::ggplotGrob(p))
})

test_that("signed maps align the palette centre with their midpoint", {
  d <- heatmap_data()
  d$value <- d$value + 1
  p <- plot_heatmap(d, "x", "y", "value", midpoint = 0,
                    palette = "blue_red_continuous")
  scale <- ggplot2::ggplot_build(p)$plot$scales$get_scales("fill")
  expect_equal(scale$get_limits(), c(-4, 4))
  expect_equal(scale$map(0), kiyonaga_palettes$blue_red_continuous[4])
  p <- plot_heatmap(d, "x", "y", "value", midpoint = 0, limits = c(-2, 4),
                    palette = "blue_red_continuous", reverse = TRUE)
  scale <- ggplot2::ggplot_build(p)$plot$scales$get_scales("fill")
  expect_equal(scale$map(c(-2, 0, 4)), kiyonaga_palettes$blue_red_continuous[c(7, 4, 1)])
  expect_no_warning(ggplot2::ggplotGrob(p))
  d$value <- 0
  p <- plot_heatmap(d, "x", "y", "value", midpoint = 0)
  expect_equal(ggplot2::ggplot_build(p)$plot$scales$get_scales("fill")$get_limits(), c(-1, 1))
})

test_that("factor levels and reversed axes control matrix orientation", {
  d <- expand.grid(column = factor(c("B", "A"), levels = c("B", "A")),
                   row = factor(c("second", "first"), levels = c("second", "first")))
  d$value <- 1:4
  p <- plot_heatmap(d, "column", "row", "value", reverse_y = TRUE)
  built <- ggplot2::ggplot_build(p)
  expect_equal(built$layout$panel_params[[1]]$x$get_labels(), c("B", "A"))
  expect_equal(built$layout$panel_params[[1]]$y$get_labels(), c("first", "second"))
  expect_equal(built$data[[1]]$y, as.numeric(d$row[c(3, 4, 1, 2)]))
  expect_equal(built$layout$panel_params[[1]]$x.range, c(0.5, 2.5))
  expect_no_warning(ggplot2::ggplotGrob(p))
  d <- heatmap_data()
  p <- plot_heatmap(d, "x", "y", "value", reverse_y = TRUE)
  expect_equal(ggplot2::layer_data(p)$y, -as.numeric(d$y))
})

test_that("missing values, missing tiles and explicit cell sizes are retained", {
  d <- heatmap_data()[-1, ]
  d$value[1] <- NA
  p <- plot_heatmap(d, "x", "y", "value", na_colour = "#123456",
                    cell_width = 0.5, cell_height = 0.75, limits = c(-1, 1))
  built <- ggplot2::ggplot_build(p)
  expect_equal(nrow(built$data[[1]]), nrow(d))
  expect_equal(built$data[[1]]$fill[1], "#123456")
  expect_equal(built$data[[1]]$xmax - built$data[[1]]$xmin, rep(0.5, nrow(d)))
  expect_equal(built$data[[1]]$ymax - built$data[[1]]$ymin, rep(0.75, nrow(d)))
  scale <- built$plot$scales$get_scales("fill")
  expect_equal(scale$map(c(NA, -2, 2)), rep("#123456", 3))
})

test_that("condition panels share one scale and preserve facet labels", {
  d <- heatmap_data()
  d <- rbind(transform(d, task = "A", session = "first"),
             transform(d, task = "A", session = "second", value = value * 2),
             transform(d, task = "B", session = "first"),
             transform(d, task = "B", session = "second"))
  p <- plot_heatmap(d, "x", "y", "value", group = "task", subgroup = "session")
  built <- ggplot2::ggplot_build(p)
  expect_equal(nrow(built$layout$layout), 4)
  expect_equal(as.character(built$layout$layout$task), c("A", "A", "B", "B"))
  expect_equal(built$plot$scales$get_scales("fill")$get_limits(), c(-6, 6))
  expect_equal(nrow(built$data[[1]]), nrow(d))
  expect_no_warning(ggplot2::ggplotGrob(p))
})

test_that("hidden axes and separate colour bars use the shared legend API", {
  p <- plot_heatmap(heatmap_data(), "x", "y", "value", show_axes = FALSE,
                    legend = "separate")
  expect_equal(p$theme$legend.position, "none")
  expect_s3_class(ggplot2::calc_element("axis.text.x.bottom", p$theme), "element_blank")
  expect_s3_class(ggplot2::calc_element("axis.title.y.left", p$theme), "element_blank")
  key <- plot_legend(p)
  expect_s3_class(key, "gtable")
  f <- tempfile(fileext = ".png")
  expect_no_error(nice_save(f, key, dpi = 72))
  expect_gt(file.info(f)$size, 0)
  p <- plot_heatmap(heatmap_data(), "x", "y", "value", legend = "none", aspect_ratio = 0.7)
  expect_equal(p$theme$aspect.ratio, 0.7)
  expect_equal(p$theme$legend.position, "none")
})

test_that("ambiguous grids and invalid options fail clearly", {
  d <- heatmap_data()
  expect_error(plot_heatmap(rbind(d, d[1, ]), "x", "y", "value"), "one value per")
  expect_error(plot_heatmap(d, "x", "y", "missing"), "not found")
  expect_error(plot_heatmap(d, "x", "y", "value", subgroup = "x"), "requires `group`")
  expect_error(plot_heatmap(d, "x", "y", "value", limits = c(1, 0)), "increasing")
  expect_error(plot_heatmap(d, "x", "y", "value", midpoint = NA), "finite")
  expect_error(plot_heatmap(d, "x", "y", "value", midpoint = 0, limits = c(0, 1)), "strictly")
  expect_error(plot_heatmap(d, "x", "y", "value", cell_width = -1), "positive")
  d$x[1] <- NA
  expect_error(plot_heatmap(d, "x", "y", "value"), "coordinates")
  d <- heatmap_data()
  d$value[1] <- Inf
  expect_error(plot_heatmap(d, "x", "y", "value"), "finite or NA")
  d$value <- NA_real_
  expect_error(plot_heatmap(d, "x", "y", "value", midpoint = 0), "finite values")
})


test_that("custom palettes honour an asymmetric midpoint and reference lines", {
  d <- heatmap_data()
  p <- plot_heatmap(d, "x", "y", "value", palette = c("#0000FF", "#FF0000"),
                    midpoint = 0, limits = c(-1, 3), reference = c(0, 1))
  built <- ggplot2::ggplot_build(p)
  scale <- built$plot$scales$get_scales("fill")
  expect_equal(scale$map(c(-1, 0, 3)), c("#0000FF", "#7F007F", "#FF0000"))
  expect_equal(built$data[[2]]$xintercept, 0)
  expect_equal(built$data[[3]]$yintercept, 1)
  expect_equal(built$data[[2]]$linewidth, 0.3)
  expect_no_warning(ggplot2::ggplotGrob(p))
  expect_error(plot_heatmap(d, "x", "y", "value", reference = c(NA, 0)), "reference")
})
