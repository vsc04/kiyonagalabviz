test_that("plot presets contain ratios and no paper-specific size or font settings", {
  ratios <- c(bars = 1.55, bars_tall = 3.08, timecourse = 0.68,
               scatter = 0.92, distribution = 1, heatmap = 1)
  for (name in names(ratios)) {
    preset <- kiyonaga_plot_presets[[name]]
    expect_equal(preset$size_type, "ratio")
    expect_equal(preset$aspect_ratio, unname(ratios[[name]]))
    expect_setequal(names(preset), if (name %in% c("bars", "bars_tall")) {
      c("size_type", "aspect_ratio", "reference_bars")
    } else c("size_type", "aspect_ratio"))
    th <- theme_kiyonaga(preset = name)
    expect_equal(th$text$size, 8)
    expect_equal(ggplot2::calc_element("axis.text", th)$size, 6.8)
    expect_equal(th$aspect.ratio, unname(ratios[[name]]))
  }
  expect_false("timecourse_compact" %in% names(kiyonaga_plot_presets))
})

test_that("bar ratios scale inversely with the number of displayed bars", {
  for (n in c(1, 2, 4, 6, 12)) {
    expect_equal(theme_kiyonaga(preset = "bars", n_bars = n)$aspect.ratio, 3.10 / n)
    expect_equal(theme_kiyonaga(preset = "bars_tall", n_bars = n)$aspect.ratio, 6.16 / n)
  }
  for (n in list(0, -1, 2.5, Inf, NA_real_, c(2, 4), "4")) {
    expect_error(theme_kiyonaga(preset = "bars", n_bars = n), "n_bars")
  }
  expect_equal(theme_kiyonaga(preset = "scatter", n_bars = 6)$aspect.ratio, 0.92)
  expect_equal(theme_kiyonaga(preset = "bars", n_bars = 4,
                             aspect_ratio = 0.5, font_size = 12)$aspect.ratio, 0.5)
  expect_equal(theme_kiyonaga(preset = "scatter", font_size = 12)$text$size, 12)
  expect_error(theme_kiyonaga(preset = "typo"), "preset")
})

bar_preset_data <- expand.grid(subject = 1:3, load = c("easy", "hard"),
                                session = c("one", "two"))
bar_preset_data$value <- seq_len(nrow(bar_preset_data)) / 10

test_that("bar helpers count conditions rather than observations or factor levels", {
  d <- bar_preset_data
  p <- plot_bars(d, "load", "value", group = "session")
  expect_equal(p$theme$aspect.ratio, 3.10 / 4)
  expect_equal(count_plot_bars(p), 4)
  expect_equal(plot_bars(d, "load", "value")$theme$aspect.ratio, 3.10 / 2)
  expect_equal(plot_bars(d, "load", "value", group = "load")$theme$aspect.ratio, 3.10 / 2)
  d$load <- factor(d$load, levels = c("easy", "hard", "unused"))
  d$value[d$load == "hard" & d$session == "two"] <- NA_real_
  expect_equal(plot_bars(d, "load", "value", group = "session")$theme$aspect.ratio, 3.10 / 3)
  expect_equal(plot_bars(d, "load", "value", preset = "bars_tall")$theme$aspect.ratio,
               6.16 / 2)
  manual <- plot_bars(d, "load", "value", n_bars = 6)
  expect_equal(manual$theme$aspect.ratio, 3.10 / 6)
  expect_null(attr(manual, "kiyonaga_bar_preset"))
  expect_equal(plot_bars(d, "load", "value", aspect_ratio = 0.4)$theme$aspect.ratio, 0.4)
  expect_equal(plot_bars(d, "load", "value", preset = NULL)$theme$aspect.ratio, 1)
  sim <- simulate_lab_data(n_subjects = 3)
  expect_equal(plot_timecourse(sim$timecourse, "time", "pupil")$theme$aspect.ratio, 0.68)
})

test_that("built bar counts handle dodging, stacking, faceting and overlays", {
  d <- bar_preset_data
  p <- plot_bars(d, "load", "value", group = "session")
  expect_equal(count_plot_bars(p + ggplot2::facet_wrap(~session)), 2)
  stacked <- ggplot2::ggplot(d, ggplot2::aes(load, value, fill = session)) +
    ggplot2::geom_col()
  expect_equal(count_plot_bars(stacked), 2)
  expect_equal(count_plot_bars(stacked + ggplot2::geom_col()), 2)
  expect_error(count_plot_bars(ggplot2::ggplot(d, ggplot2::aes(load, value)) +
                                ggplot2::geom_point()), "n_bars")
})

