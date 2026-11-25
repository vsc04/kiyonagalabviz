test_that("paper palettes contain valid colours and keep the original palettes", {
  expect_false("scene_check" %in% names(kiyonaga_palettes))
  expect_identical(names(kiyonaga_palette_groups), c(
    "accent_2", "accent_3", "green_purple", "green_purple_2",
    "green_purple_3", "skyblue_orange", "blue_yellow", "blue_yellow_2"
  ))
  expect_identical(kiyonaga_palettes$green_purple, c("#83B174", "#A96FAE"))
  expect_identical(kiyonaga_palettes$green_purple_light, c("#A8C89D", "#C29AC6"))
  expect_equal(kiyonaga_palettes$greys,
               c("#D9D9D9", "#A6A6A6", "#404040"))
  expect_equal(kiyonaga_palettes$skyblue_orange, c("#75C9EB", "#FA703E"))
  expect_equal(kiyonaga_palettes$skyblue_orange_light, c("#BBD9E6", "#E6C6BA"))
  expect_false("skyblue_orange_error" %in% names(kiyonaga_palettes))
  expect_equal(kiyonaga_palettes$blue_yellow_2, c("#506488", "#B08B27"))
  for (pal in kiyonaga_palettes) {
    expect_no_error(grDevices::col2rgb(pal, alpha = TRUE))
    expect_identical(make_kiyonaga_palette(pal)(length(pal)), unname(pal))
  }
})

test_that("explicit alpha modifiers preserve the supplied RGB colours", {
  cols <- rep(kiyonaga_palettes$skyblue_orange, each = 2)
  pal <- make_kiyonaga_palette(cols, alpha = c(1, 0.4, 1, 0.4))(4)
  expect_identical(pal, c("#75C9EBFF", "#75C9EB66", "#FA703EFF", "#FA703E66"))
  expect_equal(grDevices::col2rgb(pal), grDevices::col2rgb(cols))
  expect_identical(make_kiyonaga_palette(cols, reverse = TRUE,
                                        alpha = c(1, 0.4, 1, 0.4))(4), rev(pal))
})

test_that("alpha is validated and multiplies existing opacity", {
  for (alpha in list(-1, 1.1, NA_real_, Inf, numeric(0), c(1, 0.5, 0), "0.5")) {
    expect_error(make_kiyonaga_palette("skyblue_orange", alpha = alpha), "alpha")
  }
  pal <- c("#87CEEB80", "#FF7F5040")
  expect_identical(make_kiyonaga_palette(pal)(2), pal)
  expect_identical(make_kiyonaga_palette(pal, alpha = 0.5)(2),
                   c("#87CEEB40", "#FF7F5020"))
})

test_that("interpolation retains alpha and keeps opaque output compatible", {
  pal <- c("#87CEEBFF", "#FF7F5000")
  out <- grDevices::col2rgb(make_kiyonaga_palette(pal)(5), alpha = TRUE)
  expect_equal(out[4, c(1, 5)], c(255, 0))
  expect_true(all(diff(out[4, ]) < 0))
  opaque <- make_kiyonaga_palette("skyblue_orange")(5)
  expect_true(all(nchar(opaque) == 7))
})

test_that("discrete and continuous ggplot scales preserve palette opacity", {
  for (scale_fun in list(scale_fill_kiyonaga, scale_colour_kiyonaga,
                         scale_color_kiyonaga)) {
    s <- scale_fun("skyblue_orange", alpha = c(1, 0.4))
    s$train(c("draw", "wheel"))
    expect_identical(unname(s$map(c("draw", "wheel"))),
                     c("#75C9EBFF", "#FA703E66"))
    s <- scale_fun("skyblue_orange", discrete = FALSE, alpha = c(1, 0.4))
    rgba <- grDevices::col2rgb(s$map(c(0, 0.5, 1)), alpha = TRUE)
    expect_equal(rgba[4, c(1, 3)], c(255, 102))
    expect_true(rgba[4, 2] > 102 && rgba[4, 2] < 255)
  }
})

test_that("timecourse ribbons can retain explicitly supplied palette opacity", {
  sim <- simulate_lab_data(n_subjects = 4)
  cols <- make_kiyonaga_palette("skyblue_orange", alpha = c(0.2, 0.4))(2)
  p <- plot_timecourse(sim$timecourse, "time", "pupil", group = "load",
                        palette = cols, ribbon_alpha = NULL)
  ribbon <- ggplot2::layer_data(p, 1)
  expect_setequal(unique(ribbon$fill), cols)
  expect_true(all(is.na(ribbon$alpha)))
  expect_no_error(ggplot2::ggplotGrob(p))
})


