sim <- simulate_lab_data(n_subjects = 8)

test_that("window, ribbon and line layers are drawn in that order", {
  p <- plot_timecourse(sim$timecourse, "time", "pupil", group = "load",
                       window = c(3, 5))
  geoms <- unname(vapply(p$layers, function(l) class(l$geom)[1], character(1)))
  expect_equal(geoms, c("GeomRect", "GeomRibbon", "GeomLine"))
  expect_no_error(ggplot2::ggplotGrob(p))
})

test_that("ribbons use alpha 0.4 and follow the mean +/- SE", {
  p <- plot_timecourse(sim$timecourse, "time", "pupil", group = "load")
  ribbon <- ggplot2::layer_data(p, 1)
  expect_true(all(ribbon$alpha == 0.4))
  t_last <- max(sim$timecourse$time)
  hard_last <- sim$timecourse[sim$timecourse$time == t_last &
                                sim$timecourse$load == "hard", "pupil"]
  r <- ribbon[ribbon$x == t_last & ribbon$group == 2, ]
  expect_equal(r$ymax, ggplot2::mean_se(hard_last)$ymax)
})

test_that("plot without group or window works", {
  p <- plot_timecourse(sim$timecourse, "time", "pupil", error = "ci")
  expect_length(p$layers, 2)
  expect_no_error(ggplot2::ggplotGrob(p))
})

test_that("invalid input gives informative errors", {
  expect_error(plot_timecourse(sim$timecourse, "time", "nope"), "not found")
  expect_error(plot_timecourse(sim$timecourse, "time", "pupil",
                               window = c(5, 3)), "start < end")
})
