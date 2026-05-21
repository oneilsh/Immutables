#SO

# Point containment predicate for fallback/non-fast endpoint types.
# **Inputs:** scalar `start`, `end`, `point`; scalar `bounds` string; scalar `endpoint_type`.
# **Outputs:** scalar logical; TRUE when `point` is inside [start,end] under `bounds`.
# **Used by:** .ivx_spec_point() fallback leaf matcher.
.ivx_contains_point <- function(start, end, point, bounds, endpoint_type) {
  f <- .ivx_bounds_flags(bounds)
  cmp_lo <- .ivx_compare_scalar(point, start, endpoint_type)
  cmp_hi <- .ivx_compare_scalar(point, end, endpoint_type)

  left_ok <- if(isTRUE(f$include_start)) cmp_lo >= 0L else cmp_lo > 0L
  right_ok <- if(isTRUE(f$include_end)) cmp_hi <= 0L else cmp_hi < 0L
  isTRUE(left_ok && right_ok)
}

# Runtime: O(1).
# Interval overlap predicate for fallback/non-fast endpoint types.
# **Inputs:** scalar interval endpoints + bounds + endpoint_type.
# **Outputs:** scalar logical; TRUE when intervals overlap under `bounds`.
# **Used by:** .ivx_spec_overlaps(), .ivx_spec_containing(), .ivx_spec_within() fallback leaf matchers.
.ivx_overlaps_interval <- function(a_start, a_end, b_start, b_end, bounds, endpoint_type) {
  f <- .ivx_bounds_flags(bounds)
  touching_is_overlap <- isTRUE(f$include_start) && isTRUE(f$include_end)

  cmp_aend_bstart <- .ivx_compare_scalar(a_end, b_start, endpoint_type)
  cmp_bend_astart <- .ivx_compare_scalar(b_end, a_start, endpoint_type)

  a_before_b <- if(touching_is_overlap) cmp_aend_bstart < 0L else cmp_aend_bstart <= 0L
  b_before_a <- if(touching_is_overlap) cmp_bend_astart < 0L else cmp_bend_astart <= 0L

  !isTRUE(a_before_b || b_before_a)
}

# Runtime: O(1).
# Interval containment predicate for fallback/non-fast endpoint types.
# **Inputs:** scalar container endpoints, scalar inner endpoints, scalar endpoint_type.
# **Outputs:** scalar logical; TRUE when [inner_start,inner_end] is inside container interval.
# **Used by:** .ivx_spec_containing(), .ivx_spec_within() fallback leaf matchers.
.ivx_contains_interval <- function(container_start, container_end, inner_start, inner_end, endpoint_type) {
  left_ok <- .ivx_compare_scalar(container_start, inner_start, endpoint_type) <= 0L
  right_ok <- .ivx_compare_scalar(container_end, inner_end, endpoint_type) >= 0L
  isTRUE(left_ok && right_ok)
}

# Runtime: O(k) in matched entry count.
# Rebuilds an interval_index from entry payloads while preserving wrapper metadata.
# **Inputs:** `x` interval_index template; `entries` list of interval entry records.
# **Outputs:** interval_index containing `entries` in order (or empty-like if none).
# **Used by:** .ivx_run_relation_query() and all-match pop rebuild path.
.ivx_slice_entries <- function(x, entries) {
  if(length(entries) == 0L) {
    return(.ivx_empty_like(x))
  }

  ms <- resolve_tree_monoids(x, required = TRUE)
  tree <- .ivx_tree_from_ordered_entries(entries, monoids = ms)
  .ivx_wrap_like(x, tree)
}

# Runtime: O(k) in matched entry count.
# Converts a list of interval entries to parallel-vector list shape used by
# `as_list = TRUE` peek_all_* paths. Skips the result-tree rebuild.
# **Inputs:** `entries` list of interval entry records; scalar character
#   `endpoint_type` from `.ivx_endpoint_type_state()`.
# **Outputs:** list(values=<list>, starts=<atomic-or-list>, ends=<atomic-or-list>).
# **Used by:** .ivx_run_relation_query() as_list peek branches.
.ivx_entries_to_list <- function(entries, endpoint_type) {
  values <- lapply(entries, .subset2, "value")
  starts_l <- lapply(entries, .subset2, "start")
  ends_l   <- lapply(entries, .subset2, "end")
  list(
    values = values,
    starts = .ivx_simplify_endpoints(starts_l, endpoint_type),
    ends   = .ivx_simplify_endpoints(ends_l,   endpoint_type)
  )
}