svg_panel_ratios <- function(file) {
  lines <- readLines(file)
  rects <- lines[grep("<clipPath", lines, fixed = TRUE) + 1L]
  matches <- regmatches(rects, regexec("width='([0-9.]+)' height='([0-9.]+)'", rects))
  ratios <- vapply(matches, function(m) as.numeric(m[3]) / as.numeric(m[2]), numeric(1))
  ratios[-1]
}

test_that("export layouts determine physical size while preserving plot ratios", {
  skip_if_not_installed("svglite")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point() +
    theme_kiyonaga(preset = "scatter")
  f <- tempfile(fileext = ".svg")
  on.exit(unlink(f))
  expect_message(nice_save(f, p, layout = "half col"), "Saving")
  expect_match(readLines(f)[2], "width='129.60pt'", fixed = TRUE)
  expect_true(any(abs(svg_panel_ratios(f) - 0.92) < 0.01))
  expect_message(nice_save(f, p, layout = "full col"), "Saving")
  expect_match(readLines(f)[2], "width='259.20pt'", fixed = TRUE)
  expect_true(any(abs(svg_panel_ratios(f) - 0.92) < 0.01))
  expect_message(nice_save(f, p, preset = "timecourse", layout = "half col"), "Saving")
  expect_true(any(abs(svg_panel_ratios(f) - 0.68) < 0.01))
  facets <- p + ggplot2::facet_wrap(~cyl, nrow = 1)
  expect_message(nice_save(f, facets, layout = "full col"), "Saving")
  expect_true(any(abs(svg_panel_ratios(f) - 0.92) < 0.01))
  geometry <- plot_geometry(facets)
  expect_equal(geometry$cols, 3)
  expect_equal(geometry$rows, 1)
})

test_that("bar ratios refresh after faceting but respect explicit overrides", {
  skip_if_not_installed("svglite")
  p <- plot_bars(bar_preset_data, "load", "value", group = "session",
                  legend_position = "none") + ggplot2::facet_wrap(~session)
  f <- tempfile(fileext = ".svg")
  on.exit(unlink(f))
  expect_message(nice_save(f, p, layout = "full col"), "Saving")
  expect_true(any(abs(svg_panel_ratios(f) - 1.55) < 0.01))
  expect_message(nice_save(f, p, preset = "bars_tall", layout = "full col"), "Saving")
  expect_true(any(abs(svg_panel_ratios(f) - 3.08) < 0.01))
  expect_message(nice_save(f, p, preset = "bars", n_bars = 6), "Saving")
  expect_true(any(abs(svg_panel_ratios(f) - 3.10 / 6) < 0.01))
  p <- p + ggplot2::theme(aspect.ratio = 0.4)
  expect_message(nice_save(f, p), "Saving")
  expect_true(any(abs(svg_panel_ratios(f) - 0.4) < 0.01))
})

test_that("existing whole-figure layouts retain their dimensions and font defaults", {
  widths <- c("full col" = 3.6, "half col" = 1.8, tiny = 1, "full page" = 7.2)
  for (name in names(widths)) {
    preset <- kiyonaga_plot_presets[[name]]
    expect_equal(preset$size_type, "figure")
    expect_equal(preset$figure_width, unname(widths[[name]]))
    expect_null(preset$figure_height)
  }
  expect_equal(kiyonaga_plot_presets$slides$figure_height, 4.4)
  expect_null(kiyonaga_plot_presets$slides$figure_width)
  expect_equal(theme_kiyonaga(preset = "slides")$text$size, 14)
  expect_equal(theme_kiyonaga(preset = "tiny")$text$size, 6)
})

test_that("whole-figure preset exports match the existing layout interface", {
  skip_if_not_installed("svglite")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point() +
    ggplot2::labs(x = "Weight", y = "Fuel economy") +
    theme_kiyonaga(font_size = 12, aspect_ratio = 0.6)
  f <- tempfile(fileext = ".svg")
  g <- tempfile(fileext = ".svg")
  on.exit(unlink(c(f, g)))
  for (name in c("full col", "half col", "tiny", "full page", "slides")) {
    expect_message(nice_save(f, p, layout = name), "Saving")
    expect_message(nice_save(g, p, preset = name), "Saving")
    expect_identical(readLines(f)[2], readLines(g)[2])
    size <- if (name == "slides") 14 else if (name == "tiny") 6 else 12
    expect_match(paste(readLines(g), collapse = "\n"),
                  sprintf("font-size: %.2fpx", size), fixed = TRUE)
  }
  expect_message(nice_save(g, p, preset = "slides", layout = "tiny"), "Saving")
  expect_match(readLines(g)[2], "width='72.00pt'", fixed = TRUE)
  expect_message(nice_save(g, p, preset = "slides", custom = c(3, 2)), "Saving")
  expect_match(readLines(g)[2], "width='216.00pt' height='144.00pt'", fixed = TRUE)
})
