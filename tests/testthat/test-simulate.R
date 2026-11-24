sim <- simulate_lab_data(n_subjects = 10, duration = 5, sampling_rate = 20)

test_that("simulation returns timecourse and behaviour tables", {
  expect_named(sim, c("timecourse", "behavior"))
  expect_named(sim$timecourse, c("subject", "load", "time", "pupil"))
  expect_named(sim$behavior, c("subject", "load", "accuracy"))
})

test_that("timecourse covers 0-5 s for every subject and load", {
  n_time <- 5 * 20 + 1
  expect_equal(nrow(sim$timecourse), 10 * 2 * n_time)
  expect_equal(range(sim$timecourse$time), c(0, 5))
  expect_equal(levels(sim$timecourse$load), c("easy", "hard"))
})

test_that("hard load gives a larger pupil response late in the delay", {
  late <- average_window(sim$timecourse, window = c(3, 5))
  means <- tapply(late$pupil, late$load, mean)
  expect_gt(means[["hard"]], means[["easy"]])
})

test_that("accuracy is a proportion", {
  expect_true(all(sim$behavior$accuracy >= 0 & sim$behavior$accuracy <= 1))
})

test_that("simulation is reproducible and restores the RNG state", {
  expect_identical(simulate_lab_data(seed = 2), simulate_lab_data(seed = 2))
  set.seed(42); a <- stats::runif(1)
  set.seed(42); simulate_lab_data(); b <- stats::runif(1)
  expect_equal(a, b)
})
