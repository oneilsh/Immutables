#SO

# Runtime: O(n) from list materialization + linear rebuild.
.as_flexseq_build.ordered_sequence <- function(x, monoids = NULL) {
  entries <- as.list.flexseq(x)
  out_monoids <- monoids
  if(is.null(out_monoids)) {
    ms <- attr(x, "monoids", exact = TRUE)
    out_monoids <- ms[setdiff(names(ms), c(".oms_max_key"))]
  }
  .as_flexseq_build.default(entries, monoids = out_monoids)
}

#' @method as_flexseq ordered_sequence
#' @export
# Runtime: O(n) from list materialization + linear rebuild.
as_flexseq.ordered_sequence <- function(x) {
  .as_flexseq_build.ordered_sequence(x, monoids = NULL)
}

#' Plot an Ordered Sequence Tree
#'
#' Plots the underlying tree structure used by an `ordered_sequence`.
#'
#' @method plot ordered_sequence
#' @param x An `ordered_sequence`.
#' @param ... Passed to the internal tree plotting routine.
#' @examples
#' x <- ordered_sequence("a", "b", "c", keys = c(2, 1, 3))
#' plot(x)
#' @export
# Runtime: O(n) to build plot graph data.
plot.ordered_sequence <- function(x, ...) {
  plot.flexseq(x, ...)
}

#' Coerce Ordered Sequence to List
#'
#' @method as.list ordered_sequence
#' @param x An `ordered_sequence`.
#' @param ... Unused.
#' @return A plain list of elements in key order.
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
#' @export
# Runtime: O(1).
length.ordered_sequence <- function(x) {
  .oms_assert_set(x)
  as.integer(node_measure(x, ".size"))
}
