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
#' @details
#' `fapply()` returns a new object and preserves class semantics.
#'
#' Method signatures:
#' - `fapply.flexseq(X, FUN, ..., preserve_custom_monoids = TRUE)`
#' - `fapply.priority_queue(X, FUN, ..., preserve_custom_monoids = TRUE)`
#' - `fapply.ordered_sequence(X, FUN, ..., preserve_custom_monoids = TRUE)`
#' - `fapply.interval_index(X, FUN, ..., preserve_custom_monoids = TRUE)`
#'
#' For `priority_queue`, `ordered_sequence`, and `interval_index`,
#' `FUN` receives structured fields (`value` plus metadata) and should return the
#' new payload value only; ordering metadata is preserved. The name argument is
#' optional: callbacks that only take value/metadata also work.
#'
#' If supported by the method, `preserve_custom_monoids = TRUE` keeps added user
#' monoids; `FALSE` rebuilds with required structural monoids only.
#' @examples
#' x <- flexseq("a", "b", "c")
#' fapply(x, toupper)
#'
#' q <- priority_queue(one = "a", two = "b", priorities = c(2, 1))
#' fapply(q, function(value, priority, name) paste0(value, priority))
#'
#' o <- ordered_sequence(one = "a", two = "b", keys = c(2, 1))
#' fapply(o, function(value, key, name) paste0(value, "_", key))
#'
#' ix <- interval_index(one = "a", two = "b", start = c(1, 3), end = c(2, 4))
#' fapply(ix, function(value, start, end, name) paste0(value, "[", start, ",", end, "]"))
#' @seealso [flexseq()], [priority_queue()], [ordered_sequence()], [interval_index()]
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
#' Measure-function signatures:
#' - `flexseq`: `measure(entry)` where `entry` is the stored element.
#' - `ordered_sequence`: `measure(entry)` where `entry` is `list(value, key)`.
#' - `priority_queue`: `measure(entry)` where `entry` is `list(value, priority)`.
#' - `interval_index`: `measure(entry)` where `entry` is `list(value, start, end)`.
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
#' # Use the monoid in a split query
#' split_around_by_predicate(x2, function(v) v >= 30, "sum")
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
#' semantics and returns a plain `flexseq`.
#'
#' @param x Input object.
#' @param drop_meta Logical scalar controlling advanced-structure cast style.
#'   For `priority_queue`, `ordered_sequence`, and `interval_index`:
#'   - `TRUE` (default): return payload-only elements and drop custom monoids.
#'   - `FALSE`: return full stored entry records (for example `value` + metadata)
#'     and preserve cast-down custom monoids.
#' @return A plain `flexseq`.
#' @details
#' This is an S3 generic. Notable method behavior:
#' - `as_flexseq.flexseq(x, drop_meta=...)` returns `x` unchanged.
#' - `as_flexseq.priority_queue(x, drop_meta=TRUE)` returns payload items;
#'   `drop_meta=FALSE` returns `list(value, priority)` entries.
#' - `as_flexseq.ordered_sequence(x, drop_meta=TRUE)` returns payload items;
#'   `drop_meta=FALSE` returns `list(value, key)` entries.
#' - `as_flexseq.interval_index(x, drop_meta=TRUE)` returns payload items;
#'   `drop_meta=FALSE` returns interval entry records.
#'
#' For advanced types with `drop_meta = TRUE`, custom monoids are dropped and
#' the rebuilt `flexseq` keeps only structural monoids (`.size`,
#' `.named_count`).
#' @examples
#' x <- as_flexseq(1:3)
#' x
#'
#' q <- priority_queue("a", "b", priorities = c(2, 1))
#' as_flexseq(q)
#' as_flexseq(q, drop_meta = FALSE)
#'
#' o <- ordered_sequence("a", "b", keys = c(2, 1))
#' as_flexseq(o)
#' as_flexseq(o, drop_meta = FALSE)
#' @seealso [flexseq()], [priority_queue()], [ordered_sequence()], [interval_index()]
#' @export
# Runtime: O(1) generic dispatch.
as_flexseq <- function(x, drop_meta = TRUE) {
  UseMethod("as_flexseq")
}

