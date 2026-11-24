#' Simulate example pupil and behaviour data
#'
#' Simulates a within-subject working memory experiment with two load
#' conditions (`"easy"`, `"hard"`). Pupil size is recorded across a delay
#' period: it rises after onset and levels off at a plateau that is about
#' twice as high for hard load. Subjects differ in the size of their pupil
#' response, and subjects with larger responses have slightly lower accuracy.
#'
#' @param n_subjects Number of subjects.
#' @param duration Length of the delay period in seconds.
#' @param sampling_rate Pupil samples per second (Hz).
#' @param seed Random seed. The global random number state is restored
#'   afterwards.
#'
#' @return A list with two data frames:
#'   - `timecourse`: `subject`, `load`, `time` (s), `pupil` (baseline-corrected
#'     pupil size, mm); one row per subject, load and time point.
#'   - `behavior`: `subject`, `load`, `accuracy` (proportion correct); one row
#'     per subject and load.
#' @export
#'
#' @examples
#' sim <- simulate_lab_data()
#' head(sim$timecourse)
#' head(sim$behavior)
simulate_lab_data <- function(n_subjects = 24, duration = 5,
                              sampling_rate = 20, seed = 1) {
  with_seed(seed, {
    subjects <- simulate_subjects(n_subjects)
    list(
      timecourse = simulate_timecourse(subjects, duration, sampling_rate),
      behavior = simulate_behavior(subjects)
    )
  })
}

#' Subject-level pupil response gain (1 = average)
#' @noRd
simulate_subjects <- function(n_subjects) {
  data.frame(
    subject = sprintf("sub-%02d", seq_len(n_subjects)),
    gain = stats::rnorm(n_subjects, mean = 1, sd = 0.25)
  )
}

#' Pupil timecourse: rise to a load-dependent plateau plus smooth noise
#' @noRd
simulate_timecourse <- function(subjects, duration, sampling_rate) {
  time <- seq(0, duration, by = 1 / sampling_rate)
  d <- expand.grid(time = time, load = c("easy", "hard"),
                   subject = subjects$subject, stringsAsFactors = FALSE)
  d$load <- factor(d$load, levels = c("easy", "hard"))
  gain <- subjects$gain[match(d$subject, subjects$subject)]
  plateau <- ifelse(d$load == "hard", 0.20, 0.10) * gain
  n_series <- nrow(d) / length(time)
  noise <- unlist(lapply(seq_len(n_series), function(i) ar1_noise(length(time))))
  d$pupil <- plateau * (1 - exp(-d$time / 0.8)) + noise
  d[c("subject", "load", "time", "pupil")]
}

#' Smooth (autocorrelated) noise for one timecourse
#' @noRd
ar1_noise <- function(n, phi = 0.95, sd = 0.01) {
  as.numeric(stats::filter(stats::rnorm(n, sd = sd), phi, method = "recursive"))
}

#' Accuracy per subject and load, lower for larger pupil responses
#' @noRd
simulate_behavior <- function(subjects) {
  d <- expand.grid(load = c("easy", "hard"), subject = subjects$subject,
                   stringsAsFactors = FALSE)
  d$load <- factor(d$load, levels = c("easy", "hard"))
  gain <- subjects$gain[match(d$subject, subjects$subject)]
  acc <- ifelse(d$load == "hard", 0.80, 0.90) - 0.10 * (gain - 1) +
    stats::rnorm(nrow(d), sd = 0.04)
  d$accuracy <- pmin(pmax(acc, 0), 1)
  d[c("subject", "load", "accuracy")]
}

#' Evaluate code with a seed, restoring the global RNG state afterwards
#' @noRd
with_seed <- function(seed, code) {
  had_seed <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  if (had_seed) old <- get(".Random.seed", envir = globalenv())
  on.exit({
    if (had_seed) {
      assign(".Random.seed", old, envir = globalenv())
    } else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
      rm(".Random.seed", envir = globalenv())
    }
  })
  set.seed(seed)
  code
}
