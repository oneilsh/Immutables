#SO

# Runtime: O(1).
# Formats bounds string into human-readable phrase for headers.
# **Inputs:** scalar `bounds` string.
# **Outputs:** scalar character phrase.
# **Used by:** print.interval_index().
.ivx_bounds_phrase <- function(bounds) {
  paste0(substr(bounds, 1L, 1L), "start, end", substr(bounds, 2L, 2L))
}

#' Print an Interval Index Summary
#'
#' Prints a compact summary with interval bounds and a head/tail preview of
#' payload elements.
#'
#' @param x An `interval_index`.
#' @param max_elements Maximum number of elements shown in the preview.
#' @param show_custom_monoids Logical; show attached non-default monoids and
#'   their root cached measures.
#' @param ... Passed through to per-element `print()`.
#' @return Invisibly returns `x`.
#' @examples
#' ix <- interval_index(
#'   one = 1, two = 2, three = 3,
#'   start = c(20, 30, 10), end = c(25, 37, 24)
#' )
#' print(ix, max_elements = 4)
#' width_sum <- measure_monoid(
#'   `+`, 0, function(entry) as.numeric(entry$end - entry$start)
#' )
#' ix3 <- add_monoids(
#'   interval_index(1, 2, start = c(1, 3), end = c(2, 5)),
#'   list(width_sum = width_sum)
#' )
#' print(ix3, max_elements = 0, show_custom_monoids = TRUE)
#'
#' ix2 <- interval_index(1, 2, 3, start = c(2, 4, 6), end = c(3, 5, 8), bounds = "[]")
#' print(ix2, max_elements = 3)
#'
#' print(interval_index())
#' @export
#' @method print interval_index
# Runtime: O((k + h) log n), where k = shown elements and h = preview split overhead.
# Pretty-printer with bounded head/tail preview in interval-start order.
# **Inputs:** `x` interval_index; scalar integer `max_elements`; scalar logical `show_custom_monoids`; forwarded `...`.
# **Outputs:** invisibly returns `x`.
# **Used by:** users/tests.
print.interval_index <- function(x, max_elements = 4L, show_custom_monoids = FALSE, ...) {
  .ivx_assert_index(x)
  max_elements <- .ft_validate_print_max_elements(max_elements)
  show_custom <- .ft_validate_show_custom_monoids(show_custom_monoids)

  n <- length(x)
  bounds <- .ivx_resolve_bounds(x, NULL)
  nn <- as.integer(node_measure(x, ".named_count"))
  named <- isTRUE(nn > 0L)

  cat(
    if(named) "Named" else "Unnamed",
    " interval_index with ",
    n,
    " element",
    if(n == 1L) "" else "s",
    ", default bounds ",
    .ivx_bounds_phrase(bounds),
    ".\n",
    sep = ""
  )
  if(show_custom) {
    .ft_print_custom_monoids(
      x,
      excluded_names = c(".size", ".named_count", ".ivx_max_start", ".ivx_max_end", ".ivx_min_end", ".oms_max_key")
    )
  }

  if(n == 0L || max_elements == 0L) {
    return(invisible(x))
  }

  cat("\nElements (by interval start order):\n\n")
  preview <- .pick_preview_sizes(n, max_elements)
  excluded_names <- c(".size", ".named_count", ".ivx_max_start", ".ivx_max_end", ".ivx_min_end", ".oms_max_key")
  for(i in preview$head) {
    entry <- .ft_get_elem_at(x, as.integer(i))
    nm <- .ft_get_name(entry)
    iv <- paste0(substr(bounds, 1L, 1L), .ft_format_scalar(entry$start), ", ", .ft_format_scalar(entry$end), substr(bounds, 2L, 2L))
    if(named && !is.null(nm)) {
      cat("$", nm, " (interval ", iv, ")\n", sep = "")
    } else {
      cat("[[", i, "]] (interval ", iv, ")\n", sep = "")
    }
    print(entry$value, ...)
    .ft_print_elem_custom_monoids(x, entry, excluded_names, show_custom)
    cat("\n")
  }

  .ft_print_skipped(preview$skipped)

  for(i in preview$tail) {
    entry <- .ft_get_elem_at(x, as.integer(i))
    nm <- .ft_get_name(entry)
    iv <- paste0(substr(bounds, 1L, 1L), .ft_format_scalar(entry$start), ", ", .ft_format_scalar(entry$end), substr(bounds, 2L, 2L))
    if(named && !is.null(nm)) {
      cat("$", nm, " (interval ", iv, ")\n", sep = "")
    } else {
      cat("[[", i, "]] (interval ", iv, ")\n", sep = "")
    }
    print(entry$value, ...)
    .ft_print_elem_custom_monoids(x, entry, excluded_names, show_custom)
    cat("\n")
  }
  invisible(x)
}
