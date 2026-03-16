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

  dot_args <- list(...)
  accepts_name <- .ft_fun_accepts_n_positional(f, 3L)
  has_dots <- length(dot_args) > 0L

  for(i in seq_len(n)) {
    e <- entries[[i]]
    cur_name <- out_names[[i]]
    item2 <- if(accepts_name && !has_dots) {
      f(e$value, e$priority, cur_name)
    } else if(!accepts_name && !has_dots) {
      f(e$value, e$priority)
    } else if(accepts_name) {
      do.call(f, c(list(e$value, e$priority, cur_name), dot_args))
    } else {
      do.call(f, c(list(e$value, e$priority), dot_args))
    }

    out[[i]] <- list(
      value = item2,
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

#' @method fapply priority_queue
#' @export
#' @noRd
fapply.priority_queue <- function(X, FUN, ..., preserve_custom_monoids = TRUE) {
  if(!is.function(FUN)) {
    stop("`FUN` must be a function.")
  }
  .pq_apply_impl(X, FUN, ..., preserve_custom_monoids = preserve_custom_monoids)
}
