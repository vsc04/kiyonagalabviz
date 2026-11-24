tc <- data.frame(
  subject = rep(c("s1", "s2"), each = 6),
  load = factor(rep(c("easy", "hard"), times = 6), levels = c("easy", "hard")),
  time = rep(c(0, 0, 3, 3, 5, 5), times = 2),
  pupil = 1:12
)

test_that("only time points inside the window are averaged", {
  out <- average_window(tc, window = c(3, 5))
  s1_easy <- out$pupil[out$subject == "s1" & out$load == "easy"]
  expect_equal(s1_easy, mean(c(3, 5)))
  expect_equal(nrow(out), 4)
  expect_named(out, c("subject", "load", "pupil"))
})

test_that("factor levels are kept", {
  out <- average_window(tc, window = c(3, 5))
  expect_equal(levels(out$load), c("easy", "hard"))
})

test_that("bad windows and columns give informative errors", {
  expect_error(average_window(tc, window = c(5, 3)), "start < end")
  expect_error(average_window(tc, window = c(10, 20)), "No time points")
  expect_error(average_window(tc, value = "nope"), "not found")
})
