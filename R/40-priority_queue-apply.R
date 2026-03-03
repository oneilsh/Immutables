#SO

# Runtime: O(n) total from entry traversal + linear queue rebuild.
.pq_apply_impl <- function(q, f, ..., preserve_custom_monoids = TRUE) {
  .pq_assert_queue(q)
  if(!is.function(f)) {
    stop("`f` must be a function.")
  }
  if(!is.logical(preserve_custom_monoids) || length(preserve_custom_monoids) != 1L || is.na(preserve_custom_monoids)) {
    stop("`preserve_custom_monoids` must be TRUE or FALSE.")
  }

  entries <- as.list(q)
  n <- length(entries)
  out <- vector("list", n)
  out_names <- if(is.null(names(entries))) rep("", n) else names(entries)

  for(i in seq_len(n)) {
    e <- entries[[i]]
    cur_name <- out_names[[i]]

    item2 <- f(e$item, e$priority, cur_name, ...)

    out[[i]] <- list(
      item = item2,
      priority = e$priority
    )
  }

  if(any(out_names != "")) {
    names(out) <- out_names
  }

  user_monoids <- if(isTRUE(preserve_custom_monoids)) {
    all_monoids <- attr(q, "monoids", exact = TRUE)
    custom <- all_monoids[setdiff(names(all_monoids), c(".size", ".named_count", ".pq_min", ".pq_max"))]
    if(length(custom) == 0L) NULL else custom
  } else {
    NULL
  }

  q2 <- .as_flexseq_build(out, monoids = .pq_merge_monoids(user_monoids))
  .pq_wrap_like(q, q2)
}

#' Apply a Function over Priority Queue Entries
#'
#' Applies `FUN` to each queue payload and returns a new `priority_queue`.
#'
#' @method fapply priority_queue
#' @param X A `priority_queue`.
#' @param FUN Function of `(item, priority, name, ...)` returning the new
#'   payload value.
#' @param preserve_custom_monoids Logical scalar. If `TRUE` (default), preserve
#'   custom user monoids; if `FALSE`, keep only required built-in monoids.
#' @param ... Additional arguments passed to `FUN`.
#' @return A new `priority_queue` with transformed payload values.
#' @details
#' Priorities and names are preserved.
#' @examples
#' q <- priority_queue(one = "a", two = "b", three = "c", priorities = c(2, 1, 3))
#' q2 <- fapply(q, function(item, priority, name) toupper(item))
#' peek_min(q2)
#' peek_max(q2)
#'
#' # Extra arguments are forwarded to FUN
#' q3 <- fapply(q, function(item, priority, name, suffix) paste0(item, suffix), suffix = "!")
#' peek_min(q3)
#' @export
fapply.priority_queue <- function(X, FUN, ..., preserve_custom_monoids = TRUE) {
  if(!is.function(FUN)) {
    stop("`FUN` must be a function.")
  }
  .pq_apply_impl(X, FUN, ..., preserve_custom_monoids = preserve_custom_monoids)
}
