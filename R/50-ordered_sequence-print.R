#SO

#' Print an Ordered Sequence Summary
#'
#' Prints a compact summary and head/tail preview in key order.
#'
#' @param x An `ordered_sequence`.
#' @param max_elements Maximum number of elements shown in the preview.
#' @param show_custom_monoids Logical; show attached non-default monoids and
#'   their root cached measures.
#' @param ... Passed through to per-element `print()`.
#' @return Invisibly returns `x`.
#' @examples
#' xs <- ordered_sequence(one = "a", two = "b", three = "c", keys = c(20, 30, 10))
#' print(xs, max_elements = 4)
#' sum_key <- measure_monoid(`+`, 0, function(entry) as.numeric(entry$key))
#' ys2 <- add_monoids(ordered_sequence("a", "b", keys = c(2, 1)), list(sum_key = sum_key))
#' print(ys2, max_elements = 0, show_custom_monoids = TRUE)
#'
#' ys <- ordered_sequence("x", "y", "z", keys = c(2, 1, 3))
#' print(ys, max_elements = 3)
#'
#' print(ordered_sequence())
#' @export
#' @method print ordered_sequence
# Runtime: O((k + h) log n), where k = shown elements and h = preview split overhead.
print.ordered_sequence <- function(x, max_elements = 4L, show_custom_monoids = FALSE, ...) {
  .oms_assert_set(x)
  max_elements <- .ft_validate_print_max_elements(max_elements)
  show_custom <- .ft_validate_show_custom_monoids(show_custom_monoids)

  n <- length(x)
  nn <- as.integer(node_measure(x, ".named_count"))
  named <- isTRUE(nn > 0L)
  cat(if(named) "Named" else "Unnamed", " ordered_sequence with ", n, " element", if(n == 1L) "" else "s", ".\n", sep = "")
  if(show_custom) {
    .ft_print_custom_monoids(x, excluded_names = c(".size", ".named_count", ".oms_max_key"))
  }

  if(n == 0L || max_elements == 0L) {
    return(invisible(x))
  }

  cat("\nElements (by key order):\n\n")
  preview <- .pick_preview_sizes(n, max_elements)
  for(i in preview$head) {
    entry <- .ft_get_elem_at(x, as.integer(i))
    nm <- .ft_get_name(entry)
    if(named && !is.null(nm)) {
      cat("$", nm, " (key ", .ft_format_scalar(entry$key), ")\n", sep = "")
    } else {
      cat("[[", i, "]] (key ", .ft_format_scalar(entry$key), ")\n", sep = "")
    }
    print(entry$value, ...)
    cat("\n")
  }

  .ft_print_skipped(preview$skipped)

  for(i in preview$tail) {
    entry <- .ft_get_elem_at(x, as.integer(i))
    nm <- .ft_get_name(entry)
    if(named && !is.null(nm)) {
      cat("$", nm, " (key ", .ft_format_scalar(entry$key), ")\n", sep = "")
    } else {
      cat("[[", i, "]] (key ", .ft_format_scalar(entry$key), ")\n", sep = "")
    }
    print(entry$value, ...)
    cat("\n")
  }
  invisible(x)
}
