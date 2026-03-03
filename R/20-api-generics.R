#SO

#' Fapply with S3 dispatch
#'
#' `fapply()` is an S3 generic for applying functions over immutable
#' structures with type-specific dispatch.
#'
#' @param X Object to apply over.
#' @param FUN Function to apply.
#' @param ... Method-specific arguments.
#' @return Method-dependent result.
#' @seealso [fapply.flexseq()], [fapply.priority_queue()], [fapply.ordered_sequence()], [fapply.interval_index()]
#' @export
fapply <- function(X, FUN, ...) {
  UseMethod("fapply")
}

#' Add or Merge Measure Monoids
#'
#' Attaches one or more named [measure_monoid()] definitions to an existing
#' immutable structure.
#'
#' @param t Immutable structure (`flexseq` and subclasses).
#' @param monoids Named list of [measure_monoid()] objects.
#' @param overwrite Logical; if `TRUE`, replace existing monoids with the same
#'   names. If `FALSE`, existing names are kept.
#' @return A persistent copy with updated monoid definitions and cached measures.
#' @details
#' Mechanics:
#' - Each monoid name defines an independent accumulated measure over elements in the tree.
#' - New monoids are computed for all elements and cached in the returned object.
#' - Existing monoids are unchanged unless `overwrite = TRUE`.
#' - Structural/reserved monoid names cannot be replaced.
#'
#' This operation is persistent: `t` is not modified.
#'
#' Use this when you want fast predicate scans (for example with
#' [locate_by_predicate()], [split_by_predicate()], [split_around_by_predicate()])
#' driven by domain-specific accumulated values.
#' @examples
#' x <- flexseq(10, 20, 30)
#'
#' running_sum <- measure_monoid(`+`, 0, as.numeric)
#' x2 <- add_monoids(x, list(sum = running_sum))
#' attr(x2, "measures")$sum
#'
#' # Overwrite an existing monoid definition
#' running_count <- measure_monoid(`+`, 0L, function(e) 1L)
#' x3 <- add_monoids(x2, list(sum = running_count), overwrite = TRUE)
#' attr(x3, "measures")$sum
#' @export
#' @seealso [add_monoids.flexseq()], [add_monoids.priority_queue()],
#'   [add_monoids.ordered_sequence()], [add_monoids.interval_index()]
# Runtime: O(1) dispatch.
add_monoids <- function(t, monoids, overwrite = FALSE) {
  UseMethod("add_monoids")
}

# Runtime: O(1).
#' @export
#' @noRd
add_monoids.default <- function(t, monoids, overwrite = FALSE) {
  cls <- class(t)
  cls_txt <- if(length(cls) == 0L) "unknown" else paste(cls, collapse = "/")
  stop(sprintf("No `add_monoids()` method for class '%s'.", cls_txt))
}

#' Coerce Objects to `flexseq`
#'
#' `as_flexseq()` is the canonical way to obtain a plain `flexseq` for full
#' sequence-style operations.
#'
#' For base vectors/lists, this builds a new `flexseq` preserving element order
#' and names.
#'
#' For specialized immutable subclasses (`priority_queue`,
#' `ordered_sequence`, `interval_index`), this intentionally drops subclass
#' semantics and returns a plain `flexseq` over stored entries.
#'
#' @param x Input object.
#' @return A plain `flexseq`.
#' @details
#' This is an S3 generic. Notable method behavior:
#' - `as_flexseq.flexseq(x)` returns `x` unchanged.
#' - `as_flexseq.priority_queue(x)` drops queue-only API constraints and removes
#'   queue-specific monoids.
#' - `as_flexseq.ordered_sequence(x)` and `as_flexseq.interval_index(x)` drop
#'   ordered/query semantics and return sequence entries.
#' @examples
#' x <- as_flexseq(1:3)
#' x
#'
#' q <- priority_queue("a", "b", priorities = c(2, 1))
#' as_flexseq(q)
#'
#' o <- ordered_sequence("a", "b", keys = c(2, 1))
#' as_flexseq(o)
#' @seealso [flexseq()], [priority_queue()], [ordered_sequence()], [interval_index()]
#' @export
# Runtime: O(1) generic dispatch.
as_flexseq <- function(x) {
  UseMethod("as_flexseq")
}

#' Locate First Predicate Flip Without Reconstructing Context Trees
#'
#' Read-only analogue of [split_around_by_predicate()]: finds the distinguished
#' element where the scan predicate flips, but does not rebuild left/right
#' trees.
#'
#' @param t A `flexseq`.
#' @param predicate Function on accumulated measure values.
#' @param monoid_name Name of monoid from `attr(t, "monoids")`.
#' @param accumulator Optional starting measure (defaults to monoid identity).
#' @param include_metadata Logical; include left/hit/right measures and index.
#' @details
#' For `priority_queue` objects, `metadata$index` (when requested) is the
#' internal structural position in the underlying sequence representation. It is
#' not related to priority rank and is not stable across queue updates, so it
#' should be treated as diagnostic metadata only.
#' @return If `include_metadata = FALSE`: `list(found, elem)`.
#'   If `TRUE`: `list(found, elem, metadata = list(left_measure, hit_measure,
#'   right_measure, index))`.
#' @export
locate_by_predicate <- function(t, predicate, monoid_name, accumulator = NULL, include_metadata = FALSE) {
  UseMethod("locate_by_predicate")
}

