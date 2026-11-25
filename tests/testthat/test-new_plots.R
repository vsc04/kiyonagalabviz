plot_test_data <- function() {
  d <- expand.grid(subject = factor(1:6), task = factor(c("B", "A"), levels = c("B", "A")),
                   session = factor(c("late", "early"), levels = c("late", "early")),
                   x = 1:6)
  d$y <- as.integer(d$subject) + d$x * as.integer(d$task) + as.integer(d$session) * 3
  d
}

test_that("mean points summarize each condition and retain individual points", {
  d <- plot_test_data()
  p <- plot_means(d, "task", "y", group = "task", subgroup = "session",
                  palette = "blue_yellow_2", show_points = TRUE, error = "ci")
  built <- ggplot2::ggplot_build(p)
  means <- stats::aggregate(y ~ task + session, d, mean)
  expect_equal(sort(built$data[[3]]$y), sort(means$y))
  expect_equal(nrow(built$data[[1]]), nrow(d))
  expect_equal(sort(unique(built$data[[3]]$colour)),
               sort(make_kiyonaga_palette("blue_yellow_2", condition_groups = 2)(4)))
  expect_equal(built$data[[2]]$linewidth, rep(0.5, 4))
  expect_length(plot_means(d, "task", "y", error = "none")$layers, 1)
  expect_no_warning(ggplot2::ggplotGrob(p))
})

test_that("fits use all rows and binned observations have correct intervals", {
  d <- data.frame(x = 1:20, y = (1:20)^2 + rep(c(-1, 1), 10))
  p <- plot_predictions(d, "x", "y", bins = 5)
  built <- ggplot2::ggplot_build(p)
  fit <- stats::lm(y ~ x, d)
  expect_equal(built$data[[1]]$y,
               unname(stats::predict(fit, data.frame(x = built$data[[1]]$x))))
  expect_equal(built$data[[3]]$x, seq(2.5, 18.5, by = 4))
  expected <- mean_ci(d$y[1:4])
  expect_equal(built$data[[2]]$ymin[1], expected$ymin)
  expect_equal(built$data[[2]]$ymax[1], expected$ymax)
  expect_equal(built$data[[3]]$y[1], mean(d$y[1:4]))
  expect_no_warning(ggplot2::ggplotGrob(p))
  no_bins <- plot_predictions(d, "x", "y", bins = NULL, confidence = FALSE)
  expect_length(no_bins$layers, 1)
  expect_false("ymin" %in% names(ggplot2::layer_data(no_bins)))
})

test_that("quantile bins, tied predictors and singleton bins remain usable", {
  d <- data.frame(x = c(1:9, 100), y = 1:10)
  p <- plot_predictions(d, "x", "y", bins = 2, bin_method = "quantile")
  expect_equal(ggplot2::layer_data(p, 3)$y, c(3, 8))
  one <- StatKiyonagaBins$compute_group(data.frame(x = rep(1, 4), y = 1:4), NULL,
                                       bins = 5, bin_method = "quantile")
  expect_equal(one$y, 2.5)
  p <- plot_predictions(d, "x", "y", bins = 20)
  expect_true(anyNA(ggplot2::layer_data(p, 2)$ymin))
  expect_no_warning(ggplot2::ggplotGrob(p))
})

test_that("precomputed predictions and confidence limits are drawn unchanged", {
  d <- plot_test_data()
  pred <- unique(d[c("task", "session", "x")])
  pred$y <- pred$x * 5
  pred$lower <- pred$y - 2
  pred$upper <- pred$y + 3
  p <- plot_predictions(d, "x", "y", group = "task", subgroup = "session",
                        predictions = pred, palette = "blue_yellow_2")
  built <- ggplot2::ggplot_build(p)
  expect_equal(sort(built$data[[1]]$ymin), sort(pred$lower))
  expect_equal(sort(built$data[[1]]$ymax), sort(pred$upper))
  expect_equal(sort(built$data[[2]]$y), sort(pred$y))
  expect_setequal(built$data[[2]]$colour,
                  make_kiyonaga_palette("blue_yellow_2", condition_groups = 2)(4))
  expect_no_warning(ggplot2::ggplotGrob(p))
  expect_error(plot_predictions(d, "x", "y", predictions = pred[-5]), "not found")
  pred$task <- "unknown"
  expect_error(plot_predictions(d, "x", "y", group = "task", predictions = pred), "Unknown")
})

