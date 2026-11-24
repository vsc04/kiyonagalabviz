sim <- simulate_lab_data(n_subjects = 10)
d <- average_window(sim$timecourse, window = c(3, 5))
# a second factor to test dodging of grouped bars
d$session <- ifelse(as.integer(factor(d$subject)) %% 2 == 0, "S1", "S2")

test_that("bars, points and error bars are drawn", {
  p <- plot_bars(d, "load", "pupil", group = "session")
  geoms <- unname(vapply(p$layers, function(l) class(l$geom)[1], character(1)))
  expect_equal(geoms, c("GeomCol", "GeomPoint", "GeomLinerange"))
  expect_no_error(ggplot2::ggplotGrob(p))
})

test_that("points and error bars can be switched off", {
  p <- plot_bars(d, "load", "pupil", group = "session",
                 show_points = FALSE, error = "none")
  expect_length(p$layers, 1)
})

test_that("bar heights are the condition means", {
  p <- plot_bars(d, "load", "pupil", group = "session", show_points = FALSE)
  bars <- ggplot2::layer_data(p, 1)
  means <- stats::aggregate(pupil ~ session + load, data = d, FUN = mean)
  expect_equal(sort(bars$y), sort(means$pupil))
})

test_that("points are dodged into their own bar", {
  p <- plot_bars(d, "load", "pupil", group = "session")
  bars <- ggplot2::layer_data(p, 1)
  pts <- ggplot2::layer_data(p, 2)
  inside_own_bar <- vapply(seq_len(nrow(pts)), function(i) {
    b <- bars[bars$group == pts$group[i], ]
    b <- b[which.min(abs(b$x - pts$x[i])), ]
    pts$x[i] >= b$xmin && pts$x[i] <= b$xmax
  }, logical(1))
  expect_true(all(inside_own_bar))
})

test_that("load as both x and group gives light/dark grey bars", {
  p <- plot_bars(d, "load", "pupil", group = "load")
  fills <- unique(ggplot2::layer_data(p, 1)$fill)
  expect_equal(fills, c(kiyonaga_colors$GREY_LIGHT, kiyonaga_colors$GREY_DARK))
})

test_that("error types give the right bounds", {
  x <- c(1, 2, 3, 4)
  expect_equal(mean_sd(x)$ymax, mean(x) + sd(x))
  half <- qt(0.975, 3) * sd(x) / 2
  expect_equal(mean_ci(x)$ymin, mean(x) - half)
})

test_that("plot without a group works", {
  p <- plot_bars(d, "load", "pupil", error = "sd")
  expect_no_error(ggplot2::ggplotGrob(p))
})

test_that("invalid input gives informative errors", {
  expect_error(plot_bars(d, "load", "nope"), "not found")
  expect_error(plot_bars(d, "load", "subject"), "numeric")
})