# Runtime: O(k).
# Concatenates a list of scalar endpoints into an atomic vector when the
# index's endpoint domain is the simple `numeric` family (covering integer
# and double). For class-bearing domains (e.g. `Date`, `POSIXct`) and other
# non-simple domains, preserves the original list so each element keeps its
# class. Domain-driven design mirrors `.ivx_empty_endpoint_vector`.
# **Inputs:** `xs` list of scalar endpoint values; scalar character
#   `endpoint_type` from `.ivx_endpoint_type_state()`.
# **Outputs:** atomic vector or list.
# **Used by:** .ivx_entries_to_list().
.ivx_simplify_endpoints <- function(xs, endpoint_type) {
  if(length(xs) == 0L) {
    return(list())
  }
  if(identical(endpoint_type, "numeric")) {
    return(unlist(xs, use.names = FALSE))
  }
  xs
}

# Runtime: O(1).
# Returns a typed empty endpoint vector matching the index's endpoint domain.
# **Inputs:** scalar character `endpoint_type` (e.g. from `.ivx_endpoint_type_state`).
# **Outputs:** zero-length atomic vector or empty list for non-simple domains.
# **Used by:** .ivx_query_peek_miss() as_list branch.
.ivx_empty_endpoint_vector <- function(endpoint_type) {
  if(is.null(endpoint_type)) {
    return(list())
  }
  switch(endpoint_type,
    numeric = numeric(0),
    list()
  )
}

# Runtime: O(log n) near locate point depth.
# Computes lower/upper bound index from prepared start key and strictness.
# **Inputs:** `x` interval_index; scalar `key`; scalar logical `strict`.
# **Outputs:** 1-based integer insertion/bound index in [1, n+1].
# **Used by:** .ivx_query_candidate_span().
.ivx_bound_index_prepared <- function(x, key, strict = FALSE) {
  n <- length(x)
  if(n == 0L) {
    return(1L)
  }

  pred <- if(!isTRUE(strict)) {
    function(v) {
      isTRUE(v$has) && .ivx_compare_scalar_fast(v$start, key, v$endpoint_type) >= 0L
    }
  } else {
    function(v) {
      isTRUE(v$has) && .ivx_compare_scalar_fast(v$start, key, v$endpoint_type) > 0L
    }
  }

  loc <- locate_by_predicate(x, pred, ".ivx_max_start", include_metadata = TRUE)
  if(!isTRUE(loc$found)) {
    return(as.integer(n + 1L))
  }
  as.integer(loc$metadata$index)
}

# Runtime: O(log n) near bound locate points.
# Computes candidate start-index window from query spec bounds.
# **Inputs:** `x` interval_index; optional scalar `lower`/`upper`; scalar logical strict flags.
# **Outputs:** list(start, end_excl, empty) describing candidate index span.
# **Used by:** .ivx_run_relation_query().
.ivx_query_candidate_span <- function(x, lower = NULL, lower_strict = FALSE, upper = NULL, upper_strict = FALSE) {
  n <- length(x)
  if(n == 0L) {
    return(list(start = 1L, end_excl = 1L, empty = TRUE))
  }

  start <- if(is.null(lower)) {
    1L
  } else {
    # determine start index; if strict == TRUE then first index with start > key,
    # if FALSE then first index with start >= key
    .ivx_bound_index_prepared(x, lower, strict = isTRUE(lower_strict))
  }

  end_excl <- if(is.null(upper)) {
    as.integer(n + 1L)
  } else {
    # upper_strict means use first start >= upper as exclusive bound.
    .ivx_bound_index_prepared(x, upper, strict = !isTRUE(upper_strict))
  }

  if(start > n || end_excl <= start) {
    # empty span
    return(list(start = as.integer(start), end_excl = as.integer(end_excl), empty = TRUE))
  }

  list(start = as.integer(start), end_excl = as.integer(end_excl), empty = FALSE)
}

