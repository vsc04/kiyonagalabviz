#' Simulate example data for trying out the package
#'
#' Simulates a within-subject design like the lab's working memory / visual
#' search studies: each subject has one parietal beta per WM load
#' (`"1 item"`, `"2 items"`) and search difficulty (`"easy"`, `"hard"`).
#'
#' @param n_subjects Number of subjects.
#' @param seed Random seed. The global random number state is restored
#'   afterwards.
#'
#' @return A data frame with columns `subject`, `load`, `difficulty`, `beta`.
#' @export
#'
#' @examples
#' head(simulate_lab_data())
simulate_lab_data <- function(n_subjects = 24, seed = 1) {
  with_seed(seed, {
    d <- expand.grid(
      subject = sprintf("sub-%02d", seq_len(n_subjects)),
      load = factor(c("1 item", "2 items")),
      difficulty = factor(c("easy", "hard")),
      stringsAsFactors = FALSE
    )
    subject_offset <- stats::rnorm(n_subjects, sd = 0.08)
    d$beta <- 0.25 +
      0.20 * (d$difficulty == "hard") -
      0.08 * (d$load == "2 items" & d$difficulty == "easy") +
      subject_offset[match(d$subject, unique(d$subject))] +
      stats::rnorm(nrow(d), sd = 0.10)
    d
  })
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
