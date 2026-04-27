#SO

#' Create an Empty Structural Tree
#'
#' @param monoids Optional named list of `measure_monoid` objects.
#' @return An empty finger tree with structural `monoids` and `measures` attrs.
#' @keywords internal
# Runtime: O(1).
empty_tree <- function(monoids = NULL) {
  ms <- if(is.null(monoids)) {
    list(.size = size_measure_monoid())
  } else {
    ensure_size_monoids(monoids)
  }
  measured_empty(ms)
}
