p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
  ggplot2::geom_point() +
  ggplot2::labs(title = "Title") +
  theme_kiyonaga() +
  ggplot2::theme(legend.position = "none")

text_size <- function(plot, element) {
  ggplot2::calc_element(element, plot$theme)$size
}

test_that("resizing scales titles and tick labels together", {
  big <- resize_text(p, 14)
  expect_equal(text_size(big, "plot.title"), 14)
  expect_equal(text_size(big, "axis.title.x.bottom"), 14)
  expect_equal(text_size(big, "axis.text.x.bottom"), 14 * 0.85)
})

test_that("resizing keeps other theme settings", {
  big <- resize_text(p, 14)
  expect_equal(big$theme$legend.position, "none")
  expect_equal(big$theme$axis.text$colour, kiyonaga_colors$GREY_TEXT)
})

test_that("layouts have the right default font sizes", {
  expect_equal(layout_font_size("slides"), 14)
  expect_equal(layout_font_size("tiny"), 6)
  expect_null(layout_font_size("full col"))
  expect_error(resize_text(p, -1), "positive")
})

test_that("larger text takes more room around the panel; slide height is fixed", {
  small <- non_panel_size(resize_text(p, 8))
  big <- non_panel_size(resize_text(p, 14))
  expect_gt(big$h, small$h)
  expect_gt(big$w, small$w)
  expect_equal(figure_dims(resize_text(p, 14), "slides", NULL)$height, 4.4)
})

test_that("files are written for slides and tiny layouts", {
  f_slides <- tempfile(fileext = ".png")
  f_tiny <- tempfile(fileext = ".pdf")
  expect_message(nice_save(f_slides, p, layout = "slides", dpi = 72), "Saving")
  expect_message(nice_save(f_tiny, p, layout = "tiny"), "Saving")
  expect_true(file.exists(f_slides) && file.exists(f_tiny))
})