test_that("fitting and binning respect added facets", {
  d <- plot_test_data()
  p <- plot_predictions(d, "x", "y", group = "session") + ggplot2::facet_wrap(~task)
  built <- ggplot2::ggplot_build(p)
  expect_equal(length(unique(built$data[[1]]$PANEL)), 2)
  expect_equal(length(unique(built$data[[3]]$PANEL)), 2)
  expect_no_warning(ggplot2::ggplotGrob(p))
})

test_that("histograms count observations and density overlays use density units", {
  d <- plot_test_data()
  p <- plot_histogram(d, "y", group = "task", bins = 10)
  expect_equal(sum(ggplot2::layer_data(p)$count), nrow(d))
  overlay <- plot_histogram(d, "y", bins = 10, density = TRUE)
  hist <- ggplot2::layer_data(overlay, 1)
  expect_equal(hist$y, hist$density)
  expect_length(overlay$layers, 2)
  expect_no_warning(ggplot2::ggplotGrob(overlay))
  density <- plot_density(d, "y", group = "task", subgroup = "session",
                          palette = "blue_yellow_2")
  expect_setequal(ggplot2::layer_data(density)$colour,
                  make_kiyonaga_palette("blue_yellow_2", condition_groups = 2)(4))
  expect_no_warning(ggplot2::ggplotGrob(density))
})

test_that("boxplots have medians, whiskers and no duplicate outliers", {
  d <- data.frame(x = rep(c("a", "b"), each = 10), y = c(1:9, 100, 11:20))
  p <- plot_boxplots(d, "x", "y")
  box <- ggplot2::layer_data(p)
  expect_equal(box$middle, c(5.5, 15.5))
  expect_equal(box$ymax[1], 9)
  expect_true(is.na(p$layers[[1]]$geom_params$outlier_gp$shape))
  expect_equal(nrow(ggplot2::layer_data(p, 2)), nrow(d))
  expect_length(plot_boxplots(d, "x", "y", show_points = FALSE)$layers, 1)
  expect_no_warning(ggplot2::ggplotGrob(p))
})

test_that("paired plots average repeated subject observations and connect correctly", {
  d <- plot_test_data()
  p <- plot_paired(d, "task", "y", subject = "subject", group = "task",
                   subgroup = "session", palette = "blue_yellow_2")
  built <- ggplot2::ggplot_build(p)
  means <- stats::aggregate(y ~ task + subject + session, d, mean)
  expect_equal(sort(built$data[[2]]$y), sort(means$y))
  expect_equal(nrow(built$data[[2]]), 24)
  expect_true(all(table(built$data[[1]]$group) == 2))
  expect_equal(length(unique(built$data[[1]]$group)), 12)
  expect_no_warning(ggplot2::ggplotGrob(p))
})

test_that("rolling windows use x units within each subject before averaging", {
  d <- expand.grid(subject = c("s1", "s2"), x = c(0, 1, 4))
  d$y <- ifelse(d$subject == "s1", d$x^2, d$x^2 + 10)
  # Unequal replication at a subject/time must not change the subject's weight.
  d <- rbind(d, d[1, ], d[1, ])
  p <- plot_lines(d, "x", "y", subject = "subject", rolling_window = 2)
  line <- ggplot2::layer_data(p, 2)
  expect_equal(line$y, c(5.5, 5.5, 21))
  ribbon <- ggplot2::layer_data(p, 1)
  expect_equal(ribbon$ymax - ribbon$ymin, rep(10, 3))
  expect_no_warning(ggplot2::ggplotGrob(p))
  expect_warning(ggplot2::ggplot_build(plot_lines(d, "x", "y", rolling_window = 2, error = "none")),
                 "requires a `subject`")
  one <- data.frame(x = c(0, 1, 4), y = c(0, 1, 16))
  p <- plot_lines(one, "x", "y", rolling_window = 2, error = "none")
  expect_equal(ggplot2::layer_data(p)$y, c(0.5, 0.5, 16))
  p <- plot_lines(d, "x", "y", subject = "subject")
  expect_equal(ggplot2::layer_data(p, 2)$y, c(5, 6, 21))
})