test_that("secondary conditions use exactly the recorded opaque shade combinations", {
  p <- kiyonaga_palettes
  expected <- list(
    accent_2 = c(p$accent_2[1], p$accent_2_light[1], p$accent_2[2], p$accent_2_light[2],
                p$accent_2[3], p$accent_2_light[3]),
    skyblue_orange = c(p$skyblue_orange[1], p$skyblue_orange_light[1],
                       p$skyblue_orange[2], p$skyblue_orange_light[2]),
    green_purple = c(p$green_purple[1], p$green_purple_light[1],
                              p$green_purple[2], p$green_purple_light[2]),
    blue_yellow = c(p$blue_yellow[1], p$blue_yellow_light[1], p$blue_yellow[2], p$blue_yellow_light[2]),
    green_purple_2 = c(p$green_purple_2[1], p$green_purple_2_light[1], p$green_purple_2[2], p$green_purple_2_light[2]),
    green_purple_3 = c(p$green_purple_3[1], p$green_purple_3_light[1], p$green_purple_3[2], p$green_purple_3_light[2]),
    blue_yellow_2 = c(p$blue_yellow_2[1], p$blue_yellow_2_light[1],
                       p$blue_yellow_2[2], p$blue_yellow_2_light[2]),
    accent_3 = c(p$accent_3[1], p$accent_3_med[1], p$accent_3_light[1],
                 p$accent_3[2], p$accent_3_med[2], p$accent_3_light[2],
                 p$accent_3[3], p$accent_3_med[3], p$accent_3_light[3])
  )
  expect_setequal(names(kiyonaga_palette_groups), names(expected))
  for (name in names(expected)) {
    groups <- if (name == "accent_3") 3 else 2
    cols <- make_kiyonaga_palette(name, condition_groups = groups)(length(expected[[name]]))
    expect_identical(cols, unname(expected[[name]]))
    expect_true(all(grDevices::col2rgb(cols, alpha = TRUE)[4, ] == 255))
    expect_identical(make_kiyonaga_palette(name)(length(p[[name]])), p[[name]])
  }
})

test_that("selection and reversal preserve complete secondary-colour blocks", {
  full <- make_kiyonaga_palette("accent_2", condition_groups = 2)(6)
  expect_identical(make_kiyonaga_palette("accent_2", condition_groups = 2)(4), full[c(1, 2, 5, 6)])
  expect_identical(make_kiyonaga_palette("accent_2", condition_groups = 2, reverse = TRUE)(6),
                   full[c(5, 6, 3, 4, 1, 2)])
  expect_identical(make_kiyonaga_palette("accent_2", condition_groups = 2)(0), character(0))
  changed <- make_kiyonaga_palette("accent_2", condition_groups = 2, alpha = 0.5)(6)
  expect_true(all(grDevices::col2rgb(changed, alpha = TRUE)[4, ] == 128))
})

test_that("graded palettes reject unsupported families, group counts and interpolation", {
  for (groups in list(1, 4, 2.5, NA_real_, Inf, c(2, 3), "2", numeric(0))) {
    expect_error(make_kiyonaga_palette("accent_2", condition_groups = groups), "condition_groups")
  }
  expect_error(make_kiyonaga_palette("accent_2", condition_groups = 3), "supports")
  expect_error(make_kiyonaga_palette("accent_3", condition_groups = 2), "supports")
  expect_error(make_kiyonaga_palette("sunset", condition_groups = 2), "main palette")
  expect_error(make_kiyonaga_palette(c("#123456", "#654321"), condition_groups = 2), "main palette")
  pal <- make_kiyonaga_palette("accent_2", condition_groups = 2)
  for (n in list(1, 3, 4.5, -2, NA_real_, Inf, c(2, 4), "6")) {
    expect_error(pal(n), "multiple")
  }
  expect_error(pal(8), "at most")
  expect_error(scale_fill_kiyonaga(discrete = FALSE, condition_groups = 2), "discrete")
})

test_that("scales and plot helpers use fully opaque graded condition colours", {
  expected <- make_kiyonaga_palette("accent_3", condition_groups = 3)(9)
  conditions <- paste0("condition", 1:9)
  for (scale_fun in list(scale_fill_kiyonaga, scale_colour_kiyonaga, scale_color_kiyonaga)) {
    s <- scale_fun("accent_3", condition_groups = 3, limits = conditions)
    s$train(conditions)
    expect_identical(unname(s$map(conditions)), expected)
  }
  d <- expand.grid(condition = factor(conditions, levels = conditions),
                    time = 0:2, subject = 1:3)
  d$value <- seq_len(nrow(d)) / 100
  bars <- plot_bars(d, "time", "value", group = "condition",
                    palette = "accent_3", condition_groups = 3)
  expect_setequal(ggplot2::layer_data(bars, 1)$fill, expected)
  p <- plot_timecourse(d, "time", "value", group = "condition",
                        palette = "accent_3", condition_groups = 3)
  expect_setequal(ggplot2::layer_data(p, 1)$fill, expected)
  expect_setequal(ggplot2::layer_data(p, 2)$colour, expected)
  expect_true(all(grDevices::col2rgb(ggplot2::layer_data(p, 2)$colour, alpha = TRUE)[4, ] == 255))
  expect_true(all(ggplot2::layer_data(p, 1)$alpha == 0.4))
  expect_no_warning(ggplot2::ggplotGrob(p))
})


test_that("renamed shade sets contain matching accents in dark-to-light order", {
  p <- kiyonaga_palettes
  expect_identical(p$blue_yellow_2, c("#506488", "#B08B27"))
  expect_identical(p$blue_yellow_2_light, c("#8BA4C0", "#D4BC73"))
  expect_identical(p$accent_3, c("#6A0136", "#60A27D", "#CB8589"))
  expect_identical(p$accent_3_med, c("#9E597C", "#97C2AA", "#DDAFB2"))
  expect_identical(p$accent_3_light, c("#C399AE", "#BFD9CB", "#EACECF"))
  expect_false(any(c("blue_yellow_2_visual", "blue_yellow_2_verbal", "memorability_rt",
                     "memorability_accuracy", "memorability_errors") %in% names(p)))
  expect_identical(make_kiyonaga_palette("blue_yellow_2", condition_groups = 2)(4),
                   c("#506488", "#8BA4C0", "#B08B27", "#D4BC73"))
  expect_identical(make_kiyonaga_palette("accent_3", condition_groups = 3)(9),
                   c("#6A0136", "#9E597C", "#C399AE", "#60A27D", "#97C2AA",
                     "#BFD9CB", "#CB8589", "#DDAFB2", "#EACECF"))
})
