#SO

# Runtime: O(log n).
#' Minimum Left Endpoint
#'
#' Returns the smallest left endpoint (`start`) currently present.
#'
#' @param x An `interval_index`.
#' @return Minimum left endpoint, or `NULL` when `x` is empty.
#' @details
#' Because intervals are stored in start order, this reads the first entry's
#' `start`.
#' @examples
#' ix <- interval_index("a", "b", start = c(3, 1), end = c(4, 2))
#' min_endpoint(ix)
#' min_endpoint(interval_index())
#' @export
min_endpoint <- function(x) {
  .ivx_assert_index(x)
  if(length(x) == 0L) {
    return(NULL)
  }
  .ft_get_elem_at(x, 1L)$start
}

# Runtime: O(1).
#' Maximum Right Endpoint
#'
#' Returns the largest right endpoint (`end`) currently present.
#'
#' @param x An `interval_index`.
#' @return Maximum right endpoint, or `NULL` when `x` is empty.
#' @details
#' Uses cached `.ivx_max_end` monoid state.
#' @examples
#' ix <- interval_index("a", "b", start = c(3, 1), end = c(4, 2))
#' max_endpoint(ix)
#' max_endpoint(interval_index())
#' @export
max_endpoint <- function(x) {
  .ivx_assert_index(x)
  m <- node_measure(x, ".ivx_max_end")
  if(!isTRUE(m$has)) {
    return(NULL)
  }
  m$end
}

# Runtime: O(log n + c), where c is candidate count (worst-case O(n)).
#' Peek First Interval Matching a Point
#'
#' @param x An `interval_index`.
#' @param point Query point.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#'   Ignored when `match_at` is not `"interval"`.
#' @param match_at How the query point is matched against each entry. One of
#'   `"interval"` (default; entry interval contains `point`, under `bounds`),
#'   `"start"` (entry's start coordinate equals `point`), `"end"` (entry's end
#'   equals `point`), or `"either"` (start or end equals `point`). The three
#'   coordinate-equality modes are structural and ignore `bounds`.
#' @return The payload value from the first match, or `NULL` on no match.
#' @details
#' Returns the first match in canonical interval order. Use [peek_all_point()] to
#' retrieve all matches as an `interval_index` slice.
#' @examples
#' ix <- interval_index("a", "b", "c", start = c(1, 2, 4), end = c(3, 2, 5))
#' peek_point(ix, 2)
#'
#' # Boundary override at an endpoint
#' edge <- interval_index("a", start = 1, end = 3, default_query_bounds = "[)")
#' peek_point(edge, 3)                # default "[)": no match at right endpoint
#' peek_point(edge, 3, bounds = "[]") # closed bounds: endpoint matches
#'
#' # Coordinate-equality modes (bounds irrelevant)
#' peek_point(ix, 2, match_at = "start")  # entry starting at 2
#' peek_point(ix, 3, match_at = "end")    # entry ending at 3
#' @export
peek_point <- function(x, point, bounds = NULL,
                       match_at = c("interval", "start", "end", "either")) {
  .ivx_assert_index(x)
  match_at <- match.arg(match_at)
  et <- .ivx_endpoint_type_state(x)
  qp <- .ivx_normalize_endpoint(point, "point", endpoint_type = et)
  if(identical(match_at, "interval")) {
    b <- .ivx_resolve_bounds(x, bounds)
    spec <- .ivx_spec_point(qp, b, .ivx_bounds_flags(b), match_at, endpoint_type = et)
  } else {
    spec <- .ivx_spec_point(qp, NULL, NULL, match_at, endpoint_type = et)
  }
  .ivx_run_relation_query(x, spec, mode = "peek", which = "first")
}

