#SO

# Canonical interval entry constructor.
# **Inputs:** payload `value`; scalar `start`/`end`.
# **Outputs:** entry list(value,start,end,key) with key==start.
# **Used by:** constructor/insert/apply/parse rebuild paths.
.ivx_make_entry <- function(value, start, end) {
  # `key` mirrors `start` so interval entries remain compatible with ordered
  # key monoid paths (e.g. `.oms_max_key`) when those monoids are present.
  list(value = value, start = start, end = end, key = start)
}


# Applies validated element names to entry records as `ft_name` attrs.
# **Inputs:** `entries` list of entry records (optionally named).
# **Outputs:** entries list with normalized per-entry names and stripped list names.
# **Used by:** .ivx_tree_from_ordered_entries().
.ivx_prepare_entry_names <- function(entries) {
  if(length(entries) == 0L) {
    return(entries)
  }
  nms <- names(entries)
  if(is.null(nms)) {
    return(entries)
  }

  out <- entries
  for(i in seq_along(out)) {
    nm <- .ft_normalize_name(nms[[i]])
    if(!is.null(nm)) {
      out[[i]] <- .ft_set_name(out[[i]], nm)
    }
  }
  names(out) <- NULL
  out
}

# Runtime: O(n) for ordered entries.
# Bulk-builds a measured tree from already ordered entries.
# **Inputs:** `entries` ordered entry list; `monoids` normalized monoid list.
# **Outputs:** structural tree/flexseq node carrying the entries.
# **Used by:** constructors and rebuild helpers.
.ivx_tree_from_ordered_entries <- function(entries, monoids) {
  entries <- .ivx_prepare_entry_names(entries)
  if(.ft_cpp_can_use(monoids)) {
    return(.as_flexseq(.ft_cpp_tree_from_sorted(entries, monoids)))
  }
  .ft_tree_from_list_linear(entries, monoids)
}

# Runtime: O(n log n) for stable merge sort by start.
# Stable merge-sort over entry indices by `start`.
# **Inputs:** integer index vector `idx`; `entries` list; scalar `endpoint_type`.
# **Outputs:** reordered integer index vector.
# **Used by:** .ivx_order_entries() fallback path.
.ivx_merge_sort_indices <- function(idx, entries, endpoint_type) {
  n <- length(idx)
  if(n <= 1L) {
    return(idx)
  }

  mid <- as.integer(n %/% 2L)
  left <- .ivx_merge_sort_indices(idx[seq_len(mid)], entries, endpoint_type)
  right <- .ivx_merge_sort_indices(idx[(mid + 1L):n], entries, endpoint_type)

  out <- integer(n)
  i <- 1L
  j <- 1L
  k <- 1L
  while(i <= length(left) && j <= length(right)) {
    cmp <- .ivx_compare_scalar(entries[[left[[i]]]]$start, entries[[right[[j]]]]$start, endpoint_type)
    if(cmp <= 0L) {
      out[[k]] <- left[[i]]
      i <- i + 1L
    } else {
      out[[k]] <- right[[j]]
      j <- j + 1L
    }
    k <- k + 1L
  }

  while(i <= length(left)) {
    out[[k]] <- left[[i]]
    i <- i + 1L
    k <- k + 1L
  }
  while(j <= length(right)) {
    out[[k]] <- right[[j]]
    j <- j + 1L
    k <- k + 1L
  }
  out
}

# Runtime: O(n log n) stable by start and FIFO on ties.
# Produces start-ordered entries with stable tie handling.
# **Inputs:** `entries` list; scalar `endpoint_type`.
# **Outputs:** ordered entry list.
# **Used by:** .ivx_build_from_items().
.ivx_order_entries <- function(entries, endpoint_type) {
  if(length(entries) <= 1L) {
    return(entries)
  }

  idx <- seq_along(entries)
  starts <- lapply(entries, function(e) e$start)
  ord <- tryCatch(
    order(do.call(c, starts), idx),
    error = function(e) NULL
  )
  if(is.null(ord) || length(ord) != length(entries)) {
    ord <- .ivx_merge_sort_indices(idx, entries, endpoint_type)
  }
  entries[ord]
}

