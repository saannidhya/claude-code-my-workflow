#' Publication-ready ggplot2 theme matching the LaTeX/Beamer palette
#'
#' Use via `theme_set(theme_paper())` in 00_setup.R.

suppressPackageStartupMessages({
  library(ggplot2)
})

#' Theme for paper-quality figures
#'
#' @param base_size Base font size in points (default 11)
#' @param base_family Base font family (default "" = system default; matches Beamer default rendering)
theme_paper <- function(base_size = 11, base_family = "") {
  theme_minimal(base_size = base_size, base_family = base_family) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(linewidth = 0.25, color = "grey85"),
      panel.border     = element_rect(fill = NA, color = "grey20", linewidth = 0.4),
      axis.text        = element_text(size = base_size - 1, color = "grey20"),
      axis.title       = element_text(size = base_size, color = "grey10"),
      axis.ticks       = element_line(color = "grey50", linewidth = 0.3),
      legend.position  = "bottom",
      legend.title     = element_text(size = base_size - 1),
      legend.text      = element_text(size = base_size - 1),
      plot.title       = element_text(size = base_size + 1, face = "bold", color = "grey10"),
      plot.subtitle    = element_text(size = base_size, color = "grey30"),
      plot.caption     = element_text(size = base_size - 2, color = "grey40", hjust = 0),
      strip.background = element_rect(fill = "grey95", color = NA),
      strip.text       = element_text(size = base_size, face = "bold", color = "grey20")
    )
}

#' Colorblind-safe palette matching academic norms
palette_paper <- function() {
  c("#1f77b4", "#d62728", "#2ca02c", "#9467bd", "#ff7f0e",
    "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf")
}

#' Convenience: discrete scale using palette_paper()
scale_color_paper <- function(...) {
  scale_color_manual(values = palette_paper(), ...)
}
scale_fill_paper <- function(...) {
  scale_fill_manual(values = palette_paper(), ...)
}