# Runtime: O(log n + c + k), where k is matched count (worst-case O(n)).
#' Peek All Intervals Matching a Point
#'
#' @param x An `interval_index`.
#' @param point Query point.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#'   Ignored when `match_at` is not `"interval"`.
#' @param match_at How the query point is matched against each entry. One of
#'   `"interval"` (default; containment under `bounds`), `"start"`, `"end"`,
#'   or `"either"`. See [peek_point()] for details.
#' @param as_list If `TRUE`, return a list with `values` (list of payloads),
#'   `starts`, and `ends` parallel vectors instead of an `interval_index`
#'   slice. Avoids the result-tree rebuild and is significantly faster for
#'   large match sets when the caller doesn't need a queryable result.
#' @return When `as_list = FALSE` (default): an `interval_index` slice of all
#'   matches (possibly empty). When `as_list = TRUE`: a named list with
#'   `values` (list of payloads), `starts`, and `ends`. For `numeric` /
#'   integer endpoint domains, `starts` and `ends` are atomic vectors; for
#'   class-bearing endpoint domains (e.g. `Date`, `POSIXct`) they are
#'   returned as lists to preserve the endpoint class.
#' @details
#' With `as_list = FALSE`, the returned `interval_index` can be inspected with
#' [as.list()].
#' @examples
#' ix <- interval_index("a", "b", "c", start = c(1, 2, 4), end = c(3, 2, 5))
#' as.list(peek_all_point(ix, 2))
#'
#' # Entries ending at 3
#' as.list(peek_all_point(ix, 3, match_at = "end"))
#' @export
peek_all_point <- function(x, point, bounds = NULL,
                           match_at = c("interval", "start", "end", "either"),
                           as_list = FALSE) {
  .ivx_assert_index(x)
  match_at <- match.arg(match_at)
  et <- .ivx_endpoint_type_state(x)
  qp <- .ivx_normalize_endpoint(point, "point", endpoint_type = et)
  if(identical(match_at, "interval")) {
    b <- .ivx_resolve_bounds(x, bounds)
    spec <- .ivx_spec_point(qp, b, .ivx_bounds_flags(b), match_at, endpoint_type = et)
  } else {
    spec <- .ivx_spec_point(qp, NULL, NULL, match_at, endpoint_type = et)
  }
  .ivx_run_relation_query(x, spec, mode = "peek", which = "all", as_list = isTRUE(as_list))
}

# Runtime: O(log n + c).
#' Pop First Interval Matching a Point
#'
#' @param x An `interval_index`.
#' @param point Query point.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#'   Ignored when `match_at` is not `"interval"`.
#' @param match_at How the query point is matched against each entry. One of
#'   `"interval"` (default; containment under `bounds`), `"start"`, `"end"`,
#'   or `"either"`. See [peek_point()] for details.
#' @return A list with `element`, `start`, `end`, and `remaining`.
#'   On miss: `element`, `start`, and `end` are `NULL`.
#' @details
#' Removes the first match in canonical interval order. On miss, returns a
#' non-throwing miss object with `remaining = x`.
#' Use [pop_all_point()] to remove all matches.
#' @examples
#' ix <- interval_index("a", "b", "c", start = c(1, 2, 4), end = c(3, 2, 5))
#' pop_point(ix, 2)
#' @export
pop_point <- function(x, point, bounds = NULL,
                      match_at = c("interval", "start", "end", "either")) {
  .ivx_assert_index(x)
  match_at <- match.arg(match_at)
  et <- .ivx_endpoint_type_state(x)
  qp <- .ivx_normalize_endpoint(point, "point", endpoint_type = et)
  if(identical(match_at, "interval")) {
    b <- .ivx_resolve_bounds(x, bounds)
    spec <- .ivx_spec_point(qp, b, .ivx_bounds_flags(b), match_at, endpoint_type = et)
  } else {
    spec <- .ivx_spec_point(qp, NULL, NULL, match_at, endpoint_type = et)
  }
  .ivx_run_relation_query(x, spec, mode = "pop", which = "first")
}

