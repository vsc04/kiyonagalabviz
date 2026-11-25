scatter_data <- function() {
  d <- expand.grid(x = 1:8, task = factor(c("B", "A"), levels = c("B", "A")),
                   session = factor(c("late", "early"), levels = c("late", "early")), subject = 1:5)
  d$y <- d$x * as.integer(d$task) + as.integer(d$session) + sin(d$subject * 2)
  d
}

test_that("scatterplots preserve observations without binning or jitter", {
  d <- scatter_data()
  p <- plot_scatter(d, "x", "y")
  dots <- ggplot2::layer_data(p)
  expect_length(p$layers, 1)
  expect_equal(dots$x, as.numeric(d$x))
  expect_equal(dots$y, d$y)
  expect_equal(nrow(dots), nrow(d))
  expect_equal(unique(dots$shape), 21)
  expect_equal(unique(dots$size), 1.5)
  expect_equal(unique(dots$alpha), 0.8)
  expect_equal(unique(dots$colour), kiyonaga_colors$GREY_MID)
  expect_equal(p$theme$aspect.ratio, 0.92)
  expect_no_warning(ggplot2::ggplotGrob(p))
})

test_that("scatter hue and shade follow group and subgroup levels", {
  d <- scatter_data()
  p <- plot_scatter(d, "x", "y", group = "task", subgroup = "session",
                    palette = "blue_yellow_2", fit = TRUE, point_preset = "colour_outlined")
  built <- ggplot2::ggplot_build(p)
  colours <- make_kiyonaga_palette("blue_yellow_2", condition_groups = 2)(4)
  expect_setequal(built$data[[2]]$fill, colours)
  expect_setequal(built$data[[1]]$colour, colours)
  expect_equal(built$plot$scales$get_scales("colour")$get_limits(),
               c("B / late", "B / early", "A / late", "A / early"))
  expect_no_warning(ggplot2::ggplotGrob(p))
})

test_that("scatter fits use all observations and confidence is independent of points", {
  d <- scatter_data()
  p <- plot_scatter(d, "x", "y", group = "task", fit = TRUE, conf = 0.8)
  built <- ggplot2::ggplot_build(p)
  for (i in 1:2) {
    rows <- built$data[[1]][built$data[[1]]$group == i, ]
    model <- stats::lm(y ~ x, d[as.integer(d$task) == i, ])
    expected <- stats::predict(model, data.frame(x = rows$x), interval = "confidence", level = 0.8)
    expect_equal(rows$y, unname(expected[, "fit"]))
    expect_equal(rows$ymin, unname(expected[, "lwr"]))
    expect_equal(rows$ymax, unname(expected[, "upr"]))
  }
  p_no_band <- plot_scatter(d, "x", "y", group = "task", fit = TRUE, confidence = FALSE)
  expect_false("ymin" %in% names(ggplot2::layer_data(p_no_band, 1)))
  expect_equal(ggplot2::layer_data(p_no_band, 2)$y, built$data[[2]]$y)
  expect_no_warning(ggplot2::ggplotGrob(p_no_band))
})

test_that("scatter styles allow presets and explicit overrides", {
  d <- scatter_data()
  p <- plot_scatter(d, "x", "y", group = "task", point_preset = "colour_outlined")
  dots <- ggplot2::layer_data(p)
  expect_equal(unique(dots$shape), 21)
  expect_equal(unique(dots$size), 1.5)
  expect_setequal(dots$fill, make_kiyonaga_palette("accent")(2))
  p <- plot_scatter(d, "x", "y", point_preset = "grey_filled", point_size = 2)
  expect_equal(unique(ggplot2::layer_data(p)$size), 2)
  p <- plot_scatter(d, "x", "y", point_size = 2,
                    point_style = list(size = 1.5, shape = 23, fill = "red", alpha = 0.4))
  dots <- ggplot2::layer_data(p)
  expect_equal(unique(dots$size), 1.5)
  expect_equal(unique(dots$shape), 23)
  expect_equal(unique(dots$fill), "red")
  expect_equal(unique(dots$alpha), 0.4)
  expect_no_warning(ggplot2::ggplotGrob(p))
})

test_that("scatterplots support facets, finite coordinates and separate export", {
  d <- scatter_data()
  d$x[1] <- Inf
  d$y[2] <- NA
  p <- plot_scatter(d, "x", "y", group = "task", fit = TRUE, legend = "separate") +
    ggplot2::facet_wrap(~session)
  built <- ggplot2::ggplot_build(p)
  expect_equal(nrow(built$data[[2]]), nrow(d) - 2)
  expect_equal(length(unique(built$data[[2]]$PANEL)), 2)
  expect_equal(length(unique(built$data[[1]]$PANEL)), 2)
  expect_equal(p$theme$legend.position, "none")
  expect_no_warning(key <- plot_legend(p))
  expect_s3_class(key, "gtable")
  f <- tempfile(fileext = ".png")
  expect_no_error(nice_save(f, key, dpi = 72))
  expect_gt(file.info(f)$size, 0)
  expect_no_warning(ggplot2::ggplotGrob(p))
})

test_that("scatter fits accept alternative methods and formulas", {
  p <- plot_scatter(mtcars, "wt", "mpg", fit = TRUE, formula = y ~ poly(x, 2))
  expect_no_warning(ggplot2::ggplotGrob(p))
  p <- plot_scatter(mtcars, "wt", "am", fit = TRUE, method = "glm",
                    method_args = list(family = stats::binomial()))
  fit <- ggplot2::layer_data(p, 1)
  expect_true(all(fit$y >= 0 & fit$y <= 1))
  expect_no_warning(ggplot2::ggplotGrob(p))
})

test_that("invalid scatter input fails clearly", {
  expect_error(plot_scatter(mtcars, "wt", "missing"), "not found")
  expect_error(plot_scatter(transform(mtcars, mpg = as.character(mpg)), "wt", "mpg"), "numeric")
  expect_error(plot_scatter(mtcars, "wt", "mpg", group = "wt"), "distinct")
  expect_error(plot_scatter(mtcars, "wt", "mpg", subgroup = "am"), "requires")
  expect_error(plot_scatter(mtcars, "wt", "mpg", fit = NA), "fit")
  expect_error(plot_scatter(mtcars, "wt", "mpg", point_size = -1), "positive")
  expect_error(plot_scatter(mtcars, "wt", "mpg", conf = 2), "conf")
  expect_error(plot_scatter(mtcars, "wt", "mpg", point_preset = "missing"), "point_preset")
})
