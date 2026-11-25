test_that("theme uses the PI's sizes and greys", {
  th <- theme_kiyonaga()
  expect_true(ggplot2::is_theme(th))
  expect_equal(th$text$size, 8)
  expect_equal(ggplot2::calc_element("axis.text.x.bottom", th)$size, 6.8)
  expect_equal(ggplot2::calc_element("plot.title", th)$size, 8)
  expect_equal(th$axis.text$colour, kiyonaga_colors$GREY_TEXT)
  expect_equal(th$axis.line$colour, kiyonaga_colors$GREY_AXIS)
  expect_equal(th$legend.position, "top")
})

test_that("ticks are off by default and can be switched on", {
  expect_true(ggplot2::is_theme_element(theme_kiyonaga()$axis.ticks, "blank"))
  expect_true(
    ggplot2::is_theme_element(theme_kiyonaga(ticks = TRUE)$axis.ticks, "line")
  )
})

test_that("missing fonts fall back to sans with a warning", {
  expect_warning(th <- theme_kiyonaga(font = "NotARealFont123"), "not installed")
  expect_equal(th$text$family, "sans")
})

test_that("a themed plot builds without error", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() +
    theme_kiyonaga(grid = TRUE, debug_area = TRUE)
  expect_no_error(ggplot2::ggplotGrob(p))
})

test_that("tick direction and length preserve the logical API", {
  expect_equal(theme_kiyonaga(ticks = "off"), theme_kiyonaga(ticks = FALSE))
  expect_equal(theme_kiyonaga(ticks = "outside"), theme_kiyonaga(ticks = TRUE))
  for (direction in c("inside", "outside", "off")) {
    th <- theme_kiyonaga(ticks = direction, tick_length = 3)
    length <- grid::convertUnit(th$axis.ticks.length, "pt", valueOnly = TRUE)
    expect_equal(length, switch(direction, inside = -3, outside = 3, off = 0))
    expect_equal(ggplot2::calc_element("axis.text.x.bottom", th)$size, 6.8)
    if (direction != "off") {
      expect_equal(th$axis.ticks$linewidth, th$axis.line$linewidth)
      expect_equal(th$axis.ticks$colour, th$axis.line$colour)
    }
    p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point() + th
    expect_no_warning(ggplot2::ggplotGrob(p))
    top_right <- p + ggplot2::scale_x_continuous(position = "top") +
      ggplot2::scale_y_continuous(position = "right")
    expect_no_warning(ggplot2::ggplotGrob(top_right))
    expect_equal(ggplot2::calc_element("axis.text.x.top", th)$margin[3],
                 ggplot2::margin(b = 3)[3])
  }
})

test_that("tick settings pass through plotting helpers", {
  d <- average_window(simulate_lab_data(n_subjects = 4)$timecourse)
  p <- plot_bars(d, "load", "pupil", ticks = "inside", tick_length = 4)
  expect_equal(grid::convertUnit(p$theme$axis.ticks.length, "pt", valueOnly = TRUE), -4)
  expect_no_warning(ggplot2::ggplotGrob(p))
  map <- expand.grid(x = 1:2, y = 1:2)
  map$value <- 1:4
  p <- plot_heatmap(map, "x", "y", "value", ticks = "inside", show_axes = FALSE)
  expect_s3_class(ggplot2::calc_element("axis.ticks.x.bottom", p$theme), "element_blank")
  expect_s3_class(ggplot2::calc_element("axis.text.x.top", p$theme), "element_blank")
  expect_s3_class(ggplot2::calc_element("axis.text.y.right", p$theme), "element_blank")
})

test_that("invalid tick options give useful errors", {
  for (value in list(NA, NULL, 1, "inwards", c("inside", "outside"))) {
    expect_error(theme_kiyonaga(ticks = value), "ticks")
  }
  for (value in list(0, -1, NA, Inf, "long")) {
    expect_error(theme_kiyonaga(ticks = "inside", tick_length = value), "tick_length")
  }
})
