#SO

# Runtime: O(log n) near locate point depth.
# Core bound-search worker on a pre-normalized key; strict=FALSE yields first
# key >= target, strict=TRUE yields first key > target.
# Used by: .oms_bound_index(), .oms_key_span().
.oms_bound_index_prepared <- function(x, key, strict = FALSE) {
  .oms_assert_set(x)
  n <- length(x)
  if(n == 0L) {
    return(1L)
  }

  pred <- if(!isTRUE(strict)) {
    function(v) {
      isTRUE(v$has) && .oms_compare_key(v$key, key, v$key_type) >= 0L
    }
  } else {
    function(v) {
      isTRUE(v$has) && .oms_compare_key(v$key, key, v$key_type) > 0L
    }
  }

  loc <- locate_by_predicate(x, pred, ".oms_max_key", include_metadata = TRUE)
  if(!isTRUE(loc$found)) {
    return(as.integer(n + 1L))
  }
  as.integer(loc$metadata$index)
}

# Runtime: O(n) over tree size for any non-trivial update (rebind/recompute pass).
#' @method add_monoids ordered_sequence
#' @export
#' @noRd
add_monoids.ordered_sequence <- function(t, monoids, overwrite = FALSE) {
  if(length(monoids) > 0L) {
    bad <- intersect(names(monoids), c(".size", ".named_count", ".oms_max_key"))
    if(length(bad) > 0L) {
      target <- .ft_ordered_owner_class(t)
      stop("Reserved monoid names cannot be supplied for ", target, ": ", paste(bad, collapse = ", "))
    }
  }
  add_monoids.flexseq(t, monoids, overwrite = overwrite)
}

# Runtime: O(log n).
#' Minimum Key Value
#'
#' Returns the smallest key currently present in the ordered sequence.
#'
#' @param x An `ordered_sequence`.
#' @return Minimum key, or `NULL` when `x` is empty.
#' @details
#' This follows sequence key order directly.
#' @examples
#' x <- ordered_sequence("a", "b", keys = c(2, 1))
#' min_key(x)
#' min_key(ordered_sequence())
#' @export
min_key <- function(x) {
  .oms_stop_interval_index(x, "min_key")
  .oms_assert_set(x)
  if(length(x) == 0L) {
    return(NULL)
  }
  .ft_get_elem_at(x, 1L)$key
}

# Runtime: O(1).
#' Maximum Key Value
#'
#' Returns the largest key currently present in the ordered sequence.
#'
#' @param x An `ordered_sequence`.
#' @return Maximum key, or `NULL` when `x` is empty.
#' @details
#' Uses cached `.oms_max_key` monoid state.
#' @examples
#' x <- ordered_sequence("a", "b", keys = c(2, 1))
#' max_key(x)
#' max_key(ordered_sequence())
#' @export
max_key <- function(x) {
  .oms_stop_interval_index(x, "max_key")
  .oms_assert_set(x)
  m <- node_measure(x, ".oms_max_key")
  if(!isTRUE(m$has)) {
    return(NULL)
  }
  m$key
}

# Runtime: O(log n) near locate point depth.
# Normalize/validate a key against sequence key_type, then delegate to prepared
# bound search.
# Used by: lower_bound()/upper_bound(), range/count helpers, key span logic.
.oms_bound_index <- function(x, key_value, strict = FALSE) {
  .oms_assert_set(x)
  key_type <- .oms_key_type_state(x)
  norm <- .oms_normalize_key(key_value)
  .oms_validate_key_type(key_type, norm$key_type)
  .oms_bound_index_prepared(x, norm$key, strict = strict)
}

# Runtime: O(1).
# Resolve inclusive/exclusive lower-range boundary into a start index.
# Used by: elements_between(), count_between().
.oms_range_start_index <- function(x, lo, include_lo) {
  if(isTRUE(include_lo)) {
    .oms_bound_index(x, lo, strict = FALSE)
  } else {
    .oms_bound_index(x, lo, strict = TRUE)
  }
}

# Runtime: O(1).
# Resolve inclusive/exclusive upper-range boundary into an exclusive end index.
# Used by: elements_between(), count_between().
.oms_range_end_exclusive_index <- function(x, hi, include_hi) {
  if(isTRUE(include_hi)) {
    .oms_bound_index(x, hi, strict = TRUE)
  } else {
    .oms_bound_index(x, hi, strict = FALSE)
  }
}


