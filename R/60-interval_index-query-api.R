#SO

# Runtime: O(n).
# Returns per-entry interval endpoints in current sequence order.
# **Inputs:** `x` interval_index.
# **Outputs:** data.frame with list-cols `start` and `end`.
# **Used by:** users/tests.
#' Get interval bounds in sequence order
#'
#' @param x An `interval_index`.
#' @return A data frame in current sequence order with one row per entry and
#'   two list-columns:
#'   \describe{
#'     \item{`start`}{Start endpoint for each entry.}
#'     \item{`end`}{End endpoint for each entry.}
#'   }
#'   Returns a zero-row data frame with the same columns for empty indexes.
#' @export
interval_bounds <- function(x) {
  .ivx_assert_index(x)
  entries <- .ivx_entries(x)
  n <- length(entries)

  if(n == 0L) {
    return(data.frame(start = I(list()), end = I(list()), row.names = integer(0)))
  }

  starts <- unname(lapply(entries, function(e) e$start))
  ends <- unname(lapply(entries, function(e) e$end))
  data.frame(start = I(starts), end = I(ends), row.names = seq_len(n))
}

# Runtime: O(log n + c), where c is candidate count (worst-case O(n)).
#' Peek first interval containing a point
#'
#' @param x An `interval_index`.
#' @param point Query point.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @return The payload item from the first match, or `NULL` on no match.
#' @export
peek_point <- function(x, point, bounds = NULL) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  qp <- .ivx_normalize_endpoint(point, "point", endpoint_type = .ivx_endpoint_type_state(x))
  spec <- .ivx_spec_point(qp, b, .ivx_bounds_flags(b))
  .ivx_run_relation_query(x, spec, mode = "peek", which = "first")
}

# Runtime: O(log n + c + k), where k is matched count (worst-case O(n)).
#' Peek all intervals containing a point
#'
#' @param x An `interval_index`.
#' @param point Query point.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @return An `interval_index` slice of all matches (possibly empty).
#' @export
peek_all_point <- function(x, point, bounds = NULL) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  qp <- .ivx_normalize_endpoint(point, "point", endpoint_type = .ivx_endpoint_type_state(x))
  spec <- .ivx_spec_point(qp, b, .ivx_bounds_flags(b))
  .ivx_run_relation_query(x, spec, mode = "peek", which = "all")
}

# Runtime: O(log n + c).
#' Pop first interval containing a point
#'
#' @param x An `interval_index`.
#' @param point Query point.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @return A list with `element`, `start`, `end`, and `remaining`.
#'   On miss: `element`, `start`, and `end` are `NULL`.
#' @export
pop_point <- function(x, point, bounds = NULL) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  qp <- .ivx_normalize_endpoint(point, "point", endpoint_type = .ivx_endpoint_type_state(x))
  spec <- .ivx_spec_point(qp, b, .ivx_bounds_flags(b))
  .ivx_run_relation_query(x, spec, mode = "pop", which = "first")
}

# Runtime: O(n log n) in worst-case rebuild path.
#' Pop all intervals containing a point
#'
#' @param x An `interval_index`.
#' @param point Query point.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @return A list with `elements` and `remaining`, both `interval_index` objects.
#' @export
pop_all_point <- function(x, point, bounds = NULL) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  qp <- .ivx_normalize_endpoint(point, "point", endpoint_type = .ivx_endpoint_type_state(x))
  spec <- .ivx_spec_point(qp, b, .ivx_bounds_flags(b))
  .ivx_run_relation_query(x, spec, mode = "pop", which = "all")
}

# Runtime: O(log n + c).
#' Peek first interval overlapping a query interval
#'
#' @param x An `interval_index`.
#' @param start Query interval start.
#' @param end Query interval end.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @return The payload item from the first match, or `NULL` on no match.
#' @export
peek_overlaps <- function(x, start, end, bounds = NULL) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  q <- .ivx_normalize_interval(start, end, endpoint_type = .ivx_endpoint_type_state(x))
  spec <- .ivx_spec_overlaps(q, b, .ivx_bounds_flags(b))
  .ivx_run_relation_query(x, spec, mode = "peek", which = "first")
}

# Runtime: O(log n + c + k), where k is matched count (worst-case O(n)).
#' Peek all intervals overlapping a query interval
#'
#' @param x An `interval_index`.
#' @param start Query interval start.
#' @param end Query interval end.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @return An `interval_index` slice of all matches (possibly empty).
#' @export
peek_all_overlaps <- function(x, start, end, bounds = NULL) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  q <- .ivx_normalize_interval(start, end, endpoint_type = .ivx_endpoint_type_state(x))
  spec <- .ivx_spec_overlaps(q, b, .ivx_bounds_flags(b))
  .ivx_run_relation_query(x, spec, mode = "peek", which = "all")
}

# Runtime: O(log n + c).
#' Peek first interval containing a query interval
#'
#' @param x An `interval_index`.
#' @param start Query interval start.
#' @param end Query interval end.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @return The payload item from the first match, or `NULL` on no match.
#' @export
peek_containing <- function(x, start, end, bounds = NULL) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  q <- .ivx_normalize_interval(start, end, endpoint_type = .ivx_endpoint_type_state(x))
  spec <- .ivx_spec_containing(q, b, .ivx_bounds_flags(b))
  .ivx_run_relation_query(x, spec, mode = "peek", which = "first")
}

