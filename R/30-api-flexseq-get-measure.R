#SO

# validate common inputs for get_measure / get_measures
# Runtime: O(1).
.get_measure_validate <- function(x, monoid_name, context) {
  if(!is_structural_node(x)) {
    stop("`x` must be a finger-tree structure (flexseq or subclass).", call. = FALSE)
  }
  if(!is.character(monoid_name) || length(monoid_name) != 1L || is.na(monoid_name) || monoid_name == "") {
    stop("`monoid_name` must be a single non-empty string.", call. = FALSE)
  }
  monoids <- attr(x, "monoids", exact = TRUE)
  if(is.null(monoids) || is.null(monoids[[monoid_name]])) {
    stop("Monoid '", monoid_name, "' is not attached to `x`. ",
         "Attach it with `add_monoids()` first.", call. = FALSE)
  }
  monoids[[monoid_name]]
}

#' Read a Cached Subtree Measure
#'
#' Returns the monoid's accumulated measure across the whole (sub)tree at
#' the root of `x`. This is the cached value that internal operations use
#' for O(log n) locate and split.
#'
#' @param x A flexseq (or any immutables subclass).
#' @param monoid_name Name of an attached monoid (e.g. `.size`, a custom
#'   name from [add_monoids()], or a built-in like `.pq_min` /
#'   `.oms_max_key`).
#' @return The cached monoid value at the root of `x`. Shape depends on
#'   the monoid — typically atomic (e.g. a numeric sum) but may be a list
#'   for built-ins that carry auxiliary state.
#' @details
#' On the full tree `x`, this is the aggregate over every element. After a
#' split — e.g. `s <- split_by_predicate(x, p, "sum")` — call
#' `get_measure(s$left, "sum")` to read the aggregate of just the left
#' side in O(1).
#'
#' For per-element measures, see [get_measures()].
#' @seealso [get_measures()], [measure_monoid()], [add_monoids()]
#' @examples
#' sum_m <- measure_monoid(`+`, 0, function(el) el)
#' x <- add_monoids(as_flexseq(c(3, 1, 4, 1, 5, 9, 2, 6)),
#'                  list(sum = sum_m))
#' get_measure(x, "sum")         # total across the whole tree
#' get_measure(x, ".size")       # built-in: element count
#'
#' q <- priority_queue("a", "b", "c", priorities = c(5, 1, 3))
#' get_measure(q, ".pq_min")     # built-in, list-valued
#' @export
# Runtime: O(1), reads cached attribute.
get_measure <- function(x, monoid_name) {
  .get_measure_validate(x, monoid_name, "get_measure")
  node_measure(x, monoid_name)
}

#' Read Per-Element Monoid Measures
#'
#' Applies the named monoid's `measure()` function to each leaf entry in
#' sequence order, returning the results as a new `flexseq`.
#'
#' @param x A flexseq (or any immutables subclass).
#' @param monoid_name Name of an attached monoid.
#' @return A plain unnamed `flexseq` of length `length(x)`. Entry `i` is
#'   the monoid's `measure()` applied to the `i`-th leaf entry.
#' @details
#' Each leaf in a finger tree stores a structure-specific *entry*
#' (flexseq: the raw element; ordered_sequence: `list(value, key)`;
#' priority_queue: `list(value, priority)`; interval_index:
#' `list(value, start, end)`). A monoid's `measure()` function is defined
#' over that entry shape, and this accessor exposes the per-element
#' values that would be combined to produce the cached aggregate.
#'
#' Returns a `flexseq` rather than a base list so results can be piped
#' back into other immutables operations; use [as.list()] or [unlist()]
#' to convert.
#' @seealso [get_measure()], [measure_monoid()], [fapply()]
#' @examples
#' sum_m <- measure_monoid(`+`, 0, function(el) el)
#' x <- add_monoids(as_flexseq(c(3, 1, 4, 1, 5, 9)), list(sum = sum_m))
#' get_measures(x, "sum") |> unlist()
#'
#' q <- priority_queue("a", "b", "c", priorities = c(5, 1, 3))
#' # Per-element .pq_min measures — each is list(has, priority).
#' get_measures(q, ".pq_min")
#' @export
# Runtime: O(n) over number of elements.
get_measures <- function(x, monoid_name) {
  monoid <- .get_measure_validate(x, monoid_name, "get_measures")
  entries <- .ft_to_list(x)
  if(length(entries) == 0L) {
    return(flexseq())
  }
  as_flexseq(lapply(entries, monoid$measure))
}
