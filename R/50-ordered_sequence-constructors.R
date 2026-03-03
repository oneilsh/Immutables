#SO

# Runtime: O(1).
# Build one canonical ordered entry payload.
# Used by: .oms_build_from_items() constructor assembly loop.
.oms_make_entry <- function(item, key_value) {
  list(item = item, key = key_value)
}

# Runtime: O(n log n) for stable merge sort by key.
# Stable sort fallback when base order() cannot safely order key objects.
# Used by: .oms_order_entries() for non-primitive/custom key classes.
.oms_merge_sort_indices <- function(idx, entries, key_type) {
  n <- length(idx)
  if(n <= 1L) {
    return(idx)
  }

  mid <- as.integer(n %/% 2L)
  left <- .oms_merge_sort_indices(idx[seq_len(mid)], entries, key_type)
  right <- .oms_merge_sort_indices(idx[(mid + 1L):n], entries, key_type)

  out <- integer(n)
  i <- 1L
  j <- 1L
  k <- 1L
  while(i <= length(left) && j <= length(right)) {
    cmp <- .oms_compare_key(entries[[left[[i]]]]$key, entries[[right[[j]]]]$key, key_type)
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

# Runtime: O(n log n) stable by key and FIFO on ties.
# Sort entries by key while preserving input order across ties.
# Used by: .oms_build_from_items() before tree construction.
.oms_order_entries <- function(entries, key_type) {
  if(length(entries) <= 1L) {
    return(entries)
  }

  idx <- seq_along(entries)
  ord <- if(identical(key_type, "numeric")) {
    order(vapply(entries, function(e) e$key, numeric(1)), idx)
  } else if(identical(key_type, "character")) {
    order(vapply(entries, function(e) e$key, character(1)), idx)
  } else if(identical(key_type, "logical")) {
    order(vapply(entries, function(e) e$key, logical(1)), idx)
  } else {
    keys <- lapply(entries, function(e) e$key)
    ord_try <- tryCatch(order(do.call(c, keys), idx), error = function(e) NULL)
    if(is.null(ord_try) || length(ord_try) != length(entries)) {
      .oms_merge_sort_indices(idx, entries, key_type)
    } else {
      ord_try
    }
  }
  entries[ord]
}

# Runtime: O(n) in entry count.
# Normalize outer names into ft_name entry attrs, then clear list names.
# Used by: .oms_tree_from_ordered_entries() to preserve name indexing contract.
.oms_prepare_entry_names <- function(entries) {
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

# Runtime: O(n log n) for sorting + O(n) bulk build.
# Main constructor pipeline: validate lengths, normalize keys/type, build
# canonical entries, stable-sort, merge required monoids, and wrap class state.
# Used by: as_ordered_sequence() and ordered_sequence().
.oms_build_from_items <- function(items, keys = NULL, monoids = NULL) {
  n <- length(items)

  if(n == 0L) {
    if(!is.null(keys) && length(as.list(keys)) > 0L) {
      stop("`keys` must be empty when no elements are supplied.")
    }
    base <- .as_flexseq_build(list(), monoids = .oms_merge_monoids(monoids))
    return(.as_ordered_sequence(base, key_type = NULL))
  }

  if(is.null(keys)) {
    stop("`keys` is required when elements are supplied.")
  }
  key_list <- as.list(keys)
  if(length(key_list) != n) {
    stop("`keys` length must match elements length.")
  }

  entries <- vector("list", n)
  item_names <- names(items)
  key_type <- NULL
  for(i in seq_len(n)) {
    norm <- .oms_normalize_key(key_list[[i]])
    key_type <- .oms_validate_key_type(key_type, norm$key_type)
    entries[[i]] <- .oms_make_entry(items[[i]], norm$key)
  }
  if(!is.null(item_names) && length(item_names) == n) {
    names(entries) <- item_names
  }

  entries <- .oms_order_entries(entries, key_type)

  merged_monoids <- .oms_merge_monoids(monoids)
  base <- .oms_tree_from_ordered_entries(entries, merged_monoids)
  .as_ordered_sequence(base, key_type = key_type)
}

# Runtime: O(n) for ordered entries.
# Build a measured tree from already key-ordered entries (C++ fast path when
# available, otherwise linear R reference path).
# Used by: .oms_build_from_items() and ordered fapply rebuild path.
.oms_tree_from_ordered_entries <- function(entries, monoids) {
  entries <- .oms_prepare_entry_names(entries)
  if(.ft_cpp_can_use(monoids)) {
    return(.as_flexseq(.ft_cpp_tree_from_sorted(entries, monoids)))
  }
  .ft_tree_from_list_linear(entries, monoids)
}

# Runtime: O(n log n) from build and ordering.
#' Build an Ordered Sequence from `x` and `keys`
#'
#' Constructs an `ordered_sequence` by pairing each element of `x` with the
#' corresponding key in `keys`.
#'
#' @param x Elements to add.
#' @param keys Key values with the same length as `x`.
#' @return An `ordered_sequence`.
#' @details
#' Output is always sorted by key.
#'
#' Duplicate keys are allowed; ties preserve input order (stable/FIFO within the
#' same key).
#'
#' Names on `x` are preserved as element names.
#' @examples
#' xs <- as_ordered_sequence(c("d", "a", "b", "a2"), keys = c(4, 1, 2, 1))
#' xs
#' length(elements_between(xs, 1, 1))
#'
#' n <- as_ordered_sequence(setNames(as.list(c("a", "b")), c("ka", "kb")), keys = c(2, 1))
#' n[["kb"]]
#'
#' # Keys can be other comparable types
#' num_by_chr <- as_ordered_sequence(c(20, 10, 30), keys = c("b", "a", "c"))
#' num_by_chr
#' @export
# Public cast/build entry for list/vector-like inputs.
# Used by: users and tests; delegates to .oms_build_from_items().
as_ordered_sequence <- function(x, keys) {
  .oms_build_from_items(as.list(x), keys = keys, monoids = NULL)
}

# Runtime: O(n log n) from build and ordering.
#' Construct an Ordered Sequence
#'
#' Convenience constructor from `...` and matching `keys`.
#'
#' @param ... Elements to add.
#' @param keys Key values with the same length as `...`.
#' @return An `ordered_sequence`.
#' @details
#' Empty construction is supported: `ordered_sequence()` returns an empty
#' ordered sequence.
#'
#' Output is always sorted by key, with stable order across duplicate keys.
#' @examples
#' xs <- ordered_sequence("bb", "a", "ccc", keys = c(2, 1, 3))
#' xs
#' lower_bound(xs, 2)
#'
#' num_by_chr <- ordered_sequence(20, 10, 30, keys = c("b", "a", "c"))
#' num_by_chr
#'
#' ordered_sequence()
#' @export
# Variadic convenience constructor; delegates to .oms_build_from_items().
ordered_sequence <- function(..., keys) {
  if(missing(keys)) {
    keys <- NULL
  }
  .oms_build_from_items(list(...), keys = keys, monoids = NULL)
}
