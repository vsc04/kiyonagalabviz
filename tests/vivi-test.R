# Demo of all kiyonagalabviz plots with the simulated pupil data.
# Run from the package folder after devtools::install() or devtools::load_all().

library(kiyonagalabviz)
library(ggplot2)

out_dir <- file.path("tools", "output")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ---- Example data -----------------------------------------------------------
# 24 subjects x load (easy, hard); pupil over a 5 s delay; accuracy per condition
sim <- simulate_lab_data()
head(sim$timecourse)   # subject, load, time (s), pupil (mm)
head(sim$behavior)     # subject, load, accuracy

# One value per subject and load: mean pupil size 3-5 s, plus accuracy
d <- merge(average_window(sim$timecourse, window = c(3, 5)), sim$behavior)
head(d)

# ---- 1. Timecourse -------------------------------------------------------------
# Mean +/- SE ribbons (alpha 0.4), analysis window 3-5 s shaded in light grey
p_time <- plot_timecourse(sim$timecourse, time = "time", y = "pupil",
                          group = "load", window = c(3, 5)) +
  labs(x = "Time (s)", y = "Pupil size (mm)", colour = "WM load", fill = "WM load")
p_time

# Variations
plot_timecourse(sim$timecourse, "time", "pupil", group = "load",
                error = "ci", palette = "sunset")          # 95% CI, sunset colours

plot_timecourse(sim$timecourse, "time", "pupil", group = "load",
                window = c(3, 5), aspect_ratio = 0.6)       # wider panel

# ---- 2. Bar plot with individual data points ---------------------------------
# PI's greys: easy = light, hard = dark; SE error bars
p_bars <- plot_bars(d, x = "load", y = "pupil", group = "load") +
  labs(x = "WM load", y = "Pupil size 3-5 s (mm)") +
  theme(legend.position = "none")    # legend would repeat the x axis
p_bars

# Variations
plot_bars(d, "load", "pupil", group = "load",
          show_points = FALSE)                     # bars only, like the paper figure

plot_bars(d, "load", "pupil", group = "load",
          error = "ci", palette = "sunset_light")  # 95% CI, sunset_light colours

plot_bars(d, "load", "pupil", group = "load",
          point_style = list(size = 1.5, fill = kiyonaga_colors$SUNSET_ROSE),
          font_size = 12)                           # bigger points, slide-sized text

# ---- 3. Scatter: pupil vs accuracy -------------------------------------------
# Like the side panels of Figure 2: one panel per load, r in the corner
r_labels <- do.call(rbind, lapply(split(d, d$load), function(x) {
  data.frame(load = x$load[1],
             label = sprintf("r = %.2f", stats::cor(x$pupil, x$accuracy)))
}))

p_scatter <- ggplot(d, aes(x = pupil, y = accuracy)) +
  geom_point(colour = kiyonaga_colors$ACCENT_GREEN, size = 1) +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE,
              colour = kiyonaga_colors$ACCENT_GREEN, linewidth = 0.5) +
  geom_text(data = r_labels, aes(label = label), x = Inf, y = Inf,
            hjust = 1.1, vjust = 1.5, size = 7 / .pt, fontface = "bold",
            colour = kiyonaga_colors$TEXT, inherit.aes = FALSE) +
  facet_wrap(~ load) +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Pupil size 3-5 s (mm)", y = "WM accuracy") +
  theme_kiyonaga()
p_scatter

# ---- 4. Save at journal sizes (panel aspect ratio is kept) -------------------
nice_save(file.path(out_dir, "pupil_timecourses_tiny.pdf"), plot = p_time,
          layout = "tiny")


nice_save(file.path(out_dir, "pupil_bars.pdf"), plot = p_bars,
          layout = "half col")
nice_save(file.path(out_dir, "pupil_accuracy.pdf"), plot = p_scatter,
          layout = "full col")
