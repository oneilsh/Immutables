#SO

#' Deprecated functions in Immutables
#'
#' These functions still work but emit a deprecation warning and will be
#' removed in a future release. Use the replacements instead:
#'
#' * `peek_overlaps()`: use [peek_overlapping()].
#' * `peek_all_overlaps()`: use [peek_all_overlapping()].
#' * `pop_overlaps()`: use [pop_overlapping()].
#' * `pop_all_overlaps()`: use [pop_all_overlapping()].
#'
#' The `*_overlaps` names were renamed in version 1.2.0 so that the
#' single-match functions read as singular, matching `peek_containing()` and
#' `peek_within()`.
#'
#' @param x An `interval_index`.
#' @param start Query interval start.
#' @param end Query interval end.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @param as_list Passed to [peek_all_overlapping()].
#' @return The same value as the replacement function.
#' @name Immutables-deprecated
NULL

#' @rdname Immutables-deprecated
#' @export
peek_overlaps <- function(x, start, end, bounds = NULL) {
  .Deprecated("peek_overlapping", package = "Immutables")
  peek_overlapping(x, start, end, bounds = bounds)
}

#' @rdname Immutables-deprecated
#' @export
peek_all_overlaps <- function(x, start, end, bounds = NULL, as_list = FALSE) {
  .Deprecated("peek_all_overlapping", package = "Immutables")
  peek_all_overlapping(x, start, end, bounds = bounds, as_list = as_list)
}

#' @rdname Immutables-deprecated
#' @export
pop_overlaps <- function(x, start, end, bounds = NULL) {
  .Deprecated("pop_overlapping", package = "Immutables")
  pop_overlapping(x, start, end, bounds = bounds)
}

#' @rdname Immutables-deprecated
#' @export
pop_all_overlaps <- function(x, start, end, bounds = NULL) {
  .Deprecated("pop_all_overlapping", package = "Immutables")
  pop_all_overlapping(x, start, end, bounds = bounds)
}