# Runtime: O(log n + c + k), where k is matched count (worst-case O(n)).
#' Peek all intervals containing a query interval
#'
#' @param x An `interval_index`.
#' @param start Query interval start.
#' @param end Query interval end.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @return An `interval_index` slice of all matches (possibly empty).
#' @export
peek_all_containing <- function(x, start, end, bounds = NULL) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  q <- .ivx_normalize_interval(start, end, endpoint_type = .ivx_endpoint_type_state(x))
  spec <- .ivx_spec_containing(q, b, .ivx_bounds_flags(b))
  .ivx_run_relation_query(x, spec, mode = "peek", which = "all")
}

# Runtime: O(log n + c).
#' Peek first interval within a query interval
#'
#' @param x An `interval_index`.
#' @param start Query interval start.
#' @param end Query interval end.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @return The payload item from the first match, or `NULL` on no match.
#' @export
peek_within <- function(x, start, end, bounds = NULL) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  q <- .ivx_normalize_interval(start, end, endpoint_type = .ivx_endpoint_type_state(x))
  spec <- .ivx_spec_within(q, b, .ivx_bounds_flags(b))
  .ivx_run_relation_query(x, spec, mode = "peek", which = "first")
}

# Runtime: O(log n + c + k), where k is matched count (worst-case O(n)).
#' Peek all intervals within a query interval
#'
#' @param x An `interval_index`.
#' @param start Query interval start.
#' @param end Query interval end.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @return An `interval_index` slice of all matches (possibly empty).
#' @export
peek_all_within <- function(x, start, end, bounds = NULL) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  q <- .ivx_normalize_interval(start, end, endpoint_type = .ivx_endpoint_type_state(x))
  spec <- .ivx_spec_within(q, b, .ivx_bounds_flags(b))
  .ivx_run_relation_query(x, spec, mode = "peek", which = "all")
}

# Runtime: O(log n + c).
#' Pop first overlapping interval
#'
#' @param x An `interval_index`.
#' @param start Query interval start.
#' @param end Query interval end.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @return A list with `element`, `start`, `end`, and `remaining`.
#'   On miss: `element`, `start`, and `end` are `NULL`.
#' @export
pop_overlaps <- function(x, start, end, bounds = NULL) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  q <- .ivx_normalize_interval(start, end, endpoint_type = .ivx_endpoint_type_state(x))
  spec <- .ivx_spec_overlaps(q, b, .ivx_bounds_flags(b))
  .ivx_run_relation_query(x, spec, mode = "pop", which = "first")
}

# Runtime: O(n log n) in worst-case rebuild path.
#' Pop all overlapping intervals
#'
#' @param x An `interval_index`.
#' @param start Query interval start.
#' @param end Query interval end.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @return A list with `elements` and `remaining`, both `interval_index` objects.
#' @export
pop_all_overlaps <- function(x, start, end, bounds = NULL) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  q <- .ivx_normalize_interval(start, end, endpoint_type = .ivx_endpoint_type_state(x))
  spec <- .ivx_spec_overlaps(q, b, .ivx_bounds_flags(b))
  .ivx_run_relation_query(x, spec, mode = "pop", which = "all")
}

# Runtime: O(log n + c).
#' Pop first containing interval
#'
#' @param x An `interval_index`.
#' @param start Query interval start.
#' @param end Query interval end.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @return A list with `element`, `start`, `end`, and `remaining`.
#'   On miss: `element`, `start`, and `end` are `NULL`.
#' @export
pop_containing <- function(x, start, end, bounds = NULL) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  q <- .ivx_normalize_interval(start, end, endpoint_type = .ivx_endpoint_type_state(x))
  spec <- .ivx_spec_containing(q, b, .ivx_bounds_flags(b))
  .ivx_run_relation_query(x, spec, mode = "pop", which = "first")
}

# Runtime: O(n log n) in worst-case rebuild path.
#' Pop all containing intervals
#'
#' @param x An `interval_index`.
#' @param start Query interval start.
#' @param end Query interval end.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @return A list with `elements` and `remaining`, both `interval_index` objects.
#' @export
pop_all_containing <- function(x, start, end, bounds = NULL) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  q <- .ivx_normalize_interval(start, end, endpoint_type = .ivx_endpoint_type_state(x))
  spec <- .ivx_spec_containing(q, b, .ivx_bounds_flags(b))
  .ivx_run_relation_query(x, spec, mode = "pop", which = "all")
}

# Runtime: O(log n + c).
#' Pop first interval within a query interval
#'
#' @param x An `interval_index`.
#' @param start Query interval start.
#' @param end Query interval end.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @return A list with `element`, `start`, `end`, and `remaining`.
#'   On miss: `element`, `start`, and `end` are `NULL`.
#' @export
pop_within <- function(x, start, end, bounds = NULL) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  q <- .ivx_normalize_interval(start, end, endpoint_type = .ivx_endpoint_type_state(x))
  spec <- .ivx_spec_within(q, b, .ivx_bounds_flags(b))
  .ivx_run_relation_query(x, spec, mode = "pop", which = "first")
}

# Runtime: O(n log n) in worst-case rebuild path.
#' Pop all intervals within a query interval
#'
#' @param x An `interval_index`.
#' @param start Query interval start.
#' @param end Query interval end.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @return A list with `elements` and `remaining`, both `interval_index` objects.
#' @export
pop_all_within <- function(x, start, end, bounds = NULL) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  q <- .ivx_normalize_interval(start, end, endpoint_type = .ivx_endpoint_type_state(x))
  spec <- .ivx_spec_within(q, b, .ivx_bounds_flags(b))
  .ivx_run_relation_query(x, spec, mode = "pop", which = "all")
}