# Runtime: O(log n) near insertion/split point depth.
#' @noRd
# Insert one (value,key) while preserving sorted order and FIFO tie stability.
# Used by: insert.ordered_sequence().
.oms_validate_insert_name_state <- function(x, entry, context = "insert()") {
  measures <- attr(x, "measures", exact = TRUE)
  if(is.null(measures)) {
    stop("Tree has no measures attribute.")
  }
  n <- as.integer(measures[[".size"]])
  nn <- as.integer(measures[[".named_count"]])
  if(n > 0L && nn != 0L && nn != n) {
    stop("Invalid tree name state: mixed named and unnamed elements.")
  }
  if(n == 0L) {
    return(invisible(TRUE))
  }
  entry_name <- .ft_get_name(entry)
  if(nn == 0L && !is.null(entry_name)) {
    stop("Cannot mix named and unnamed elements (", context, " would create mixed named and unnamed tree).")
  }
  if(nn == n && is.null(entry_name)) {
    stop("Cannot mix named and unnamed elements (", context, " would create mixed named and unnamed tree).")
  }
  invisible(TRUE)
}

.oms_insert_impl <- function(x, element, key) {
  .oms_assert_set(x)
  norm <- .oms_normalize_key(key)
  key_type <- .oms_validate_key_type(.oms_key_type_state(x), norm$key_type)

  entry <- .oms_make_entry(element, norm$key, name = .ft_effective_name(element))
  .oms_validate_insert_name_state(x, entry, context = "insert()")
  ms <- attr(x, "monoids", exact = TRUE)

  out <- if(.ft_cpp_can_use_oms_insert(ms, key_type)) {
    .as_flexseq(.ft_cpp_oms_insert(x, entry, ms, key_type))
  } else {
    s <- split_by_predicate(
      x,
      function(v) isTRUE(v$has) && .oms_compare_key(v$key, norm$key, v$key_type) > 0L,
      ".oms_max_key"
    )
    # Internal append avoids public ordered_sequence push guards on boundary splits.
    left_plus <- .ft_push_back_impl(s$left, entry, context = "insert()")
    # concat_trees returns a flexseq so need to re-wrap with ordered seq class below
    # the .as_flexseq() above isn't required but matches the return class with this case
    concat_trees(left_plus, s$right)
  }

  .ord_wrap_like(x, out, key_type = key_type)
}

# Runtime: O(log n) near insertion/split point depth.
#' @method insert ordered_sequence
#' @export
#' @noRd
insert.ordered_sequence <- function(x, value, key, ...) {
  .oms_insert_impl(x, value, key)
}

# Runtime: O(log n).
# Compute the contiguous duplicate-key run as [start, end_excl) for one key.
# Used by: peek_key() and pop_key().
.oms_key_span <- function(x, key) {
  .oms_assert_set(x)
  norm <- .oms_normalize_key(key)
  .oms_validate_key_type(.oms_key_type_state(x), norm$key_type)

  start <- .oms_bound_index_prepared(x, norm$key, strict = FALSE)
  end_excl <- .oms_bound_index_prepared(x, norm$key, strict = TRUE)
  list(
    found = isTRUE(end_excl > start),
    key = norm$key,
    start = as.integer(start),
    end_excl = as.integer(end_excl)
  )
}

# Runtime: O(log n) near split points.
# Extract and remove the positional span [start, end_excl) using .size splits.
# Used by: peek_all_key() and pop_all_key().
.oms_slice_key_span <- function(x, start, end_excl) {
  .oms_assert_set(x)
  if(end_excl <= start) {
    empty <- .oms_empty_tree_like(x)
    return(list(matched = empty, rest = .as_flexseq(x)))
  }
  s1 <- split_by_predicate(x, function(v) v >= start, ".size")
  span_len <- as.integer(end_excl - start)
  s2 <- split_by_predicate(s1$right, function(v) v >= (span_len + 1L), ".size")
  list(
    matched = s2$left,
    rest = concat_trees(s1$left, s2$right)
  )
}

# Runtime: O(log n).
#' Find First Element with Key `>=` Query
#'
#' @param x An `ordered_sequence`.
#' @param key Query key.
#' @return A list with fields:
#' - `found`: logical flag.
#' - `index`: one-based position of the first match, or `NULL`.
#' - `value`: matched element, or `NULL`.
#' - `key`: matched key, or `NULL`.
#' @details
#' `lower_bound()` finds the first element with key `>= key`. This includes an
#' exact key match when present, which is useful for starting equality or
#' inclusive range scans.
#' @examples
#' x <- ordered_sequence("a", "b", "c", keys = c(1, 2, 2))
#' lower_bound(x, 2)
#' lower_bound(x, 10)
#' @seealso [upper_bound()]
#' @export
# Public lower-bound query wrapper over .oms_bound_index().
lower_bound <- function(x, key) {
  .oms_stop_interval_index(x, "lower_bound")
  .oms_assert_set(x)
  idx <- .oms_bound_index(x, key, strict = FALSE)
  n <- length(x)

  if(idx > n) {
    return(list(found = FALSE, index = NULL, value = NULL, key = NULL))
  }

  entry <- .ft_get_elem_at(x, as.integer(idx))
  list(found = TRUE, index = idx, value = entry$value, key = entry$key)
}

