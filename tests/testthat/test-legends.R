test_that("all helpers support keeping, extracting and hiding legends", {
  d <- expand.grid(subject = 1:4, group = c("a", "b"), x = 1:5)
  d$y <- d$x + d$subject + as.integer(factor(d$group))
  calls <- list(
    function(...) plot_bars(d, "x", "y", group = "group", ...),
    function(...) plot_timecourse(d, "x", "y", group = "group", ...),
    function(...) plot_means(d, "x", "y", group = "group", ...),
    function(...) plot_predictions(d, "x", "y", group = "group", ...),
    function(...) plot_histogram(d, "y", group = "group", ...),
    function(...) plot_density(d, "y", group = "group", ...),
    function(...) plot_boxplots(d, "group", "y", group = "group", ...),
    function(...) plot_paired(d, "x", "y", subject = "subject", group = "group", ...),
    function(...) plot_lines(d, "x", "y", subject = "subject", group = "group", ...)
  )
  for (call in calls) {
    inside <- call(legend = "inside")
    expect_equal(inside$theme$legend.position, "top")
    separate <- call(legend = "separate") + ggplot2::labs(title = "Subject summaries")
    expect_s3_class(separate, "ggplot")
    expect_equal(separate$theme$legend.position, "none")
    expect_s3_class(plot_legend(separate), "gtable")
    expect_equal(call(legend = "none")$theme$legend.position, "none")
  }
})

test_that("separate legends export at intrinsic or custom dimensions", {
  skip_if_not_installed("svglite")
  d <- average_window(simulate_lab_data(n_subjects = 4)$timecourse)
  p <- plot_means(d, "load", "pupil", group = "load", legend = "separate")
  key <- plot_legend(p)
  f <- tempfile(fileext = ".svg")
  expect_no_error(nice_save(f, key))
  expect_gt(file.info(f)$size, 0)
  txt <- readLines(f)
  expect_true(any(grepl("easy", txt)))
  expect_true(any(grepl("hard", txt)))
  png <- tempfile(fileext = ".png")
  expect_no_error(nice_save(png, key, custom = c(2, 1), dpi = 72))
  expect_gt(file.info(png)$size, 0)
  expect_error(nice_save(f, key, font_size = 14), "source plot")
  expect_error(nice_save(f, key, custom = c(0, 1)), "positive")
  expect_error(plot_legend(plot_means(d, "load", "pupil")), "no legend")
})
