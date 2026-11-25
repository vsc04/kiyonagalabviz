subgroup_data <- function() {
  d <- expand.grid(task = c("A", "B"), session = c("first", "second"),
                   time = 1:3, subject = 1:4)
  d$task <- factor(d$task, levels = c("B", "A"))
  d$session <- factor(d$session, levels = c("second", "first"))
  d$value <- as.integer(d$task) * 100 + as.integer(d$session) * 10 + d$time + d$subject
  d
}

test_that("group and subgroup select hue and shade in factor order", {
  d <- subgroup_data()
  expected <- make_kiyonaga_palette("blue_yellow_2", condition_groups = 2)(4)
  labels <- c("B / second", "B / first", "A / second", "A / first")
  p <- plot_bars(d, "time", "value", group = "task", subgroup = "session",
                 palette = "blue_yellow_2")
  built <- ggplot2::ggplot_build(p)
  scale <- built$plot$scales$get_scales("fill")
  expect_equal(scale$get_limits(), labels)
  expect_equal(unname(scale$map(labels)), expected)
  means <- stats::aggregate(value ~ task + session + time, d, mean)
  expect_equal(sort(built$data[[1]]$y), sort(means$value))
  expect_length(unique(built$data[[1]]$x), 12)
  expect_equal(p$theme$aspect.ratio, 3.10 / 12)
  expect_equal(p$labels$fill, "task / session")
  points <- built$data[[2]]
  bars <- built$data[[1]]
  expect_true(all(vapply(seq_len(nrow(points)), function(i) {
    b <- bars[bars$group == points$group[i], ]
    b <- b[which.min(abs(b$x - points$x[i])), ]
    points$x[i] >= b$xmin && points$x[i] <= b$xmax
  }, logical(1))))
  expect_no_error(ggplot2::ggplotGrob(p))
})

test_that("timecourse lines and ribbons summarize each group and subgroup", {
  d <- subgroup_data()
  p <- plot_timecourse(d, "time", "value", group = "task", subgroup = "session",
                       palette = "blue_yellow_2")
  built <- ggplot2::ggplot_build(p)
  ribbons <- built$data[[1]]
  lines <- built$data[[2]]
  expected <- make_kiyonaga_palette("blue_yellow_2", condition_groups = 2)(4)
  expect_equal(unique(lines$colour), expected)
  expect_equal(unique(ribbons$fill), expected)
  expect_true(all(ribbons$alpha == 0.4))
  expect_equal(length(unique(lines$group)), 4)
  means <- stats::aggregate(value ~ task + session + time, d, mean)
  expect_equal(sort(lines$y), sort(means$value))
  expect_no_error(ggplot2::ggplotGrob(p))
})

test_that("missing combinations and facets do not shift shade assignments", {
  d <- subgroup_data()
  d <- d[!(d$task == "B" & d$session == "first"), ]
  # Internal grouping must not replace a user's column with the same name.
  d$.kiyonaga_group <- d$subject
  p <- plot_timecourse(d, "time", "value", group = "task", subgroup = "session",
                       palette = "blue_yellow_2") + ggplot2::facet_wrap(~task)
  built <- ggplot2::ggplot_build(p)
  expected <- make_kiyonaga_palette("blue_yellow_2", condition_groups = 2)(4)
  expect_setequal(built$data[[2]]$colour, expected[c(1, 3, 4)])
  expect_equal(p$data$.kiyonaga_group, d$subject)
  expect_length(built$plot$scales$get_scales("colour")$get_limits(), 4)
})

test_that("three subgroup shades and character ordering work", {
  d <- expand.grid(task = c("C", "A", "B"), session = c("third", "first", "second"),
                   time = 1:2, subject = 1:3, stringsAsFactors = FALSE)
  d$value <- seq_len(nrow(d))
  p <- plot_timecourse(d, "time", "value", group = "task", subgroup = "session",
                       palette = "accent_3")
  built <- ggplot2::ggplot_build(p)
  expect_equal(unique(built$data[[2]]$colour),
               make_kiyonaga_palette("accent_3", condition_groups = 3)(9))
  expect_equal(built$plot$scales$get_scales("colour")$get_limits()[1:3],
               c("A / first", "A / second", "A / third"))
})

test_that("subgroup inputs are validated in both plotting helpers", {
  d <- subgroup_data()
  for (plot in list(plot_bars, plot_timecourse)) {
    expect_error(plot(d, "time", "value", subgroup = "session"), "requires `group`")
    expect_error(plot(d, "time", "value", group = "task", subgroup = "missing"), "not found")
    expect_error(plot(d, "time", "value", group = "task", subgroup = "task"), "different")
    expect_error(plot(d, "time", "value", group = "task", subgroup = "session",
                      palette = "blue_yellow_2", condition_groups = 3), "must match")
    expect_error(plot(d, "time", "value", group = "task", subgroup = "session",
                      palette = "accent_3"), "supports")
    expect_error(plot(d, "time", "value", group = "task", subgroup = "session",
                      palette = "greys"), "main palette")
  }
  d$session <- factor(d$subject)
  expect_error(plot_bars(d, "time", "value", group = "task", subgroup = "session",
                         palette = "blue_yellow_2"), "must be 2, 3")
  d$session <- factor(rep(c("a", "b"), length.out = nrow(d)))
  d$task <- factor(d$subject)
  expect_error(plot_bars(d, "time", "value", group = "task", subgroup = "session",
                         palette = "blue_yellow_2"), "at most")
})
