#SO

#' @method split_around_by_predicate flexseq
#' @export
# Runtime: O(log n) near split point depth.
split_around_by_predicate.flexseq <- function(t, predicate, monoid_name, accumulator = NULL) {
  ctx <- resolve_named_monoid(t, monoid_name)
  ms <- ctx$monoids
  mr <- ctx$monoid

  if(t %isa% Empty) {
    stop("split_around_by_predicate requires a non-empty tree.")
  }

  i <- if(is.null(accumulator)) mr$i else accumulator
  out <- if(.ft_cpp_can_use(ms)) {
    .ft_cpp_split_tree(t, predicate, ms, monoid_name, i)
  } else {
    split_tree_impl_fast(predicate, i, t, ms, mr, monoid_name)
  }
  out$left <- .ft_restore_subclass(.as_flexseq(out$left), t, context = "split_around_by_predicate()")
  out$right <- .ft_restore_subclass(.as_flexseq(out$right), t, context = "split_around_by_predicate()")
  out
}

#' @method split_by_predicate flexseq
#' @export
# Runtime: O(log n) near split point depth.
split_by_predicate.flexseq <- function(x, predicate, monoid_name) {
  ctx <- resolve_named_monoid(x, monoid_name)
  ms <- ctx$monoids
  mr <- ctx$monoid

  if(x %isa% Empty) {
    left_empty <- .ft_restore_subclass(.as_flexseq(measured_empty(ms)), x, context = "split_by_predicate()")
    right_empty <- .ft_restore_subclass(.as_flexseq(measured_empty(ms)), x, context = "split_by_predicate()")
    return(list(left = left_empty, right = right_empty))
  }

  if(predicate(node_measure(x, monoid_name))) {
    s <- if(.ft_cpp_can_use(ms)) {
      .ft_cpp_split_tree(x, predicate, ms, monoid_name, mr$i)
    } else {
      split_tree_impl_fast(predicate, mr$i, x, ms, mr, monoid_name)
    }
    right <- push_front(s$right, s$value)
    left_out <- .ft_restore_subclass(.as_flexseq(s$left), x, context = "split_by_predicate()")
    right_out <- .ft_restore_subclass(.as_flexseq(right), x, context = "split_by_predicate()")
    return(list(left = left_out, right = right_out))
  }

  left_out <- .ft_restore_subclass(.as_flexseq(x), x, context = "split_by_predicate()")
  right_out <- .ft_restore_subclass(.as_flexseq(measured_empty(ms)), x, context = "split_by_predicate()")
  list(left = left_out, right = right_out)
}

#' @method split_at flexseq
#' @export
# Runtime: O(log n) for scalar index splits; O(n) for scalar name lookup + split.
split_at.flexseq <- function(x, at, pull_index = FALSE) {
  if(is.logical(at)) {
    stop("`at` must be a scalar index or name.")
  }

  idx <- NULL
  if(is.numeric(at) && length(at) == 1L && !is.na(at) && at == as.integer(at)) {
    n <- as.integer(node_measure(x, ".size"))
    idx <- .ft_assert_int_indices(as.integer(at), n)
    if(length(idx) != 1L) {
      stop("`at` must be a single valid index.")
    }
    idx <- as.integer(idx[[1L]])
  } else if(is.character(at) && length(at) == 1L && !is.na(at) && at != "") {
    idx <- .ft_match_name_indices(x, at, strict_missing = TRUE)
    idx <- as.integer(idx[[1L]])
  } else {
    stop("`at` must be a positive scalar integer index or a scalar non-empty name.")
  }

  predicate <- function(v) v >= idx
  if(isTRUE(pull_index)) {
    return(split_by_predicate(x, predicate, ".size"))
  }
  split_around_by_predicate(x, predicate, ".size")
}