# Runtime: O(1).
# Returns subtree element count using `.size` measure (or 1 for leaves).
# **Inputs:** structural node or leaf entry.
# **Outputs:** scalar integer subtree size.
# **Used by:** .ivx_collect_query() when pruning whole subtrees.
.ivx_subtree_size <- function(node) {
  if(!.ivx_is_structural_fast(node)) {
    return(1L)
  }
  as.integer(node_measure(node, ".size"))
}

# Runtime: O(log n) near split point depth.
# Splits an interval_index at 1-based position into left/right interval_index trees.
# **Inputs:** `x` interval_index; scalar integer-like `index`.
# **Outputs:** list(left, right) interval_index fragments.
# **Used by:** .ivx_partition_span().
.ivx_split_at_index <- function(x, index) {
  n <- length(x)
  idx <- as.integer(index)
  if(is.na(idx)) {
    stop("`index` must be a non-missing integer.")
  }

  if(n == 0L) {
    empty <- .ivx_empty_like(x)
    return(list(left = empty, right = empty))
  }
  if(idx <= 1L) {
    return(list(left = .ivx_empty_like(x), right = x))
  }
  if(idx > n) {
    return(list(left = x, right = .ivx_empty_like(x)))
  }

  ms <- resolve_tree_monoids(x, required = TRUE)
  if(.ft_cpp_can_use(ms)) {
    # Native 3-way split returns (left, value-at-idx, right). Re-attach the
    # value-at-idx to the front of `right` to produce the 2-way split we need
    # (left = elements 1..idx-1, right = elements idx..n).
    s <- .ft_cpp_split_at_index(x, idx, ms)
    return(list(
      left  = .ivx_wrap_like(x, s$left),
      right = .ivx_wrap_like(x, push_front(s$right, s$value))
    ))
  }
  s <- split_by_predicate(x, function(v) v >= idx, ".size")
  list(
    left = .ivx_wrap_like(x, s$left),
    right = .ivx_wrap_like(x, s$right)
  )
}

# Runtime: O(log n) near boundary split points.
# Splits full tree into left/candidate/right partitions for query scanning.
# **Inputs:** `x` interval_index; `span` list with `start` and `end_excl`.
# **Outputs:** list(left, candidate, right) interval_index fragments.
# **Used by:** .ivx_run_relation_query() non-window path.
.ivx_partition_span <- function(x, span) {
  s1 <- .ivx_split_at_index(x, span$start)
  left <- s1$left
  tail <- s1$right
  cand_len <- as.integer(max(0L, span$end_excl - span$start))

  if(cand_len <= 0L) {
    return(list(left = left, candidate = .ivx_empty_like(x), right = tail))
  }

  s2 <- .ivx_split_at_index(tail, cand_len + 1L)
  list(left = left, candidate = s2$left, right = s2$right)
}

# Runtime: O(1).
# Concatenates three interval_index fragments and restores wrapper metadata.
# **Inputs:** interval_index `template`; structural trees `left`, `middle`, `right`.
# **Outputs:** interval_index rebuilt as left + middle + right.
# **Used by:** all-match pop rebuild to construct remaining tree.
.ivx_concat3_like <- function(template, left, middle, right) {
  out <- concat_trees(left, middle)
  out <- concat_trees(out, right)
  .ivx_wrap_like(template, out)
}

# Runtime: O(1).
# Standardized miss return for peek relation endpoints.
# **Inputs:** `x` interval_index; `which` in {"first","all"}.
# **Outputs:** NULL for first; empty interval_index for all.
# **Used by:** .ivx_run_relation_query() miss branches.
.ivx_query_peek_miss <- function(x, which = c("first", "all"), as_list = FALSE) {
  which <- match.arg(which)
  if(identical(which, "first")) {
    return(NULL)
  }
  if(isTRUE(as_list)) {
    et <- .ivx_endpoint_type_state(x)
    return(list(
      values = list(),
      starts = .ivx_empty_endpoint_vector(et),
      ends   = .ivx_empty_endpoint_vector(et)
    ))
  }
  .ivx_empty_like(x)
}