#' Locate First Predicate Match
#'
#' Scans accumulated monoid values and returns the first element where
#' `predicate` becomes `TRUE`, without rebuilding split trees.
#'
#' @param t A `flexseq` (or subclass).
#' @param predicate Function applied to accumulated monoid values.
#' @param monoid_name Name of the monoid used for scanning.
#' @param accumulator Optional starting accumulator value.
#' @param include_metadata Logical; include scan metadata.
#' @return If `include_metadata = FALSE`, a list with:
#' - `found`: logical flag.
#' - `value`: matched element when found, otherwise `NULL`.
#'
#' If `include_metadata = TRUE`, adds `metadata` with:
#' - `left_measure`
#' - `hit_measure`
#' - `right_measure`
#' - `index`
#' @details
#' This is the read-only analogue of [split_around_by_predicate()].
#'
#' As with split helpers, a common setup is a custom monoid created with
#' [measure_monoid()] and attached via [add_monoids()].
#'
#' `value` is the matched leaf entry for the input structure:
#' - `flexseq`: stored user element.
#' - `ordered_sequence`: `list(value, key)`.
#' - `priority_queue`: `list(value, priority)`.
#' - `interval_index`: `list(value, start, end)`.
#' @examples
#' x <- flexseq("a", "b", "c", "d")
#' size_monoid <- measure_monoid(`+`, 0L, function(e) 1L)
#' x2 <- add_monoids(x, list(size = size_monoid))
#'
#' locate_by_predicate(x2, function(v) v >= 3L, "size")
#' locate_by_predicate(x2, function(v) v >= 3L, "size", include_metadata = TRUE)
#' @export
locate_by_predicate <- function(t, predicate, monoid_name, accumulator = NULL, include_metadata = FALSE) {
  UseMethod("locate_by_predicate")
}

#' Split Around First Predicate Match
#'
#' Splits at the first point where a `predicate` function becomes `TRUE` 
#' while scanning the sequence.
#'
#' @param t A `flexseq` (or subclass).
#' @param predicate Function applied to accumulated monoid values.
#' @param monoid_name Name of the monoid used for scanning.
#' @param accumulator Optional starting accumulator value.
#' @return A list with fields:
#' - `left`: elements before the split point.
#' - `value`: the matched element at the split point.
#' - `right`: elements after the split point.
#' @details
#' This function generally requires the sequence be annotated with
#' a `measure_monoid()`; see the examples and `measure_monoid()`
#' for more information.
#'
#' `value` is the matched leaf entry for the input structure:
#' - `flexseq`: stored user element.
#' - `ordered_sequence`: `list(value, key)`.
#' - `priority_queue`: `list(value, priority)`.
#' - `interval_index`: `list(value, start, end)`.
#'
#' `left` and `right` preserve subclass when the input is a subclass of
#' `flexseq`.
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
#' @param x A `flexseq` (or subclass).
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
#'
#' `left` and `right` preserve subclass when the input is a subclass of
#' `flexseq`.
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
#' - `FALSE` (default): returns `list(left, value, right)`.
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

#' Insert an Element
#'
#' Inserts an element into a structure-specific position according to class
#' semantics.
#'
#' @param x Object to insert into.
#' @param ... Method-specific arguments.
#' @return Updated object of the same class as `x`.
#' @details
#' `insert()` is an S3 generic. Required arguments in `...` depend on `x`:
#' - `priority_queue`: `element`, `priority` (optional `name`)
#' - `ordered_sequence`: `element`, `key` (optional `name`)
#' - `interval_index`: `element`, `start`, `end` (optional `name`)
#'
#' This operation is persistent: `x` is not modified.
#' @examples
#' q <- priority_queue("a", "b", priorities = c(2, 1))
#' insert(q, "c", priority = 3)
#'
#' o <- ordered_sequence("a", "c", keys = c(1, 3))
#' insert(o, "b", key = 2)
#'
#' iv <- interval_index("A", "B", starts = c(1, 5), ends = c(3, 8))
#' insert(iv, "C", start = 2, end = 6)
#' @seealso [priority_queue()], [ordered_sequence()], [interval_index()],
#'   [insert_at()]
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
