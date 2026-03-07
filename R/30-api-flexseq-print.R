#SO

# Runtime: O(1).
.ft_validate_print_max_elements <- function(max_elements) {
  out <- as.integer(max_elements)
  if(length(out) != 1L || is.na(out) || out < 0L) {
    stop("`max_elements` must be a single non-negative integer.")
  }
  out
}

# Runtime: O(1).
.ft_validate_show_custom_monoids <- function(show_custom_monoids) {
  if(!is.logical(show_custom_monoids) || length(show_custom_monoids) != 1L || is.na(show_custom_monoids)) {
    stop("`show_custom_monoids` must be TRUE or FALSE.")
  }
  isTRUE(show_custom_monoids)
}

# Runtime: O(1).
.pick_preview_sizes <- function(n, max_elements) {
  if(n <= 0L || max_elements <= 0L) {
    return(list(head = integer(0), tail = integer(0), skipped = max(0L, n)))
  }
  if(n <= max_elements) {
    return(list(head = seq_len(n), tail = integer(0), skipped = 0L))
  }

  head_n <- as.integer(ceiling(max_elements / 2))
  tail_n <- as.integer(max_elements - head_n)

  head <- seq_len(head_n)
  tail <- if(tail_n > 0L) seq.int(n - tail_n + 1L, n) else integer(0)
  skipped <- as.integer(n - length(head) - length(tail))
  list(head = head, tail = tail, skipped = skipped)
}

# Runtime: O(1).
.ft_print_skipped <- function(skipped) {
  if(skipped <= 0L) {
    return(invisible(NULL))
  }
  cat(
    "... (skipping ",
    skipped,
    " element",
    if(skipped == 1L) "" else "s",
    ")\n\n",
    sep = ""
  )
  invisible(NULL)
}

# Runtime: O(1) expected for scalar formatting.
.ft_format_scalar <- function(x) {
  txt <- tryCatch(format(x), error = function(e) NULL)
  if(is.null(txt) || length(txt) == 0L) {
    return("<unprintable>")
  }
  trimws(paste(txt, collapse = " "))
}

# Runtime: O(m), where m = number of monoids on tree root.
.ft_custom_monoid_names <- function(x, excluded_names) {
  monoids <- names(resolve_tree_monoids(x, required = TRUE))
  setdiff(monoids, excluded_names)
}

# Runtime: O(m), where m = number of visible custom monoids.
.ft_print_custom_monoids <- function(x, excluded_names) {
  custom <- .ft_custom_monoid_names(x, excluded_names = excluded_names)
  if(length(custom) == 0L) {
    cat("Custom monoids + measures: <none>\n")
    return(invisible(NULL))
  }

  cat("Custom monoids + measures:\n")
  for(name in custom) {
    cat("  ", name, ": ", .ft_format_scalar(node_measure(x, name)), "\n", sep = "")
  }
  invisible(NULL)
}

# Runtime: O(log n).
.ft_print_elem_at <- function(x, i, named, ...) {
  el <- .ft_get_elem_at(x, as.integer(i))
  nm <- .ft_get_name(el)
  if(isTRUE(named) && !is.null(nm)) {
    cat("$", nm, "\n", sep = "")
  } else {
    cat("[[", i, "]]\n", sep = "")
  }
  print(.ft_strip_name(el), ...)
  cat("\n")
  invisible(NULL)
}

#' Print a compact summary of a finger tree
#'
#' @method print FingerTree
#' @param x FingerTree.
#' @param max_elements Maximum number of elements shown in preview (`head + tail`).
#'   Default `4`.
#' @param show_custom_monoids Logical; show attached non-default monoids and
#'   their root cached measures. Default `FALSE`.
#' @param ... Passed through to `print()` for preview elements.
#' @return `x`, invisibly.
#' @examples
#' x <- as_flexseq(setNames(as.list(1:6), letters[1:6]))
#' print(x, max_elements = 4)
#' sum_m <- measure_monoid(`+`, 0, function(el) as.numeric(el))
#' print(add_monoids(as_flexseq(1:3), list(sum = sum_m)), max_elements = 0, show_custom_monoids = TRUE)
#'
#' y <- as_flexseq(as.list(1:6))
#' print(y, max_elements = 3)
#' @keywords internal
# Runtime: O((k + h) log n), where k = shown elements and h = preview split overhead.
print.FingerTree <- function(x, max_elements = 4L, show_custom_monoids = FALSE, ...) {
  n <- as.integer(node_measure(x, ".size"))
  nn <- as.integer(node_measure(x, ".named_count"))
  named <- isTRUE(nn > 0L)
  max_elements <- .ft_validate_print_max_elements(max_elements)
  show_custom <- .ft_validate_show_custom_monoids(show_custom_monoids)
  preview <- .pick_preview_sizes(n, max_elements)
  cat(if(named) "Named" else "Unnamed", " flexseq with ", n, " element", if(n == 1L) "" else "s", ".\n", sep = "")
  if(show_custom) {
    .ft_print_custom_monoids(x, excluded_names = c(".size", ".named_count"))
  }

  if(n == 0L || max_elements == 0L) {
    return(invisible(x))
  }

  cat("\nElements:\n\n")

  for(i in preview$head) {
    .ft_print_elem_at(x, i, named, ...)
  }

  .ft_print_skipped(preview$skipped)

  for(i in preview$tail) {
    .ft_print_elem_at(x, i, named, ...)
  }
  invisible(x)
}

#' Print a flexseq
#'
#' @name print.flexseq
#' @method print flexseq
#' @param x A `flexseq`.
#' @param max_elements Maximum number of elements shown in preview (`head + tail`).
#' @param show_custom_monoids Logical; show attached non-default monoids and
#'   their root cached measures.
#' @param ... Passed through to per-element `print()`.
#' @examples
#' x <- as_flexseq(setNames(as.list(1:6), letters[1:6]))
#' print(x, max_elements = 4)
#'
#' y <- as_flexseq(as.list(1:6))
#' print(y, max_elements = 3)
#' @export
# Runtime: Delegates to `print.FingerTree`.
print.flexseq <- function(x, max_elements = 4L, show_custom_monoids = FALSE, ...) {
  print.FingerTree(x, max_elements = max_elements, show_custom_monoids = show_custom_monoids, ...)
}

#' @rdname print.FingerTree
#' @method print Deep
#' @keywords internal
# Runtime: Delegates to `print.FingerTree`.
print.Deep <- function(x, ...) {
  print.FingerTree(x, ...)
}

#' @rdname print.FingerTree
#' @method print Single
#' @keywords internal
# Runtime: Delegates to `print.FingerTree`.
print.Single <- function(x, ...) {
  print.FingerTree(x, ...)
}

#' @rdname print.FingerTree
#' @method print Empty
#' @keywords internal
# Runtime: Delegates to `print.FingerTree`.
print.Empty <- function(x, ...) {
  print.FingerTree(x, ...)
}