# Runtime: O(1).
# Standardized miss return for pop relation endpoints.
# **Inputs:** `x` interval_index; `which` in {"first","all"}.
# **Outputs:** scalar miss for first; bulk miss for all with empty elements slice.
# **Used by:** .ivx_run_relation_query() miss branches.
.ivx_query_pop_miss <- function(x, which = c("first", "all")) {
  which <- match.arg(which)
  if(identical(which, "all")) {
    return(list(elements = .ivx_empty_like(x), remaining = x))
  }
  list(value = NULL, start = NULL, end = NULL, remaining = x)
}

# Runtime: O(s), where s is traversed subtree size after aggressive pruning 
# based on subtree span and query span.
# Traverses candidate tree with spec predicates and optional unmatched collection.
# **Inputs:**
#
# - `tree`: structural candidate subtree.
# - `no_match_subtree`: function(node) -> logical prune decision.
# - `leaf_match`: function(entry) -> logical exact match decision.
# - scalar logical flags `collect_unmatched`, `stop_after_first`.
#
# **Outputs:**
#
# - list(first_found, first_index, first_entry, matched_entries, unmatched_entries).
#
# **Used by:** .ivx_run_relation_query() traversal path.
.ivx_collect_query <- function(
    tree,
    no_match_subtree,
    leaf_match,
    collect_unmatched = FALSE,
    stop_after_first = FALSE
) {
  # Accumulator state for traversal order, first-hit tracking, and optional
  # matched/unmatched entry capture.
  st <- new.env(parent = emptyenv())
  st$index <- 0L
  st$first_index <- NULL
  st$first_entry <- NULL
  st$m <- 0L
  st$u <- 0L
  st$matched <- list()
  st$unmatched <- list()

  append_many <- function(bucket, entries) {
    if(length(entries) == 0L) {
      return(invisible(NULL))
    }
    if(identical(bucket, "unmatched")) {
      for(el in entries) {
        st$u <- st$u + 1L
        st$unmatched[[st$u]] <- el
      }
      return(invisible(NULL))
    }
    for(el in entries) {
      st$m <- st$m + 1L
      st$matched[[st$m]] <- el
    }
    invisible(NULL)
  }

  walk <- function(node) {
    # Early stop for first-hit queries once a hit has been recorded.
    if(isTRUE(stop_after_first) && !is.null(st$first_index)) {
      return(invisible(NULL))
    }

    # Leaf entry path: evaluate exact predicate and capture into requested
    # output buckets.
    if(!.ivx_is_structural_fast(node)) {
      st$index <- st$index + 1L
      hit <- isTRUE(leaf_match(node))

      if(isTRUE(hit)) {
        if(is.null(st$first_index)) {
          st$first_index <- st$index
          st$first_entry <- node
        }
        st$m <- st$m + 1L
        st$matched[[st$m]] <- node
      } else if(isTRUE(collect_unmatched)) {
        st$u <- st$u + 1L
        st$unmatched[[st$u]] <- node
      }
      return(invisible(NULL))
    }

    # Prune only at Deep nodes where subtree measures summarize meaningful
    # spans; pruning tiny Digit/Node fragments often costs more than it saves.
    can_prune <- inherits(node, "Deep")
    if(isTRUE(can_prune) && isTRUE(no_match_subtree(node))) {
      # Pruned subtree contributes only index offset; optionally capture
      # unmatched entries for all-pop rebuild path.
      sz <- .ivx_subtree_size(node)
      if(isTRUE(collect_unmatched) && sz > 0L) {
        append_many("unmatched", .ivx_entries(node))
      }
      st$index <- st$index + sz
      return(invisible(NULL))
    }

    # Structural descent in left-to-right entry order.
    if(inherits(node, "Empty")) {
      return(invisible(NULL))
    }
    if(inherits(node, "Single")) {
      walk(.subset2(node, 1L))
      return(invisible(NULL))
    }
    if(inherits(node, "Deep")) {
      walk(.subset2(node, "prefix"))
      walk(.subset2(node, "middle"))
      walk(.subset2(node, "suffix"))
      return(invisible(NULL))
    }

    for(el in node) {
      walk(el)
    }
    invisible(NULL)
  }

  walk(tree)

  # Return traversal summary used by peek/pop execution paths.
  list(
    first_found = !is.null(st$first_index),
    first_index = st$first_index,
    first_entry = st$first_entry,
    matched_entries = if(st$m > 0L) st$matched[seq_len(st$m)] else list(),
    unmatched_entries = if(st$u > 0L) st$unmatched[seq_len(st$u)] else list()
  )
}

