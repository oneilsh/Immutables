#SO

#' Indexing for Interval Indexes
#'
#' Read indexing returns `interval_index` subsets while preserving interval/key
#' order; out-of-order selectors are canonicalized with a warning. Replacement
#' indexing is blocked.
#'
#' @name sub-.interval_index
#' @param x An `interval_index`.
#' @param i Index input.
#' @param value Replacement value (unsupported).
#' @param ... Unused.
#' @return Read methods return interval payload values/subsets; replacement forms
#'   always error.
#' @details
#' Read indexing preserves canonical interval order in returned subsets.
#'
#' - Integer/character vectors are treated as selectors and canonicalized to
#'   interval-order output.
#' - Out-of-order selector vectors trigger a warning and are canonicalized.
#' - Duplicate selectors are rejected.
#' - `[[` and `$` return payload values.
#' - Replacement indexing (`[<-`, `[[<-`, `$<-`) is unsupported.
#' @examples
#' ix <- interval_index(a = "A", b = "B", c = "C", start = c(1, 3, 5), end = c(2, 4, 6))
#'
#' ix[c(3, 1)]         # warning; result returned in interval order
#' ix[c("c", "a")]     # warning; result returned in interval order
#' ix[c(TRUE, FALSE, TRUE)]
#' ix[["b"]]
#' ix$b
#'
#' try(ix[c(2, 2)])
#' try(ix$b <- "updated")
NULL

# Runtime: O(k log n) for reads + O(k log k) selector normalization.
# Subset method preserving interval-index wrapper semantics.
# **Inputs:** `x` interval_index; `i` integer/logical/character index.
# **Outputs:** interval_index subset (empty-like when no positions selected).
# **Used by:** user indexing and internal position-based slicing.
#' @rdname sub-.interval_index
#' @method [ interval_index
#' @export
`[.interval_index` <- function(x, i, ...) {
  if(missing(i)) {
    return(x)
  }
  .ivx_assert_index(x)

  ms <- resolve_tree_monoids(x, required = TRUE)
  n <- as.integer(node_measure(x, ".size"))

  if(is.logical(i)) {
    mask <- .ft_assert_lgl_indices(i, n)
    idx <- .ft_true_positions(mask)
    if(length(idx) == 0L) {
      return(.ivx_wrap_like(x, empty_tree(monoids = ms)))
    }
    out <- .ft_prepare_subset_entries(.ft_get_elems_at(x, idx))
    return(.ivx_wrap_like(x, tree_from(out, monoids = ms)))
  }

  if(is.character(i)) {
    idx <- .ft_assert_chr_indices(i)
    if(length(idx) == 0L) {
      return(.ivx_wrap_like(x, empty_tree(monoids = ms)))
    }
    pos <- .ft_match_name_indices(x, idx, strict_missing = TRUE)
    pos <- .ord_normalize_selector_positions(pos)
    out <- .ft_prepare_subset_entries(.ft_get_elems_at(x, pos))
    return(.ivx_wrap_like(x, tree_from(out, monoids = ms)))
  }

  idx <- .ft_assert_int_indices(i, n)
  if(length(idx) == 0L) {
    return(.ivx_wrap_like(x, empty_tree(monoids = ms)))
  }
  idx <- .ord_normalize_selector_positions(idx)
  out <- .ft_prepare_subset_entries(.ft_get_elems_at(x, idx))
  .ivx_wrap_like(x, tree_from(out, monoids = ms))
}

# Runtime: O(log n) by index, O(n_lookup) by name.
# Scalar extract method returning payload value (not full entry record).
# **Inputs:** `x` interval_index; scalar index/name `i`.
# **Outputs:** payload value.
# **Used by:** `$.interval_index()`, users.
#' @rdname sub-.interval_index
#' @method [[ interval_index
#' @export
`[[.interval_index` <- function(x, i, ...) {
  .ivx_assert_index(x)
  entry <- `[[.flexseq`(x, i, ...)
  if(!is.list(entry) || !("value" %in% names(entry))) {
    stop("Malformed interval_index entry.")
  }
  entry$value
}

# Runtime: O(1).
# Replacement subset is intentionally blocked for ordered interval semantics.
# **Inputs:** `x` interval_index; `i`; `value`.
# **Outputs:** none (always errors).
# **Used by:** users.
#' @rdname sub-.interval_index
#' @method [<- interval_index
#' @export
`[<-.interval_index` <- function(x, i, value) {
  stop("`[<-` is not supported for interval_index.")
}

# Runtime: O(1).
# Replacement scalar extract is intentionally blocked.
# **Inputs:** `x` interval_index; `i`; `value`.
# **Outputs:** none (always errors).
# **Used by:** users.
#' @rdname sub-.interval_index
#' @method [[<- interval_index
#' @export
`[[<-.interval_index` <- function(x, i, value) {
  stop("`[[<-` is not supported for interval_index.")
}

# Name-based scalar read forwarding to `[[.interval_index`.
# **Inputs:** `x` interval_index; symbol/character `name`.
# **Outputs:** payload value.
# **Used by:** users.
#' @rdname sub-.interval_index
#' @method $ interval_index
#' @param name Element name (for `$` and `$<-`).
#' @return For `$`: the matched payload element.
#' @export
`$.interval_index` <- function(x, name) {
  nm <- .ft_dollar_name(substitute(name))
  `[[.interval_index`(x, nm)
}

# Name-based replacement is intentionally blocked.
# **Inputs:** `x` interval_index; `name`; `value`.
# **Outputs:** none (always errors).
# **Used by:** users.
#' @rdname sub-.interval_index
#' @method $<- interval_index
#' @param value Replacement value (unsupported).
#' @return No return value; always errors because replacement indexing is unsupported.
#' @export
`$<-.interval_index` <- function(x, name, value) {
  stop("`$<-` is not supported for interval_index.")
}