# Runtime: O(log n).
#' Find First Element with Key `>` Query
#'
#' @param x An `ordered_sequence`.
#' @param key Query key.
#' @return A list with fields:
#' - `found`: logical flag.
#' - `index`: one-based position of the first match, or `NULL`.
#' - `value`: matched element, or `NULL`.
#' - `key`: matched key, or `NULL`.
#' @details
#' `upper_bound()` finds the first element with key `> key`. This skips exact
#' key matches, which is useful for exclusive range endpoints and for finding
#' the position immediately after a duplicate-key run.
#' @examples
#' x <- ordered_sequence("a", "b", "c", keys = c(1, 2, 2))
#' upper_bound(x, 2)
#' upper_bound(x, 10)
#' @seealso [lower_bound()]
#' @export
# Public upper-bound query wrapper over .oms_bound_index().
upper_bound <- function(x, key) {
  .oms_stop_interval_index(x, "upper_bound")
  .oms_assert_set(x)
  idx <- .oms_bound_index(x, key, strict = TRUE)
  n <- length(x)

  if(idx > n) {
    return(list(found = FALSE, index = NULL, value = NULL, key = NULL))
  }

  entry <- .ft_get_elem_at(x, as.integer(idx))
  list(found = TRUE, index = idx, value = entry$value, key = entry$key)
}

# Runtime: O(log n).
#' Peek First Element for One Key
#'
#' Returns the first element whose key equals `key`.
#'
#' @param x An `ordered_sequence`.
#' @param key Query key.
#' @return Matched element, or `NULL` when no matching key exists.
#' @details
#' For duplicate keys, this returns the first element in stable sequence order.
#' @examples
#' x <- ordered_sequence("a", "b", "c", keys = c(1, 2, 2))
#' peek_key(x, 2)
#' peek_key(x, 10)
#' @export
peek_key <- function(x, key) {
  .oms_stop_interval_index(x, "peek_key")
  span <- .oms_key_span(x, key)
  if(!isTRUE(span$found)) {
    return(NULL)
  }
  s <- split_around_by_predicate(x, function(v) v >= span$start, ".size")
  s$value$value
}

# Runtime: O(log n) near split points.
#' Peek All Elements for One Key
#'
#' Returns all elements whose key equals `key`.
#'
#' @param x An `ordered_sequence`.
#' @param key Query key.
#' @return An `ordered_sequence` containing all matches; empty on miss.
#' @details
#' The returned `ordered_sequence` can be inspected with [as.list()].
#' @examples
#' x <- ordered_sequence("a", "b", "c", keys = c(1, 2, 2))
#' out <- peek_all_key(x, 2)
#' as.list(out)
#' @export
peek_all_key <- function(x, key) {
  .oms_stop_interval_index(x, "peek_all_key")
  span <- .oms_key_span(x, key)
  if(!isTRUE(span$found)) {
    return(.ord_wrap_like(x, .oms_empty_tree_like(x)))
  }
  parts <- .oms_slice_key_span(x, span$start, span$end_excl)
  .ord_wrap_like(x, parts$matched)
}

# Runtime: O(log n) near split point depth.
#' Pop First Element for One Key
#'
#' Removes and returns the first element whose key equals `key`.
#'
#' @param x An `ordered_sequence`.
#' @param key Query key.
#' @return A list with fields:
#' - `value`: removed element, or `NULL` on miss.
#' - `key`: removed key, or `NULL` on miss.
#' - `remaining`: ordered sequence after removal.
#' @details
#' For duplicate keys, the first element in stable sequence order is removed.
#' @examples
#' x <- ordered_sequence("a", "b", "c", keys = c(1, 2, 2))
#' out <- pop_key(x, 2)
#' out$value
#' out$remaining
#' pop_key(x, 10)
#' @export
pop_key <- function(x, key) {
  .oms_stop_interval_index(x, "pop_key")
  span <- .oms_key_span(x, key)

  if(!isTRUE(span$found)) {
    return(list(value = NULL, key = NULL, remaining = x))
  }

  s <- split_around_by_predicate(x, function(v) v >= span$start, ".size")
  out <- concat_trees(s$left, s$right)
  seq_out <- .ord_wrap_like(x, out)
  list(value = s$value$value, key = s$value$key, remaining = seq_out)
}