# Runtime: O(log n + s), where s is traversed candidate subtree size after pruning.
# Main executor for interval relation queries.
# **Inputs:**
#
# - `x`: interval_index.
# - `spec`: query-spec list from .ivx_spec_*.
# - `mode`: "peek" or "pop".
# - `which`: "first" or "all".
#
# **Outputs:**
#
# - peek/first: element value or NULL.
# - peek/all: interval_index slice of matches (possibly empty).
# - pop/first: list(value,start,end,remaining).
# - pop/all: list(elements=<interval_index>, remaining=<interval_index>).
#
# **Used by:** public query API (peek_*/pop_* endpoints).
.ivx_run_relation_query <- function(x, spec, mode = c("peek", "pop"),
                                    which = c("first", "all"),
                                    as_list = FALSE) {
  mode <- match.arg(mode)
  which <- match.arg(which)
  ms <- resolve_tree_monoids(x, required = TRUE)
  use_window_fast_path <- isTRUE(.ft_cpp_can_use(ms))
  # `as_list` only affects peek/all returns; pop paths still need rebuilt trees.
  list_shape <- isTRUE(as_list) && identical(mode, "peek") && identical(which, "all")

  # Phase 1: derive candidate start-index window span from query-spec bounds.
  span <- .ivx_query_candidate_span(
    x,
    lower = spec$lower,
    lower_strict = spec$lower_strict,
    upper = spec$upper,
    upper_strict = spec$upper_strict
  )
  # if the span is empty we return no data (depending on peek/pop/which behavior)
  if(isTRUE(span$empty)) {
    if(identical(mode, "peek")) {
      return(.ivx_query_peek_miss(x, which = which, as_list = list_shape))
    }
    return(.ivx_query_pop_miss(x, which = which))
  }

  # Native compound query path: walks the candidate subtree leaf-by-leaf
  # with .ivx_max_end pruning (where applicable), avoiding the candidate-
  # window materialisation. Covers all four predicate kinds for peek.
  use_native_query <- isTRUE(getOption("immutables.ivx.cpp_scan", TRUE)) &&
                      !is.null(spec$native) &&
                      isTRUE(spec$native$endpoint_kind != 0L) &&
                      !is.null(spec$native$bounds_flags) &&
                      spec$native$relation_kind %in% c("point", "overlaps", "containing", "within")

  if(isTRUE(use_native_query)) {
    parts <- .ivx_partition_span(x, span)
    with_unmatched <- identical(mode, "pop")
    peek_all <- identical(mode, "peek") && identical(which, "all")
    native_as_list <- peek_all && isTRUE(list_shape)
    # Monoids are needed whenever the C++ side may build a tree: pop (always)
    # or peek/all with slice-shape result (matched_tree).
    needs_tree <- with_unmatched || (peek_all && !isTRUE(list_shape))
    ms <- if(needs_tree) resolve_tree_monoids(x, required = TRUE) else NULL

    q <- .ivx_native_query(
      candidate_tree = parts$candidate,
      relation_kind  = spec$native$relation_kind,
      qlo            = spec$native$qlo,
      qhi            = spec$native$qhi,
      bounds_flags   = spec$native$bounds_flags,
      endpoint_kind  = spec$native$endpoint_kind,
      which          = which,
      with_unmatched = with_unmatched,
      monoids        = ms,
      as_list        = native_as_list
    )

    matched <- q$matched

    if(identical(mode, "peek")) {
      if(identical(which, "first")) {
        return(if(length(matched) == 0L) NULL else .subset2(matched[[1L]], "value"))
      }
      # which == "all": consume the C++-built result shape directly.
      if(length(matched) == 0L) {
        return(.ivx_query_peek_miss(x, which = which, as_list = list_shape))
      }
      if(isTRUE(list_shape)) {
        et <- .ivx_endpoint_type_state(x)
        return(list(
          values = q$values,
          starts = .ivx_simplify_endpoints(q$starts_l, et),
          ends   = .ivx_simplify_endpoints(q$ends_l,   et)
        ))
      }
      return(.ivx_wrap_like(x, q$matched_tree))
    }

    # mode == "pop"
    # q$unmatched_tree is a bare structural tree; wrap before concat
    unmatched_wrapped <- .ivx_wrap_like(x, q$unmatched_tree)
    remaining <- .ivx_concat3_like(x, parts$left, unmatched_wrapped, parts$right)

    if(identical(which, "first")) {
      if(length(matched) == 0L) return(.ivx_query_pop_miss(x, which = which))
      e <- matched[[1L]]
      return(list(value = .subset2(e, "value"),
                  start = .subset2(e, "start"),
                  end   = .subset2(e, "end"),
                  remaining = remaining))
    }

    # pop / all
    if(length(matched) == 0L) {
      return(.ivx_query_pop_miss(x, which = which))
    }
    elements <- .ivx_wrap_like(x, q$matched_tree)
    return(list(elements = elements, remaining = remaining))
  }

  # Phase 2: C++-friendly window scan fast path for peek and first-hit pop.
  # When C++ backend is active, candidate-window scanning has lower constants
  # for read-heavy/first-hit queries than split+rebuild traversal.
  # With native_query handling all eligible peek cases above, this block now
  # serves pop first-hit and non-eligible peek (e.g. point match_at != "interval",
  # non-numeric endpoints) via the R closure loop.
  if(isTRUE(use_window_fast_path) && (identical(mode, "peek") || identical(which, "first"))) {
    entries <- .ft_get_elems_at(x, seq.int(span$start, span$end_excl - 1L))
    n <- length(entries)
    if(n == 0L) {
      if(identical(mode, "peek")) {
        return(.ivx_query_peek_miss(x, which = which, as_list = list_shape))
      }
      return(.ivx_query_pop_miss(x, which = which))
    }

    first_i <- NULL
    hit <- if(!identical(which, "first")) logical(n) else NULL
    for(i in seq_len(n)) {
      ok <- isTRUE(spec$leaf_match(entries[[i]]))
      if(ok) {
        if(is.null(first_i)) {
          first_i <- i
          if(identical(which, "first")) {
            break
          }
        }
      }
      if(!is.null(hit)) {
        hit[[i]] <- ok
      }
    }

    if(is.null(first_i)) {
      if(identical(mode, "peek")) {
        return(.ivx_query_peek_miss(x, which = which, as_list = list_shape))
      }
      return(.ivx_query_pop_miss(x, which = which))
    }

    # First-hit branches can return value directly (peek) or pop by absolute
    # index without rebuilding candidate partitions.
    if(identical(which, "first")) {
      if(identical(mode, "peek")) {
        return(entries[[first_i]]$value)
      }
      abs_idx <- as.integer(span$start + first_i - 1L)
      return(.ivx_pop_positions(x, abs_idx, which = "first"))
    }

    matched_entries <- entries[hit]
    if(length(matched_entries) == 0L) {
      return(.ivx_query_peek_miss(x, which = which, as_list = list_shape))
    }
    if(isTRUE(list_shape)) {
      return(.ivx_entries_to_list(matched_entries, endpoint_type = .ivx_endpoint_type_state(x)))
    }
    return(.ivx_slice_entries(x, matched_entries))
  }

  # Phase 3: split into left/candidate/right and traverse only candidate tree.
  parts <- .ivx_partition_span(x, span)
  cand <- parts$candidate
  if(length(cand) == 0L) {
    if(identical(mode, "peek")) {
      return(.ivx_query_peek_miss(x, which = which, as_list = list_shape))
    }
    return(.ivx_query_pop_miss(x, which = which))
  }

  # Phase 4A: peek branches (first/all) from collected candidate hits.
  if(identical(mode, "peek")) {
    hit <- .ivx_collect_query(
      cand,
      no_match_subtree = spec$no_match_subtree,
      leaf_match = spec$leaf_match,
      collect_unmatched = FALSE,
      stop_after_first = identical(which, "first")
    )

    if(identical(which, "first")) {
      if(!isTRUE(hit$first_found)) {
        return(.ivx_query_peek_miss(x, which = which))
      }
      return(hit$first_entry$value)
    }

    if(length(hit$matched_entries) == 0L) {
      return(.ivx_query_peek_miss(x, which = which, as_list = list_shape))
    }
    if(isTRUE(list_shape)) {
      return(.ivx_entries_to_list(hit$matched_entries, endpoint_type = .ivx_endpoint_type_state(x)))
    }
    return(.ivx_slice_entries(x, hit$matched_entries))
  }

  # Phase 4B: pop first-hit branch via absolute index.
  if(identical(which, "first")) {
    hit <- .ivx_collect_query(
      cand,
      no_match_subtree = spec$no_match_subtree,
      leaf_match = spec$leaf_match,
      collect_unmatched = FALSE,
      stop_after_first = TRUE
    )

    if(!isTRUE(hit$first_found)) {
      return(.ivx_query_pop_miss(x, which = which))
    }
    abs_idx <- as.integer(span$start + hit$first_index - 1L)
    return(.ivx_pop_positions(x, abs_idx, which = "first"))
  }

  # Phase 4C: pop all branch rebuilds matched slice and remaining tree from
  # matched/unmatched candidate partitions.
  hit <- .ivx_collect_query(
    cand,
    no_match_subtree = spec$no_match_subtree,
    leaf_match = spec$leaf_match,
    collect_unmatched = TRUE,
    stop_after_first = FALSE
  )
  if(length(hit$matched_entries) == 0L) {
    return(.ivx_query_pop_miss(x, which = which))
  }

  # `which = "all"` pop keeps deterministic order by rebuilding matched and
  # unmatched candidate partitions from collected entries.
  matched <- .ivx_slice_entries(x, hit$matched_entries)
  unmatched <- .ivx_slice_entries(x, hit$unmatched_entries)
  remaining <- .ivx_concat3_like(x, parts$left, unmatched, parts$right)

  list(elements = matched, remaining = remaining)
}