# Runtime: O(n log n) in worst-case rebuild path.
#' Pop All Intervals Matching a Point
#'
#' @param x An `interval_index`.
#' @param point Query point.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#'   Ignored when `match_at` is not `"interval"`.
#' @param match_at How the query point is matched against each entry. One of
#'   `"interval"` (default; containment under `bounds`), `"start"`, `"end"`,
#'   or `"either"`. See [peek_point()] for details. The `"end"` mode is the
#'   standard primitive for retiring active intervals in a sweep-line.
#' @return A list with `elements` and `remaining`, both `interval_index` objects.
#' @details
#' Use [as.list()] to convert `elements` to a standard R list.
#' @examples
#' ix <- interval_index("a", "b", "c", start = c(1, 2, 4), end = c(3, 2, 5))
#' out <- pop_all_point(ix, 2)
#' as.list(out$elements)
#'
#' # Sweep-line retirement: remove everything ending at x = 3
#' retired <- pop_all_point(ix, 3, match_at = "end")
#' as.list(retired$elements)
#' as.list(retired$remaining)
#' @export
pop_all_point <- function(x, point, bounds = NULL,
                          match_at = c("interval", "start", "end", "either")) {
  .ivx_assert_index(x)
  match_at <- match.arg(match_at)
  et <- .ivx_endpoint_type_state(x)
  qp <- .ivx_normalize_endpoint(point, "point", endpoint_type = et)
  if(identical(match_at, "interval")) {
    b <- .ivx_resolve_bounds(x, bounds)
    spec <- .ivx_spec_point(qp, b, .ivx_bounds_flags(b), match_at, endpoint_type = et)
  } else {
    spec <- .ivx_spec_point(qp, NULL, NULL, match_at, endpoint_type = et)
  }
  .ivx_run_relation_query(x, spec, mode = "pop", which = "all")
}

# Runtime: O(log n + c).
#' Peek First Interval Overlapping a Query Interval
#'
#' @param x An `interval_index`.
#' @param start Query interval start.
#' @param end Query interval end.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @return The payload value from the first match, or `NULL` on no match.
#' @details
#' Returns the first match in canonical interval order. Use
#' [peek_all_overlaps()] to retrieve all matches as an `interval_index` slice.
#' @examples
#' ix <- interval_index("a", "b", "c", start = c(1, 3, 5), end = c(2, 4, 6))
#' peek_overlaps(ix, 2, 3)
#'
#' # Boundary override at touching endpoints
#' edge <- interval_index("a", start = 1, end = 3, default_query_bounds = "[)")
#' peek_overlaps(edge, 3, 4)                # default "[)": no endpoint overlap
#' peek_overlaps(edge, 3, 4, bounds = "[]") # closed bounds: endpoint overlaps
#' @export
peek_overlaps <- function(x, start, end, bounds = NULL) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  et <- .ivx_endpoint_type_state(x)
  q <- .ivx_normalize_interval(start, end, endpoint_type = et)
  spec <- .ivx_spec_overlaps(q, b, .ivx_bounds_flags(b), endpoint_type = et)
  .ivx_run_relation_query(x, spec, mode = "peek", which = "first")
}

# Runtime: O(log n + c + k), where k is matched count (worst-case O(n)).
#' Peek All Intervals Overlapping a Query Interval
#'
#' @param x An `interval_index`.
#' @param start Query interval start.
#' @param end Query interval end.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @param as_list If `TRUE`, return a list with `values` (list of payloads),
#'   `starts`, and `ends` parallel vectors instead of an `interval_index`
#'   slice. Avoids the result-tree rebuild and is significantly faster for
#'   large match sets when the caller doesn't need a queryable result.
#' @return When `as_list = FALSE` (default): an `interval_index` slice of all
#'   matches (possibly empty). When `as_list = TRUE`: a named list with
#'   `values` (list of payloads), `starts`, and `ends`. For `numeric` /
#'   integer endpoint domains, `starts` and `ends` are atomic vectors; for
#'   class-bearing endpoint domains (e.g. `Date`, `POSIXct`) they are
#'   returned as lists to preserve the endpoint class.
#' @details
#' With `as_list = FALSE`, the returned `interval_index` can be inspected with
#' [as.list()].
#' @examples
#' ix <- interval_index("a", "b", "c", start = c(1, 3, 5), end = c(2, 4, 6))
#' as.list(peek_all_overlaps(ix, 2, 5))
#' @export
peek_all_overlaps <- function(x, start, end, bounds = NULL, as_list = FALSE) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  et <- .ivx_endpoint_type_state(x)
  q <- .ivx_normalize_interval(start, end, endpoint_type = et)
  spec <- .ivx_spec_overlaps(q, b, .ivx_bounds_flags(b), endpoint_type = et)
  .ivx_run_relation_query(x, spec, mode = "peek", which = "all", as_list = isTRUE(as_list))
}