# Runtime: O(log n) near split point depth.
#' Pop All Elements for One Key
#'
#' Removes and returns all elements whose key equals `key`.
#'
#' @param x An `ordered_sequence`.
#' @param key Query key.
#' @return A list with fields:
#' - `elements`: `ordered_sequence` of removed matches.
#' - `remaining`: `ordered_sequence` after removal.
#' @details
#' Use [as.list()] to convert `elements` to a standard R list.
#' @examples
#' x <- ordered_sequence("a", "b", "c", keys = c(1, 2, 2))
#' out <- pop_all_key(x, 2)
#' as.list(out$elements)
#' out$remaining
#' @export
pop_all_key <- function(x, key) {
  .oms_stop_interval_index(x, "pop_all_key")
  span <- .oms_key_span(x, key)

  if(!isTRUE(span$found)) {
    return(list(elements = .ord_wrap_like(x, .oms_empty_tree_like(x)), remaining = x))
  }

  parts <- .oms_slice_key_span(x, span$start, span$end_excl)
  list(
    elements = .ord_wrap_like(x, parts$matched),
    remaining = .ord_wrap_like(x, parts$rest)
  )
}

# Runtime: O(log n) via tree-surgery splits; no per-element gather.
#' Return Elements in a Key Range
#'
#' @param x An `ordered_sequence`.
#' @param from_key Lower bound key.
#' @param to_key Upper bound key.
#' @param include_from Include lower bound when `TRUE`.
#' @param include_to Include upper bound when `TRUE`.
#' @return An `ordered_sequence` of matched elements, in key order. Use
#'   [as.list()] to convert to a plain list.
#' @details
#' Range membership is controlled by `include_from` and `include_to`:
#' - `include_from = TRUE` uses `key >= from_key`; otherwise `key > from_key`.
#' - `include_to = TRUE` uses `key <= to_key`; otherwise `key < to_key`.
#'
#' If no elements fall in the range, returns an empty `ordered_sequence`.
#' @examples
#' x <- ordered_sequence("a", "b", "c", "d", keys = c(1, 2, 2, 3))
#' elements_between(x, 2, 3)
#' as.list(elements_between(x, 2, 3))
#' elements_between(x, 2, 2, include_to = FALSE)
#' @export
# Public range extraction API over bound-index helpers.
elements_between <- function(x, from_key, to_key, include_from = TRUE, include_to = TRUE) {
  .oms_stop_interval_index(x, "elements_between")
  .oms_assert_set(x)
  include_from <- .oms_coerce_lgl_scalar(include_from, "include_from")
  include_to <- .oms_coerce_lgl_scalar(include_to, "include_to")

  start <- .oms_range_start_index(x, from_key, include_from)
  end_excl <- .oms_range_end_exclusive_index(x, to_key, include_to)

  parts <- .oms_slice_key_span(x, start, end_excl)
  .ord_wrap_like(x, parts$matched)
}

# Runtime: O(log n).
#' Count Elements Matching One Key
#'
#' @param x An `ordered_sequence`.
#' @param key Query key.
#' @return Integer count of matches.
#' @details
#' Counts multiplicity for a single key. Returns `0L` when the key is not
#' present.
#' @examples
#' x <- ordered_sequence("a", "b", "c", keys = c(1, 2, 2))
#' count_key(x, 2)
#' count_key(x, 10)
#' @export
# Public multiplicity query for a single key (size of duplicate-key run).
count_key <- function(x, key) {
  .oms_stop_interval_index(x, "count_key")
  .oms_assert_set(x)
  lo <- .oms_bound_index(x, key, strict = FALSE)
  hi <- .oms_bound_index(x, key, strict = TRUE)
  as.integer(max(0L, hi - lo))
}

