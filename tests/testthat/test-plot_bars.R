d <- simulate_lab_data(n_subjects = 10)

test_that("simulated data has the expected shape and restores the RNG", {
  expect_equal(nrow(d), 10 * 4)
  expect_named(d, c("subject", "load", "difficulty", "beta"))
  set.seed(42); a <- stats::runif(1)
  set.seed(42); simulate_lab_data(); b <- stats::runif(1)
  expect_equal(a, b)
})

test_that("bars, points and error bars are drawn", {
  p <- plot_bars(d, "load", "beta", group = "difficulty")
  geoms <- unname(vapply(p$layers, function(l) class(l$geom)[1], character(1)))
  expect_equal(geoms, c("GeomCol", "GeomPoint", "GeomLinerange"))
  expect_no_error(ggplot2::ggplotGrob(p))
})

test_that("points and error bars can be switched off", {
  p <- plot_bars(d, "load", "beta", group = "difficulty",
                 show_points = FALSE, error = "none")
  expect_length(p$layers, 1)
})

test_that("bar heights are the condition means", {
  p <- plot_bars(d, "load", "beta", group = "difficulty", show_points = FALSE)
  bars <- ggplot2::layer_data(p, 1)
  means <- stats::aggregate(beta ~ difficulty + load, data = d, FUN = mean)
  expect_equal(sort(bars$y), sort(means$beta))
})

test_that("points are dodged into their own bar", {
  p <- plot_bars(d, "load", "beta", group = "difficulty")
  bars <- ggplot2::layer_data(p, 1)
  pts <- ggplot2::layer_data(p, 2)
  inside_own_bar <- vapply(seq_len(nrow(pts)), function(i) {
    b <- bars[bars$group == pts$group[i], ]
    b <- b[which.min(abs(b$x - pts$x[i])), ]
    pts$x[i] >= b$xmin && pts$x[i] <= b$xmax
  }, logical(1))
  expect_true(all(inside_own_bar))
})

test_that("error types give the right bounds", {
  x <- c(1, 2, 3, 4)
  expect_equal(mean_sd(x)$ymax, mean(x) + sd(x))
  half <- qt(0.975, 3) * sd(x) / 2
  expect_equal(mean_ci(x)$ymin, mean(x) - half)
})

test_that("plot without a group works", {
  p <- plot_bars(d, "load", "beta", error = "sd")
  expect_no_error(ggplot2::ggplotGrob(p))
})

test_that("invalid input gives informative errors", {
  expect_error(plot_bars(d, "load", "nope"), "not found")
  expect_error(plot_bars(d, "load", "subject"), "numeric")
})
