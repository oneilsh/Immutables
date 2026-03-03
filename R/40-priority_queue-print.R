#SO

# Runtime: O(log n) near split point depth.
# not using public pop/peek because those don't return priority (for peek) or name (for pop)
.pq_extract_entry <- function(q, monoid_name) {
  .pq_assert_queue(q)
  if(length(q) == 0L) {
    stop("Cannot extract from an empty priority_queue.")
  }

  target <- node_measure(q, monoid_name)
  pred <- function(v) .pq_measure_equal(v, target)
  ctx <- resolve_named_monoid(q, monoid_name)
  ms <- ctx$monoids
  mr <- ctx$monoid
  s <- if(.ft_cpp_can_use(ms)) {
    .ft_cpp_split_tree(q, pred, ms, monoid_name, mr$i)
  } else {
    split_tree_impl_fast(pred, mr$i, q, ms, mr, monoid_name)
  }

  rest <- concat_trees(s$left, s$right)
  rest <- .pq_wrap_like(q, rest)
  list(entry = s$elem, remaining = rest)
}

#' Print a Priority Queue Summary
#'
#' Prints a compact summary with priority range and a head/tail preview.
#'
#' @param x A `priority_queue`.
#' @param max_elements Maximum number of elements shown in the preview.
#' @param ... Passed through to per-element `print()`.
#' @return Invisibly returns `x`.
#' @examples
#' q <- priority_queue(one = 1, two = 2, three = 3, priorities = c(20, 30, 10))
#' print(q, max_elements = 4)
#'
#' q2 <- priority_queue(1, 2, 3, priorities = c(2, 1, 3))
#' print(q2, max_elements = 3)
#'
#' print(priority_queue())
#' @export
# Runtime: O(k log n), where k = shown elements.
print.priority_queue <- function(x, max_elements = 4L, ...) {
  .pq_assert_queue(x)
  max_elements <- .ft_validate_print_max_elements(max_elements)

  n <- as.integer(node_measure(x, ".size"))
  nn <- as.integer(node_measure(x, ".named_count"))
  named <- isTRUE(nn > 0L)
  cat(if(named) "Named" else "Unnamed", " priority_queue with ", n, " element", if(n == 1L) "" else "s", ".\n", sep = "")
  if(n > 0L) {
    minm <- node_measure(x, ".pq_min")
    maxm <- node_measure(x, ".pq_max")
    cat("Minimum priority: ", .ft_format_scalar(minm$priority), ", Maximum priority: ", .ft_format_scalar(maxm$priority), "\n", sep = "")
  }
  if(n == 0L || max_elements == 0L) {
    return(invisible(x))
  }

  cat("\nElements (by priority):\n\n")

  preview <- .pick_preview_sizes(n, max_elements)
  head_entries <- vector("list", length(preview$head))
  q_head <- x
  if(length(preview$head) > 0L) {
    for(i in seq_along(head_entries)) {
      out <- .pq_extract_entry(q_head, ".pq_min")
      head_entries[[i]] <- out$entry
      q_head <- out$remaining
    }
  }

  tail_entries <- vector("list", length(preview$tail))
  q_tail <- x
  if(length(preview$tail) > 0L) {
    for(i in seq_along(tail_entries)) {
      out <- .pq_extract_entry(q_tail, ".pq_max")
      tail_entries[[i]] <- out$entry
      q_tail <- out$remaining
    }
    tail_entries <- rev(tail_entries)
  }

  for(entry in head_entries) {
    nm <- .ft_get_name(entry)
    if(named && !is.null(nm)) {
      cat("$", nm, " (priority ", .ft_format_scalar(entry$priority), ")\n", sep = "")
    } else {
      cat("(priority ", .ft_format_scalar(entry$priority), ")\n", sep = "")
    }
    print(entry$item, ...)
    cat("\n")
  }

  .ft_print_skipped(preview$skipped)

  for(entry in tail_entries) {
    nm <- .ft_get_name(entry)
    if(named && !is.null(nm)) {
      cat("$", nm, " (priority ", .ft_format_scalar(entry$priority), ")\n", sep = "")
    } else {
      cat("(priority ", .ft_format_scalar(entry$priority), ")\n", sep = "")
    }
    print(entry$item, ...)
    cat("\n")
  }
  invisible(x)
}
