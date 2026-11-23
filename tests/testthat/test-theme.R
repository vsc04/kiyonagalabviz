test_that("theme uses the PI's sizes and greys", {
  th <- theme_kiyonaga()
  expect_true(ggplot2::is_theme(th))
  expect_equal(th$text$size, 8)
  expect_equal(th$axis.text$size, 6.8)
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
