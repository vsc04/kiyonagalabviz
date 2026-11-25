#' Heatmaps with continuous lab palettes
#'
#' Draws borderless, fully opaque tiles with a continuous colour bar and the
#' lab theme. The default `"heatmap"` preset gives square panels. Use numeric
#' coordinates for spatial maps or factors for categorical matrices. Values
#' are plotted as supplied, without smoothing, normalization or aggregation.
#'
#' @inheritParams plot_bars
#' @param x,y Names of the horizontal and vertical coordinate columns.
#'   Numeric coordinates are tile centres. Character columns are converted to
#'   factors; existing factor levels set their order. The first y level is at
#'   the bottom unless `reverse_y = TRUE`.
#' @param value Name of the numeric column mapped to fill colour. Missing
#'   values use `na_colour`; missing coordinate combinations have no tile.
#' @param group Optional condition column displayed as facet rows.
#' @param subgroup Optional second condition column displayed as facet columns;
#'   requires `group`. Conditions share one colour scale. They do not select
#'   palette shades, because colour encodes `value`.
#' @param palette Continuous palette name or vector of hex colours. Defaults
#'   to `"blue_yellow_continuous"`; use `"blue_red_continuous"` for signed maps.
#' @param limits Optional numeric `c(min, max)` for a shared colour range.
#'   Values outside these limits use `na_colour`.
#' @param midpoint Optional value mapped to the centre of the palette, such
#'   as zero for differences. With no explicit `limits`, the colour range is
#'   made symmetric around this value. With explicit limits, it must lie
#'   strictly between them. Does not automatically change the palette.
#' @param reverse Logical; reverse the colour scale?
#' @param reverse_y Logical; reverse the vertical coordinate or factor order?
#'   Useful for matrices and screen coordinates that increase downward.
#' @param show_axes Logical; show axis lines, labels and titles? Set to `FALSE`
#'   for an unlabelled spatial map. Axes and grid lines are hidden together.
#' @param cell_width,cell_height Optional positive tile dimensions in coordinate
#'   units. By default each dimension uses the smallest coordinate spacing
#'   (one for categorical axes). Irregular grids can therefore contain gaps.
#' @param reference Optional numeric `c(x, y)` for thin dashed reference lines
#'   on numeric axes, e.g. `c(0, 0)` for a gaze-map origin.
#' @param na_colour Colour for missing values; defaults to `"transparent"`.
#' @param legend_position Position of the colour bar; defaults to `"right"`.
#' @param preset Panel ratio preset; defaults to `"heatmap"`. The panel is
#'   square, but individual tiles need not be square when grid sizes differ.
#' @param ... Passed to [theme_kiyonaga()], e.g. `font_size` or `aspect_ratio`.
#' @details Supply one row per x/y cell and condition. Aggregate repeated
#'   observations before plotting. All panels share the same fill limits.
#' @return A ggplot object. Use [plot_legend()] for a separate colour bar.
#' @export
#' @examples
#' d <- expand.grid(x = -5:5, y = -5:5)
#' d$value <- with(d, exp(-(x^2 + y^2) / 8))
#' plot_heatmap(d, "x", "y", "value", show_axes = FALSE)
#'
#' d$difference <- with(d, x * exp(-(x^2 + y^2) / 8))
#' plot_heatmap(d, "x", "y", "difference",
#'              palette = "blue_red_continuous", midpoint = 0)
plot_heatmap <- function(data, x, y, value, group = NULL,
                         palette = "blue_yellow_continuous", limits = NULL,
                         midpoint = NULL, reverse = FALSE, reverse_y = FALSE,
                         show_axes = TRUE, cell_width = NULL, cell_height = NULL,
                         reference = NULL, na_colour = "transparent", legend_position = "right", ...,
                         subgroup = NULL, preset = "heatmap",
                         legend = c("inside", "separate", "none")) {
  legend <- match.arg(legend)
  check_columns(data, c(x, y, value, group, subgroup), numeric = value)
  if (!is.null(subgroup) && is.null(group)) {
    stop("`subgroup` requires `group`.", call. = FALSE)
  }
  for (column in c(x, y)) {
    if (!is.numeric(data[[column]]) && !is.character(data[[column]]) &&
        !is.factor(data[[column]])) {
      stop("Heatmap coordinates must be numeric, character or factor columns.", call. = FALSE)
    }
    if (anyNA(data[[column]]) ||
        (is.numeric(data[[column]]) && any(!is.finite(data[[column]])))) {
      stop("Heatmap coordinates must not contain missing or infinite values.", call. = FALSE)
    }
    if (!is.numeric(data[[column]])) data <- as_factors(data, column)
  }
  data <- as_factors(data, c(group, subgroup))
  if (anyDuplicated(data[unique(c(x, y, group, subgroup))])) {
    stop("Supply one value per x/y cell and condition; aggregate repeated observations first, ",
         "or specify condition columns with `group` and `subgroup`.", call. = FALSE)
  }
  if (any(is.infinite(data[[value]]))) {
    stop("Heatmap values must be finite or NA.", call. = FALSE)
  }
  if (!is.null(cell_width)) check_positive(cell_width, "cell_width")
  if (!is.null(cell_height)) check_positive(cell_height, "cell_height")
  if (!is.null(limits) &&
      (!is.numeric(limits) || length(limits) != 2L || any(!is.finite(limits)) ||
       limits[1] >= limits[2])) {
    stop("`limits` must be two finite numbers in increasing order.", call. = FALSE)
  }
  if (!is.null(reference) &&
      (!is.numeric(reference) || length(reference) != 2L || any(!is.finite(reference)) ||
       !is.numeric(data[[x]]) || !is.numeric(data[[y]]))) {
    stop("`reference` must be finite numeric c(x, y) on numeric axes.", call. = FALSE)
  }
  colours <- get_kiyonaga_palette(palette, reverse = reverse)
  if (length(colours) < 2L) stop("Heatmaps require at least two palette colours.", call. = FALSE)
  values <- NULL
  if (!is.null(midpoint)) {
    if (!is.numeric(midpoint) || length(midpoint) != 1L || !is.finite(midpoint)) {
      stop("`midpoint` must be one finite number.", call. = FALSE)
    }
    if (is.null(limits)) {
      observed <- data[[value]][is.finite(data[[value]])]
      if (!length(observed)) stop("A midpoint requires finite values or explicit `limits`.", call. = FALSE)
      radius <- max(abs(observed - midpoint))
      if (radius == 0) radius <- 1
      limits <- midpoint + c(-radius, radius)
    }
    if (midpoint <= limits[1] || midpoint >= limits[2]) {
      stop("`midpoint` must lie strictly inside `limits`.", call. = FALSE)
    }
    # Add a centre anchor for even-length custom palettes without moving
    # their existing colour stops.
    if (length(colours) %% 2L == 0L) {
      colours <- interpolate_palette(colours, 2L * length(colours) - 1L)
    }
    centre <- (midpoint - limits[1]) / diff(limits)
    stops <- seq(0, 1, length.out = length(colours))
    values <- ifelse(stops <= 0.5, stops * 2 * centre,
                     centre + (stops - 0.5) * 2 * (1 - centre))
  }
  tile_args <- list(colour = NA, linewidth = 0, na.rm = TRUE)
  if (!is.null(cell_width)) tile_args$width <- cell_width
  if (!is.null(cell_height)) tile_args$height <- cell_height
  p <- ggplot2::ggplot(data, ggplot2::aes(x = .data[[x]], y = .data[[y]],
                                         fill = .data[[value]])) +
    do.call(ggplot2::geom_tile, tile_args) +
    ggplot2::scale_fill_gradientn(colours = colours, values = values, limits = limits,
                                  na.value = na_colour) +
    ggplot2::labs(fill = value) +
    heatmap_axis(data[[x]], "x", FALSE) + heatmap_axis(data[[y]], "y", reverse_y) +
    theme_kiyonaga(..., preset = preset, legend_position = legend_position) +
    ggplot2::theme(panel.grid = ggplot2::element_blank(),
                    panel.grid.major = ggplot2::element_blank(),
                    panel.grid.minor = ggplot2::element_blank())
  if (!is.null(reference)) {
    p <- p + ggplot2::geom_vline(xintercept = reference[1], linewidth = 0.3,
                                 linetype = "dashed", colour = kiyonaga_colors$GREY_TEXT) +
      ggplot2::geom_hline(yintercept = reference[2], linewidth = 0.3,
                          linetype = "dashed", colour = kiyonaga_colors$GREY_TEXT)
  }
  if (!is.null(group)) {
    p <- p + ggplot2::facet_grid(rows = ggplot2::vars(.data[[group]]),
                                 cols = if (is.null(subgroup)) NULL else ggplot2::vars(.data[[subgroup]]))
  }
  if (!show_axes) {
    p <- p + ggplot2::theme(axis.text = ggplot2::element_blank(),
                            axis.text.x = ggplot2::element_blank(),
                            axis.text.y = ggplot2::element_blank(),
                            axis.title = ggplot2::element_blank(),
                            axis.title.x = ggplot2::element_blank(),
                            axis.title.y = ggplot2::element_blank(),
                            axis.ticks = ggplot2::element_blank(),
                            axis.line = ggplot2::element_blank(),
                            axis.line.x = ggplot2::element_blank(),
                            axis.line.y = ggplot2::element_blank())
  }
  finish_plot(p, legend)
}

#' Edge-aligned continuous tiles or categorical axes without excess padding
#' @noRd
heatmap_axis <- function(values, axis, reverse) {
  if (is.numeric(values)) {
    scale <- if (axis == "x") ggplot2::scale_x_continuous else
      if (reverse) ggplot2::scale_y_reverse else ggplot2::scale_y_continuous
    return(scale(expand = ggplot2::expansion(mult = 0)))
  }
  scale <- if (axis == "x") ggplot2::scale_x_discrete else ggplot2::scale_y_discrete
  limits <- if (reverse) rev(levels(values)) else NULL
  scale(expand = ggplot2::expansion(add = 0.5), limits = limits, drop = FALSE)
}
