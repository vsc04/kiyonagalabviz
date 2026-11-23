test_that("all palette colours are valid hex codes", {
  cols <- unlist(kiyonaga_palettes)
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", cols)))
})

test_that("exact lab colours are used when n fits the palette", {
  pal <- make_kiyonaga_palette("greys")
  expect_equal(pal(2), c(kiyonaga_colors$GREY_LIGHT, kiyonaga_colors$GREY_DARK))
  expect_equal(pal(3), unname(kiyonaga_palettes$greys))
})

test_that("palette colours are interpolated when n exceeds the palette", {
  expect_length(make_kiyonaga_palette("sunset")(10), 10)
})

test_that("reverse and custom palettes work", {
  expect_equal(make_kiyonaga_palette("greys", reverse = TRUE)(1),
               kiyonaga_colors$GREY_DARK)
  expect_equal(make_kiyonaga_palette(c("#000000", "#FFFFFF"))(2),
               c("#000000", "#FFFFFF"))
})

test_that("unknown palettes give an informative error", {
  expect_error(make_kiyonaga_palette("nope"), "Available palettes")
})

test_that("scales return ggplot2 scales for both aesthetics", {
  expect_s3_class(scale_fill_kiyonaga("sunset_light"), "ScaleDiscrete")
  expect_s3_class(scale_colour_kiyonaga("sunset", discrete = FALSE),
                  "ScaleContinuous")
  expect_equal(scale_fill_kiyonaga()$aesthetics, "fill")
})

test_that("discrete scale maps levels to lab colours", {
  p <- ggplot2::ggplot(data.frame(x = c("a", "b"), y = 1:2),
                       ggplot2::aes(x, y, fill = x)) +
    ggplot2::geom_col() +
    scale_fill_kiyonaga("greys")
  fills <- ggplot2::layer_data(p)$fill
  expect_equal(fills, c(kiyonaga_colors$GREY_LIGHT, kiyonaga_colors$GREY_DARK))
})
