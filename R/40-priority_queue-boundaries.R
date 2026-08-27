#SO

# theoretically someone could define a monoid that allows splitting a priority
# queue, but since the order of elements doesn't relate to priorities the
# resulting split wouldn't be well defined with respect to priorities.
# so we block splitting operations.

# Runtime: O(1).
#' @method split_by_predicate priority_queue
#' @export
#' @noRd
split_by_predicate.priority_queue <- function(x, predicate, monoid_name) {
  stop("`split_by_predicate()` is not supported for priority_queue. Cast first with `as_flexseq()`.")
}

# Runtime: O(1).
#' @method split_around_by_predicate priority_queue
#' @export
#' @noRd
split_around_by_predicate.priority_queue <- function(t, predicate, monoid_name, accumulator = NULL) {
  stop("`split_around_by_predicate()` is not supported for priority_queue. Cast first with `as_flexseq()`.")
}

# Runtime: O(1).
#' @method split_at priority_queue
#' @export
#' @noRd
split_at.priority_queue <- function(x, index, pull_index = FALSE) {
  stop("`split_at()` is not supported for priority_queue. Cast first with `as_flexseq()`.")
}