# Runtime: O(n log n) from sort + bulk build.
# Core builder from user value/start/end vectors.
# **Inputs:**
#
# - `items`: list payloads.
# - `start`,`end`: vectors/lists of scalar endpoints or NULL.
# - `bounds`: scalar bounds string.
# - `monoids`: optional user monoid list.
# **Outputs:** interval_index.
# **Used by:** as_interval_index(), interval_index(), .as_interval_index_build().
.ivx_build_from_items <- function(items, start = NULL, end = NULL, bounds = "[)", monoids = NULL) {
  n <- length(items)

  if(n == 0L) {
    if(!is.null(start) && length(as.list(start)) > 0L) {
      stop("`start` must be empty when no elements are supplied.")
    }
    if(!is.null(end) && length(as.list(end)) > 0L) {
      stop("`end` must be empty when no elements are supplied.")
    }

    base <- .as_flexseq_build(list(), monoids = .ivx_merge_monoids(monoids))
    return(.as_interval_index(base, endpoint_type = NULL, bounds = bounds))
  }

  if(is.null(start)) {
    stop("`start` is required when elements are supplied.")
  }
  if(is.null(end)) {
    stop("`end` is required when elements are supplied.")
  }

  starts <- as.list(start)
  ends <- as.list(end)

  if(length(starts) != n) {
    stop("`start` length must match elements length.")
  }
  if(length(ends) != n) {
    stop("`end` length must match elements length.")
  }

  entries <- vector("list", n)
  item_names <- names(items)
  endpoint_type <- NULL

  for(i in seq_len(n)) {
    norm <- .ivx_normalize_interval(starts[[i]], ends[[i]], endpoint_type = endpoint_type)
    endpoint_type <- norm$endpoint_type

    entries[[i]] <- .ivx_make_entry(items[[i]], norm$start, norm$end)
  }
  if(!is.null(item_names) && length(item_names) == n) {
    names(entries) <- item_names
  }

  entries <- .ivx_order_entries(entries, endpoint_type)
  merged_monoids <- .ivx_merge_monoids(monoids, endpoint_type = endpoint_type)
  base <- .ivx_tree_from_ordered_entries(entries, merged_monoids)
  .as_interval_index(base, endpoint_type = endpoint_type, bounds = bounds)
}

# Public coercion constructor.
# **Inputs:** `x` coercible to list; `start`/`end` endpoint vectors; `bounds`.
# **Outputs:** interval_index.
# **Used by:** users/tests.
#' Build an Interval Index from `x`, `start`, and `end`
#'
#' Constructs an `interval_index` by pairing each element of `x` with
#' corresponding `start` and `end` endpoints.
#'
#' @param x Elements to add.
#' @param start Start endpoints with the same length as `x`.
#' @param end End endpoints with the same length as `x`.
#' @param default_query_bounds Boundary convention used as the default for
#'   query operations on this index: one of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#'   Per-query `peek_*` / `pop_*` calls may override via their own `bounds`
#'   argument.
#' @return An `interval_index`.
#' @details
#' Output is ordered by interval `start`.
#'
#' Names on `x` are preserved as element names.
#' @examples
#' ix <- as_interval_index(c("a", "b", "c"), start = c(1, 2, 2), end = c(3, 2, 4))
#' ix
#' as.list(peek_all_point(ix, 2))
#'
#' # Endpoints can be other comparable types
#' ix_date <- as_interval_index(
#'   c("phase1", "phase2"),
#'   start = as.Date(c("2024-01-01", "2024-01-10")),
#'   end = as.Date(c("2024-01-05", "2024-01-15"))
#' )
#' ix_date
#' @export
as_interval_index <- function(x, start, end, default_query_bounds = "[)") {
  .as_interval_index_build(x, start = start, end = end, bounds = default_query_bounds, monoids = NULL)
}

# Runtime: O(n log n) from sort + bulk build.
# Internal constructor wrapper accepting optional custom monoids.
# **Inputs:** `x`, `start`, `end`, `bounds`, optional `monoids`.
# **Outputs:** interval_index.
# **Used by:** as_interval_index(), interval_index(), internal rebuild paths.
.as_interval_index_build <- function(x, start, end, bounds = "[)", monoids = NULL) {
  .ivx_build_from_items(as.list(x), start = start, end = end, bounds = bounds, monoids = monoids)
}

# Runtime: O(n log n) from sort + bulk build.
# Variadic convenience constructor.
# **Inputs:** variadic payload args; `start`,`end`; `bounds`.
# **Outputs:** interval_index.
# **Used by:** users/tests.
#' Construct an Interval Index
#'
#' Convenience constructor from `...`, `start`, and `end`.
#'
#' @param ... Elements to add.
#' @param start Start endpoints matching `...`.
#' @param end End endpoints matching `...`.
#' @param default_query_bounds Boundary convention used as the default for
#'   query operations on this index: one of `"[)"`, `"[]"`, `"()"`, `"(]"`.
#'   Per-query `peek_*` / `pop_*` calls may override via their own `bounds`
#'   argument.
#' @return An `interval_index`.
#' @details
#' Empty construction is supported: `interval_index()` returns an empty index.
#'
#' Output is ordered by interval `start`.
#' @examples
#' ix <- interval_index("a", "b", "c", start = c(1, 2, 2), end = c(3, 2, 4))
#' ix
#'
#' interval_index()
#' @export
interval_index <- function(..., start, end, default_query_bounds = "[)") {
  if(missing(start)) {
    start <- NULL
  }
  if(missing(end)) {
    end <- NULL
  }
  .as_interval_index_build(list(...), start = start, end = end, bounds = default_query_bounds, monoids = NULL)
}