# Runtime: O(log n + c).
#' Peek First Interval Containing a Query Interval
#'
#' @param x An `interval_index`.
#' @param start Query interval start.
#' @param end Query interval end.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @return The payload value from the first match, or `NULL` on no match.
#' @details
#' Returns the first match in canonical interval order. Use
#' [peek_all_containing()] to retrieve all matches as an `interval_index` slice.
#' @examples
#' ix <- interval_index("a", "b", "c", start = c(1, 2, 4), end = c(5, 3, 6))
#' peek_containing(ix, 2, 3)
#' @export
peek_containing <- function(x, start, end, bounds = NULL) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  et <- .ivx_endpoint_type_state(x)
  q <- .ivx_normalize_interval(start, end, endpoint_type = et)
  spec <- .ivx_spec_containing(q, b, .ivx_bounds_flags(b), endpoint_type = et)
  .ivx_run_relation_query(x, spec, mode = "peek", which = "first")
}

# Runtime: O(log n + c + k), where k is matched count (worst-case O(n)).
#' Peek All Intervals Containing a Query Interval
#'
#' @param x An `interval_index`.
#' @param start Query interval start.
#' @param end Query interval end.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @param as_list If `TRUE`, return a list with `values` (list of payloads),
#'   `starts`, and `ends` parallel vectors instead of an `interval_index`
#'   slice. Avoids the result-tree rebuild and is significantly faster for
#'   large match sets when the caller doesn't need a queryable result.
#' @return When `as_list = FALSE` (default): an `interval_index` slice of all
#'   matches (possibly empty). When `as_list = TRUE`: a named list with
#'   `values` (list of payloads), `starts`, and `ends`. For `numeric` /
#'   integer endpoint domains, `starts` and `ends` are atomic vectors; for
#'   class-bearing endpoint domains (e.g. `Date`, `POSIXct`) they are
#'   returned as lists to preserve the endpoint class.
#' @details
#' With `as_list = FALSE`, the returned `interval_index` can be inspected with
#' [as.list()].
#' @examples
#' ix <- interval_index("a", "b", "c", start = c(1, 2, 4), end = c(6, 5, 7))
#' as.list(peek_all_containing(ix, 2, 4))
#' @export
peek_all_containing <- function(x, start, end, bounds = NULL, as_list = FALSE) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  et <- .ivx_endpoint_type_state(x)
  q <- .ivx_normalize_interval(start, end, endpoint_type = et)
  spec <- .ivx_spec_containing(q, b, .ivx_bounds_flags(b), endpoint_type = et)
  .ivx_run_relation_query(x, spec, mode = "peek", which = "all", as_list = isTRUE(as_list))
}

# Runtime: O(log n + c).
#' Peek First Interval Within a Query Interval
#'
#' @param x An `interval_index`.
#' @param start Query interval start.
#' @param end Query interval end.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @return The payload value from the first match, or `NULL` on no match.
#' @details
#' Returns the first match in canonical interval order. Use [peek_all_within()]
#' to retrieve all matches as an `interval_index` slice.
#' @examples
#' ix <- interval_index("a", "b", "c", start = c(1, 2, 4), end = c(6, 3, 5))
#' peek_within(ix, 1, 4)
#' @export
peek_within <- function(x, start, end, bounds = NULL) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  et <- .ivx_endpoint_type_state(x)
  q <- .ivx_normalize_interval(start, end, endpoint_type = et)
  spec <- .ivx_spec_within(q, b, .ivx_bounds_flags(b), endpoint_type = et)
  .ivx_run_relation_query(x, spec, mode = "peek", which = "first")
}