# Returns a slice by positions as interval_index, preserving class metadata.
# **Inputs:** `x` interval_index; integer-like vector `positions`.
# **Outputs:** interval_index slice (empty-like when `positions` is empty).
# **Used by:** .ivx_pop_positions() all-branch.
.ivx_slice_positions <- function(x, positions) {
  if(length(positions) == 0L) {
    return(.ivx_empty_like(x))
  }
  x[as.integer(positions)]
}

# Runtime: O(log n) for single index removal; O(n log n) for multi-index rebuild.
# Removes one or more positions from an interval_index.
# **Inputs:** `x` interval_index; integer-like vector `positions`.
# **Outputs:** interval_index with those positions removed.
# **Used by:** .ivx_pop_positions().
.ivx_remove_positions <- function(x, positions) {
  n <- length(x)
  if(length(positions) == 0L) {
    return(x)
  }
  if(length(positions) >= n) {
    return(.ivx_empty_like(x))
  }
  if(length(positions) == 1L) {
    idx <- as.integer(positions[[1]])
    s <- split_around_by_predicate(x, function(v) v >= idx, ".size")
    return(.ivx_wrap_like(x, concat_trees(s$left, s$right)))
  }

  keep <- setdiff(seq_len(n), as.integer(positions))
  x[as.integer(keep)]
}

