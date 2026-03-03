#SO

#' Construct a Measure Monoid Specification
#'
#' Defines how element-level values are measured and combined as accumulated
#' tree metadata.
#'
#' @param f Associative binary function over measure values.
#' @param i Identity value for `f`.
#' @param measure Function mapping one element to its measure value.
#' @return An object of class `measure_monoid`.
#' @details
#' A measure monoid has three parts:
#' - `measure(element)`: maps each element to a measure value.
#' - `f(left, right)`: combines two measure values.
#' - `i`: identity value for `f`.
#'
#' Requirements:
#' - `f` should be associative.
#' - `i` should satisfy `f(i, x) == x` and `f(x, i) == x`.
#' - `measure()` outputs must be compatible with `f` and `i`.
#'
#' `measure_monoid()` only constructs the specification; it becomes active after
#' being attached to a structure via [add_monoids()].
#' @examples
#' sum_m <- measure_monoid(`+`, 0, as.numeric)
#' x <- as_flexseq(1:5)
#' x2 <- add_monoids(x, list(sum = sum_m))
#' attr(x2, "measures")$sum
#' split_around_by_predicate(x2, function(v) v >= 6, "sum")
#'
#' # Count elements
#' count_m <- measure_monoid(`+`, 0L, function(el) 1L)
#' x3 <- add_monoids(x, list(count = count_m))
#' attr(x3, "measures")$count
#'
#' # Character-width accumulation
#' width_m <- measure_monoid(`+`, 0L, function(el) nchar(as.character(el)))
#' s <- as_flexseq(c("aa", "b", "cccc"))
#' s2 <- add_monoids(s, list(width = width_m))
#' attr(s2, "measures")$width
#' @export
# Runtime: O(1).
measure_monoid <- function(f, i, measure) {
  res <- list(f = f, i = i, measure = measure)
  class(res) <- c("measure_monoid", "MeasureMonoid", class(res))
  res
}
