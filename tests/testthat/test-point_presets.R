point_data <- function() {
  d <- expand.grid(subject = 1:20, task = c("A", "B"), session = c("first", "second"), x = c("x1", "x2"))
  d$y <- d$subject + as.integer(factor(d$task)) * 10 + as.integer(factor(d$session)) * 3
  d
}

test_that("paper dot presets apply across bars, means and boxplots", {
  d <- point_data()
  functions <- list(plot_bars, plot_means, plot_boxplots)
  for (plot in functions) {
    for (preset in names(kiyonaga_point_presets)) {
      p <- plot(d, "x", "y", group = "task", subgroup = "session",
                palette = "blue_yellow_2", show_points = TRUE, point_preset = preset)
      point_layer_index <- which(vapply(p$layers, function(l) inherits(l$geom, "GeomPoint"), logical(1)))
      dots <- ggplot2::layer_data(p, point_layer_index[1])
      settings <- kiyonaga_point_presets[[preset]]
      expect_equal(unique(dots$size), settings$size)
      expect_equal(unique(dots$shape), settings$shape)
      expect_equal(unique(dots$alpha), settings$alpha)
      expect_equal(nrow(dots), nrow(d))
      if (preset == "colour_outlined") {
        expect_setequal(dots$fill, make_kiyonaga_palette("blue_yellow_2", condition_groups = 2)(4))
      }
      expect_no_warning(ggplot2::ggplotGrob(p))
    }
  }
})

test_that("explicit point style overrides presets and supports mapped fills", {
  d <- point_data()
  p <- plot_bars(d, "x", "y", group = "task", point_preset = "colour_outlined",
                 point_style = list(size = 2, shape = 23, alpha = 0.3))
  dots <- ggplot2::layer_data(p, 2)
  expect_equal(unique(dots$size), 2)
  expect_equal(unique(dots$shape), 23)
  expect_equal(unique(dots$alpha), 0.3)
  expect_setequal(dots$fill, make_kiyonaga_palette("greys")(2))
  p <- plot_means(d, "x", "y", group = "task", show_points = TRUE,
                  point_style = list(fill = NULL, colour = NULL))
  dots <- ggplot2::layer_data(p, 1)
  expect_setequal(dots$fill, make_kiyonaga_palette("accent")(2))
  expect_equal(dots$fill, dots$colour)
  expect_no_warning(ggplot2::ggplotGrob(p))
  expect_error(plot_bars(d, "x", "y", point_preset = "missing"), "point_preset")
  expect_error(plot_bars(d, "x", "y", point_style = list(szie = 2)), "Unknown")
  expect_error(plot_bars(d, "x", "y", point_style = list(2)), "named list")
})

test_that("horizontal mean markers align with means and span the individual dots", {
  d <- point_data()
  for (grouped in c(FALSE, TRUE)) {
    p <- if (grouped) {
      plot_means(d, "x", "y", group = "task", subgroup = "session",
                  palette = "blue_yellow_2", show_points = TRUE, mean_line = TRUE)
    } else plot_means(d, "x", "y", show_points = TRUE, mean_line = TRUE)
    built <- ggplot2::ggplot_build(p)
    dots <- built$data[[1]]
    marker <- built$data[[3]]
    mean_points <- built$data[[4]]
    expect_equal(marker$ymin, mean_points$y)
    expect_equal(marker$ymax, mean_points$y)
    expect_equal(marker$x, mean_points$x)
    expect_equal(marker$colour, mean_points$colour)
    expect_true(all(vapply(seq_len(nrow(dots)), function(i) {
      m <- marker[marker$group == dots$group[i], ]
      m <- m[which.min(abs(m$x - dots$x[i])), ]
      dots$x[i] > m$xmin && dots$x[i] < m$xmax
    }, logical(1))))
    expect_no_warning(ggplot2::ggplotGrob(p))
  }
  p <- plot_means(d, "x", "y", mean_line = TRUE, mean_line_width = 0.9, error = "none")
  marker <- ggplot2::layer_data(p, 1)
  expect_equal(marker$xmax - marker$xmin, rep(0.9, 2))
  expect_length(p$layers, 2)
  expect_error(plot_means(d, "x", "y", mean_line = NA), "mean_line")
  expect_error(plot_means(d, "x", "y", mean_line_width = -1), "positive")
})

test_that("mean markers and dot presets support facets and separate legends", {
  d <- point_data()
  p <- plot_means(d, "x", "y", group = "task", show_points = TRUE,
                  point_preset = "colour_outlined", mean_line = TRUE, legend = "separate") +
    ggplot2::facet_wrap(~session)
  built <- ggplot2::ggplot_build(p)
  expect_equal(length(unique(built$data[[3]]$PANEL)), 2)
  expect_equal(built$data[[3]]$x, built$data[[4]]$x)
  expect_s3_class(plot_legend(p), "gtable")
  expect_no_warning(ggplot2::ggplotGrob(p))
})
