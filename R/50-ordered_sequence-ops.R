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
# Insert one (item,key) while preserving sorted order and FIFO tie stability.
# Used by: insert.ordered_sequence().
.oms_insert_impl <- function(x, element, key) {
  .oms_assert_set(x)
  norm <- .oms_normalize_key(key)
  key_type <- .oms_validate_key_type(.oms_key_type_state(x), norm$key_type)

  entry <- .oms_make_entry(element, norm$key)
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
#' Insert an element into an ordered sequence
#'
#' @method insert ordered_sequence
#' @param x An `ordered_sequence`.
#' @param element Element to insert.
#' @param key Scalar key for `element`.
#' @param ... Unused.
#' @return Updated `ordered_sequence`.
#' @export
insert.ordered_sequence <- function(x, element, key, ...) {
  .oms_insert_impl(x, element, key)
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
#' Find first element with key >= value
#'
#' @param x An `ordered_sequence`.
#' @param key Query key.
#' @return Named list with fields `found`, `index`, `element`, and `key`.
#'   When no match exists, `found` is `FALSE` and the remaining fields
#'   are `NULL`.
#' @export
# Public lower-bound query wrapper over .oms_bound_index().
lower_bound <- function(x, key) {
  .oms_stop_interval_index(x, "lower_bound")
  .oms_assert_set(x)
  idx <- .oms_bound_index(x, key, strict = FALSE)
  n <- length(x)

  if(idx > n) {
    return(list(found = FALSE, index = NULL, element = NULL, key = NULL))
  }

  entry <- .ft_get_elem_at(x, as.integer(idx))
  list(found = TRUE, index = idx, element = entry$item, key = entry$key)
}

# Runtime: O(log n).
#' Find first element with key > value
#'
#' @param x An `ordered_sequence`.
#' @param key Query key.
#' @return Named list with fields `found`, `index`, `element`, and `key`.
#'   When no match exists, `found` is `FALSE` and the remaining fields
#'   are `NULL`.
#' @export
# Public upper-bound query wrapper over .oms_bound_index().
upper_bound <- function(x, key) {
  .oms_stop_interval_index(x, "upper_bound")
  .oms_assert_set(x)
  idx <- .oms_bound_index(x, key, strict = TRUE)
  n <- length(x)

  if(idx > n) {
    return(list(found = FALSE, index = NULL, element = NULL, key = NULL))
  }

  entry <- .ft_get_elem_at(x, as.integer(idx))
  list(found = TRUE, index = idx, element = entry$item, key = entry$key)
}

# Runtime: O(log n).
#' Peek first element for one key
#'
#' Returns the first (leftmost) sequence element among entries whose key equals
#' `key`.
#'
#' @param x An `ordered_sequence`.
#' @param key Query key.
#' @return Raw stored element on match, or `NULL` when no matching key exists.
#' @export
peek_key <- function(x, key) {
  .oms_stop_interval_index(x, "peek_key")
  span <- .oms_key_span(x, key)
  if(!isTRUE(span$found)) {
    return(NULL)
  }
  s <- split_around_by_predicate(x, function(v) v >= span$start, ".size")
  s$elem$item
}

# Runtime: O(log n) near split points.
#' Peek all elements for one key
#'
#' Returns an ordered sequence containing exactly the entries whose key equals
#' `key`.
#'
#' @param x An `ordered_sequence`.
#' @param key Query key.
#' @return An `ordered_sequence` with all matching elements; empty on miss.
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
#' Pop first element for one key
#'
#' Removes and returns the first (leftmost) sequence element among entries
#' whose key equals `key`.
#'
#' @param x An `ordered_sequence`.
#' @param key Query key.
#' @return A named list with components `element`, `key`, and `remaining`.
#'   On miss: `element = NULL`, `key = NULL`, `remaining = x`.
#' @export
pop_key <- function(x, key) {
  .oms_stop_interval_index(x, "pop_key")
  span <- .oms_key_span(x, key)

  if(!isTRUE(span$found)) {
    return(list(element = NULL, key = NULL, remaining = x))
  }

  s <- split_around_by_predicate(x, function(v) v >= span$start, ".size")
  out <- concat_trees(s$left, s$right)
  seq_out <- .ord_wrap_like(x, out)
  list(element = s$elem$item, key = s$elem$key, remaining = seq_out)
}

# Runtime: O(log n) near split point depth.
#' Pop all elements for one key
#'
#' Removes and returns all matching entries for `key` as an ordered sequence.
#'
#' @param x An `ordered_sequence`.
#' @param key Query key.
#' @return A named list with components `elements` and `remaining`. Both are
#'   `ordered_sequence` objects. On miss, `elements` is empty and `remaining`
#'   is unchanged.
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

# Runtime: O(log n + k), where k is output size.
#' Return elements in a key range
#'
#' @param x An `ordered_sequence`.
#' @param from_key Lower bound key.
#' @param to_key Upper bound key.
#' @param include_from Include lower bound when `TRUE`.
#' @param include_to Include upper bound when `TRUE`.
#' @return List of raw elements.
#' @export
# Public range extraction API over bound-index helpers.
elements_between <- function(x, from_key, to_key, include_from = TRUE, include_to = TRUE) {
  .oms_stop_interval_index(x, "elements_between")
  .oms_assert_set(x)
  include_from <- .oms_coerce_lgl_scalar(include_from, "include_from")
  include_to <- .oms_coerce_lgl_scalar(include_to, "include_to")

  start <- .oms_range_start_index(x, from_key, include_from)
  end_excl <- .oms_range_end_exclusive_index(x, to_key, include_to)

  if(end_excl <= start || start > length(x)) {
    return(list())
  }

  entries <- .ft_get_elems_at(x, seq.int(start, end_excl - 1L))
  .oms_extract_items(entries)
}

# Runtime: O(log n).
#' Count elements matching one key
#'
#' @param x An `ordered_sequence`.
#' @param key Query key.
#' @return Integer count of matching elements.
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
#' Count elements in a key range
#'
#' @param x An `ordered_sequence`.
#' @param from_key Lower bound key.
#' @param to_key Upper bound key.
#' @param include_from Include lower bound when `TRUE`.
#' @param include_to Include upper bound when `TRUE`.
#' @return Integer count of matching elements.
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
