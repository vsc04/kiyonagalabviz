#' Extract a legend for separate export
#'
#' Extracts the legend from a ggplot, including plots created with
#' `legend = "separate"`. Save the returned grob with [nice_save()] or draw it
#' with [grid::grid.draw()].
#'
#' @param plot A ggplot object.
#' @return A legend gtable grob, sized to its contents.
#' @export
#' @examples
#' p <- plot_bars(average_window(simulate_lab_data()$timecourse),
#'                "load", "pupil", group = "load", legend = "separate")
#' key <- plot_legend(p)
#' \dontrun{
#' nice_save("bars.svg", p)
#' nice_save("legend.svg", key)
#' }
plot_legend <- function(plot) {
  position <- attr(plot, "kiyonaga_legend_position")
  if (is.null(position)) position <- plot$theme$legend.position
  if (is.null(position) || identical(position, "none")) position <- "top"
  g <- ggplot2::ggplotGrob(plot + ggplot2::theme(legend.position = position))
  boxes <- which(grepl("^guide-box", g$layout$name))
  boxes <- boxes[!vapply(g$grobs[boxes], inherits, logical(1), "zeroGrob")]
  if (!length(boxes)) stop("This plot has no legend to extract.", call. = FALSE)
  if (length(boxes) > 1L) {
    stop("Place all guides at one legend position before extracting them.", call. = FALSE)
  }
  g$grobs[[boxes]]
}

#' Apply the shared legend option while preserving a ggplot return value
#' @noRd
finish_plot <- function(plot, legend) {
  legend <- match.arg(legend, c("inside", "separate", "none"))
  if (legend == "separate") {
    position <- plot$theme$legend.position
    if (is.null(position) || identical(position, "none")) position <- "top"
    attr(plot, "kiyonaga_legend_position") <- position
  }
  if (legend != "inside") plot <- plot + ggplot2::theme(legend.position = "none")
  plot
}