# Runtime: O(log n + c) for `which = "first"`; O(n log n) for `which = "all"`.
# Pop helper for already-resolved match positions.
# **Inputs:** `x` interval_index; integer-like `positions`; `which` in {"first","all"}.
# **Outputs:**
#
# - which = "first": list(value =<payload value>, start=<scalar>, end=<scalar>, remaining=<interval_index>).
# - which = "all": list(elements=<interval_index slice at `positions`>,
#   remaining=<interval_index with those positions removed>).
#
# **Used by:** .ivx_run_relation_query() fast path and first-hit pop path.
.ivx_pop_positions <- function(x, positions, which = c("first", "all")) {
  which <- match.arg(which)

  if(length(positions) == 0L) {
    if(identical(which, "all")) {
      return(list(elements = .ivx_empty_like(x), remaining = x))
    }
    return(list(value = NULL, start = NULL, end = NULL, remaining = x))
  }

  if(identical(which, "first")) {
    idx <- as.integer(positions[[1]])
    entry <- .ft_get_elem_at(x, idx)
    remaining <- .ivx_remove_positions(x, idx)
    return(list(value = entry$value, start = entry$start, end = entry$end, remaining = remaining))
  }

  matched <- .ivx_slice_positions(x, positions)
  remaining <- .ivx_remove_positions(x, positions)
  list(elements = matched, remaining = remaining)
}