# Runtime: O(log n + c + k), where k is matched count (worst-case O(n)).
#' Peek All Intervals Within a Query Interval
#'
#' @param x An `interval_index`.
#' @param start Query interval start.
#' @param end Query interval end.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @param as_list If `TRUE`, return a list with `values` (list of payloads),
#'   `starts`, and `ends` parallel vectors instead of an `interval_index`
#'   slice. Avoids the result-tree rebuild and is significantly faster for
#'   large match sets when the caller doesn't need a queryable result.
#' @return When `as_list = FALSE` (default): an `interval_index` slice of all
#'   matches (possibly empty). When `as_list = TRUE`: a named list with
#'   `values` (list of payloads), `starts`, and `ends`. For `numeric` /
#'   integer endpoint domains, `starts` and `ends` are atomic vectors; for
#'   class-bearing endpoint domains (e.g. `Date`, `POSIXct`) they are
#'   returned as lists to preserve the endpoint class.
#' @details
#' With `as_list = FALSE`, the returned `interval_index` can be inspected with
#' [as.list()].
#' @examples
#' ix <- interval_index("a", "b", "c", start = c(1, 2, 4), end = c(6, 3, 5))
#' as.list(peek_all_within(ix, 1, 4))
#' @export
peek_all_within <- function(x, start, end, bounds = NULL, as_list = FALSE) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  et <- .ivx_endpoint_type_state(x)
  q <- .ivx_normalize_interval(start, end, endpoint_type = et)
  spec <- .ivx_spec_within(q, b, .ivx_bounds_flags(b), endpoint_type = et)
  .ivx_run_relation_query(x, spec, mode = "peek", which = "all", as_list = isTRUE(as_list))
}

# Runtime: O(log n + c).
#' Pop First Overlapping Interval
#'
#' @param x An `interval_index`.
#' @param start Query interval start.
#' @param end Query interval end.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @return A list with `element`, `start`, `end`, and `remaining`.
#'   On miss: `element`, `start`, and `end` are `NULL`.
#' @details
#' Removes the first match in canonical interval order. On miss, returns a
#' non-throwing miss object with `remaining = x`.
#' Use [pop_all_overlaps()] to remove all matches.
#' @examples
#' ix <- interval_index("a", "b", "c", start = c(1, 3, 5), end = c(2, 4, 6))
#' pop_overlaps(ix, 2, 3)
#' @export
pop_overlaps <- function(x, start, end, bounds = NULL) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  et <- .ivx_endpoint_type_state(x)
  q <- .ivx_normalize_interval(start, end, endpoint_type = et)
  spec <- .ivx_spec_overlaps(q, b, .ivx_bounds_flags(b), endpoint_type = et)
  .ivx_run_relation_query(x, spec, mode = "pop", which = "first")
}

# Runtime: O(n log n) in worst-case rebuild path.
#' Pop All Overlapping Intervals
#'
#' @param x An `interval_index`.
#' @param start Query interval start.
#' @param end Query interval end.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @return A list with `elements` and `remaining`, both `interval_index` objects.
#' @details
#' Use [as.list()] to convert `elements` to a standard R list.
#' @examples
#' ix <- interval_index("a", "b", "c", start = c(1, 3, 5), end = c(2, 4, 6))
#' out <- pop_all_overlaps(ix, 2, 5)
#' as.list(out$elements)
#' @export
pop_all_overlaps <- function(x, start, end, bounds = NULL) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  et <- .ivx_endpoint_type_state(x)
  q <- .ivx_normalize_interval(start, end, endpoint_type = et)
  spec <- .ivx_spec_overlaps(q, b, .ivx_bounds_flags(b), endpoint_type = et)
  .ivx_run_relation_query(x, spec, mode = "pop", which = "all")
}