#' Split Around First Predicate Match
#'
#' Splits at the first point where a `predicate` function becomes `TRUE` 
#' while scanning the sequence.
#'
#' @param t A `flexseq`.
#' @param predicate Function applied to accumulated monoid values.
#' @param monoid_name Name of the monoid used for scanning.
#' @param accumulator Optional starting accumulator value.
#' @return A list with fields:
#' - `left`: elements before the split point.
#' - `elem`: the matched element at the split point.
#' - `right`: elements after the split point.
#' @details
#' This function generally requires the sequence be annotated with
#' a `measure_monoid()`; see the examples and `measure_monoid()`
#' for more information.
#' @examples
#' x <- flexseq("a", "b", "c", "d")
#' 
#' # Each element e has measure 1; the accumulated measure for
#' # a set of elements is computed by the associative function `+`
#' # along with the identity value 0.
#' size_monoid <- measure_monoid(`+`, 0L, function(e) 1L)
#' x2 <- add_monoids(x, list(size = size_monoid))
#' 
#' # the first time the measure stored in the size monoid
#' # accumulates to greater than or equal to 3 is the 3rd
#' # element in sequence.
#' split_around_by_predicate(x2, function(v) v >= 3L, "size")
#'
#' # Split at the first element
#' split_around_by_predicate(x2, function(v) v >= 1L, "size")
#'
#' # Split at the last element
#' split_around_by_predicate(x2, function(v) v >= 4L, "size")
#' @export
split_around_by_predicate <- function(t, predicate, monoid_name, accumulator = NULL) {
  UseMethod("split_around_by_predicate")
}

#' Split into Left and Right Parts
#'
#' Splits at the first point where `predicate` becomes `TRUE` while scanning
#' the sequence.
#'
#' @param x A `flexseq`.
#' @param predicate Function applied to accumulated monoid values.
#' @param monoid_name Name of the monoid used for scanning.
#' @return A list with fields:
#' - `left`: elements before the split point.
#' - `right`: elements from the split point onward.
#' @details
#' This is the two-way variant of [split_around_by_predicate()].
#'
#' As with [split_around_by_predicate()], a common setup is a custom monoid
#' created with [measure_monoid()] and attached via [add_monoids()].
#' @examples
#' x <- flexseq("a", "b", "c", "d")
#' size_monoid <- measure_monoid(`+`, 0L, function(e) 1L)
#' x2 <- add_monoids(x, list(size = size_monoid))
#' split_by_predicate(x2, function(v) v >= 3L, "size")
#'
#' # Split at the first element
#' split_by_predicate(x2, function(v) v >= 1L, "size")
#' @export
split_by_predicate <- function(x, predicate, monoid_name) {
  UseMethod("split_by_predicate")
}

#' Split at a Position or Name
#'
#' Splits by a single one-based position or a single element name.
#'
#' @param x A `flexseq`.
#' @param at A single positive integer position or a single character name.
#' @param pull_index Controls output shape:
#' - `FALSE` (default): returns `list(left, elem, right)`.
#' - `TRUE`: returns `list(left, right)`.
#' @return A split result with shape controlled by `pull_index`.
#' @details
#' `split_at(x, at, pull_index = FALSE)` is a convenience wrapper around
#' [split_around_by_predicate()] using positional scanning.
#'
#' `split_at(x, at, pull_index = TRUE)` is the two-way variant using
#' [split_by_predicate()].
#' @examples
#' x <- flexseq("a", "b", "c", "d")
#' split_at(x, 3)
#' split_at(x, 3, pull_index = TRUE)
#'
#' n <- flexseq(a = 1, b = 2, c = 3)
#' split_at(n, "b")
#' @export
split_at <- function(x, at, pull_index = FALSE) {
  UseMethod("split_at")
}

#' Insert an element
#'
#' Generic `insert()` dispatches by class.
#'
#' @param x Object to insert into.
#' @param ... Method-specific arguments.
#' @return Updated object.
#' @seealso [insert.priority_queue()], [insert.ordered_sequence()], [insert.interval_index()]
#' @export
insert <- function(x, ...) {
  UseMethod("insert")
}

#' @export
#' @noRd
insert.default <- function(x, ...) {
  cls <- class(x)
  cls_txt <- if(length(cls) == 0L) "unknown" else paste(cls, collapse = "/")
  stop(sprintf("No `insert()` method for class '%s'.", cls_txt))
}