# Runtime: O(log n).
#' Count Elements in a Key Range
#'
#' @param x An `ordered_sequence`.
#' @param from_key Lower bound key.
#' @param to_key Upper bound key.
#' @param include_from Include lower bound when `TRUE`.
#' @param include_to Include upper bound when `TRUE`.
#' @return Integer count of matches.
#' @details
#' Uses the same range semantics as [elements_between()] but returns only the
#' count:
#' - `include_from = TRUE` uses `key >= from_key`; otherwise `key > from_key`.
#' - `include_to = TRUE` uses `key <= to_key`; otherwise `key < to_key`.
#' @examples
#' x <- ordered_sequence("a", "b", "c", "d", keys = c(1, 2, 2, 3))
#' count_between(x, 2, 3)
#' count_between(x, 2, 2, include_to = FALSE)
#' @export
# Public multiplicity query for a key interval.
count_between <- function(x, from_key, to_key, include_from = TRUE, include_to = TRUE) {
  .oms_stop_interval_index(x, "count_between")
  .oms_assert_set(x)
  include_from <- .oms_coerce_lgl_scalar(include_from, "include_from")
  include_to <- .oms_coerce_lgl_scalar(include_to, "include_to")

  start <- .oms_range_start_index(x, from_key, include_from)
  end_excl <- .oms_range_end_exclusive_index(x, to_key, include_to)
  as.integer(max(0L, end_excl - start))
}

#' Merge Two Ordered Sequences
#'
#' Returns a new `ordered_sequence` containing every entry from both inputs,
#' preserving key order. On duplicate keys, `x`'s entries precede `y`'s
#' (left-biased FIFO).
#'
#' @method merge ordered_sequence
#' @param x An `ordered_sequence`.
#' @param y An `ordered_sequence`.
#' @param ... Unused.
#' @return A new `ordered_sequence` of size `length(x) + length(y)`.
#' @details
#' The merge runs in O(m + n) via a zipper-style traversal, with a fast path
#' to O(log(min(m, n))) when the key ranges are disjoint (all of `x`'s keys
#' `<=` all of `y`'s keys, or vice versa with a strict `<` to keep
#' left-biased FIFO intact on equal boundary keys).
#'
#' Both sequences must share the same key type and the same monoid set;
#' mismatches error rather than being silently harmonized. Merging an
#' empty sequence with a non-empty sequence returns the non-empty one
#' unchanged.
#'
#' Both inputs are left unmodified.
#' @examples
#' a <- ordered_sequence("a1", "a2", "a3", keys = c(1, 3, 5))
#' b <- ordered_sequence("b1", "b2", "b3", keys = c(2, 3, 6))
#' m <- merge(a, b)
#' as.list(m)
#' # At the tied key 3, "a2" precedes "b2".
#' @export
# Runtime: O(m + n); O(log(min(m, n))) on the disjoint fast path.
merge.ordered_sequence <- function(x, y, ...) {
  if(inherits(x, "interval_index") || inherits(y, "interval_index")) {
    stop("Cannot merge `ordered_sequence` with `interval_index`. Merge like-typed structures only.")
  }
  if(!inherits(y, "ordered_sequence")) {
    stop("Both arguments to `merge()` must be ordered_sequences.")
  }

  if(length(x) == 0L) return(y)
  if(length(y) == 0L) return(x)

  kx <- attr(x, "oms_key_type", exact = TRUE)
  ky <- attr(y, "oms_key_type", exact = TRUE)
  if(!identical(kx, ky)) {
    stop("Cannot merge ordered_sequences with different key types.")
  }
  if(!identical(sort(names(attr(x, "monoids", exact = TRUE))),
                sort(names(attr(y, "monoids", exact = TRUE))))) {
    stop("Cannot merge ordered_sequences with different monoid sets.")
  }

  # Disjoint fast paths.
  mx <- max_key(x); my_min <- min_key(y)
  if(.oms_compare_key(mx, my_min, kx) <= 0L) {
    return(.ord_wrap_like(x, concat_trees(x, y)))
  }
  ym <- max_key(y); x_min <- min_key(x)
  if(.oms_compare_key(ym, x_min, kx) < 0L) {
    return(.ord_wrap_like(x, concat_trees(y, x)))
  }

  # General O(m + n) zipper merge on pre-sorted entries.
  xs <- .ft_to_list(x)
  ys <- .ft_to_list(y)
  nxs <- length(xs); nys <- length(ys)
  merged <- vector("list", nxs + nys)
  i <- 1L; j <- 1L; k <- 1L
  while(i <= nxs && j <= nys) {
    if(.oms_compare_key(xs[[i]]$key, ys[[j]]$key, kx) <= 0L) {
      merged[[k]] <- xs[[i]]; i <- i + 1L
    } else {
      merged[[k]] <- ys[[j]]; j <- j + 1L
    }
    k <- k + 1L
  }
  while(i <= nxs) { merged[[k]] <- xs[[i]]; i <- i + 1L; k <- k + 1L }
  while(j <= nys) { merged[[k]] <- ys[[j]]; j <- j + 1L; k <- k + 1L }

  ms <- attr(x, "monoids", exact = TRUE)
  out <- .oms_tree_from_ordered_entries(merged, ms)
  .ord_wrap_like(x, out)
}