# Runtime: O(log n + c).
#' Pop First Containing Interval
#'
#' @param x An `interval_index`.
#' @param start Query interval start.
#' @param end Query interval end.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @return A list with `element`, `start`, `end`, and `remaining`.
#'   On miss: `element`, `start`, and `end` are `NULL`.
#' @details
#' Removes the first match in canonical interval order. On miss, returns a
#' non-throwing miss object with `remaining = x`.
#' Use [pop_all_containing()] to remove all matches.
#' @examples
#' ix <- interval_index("a", "b", "c", start = c(1, 2, 4), end = c(6, 3, 7))
#' pop_containing(ix, 2, 4)
#' @export
pop_containing <- function(x, start, end, bounds = NULL) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  et <- .ivx_endpoint_type_state(x)
  q <- .ivx_normalize_interval(start, end, endpoint_type = et)
  spec <- .ivx_spec_containing(q, b, .ivx_bounds_flags(b), endpoint_type = et)
  .ivx_run_relation_query(x, spec, mode = "pop", which = "first")
}

# Runtime: O(n log n) in worst-case rebuild path.
#' Pop All Containing Intervals
#'
#' @param x An `interval_index`.
#' @param start Query interval start.
#' @param end Query interval end.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @return A list with `elements` and `remaining`, both `interval_index` objects.
#' @details
#' Use [as.list()] to convert `elements` to a standard R list.
#' @examples
#' ix <- interval_index("a", "b", "c", start = c(1, 2, 4), end = c(6, 5, 7))
#' out <- pop_all_containing(ix, 2, 4)
#' as.list(out$elements)
#' @export
pop_all_containing <- function(x, start, end, bounds = NULL) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  et <- .ivx_endpoint_type_state(x)
  q <- .ivx_normalize_interval(start, end, endpoint_type = et)
  spec <- .ivx_spec_containing(q, b, .ivx_bounds_flags(b), endpoint_type = et)
  .ivx_run_relation_query(x, spec, mode = "pop", which = "all")
}

# Runtime: O(log n + c).
#' Pop First Interval Within a Query Interval
#'
#' @param x An `interval_index`.
#' @param start Query interval start.
#' @param end Query interval end.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @return A list with `element`, `start`, `end`, and `remaining`.
#'   On miss: `element`, `start`, and `end` are `NULL`.
#' @details
#' Removes the first match in canonical interval order. On miss, returns a
#' non-throwing miss object with `remaining = x`.
#' Use [pop_all_within()] to remove all matches.
#' @examples
#' ix <- interval_index("a", "b", "c", start = c(1, 2, 4), end = c(6, 3, 5))
#' pop_within(ix, 1, 4)
#' @export
pop_within <- function(x, start, end, bounds = NULL) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  et <- .ivx_endpoint_type_state(x)
  q <- .ivx_normalize_interval(start, end, endpoint_type = et)
  spec <- .ivx_spec_within(q, b, .ivx_bounds_flags(b), endpoint_type = et)
  .ivx_run_relation_query(x, spec, mode = "pop", which = "first")
}

# Runtime: O(n log n) in worst-case rebuild path.
#' Pop All Intervals Within a Query Interval
#'
#' @param x An `interval_index`.
#' @param start Query interval start.
#' @param end Query interval end.
#' @param bounds Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#' @return A list with `elements` and `remaining`, both `interval_index` objects.
#' @details
#' Use [as.list()] to convert `elements` to a standard R list.
#' @examples
#' ix <- interval_index("a", "b", "c", start = c(1, 2, 4), end = c(6, 3, 5))
#' out <- pop_all_within(ix, 1, 4)
#' as.list(out$elements)
#' @export
pop_all_within <- function(x, start, end, bounds = NULL) {
  .ivx_assert_index(x)
  b <- .ivx_resolve_bounds(x, bounds)
  et <- .ivx_endpoint_type_state(x)
  q <- .ivx_normalize_interval(start, end, endpoint_type = et)
  spec <- .ivx_spec_within(q, b, .ivx_bounds_flags(b), endpoint_type = et)
  .ivx_run_relation_query(x, spec, mode = "pop", which = "all")
}
