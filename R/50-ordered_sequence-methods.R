#SO

#' @method as_flexseq ordered_sequence
#' @export
# Runtime: O(n) from list materialization + linear rebuild.
as_flexseq.ordered_sequence <- function(x) {
  entries <- as.list(x)
  .as_flexseq_build.default(entries, monoids = NULL)
}

#' Coerce Ordered Sequence to List
#'
#' @method as.list ordered_sequence
#' @param x An `ordered_sequence`.
#' @param ... Unused.
#' @return A plain list of elements in key order.
#' @details
#' Returns payload elements only (keys are omitted) in canonical key order.
#' If entries are named, names are preserved on the returned list.
#' @examples
#' x <- ordered_sequence("a", "b", "c", keys = c(2, 1, 3))
#' as.list(x)
#' @export
# Runtime: O(n).
as.list.ordered_sequence <- function(x, ...) {
  .oms_assert_set(x)
  .oms_extract_items(as.list.flexseq(x, ...))
}

#' Ordered Sequence Length
#'
#' @method length ordered_sequence
#' @param x An `ordered_sequence`.
#' @return Integer length.
#' @details
#' Uses cached size metadata and runs in O(1).
#' @examples
#' x <- ordered_sequence("a", "b", keys = c(2, 1))
#' length(x)
#'
#' length(ordered_sequence())
#' @export
# Runtime: O(1).
length.ordered_sequence <- function(x) {
  .oms_assert_set(x)
  as.integer(node_measure(x, ".size"))
}