test_that("invalid statistical options fail clearly", {
  expect_error(plot_predictions(mtcars, "wt", "mpg", bins = 0), "positive")
  expect_error(plot_predictions(mtcars, "wt", "mpg", conf = 1), "conf")
  expect_error(plot_histogram(mtcars, "mpg", binwidth = -1), "positive")
  expect_error(plot_density(mtcars, "mpg", fill_alpha = 2), "between")
  expect_error(plot_lines(mtcars, "wt", "mpg", rolling_window = 0), "positive")
})


test_that("subject summaries and rolling windows respect added facets", {
  d <- plot_test_data()
  # Facet by a variable supplied separately from the colour groups.
  p <- plot_lines(d, "x", "y", subject = "subject", group = "task",
                   rolling_window = 2) + ggplot2::facet_wrap(~session)
  built <- ggplot2::ggplot_build(p)
  expect_equal(length(unique(built$data[[2]]$PANEL)), 2)
  expect_equal(built$data[[2]]$y[built$data[[2]]$PANEL == 2] -
                 built$data[[2]]$y[built$data[[2]]$PANEL == 1], rep(3, 12))
  expect_no_warning(ggplot2::ggplotGrob(p))
  paired <- plot_paired(d, "task", "y", subject = "subject") +
    ggplot2::facet_wrap(~session)
  built <- ggplot2::ggplot_build(paired)
  expect_equal(nrow(built$data[[2]]), 24)
  expect_equal(length(unique(built$data[[1]]$PANEL)), 2)
  expect_no_warning(ggplot2::ggplotGrob(paired))
})

test_that("binned error options change intervals without changing fits or means", {
  d <- data.frame(x = 1:12, y = c(1, 2, 5, 8, 3, 5, 8, 9, 7, 8, 10, 14))
  baseline <- ggplot2::ggplot_build(plot_predictions(d, "x", "y", bins = 3, conf = 0.8))
  for (error in c("se", "sd", "ci")) {
    p <- plot_predictions(d, "x", "y", bins = 3, error = error, conf = 0.8)
    built <- ggplot2::ggplot_build(p)
    values <- d$y[1:4]
    half_width <- switch(error, se = stats::sd(values) / 2, sd = stats::sd(values),
                         ci = stats::qt(0.9, 3) * stats::sd(values) / 2)
    expect_equal(built$data[[2]]$ymin[1], mean(values) - half_width)
    expect_equal(built$data[[2]]$ymax[1], mean(values) + half_width)
    expect_equal(built$data[[3]]$y, baseline$data[[3]]$y)
    expect_equal(built$data[[1]], baseline$data[[1]])
    expect_no_warning(ggplot2::ggplotGrob(p))
  }
  p <- plot_predictions(d, "x", "y", bins = 3, error = "none", conf = 0.8)
  built <- ggplot2::ggplot_build(p)
  expect_length(p$layers, 2)
  expect_equal(built$data[[2]]$y, baseline$data[[3]]$y)
  expect_equal(built$data[[1]], baseline$data[[1]])
  expect_no_warning(ggplot2::ggplotGrob(p))
  p <- plot_predictions(d, "x", "y", error = "sd", confidence = FALSE)
  expect_false("ymin" %in% names(ggplot2::layer_data(p, 1)))
  expect_true("ymin" %in% names(ggplot2::layer_data(p, 2)))
  expect_error(plot_predictions(d, "x", "y", error = "invalid"), "arg")
})

test_that("binned uncertainty respects groups, facets and supplied predictions", {
  d <- plot_test_data()
  p <- plot_predictions(d, "x", "y", group = "task", bins = 3, error = "sd") +
    ggplot2::facet_wrap(~session)
  built <- ggplot2::ggplot_build(p)
  expected <- stats::sd(d$y[d$task == "B" & d$session == "late" & d$x <= 2])
  expect_equal(built$data[[2]]$ymax[1] - built$data[[2]]$y[1], expected)
  expect_equal(length(unique(built$data[[2]]$PANEL)), 2)
  pred <- data.frame(x = 1:6, y = 1:6, lower = 0:5, upper = 2:7)
  p <- plot_predictions(d, "x", "y", predictions = pred, error = "none")
  built <- ggplot2::ggplot_build(p)
  expect_equal(built$data[[1]]$ymin, pred$lower)
  expect_equal(built$data[[1]]$ymax, pred$upper)
  expect_length(p$layers, 3)
  expect_no_warning(ggplot2::ggplotGrob(p))
})
