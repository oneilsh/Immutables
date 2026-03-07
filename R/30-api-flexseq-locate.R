#SO

#' @method locate_by_predicate flexseq
#' @export
# Runtime: O(log n) near locate point depth.
locate_by_predicate.flexseq <- function(t, predicate, monoid_name, accumulator = NULL, include_metadata = FALSE) {
  ctx <- resolve_named_monoid(t, monoid_name)
  ms <- ctx$monoids
  mr <- ctx$monoid

  if(t %isa% Empty) {
    if(!isTRUE(include_metadata)) {
      return(list(found = FALSE, value = NULL))
    }
    i0 <- if(is.null(accumulator)) mr$i else accumulator
    return(list(
      found = FALSE,
      value = NULL,
      metadata = list(left_measure = i0, hit_measure = NULL, right_measure = NULL, index = NULL)
    ))
  }

  i <- if(is.null(accumulator)) mr$i else accumulator
  total <- mr$f(i, node_measure(t, monoid_name))

  if(!predicate(total)) {
    if(!isTRUE(include_metadata)) {
      return(list(found = FALSE, value = NULL))
    }
    return(list(
      found = FALSE,
      value = NULL,
      metadata = list(left_measure = total, hit_measure = NULL, right_measure = NULL, index = NULL)
    ))
  }

  res <- if(.ft_cpp_can_use(ms)) {
    .ft_cpp_locate(t, predicate, ms, monoid_name, i)
  } else {
    locate_tree_impl_fast(predicate, i, t, ms, mr, monoid_name, 0L)
  }
  if(!isTRUE(include_metadata)) {
    return(list(found = res$found, value = res$value))
  }

  list(
    found = res$found,
    value = res$value,
    metadata = list(
      left_measure = res$left_measure,
      hit_measure = res$hit_measure,
      right_measure = res$right_measure,
      index = res$index
    )
  )
}
