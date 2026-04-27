#SO

#' @method as_flexseq interval_index
#' @export
# Runtime: O(n) from list materialization + linear rebuild.
# Public cast to plain flexseq while dropping interval-specific behavior.
# **Inputs:** `x` interval_index.
# **Outputs:** flexseq.
# **Used by:** users/tests.
as_flexseq.interval_index <- function(x) {
  entries <- as.list(x)
  .as_flexseq_build.default(entries, monoids = NULL)
}

# Runtime: O(n).
# Coerce to payload list in interval order.
# **Inputs:** `x` interval_index.
# **Outputs:** base list of payload items with names preserved.
# **Used by:** users/tests.
#' Coerce Interval Index to List
#'
#' @method as.list interval_index
#' @param x An `interval_index`.
#' @param ... Unused.
#' @return A plain list of payload elements in interval order.
#' @details
#' This returns payload values only.
#' @examples
#' ix <- interval_index("a", "b", "c", start = c(3, 1, 2), end = c(4, 2, 3))
#' as.list(ix)
#' @export
as.list.interval_index <- function(x, ...) {
  .ivx_assert_index(x)
  entries <- as.list.flexseq(x, ...)
  out <- lapply(entries, function(e) e$value)
  names(out) <- names(entries)
  out
}

# Runtime: O(1).
# Length method backed by cached `.size` measure.
# **Inputs:** `x` interval_index.
# **Outputs:** scalar integer length.
# **Used by:** users/tests/base generics.
#' Interval Index Length
#'
#' @method length interval_index
#' @param x An `interval_index`.
#' @return Number of indexed intervals.
#' @details
#' Uses cached size metadata and runs in O(1).
#' @examples
#' ix <- interval_index("a", "b", start = c(1, 3), end = c(2, 5))
#' length(ix)
#'
#' length(interval_index())
#' @export
length.interval_index <- function(x) {
  as.integer(node_measure(x, ".size"))
}

#' Merge Two Interval Indices
#'
#' Returns a new `interval_index` containing every entry from both inputs,
#' preserving start-position order. On tied start positions, `x`'s entries
#' precede `y`'s (left-biased FIFO).
#'
#' @method merge interval_index
#' @param x An `interval_index`.
#' @param y An `interval_index`.
#' @param ... Unused.
#' @return A new `interval_index` of size `length(x) + length(y)`.
#' @details
#' The merge runs in O(m + n) via a zipper-style traversal on interval
#' starts, with a fast path to O(log(min(m, n))) when the start ranges are
#' disjoint.
#'
#' Both indices must share the same endpoint type and the same `bounds`
#' convention (e.g. `"[)"` half-open vs. `"[]"` closed), and the same
#' monoid set. Mismatches error.
#'
#' The reserved monoids `.ivx_min_end` / `.ivx_max_end` recompute
#' automatically on the merged tree, so `min_endpoint()` / `max_endpoint()`
#' and interval-relation queries work immediately on the result.
#'
#' Both inputs are left unmodified.
#' @examples
#' a <- interval_index("A1", "A2", start = c(1, 5), end = c(4, 8))
#' b <- interval_index("B1", "B2", start = c(3, 7), end = c(6, 10))
#' m <- merge(a, b)
#' as.list(m)
#' @export
# Runtime: O(m + n); O(log(min(m, n))) on the disjoint fast path.
merge.interval_index <- function(x, y, ...) {
  if(!inherits(y, "interval_index")) {
    stop("Both arguments to `merge()` must be interval_indices.")
  }

  if(length(x) == 0L) return(y)
  if(length(y) == 0L) return(x)

  ep_x <- attr(x, "ivx_endpoint_type", exact = TRUE)
  ep_y <- attr(y, "ivx_endpoint_type", exact = TRUE)
  if(!identical(ep_x, ep_y)) {
    stop("Cannot merge interval_indices with different endpoint types.")
  }
  b_x <- attr(x, "ivx_bounds", exact = TRUE)
  b_y <- attr(y, "ivx_bounds", exact = TRUE)
  if(!identical(b_x, b_y)) {
    stop("Cannot merge interval_indices with different bounds conventions.")
  }
  if(!identical(sort(names(attr(x, "monoids", exact = TRUE))),
                sort(names(attr(y, "monoids", exact = TRUE))))) {
    stop("Cannot merge interval_indices with different monoid sets.")
  }

  nxs <- length(x); nys <- length(y)

  # Materialize entries for zipper and boundary checks.
  xs <- .ft_to_list(x)
  ys <- .ft_to_list(y)

  # Disjoint fast paths on start values.
  x_max_start <- xs[[nxs]]$start
  y_min_start <- ys[[1L]]$start
  if(.ivx_compare_scalar(x_max_start, y_min_start, ep_x) <= 0L) {
    return(.ivx_wrap_like(x, concat_trees(x, y)))
  }
  y_max_start <- ys[[nys]]$start
  x_min_start <- xs[[1L]]$start
  if(.ivx_compare_scalar(y_max_start, x_min_start, ep_x) < 0L) {
    return(.ivx_wrap_like(x, concat_trees(y, x)))
  }

  # General zipper merge on pre-sorted (by start) entries.
  merged <- vector("list", nxs + nys)
  i <- 1L; j <- 1L; k <- 1L
  while(i <= nxs && j <= nys) {
    if(.ivx_compare_scalar(xs[[i]]$start, ys[[j]]$start, ep_x) <= 0L) {
      merged[[k]] <- xs[[i]]; i <- i + 1L
    } else {
      merged[[k]] <- ys[[j]]; j <- j + 1L
    }
    k <- k + 1L
  }
  while(i <= nxs) { merged[[k]] <- xs[[i]]; i <- i + 1L; k <- k + 1L }
  while(j <= nys) { merged[[k]] <- ys[[j]]; j <- j + 1L; k <- k + 1L }

  ms <- attr(x, "monoids", exact = TRUE)
  out <- .ivx_tree_from_ordered_entries(merged, ms)
  .ivx_wrap_like(x, out)
}
