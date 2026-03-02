#SO

#' Indexing for Ordered Sequences
#'
#' Read indexing treats vectors as selectors and returns subsets in key order.
#' Out-of-order selectors are canonicalized with a warning.
#' Replacement indexing is blocked to prevent order-breaking writes.
#'
#' @name sub-.ordered_sequence
#' @param x An `ordered_sequence`.
#' @param i Index input.
#' @param value Replacement value (unsupported).
#' @param ... Unused.
#' @return Read methods return ordered payload values/subsets; replacement forms
#'   always error.
#' @rdname sub-.ordered_sequence
#' @method [ ordered_sequence
#' @export
# Runtime: O(k log n) for reads + O(k log k) selector normalization and rebuild
#          but for name access O(n + k log n) due to how name indexing works
`[.ordered_sequence` <- function(x, i, ...) {
  if(missing(i)) {
    return(x)
  }
  ms <- resolve_tree_monoids(x, required = TRUE)
  n <- as.integer(node_measure(x, ".size"))

  if(is.logical(i)) {
    mask <- .ft_assert_lgl_indices(i, n)
    idx <- .ft_true_positions(mask)
    if(length(idx) == 0L) {
      return(.ord_wrap_like(x, empty_tree(monoids = ms)))
    }
    out <- .ft_prepare_subset_entries(.ft_get_elems_at(x, idx))
    return(.ord_wrap_like(x, tree_from(out, monoids = ms)))
  }

  if(is.character(i)) {
    idx <- .ft_assert_chr_indices(i)
    if(length(idx) == 0L) {
      return(.ord_wrap_like(x, empty_tree(monoids = ms)))
    }
    pos <- .ft_match_name_indices(x, idx, strict_missing = TRUE)
    pos <- .ord_normalize_selector_positions(pos)
    out <- .ft_prepare_subset_entries(.ft_get_elems_at(x, pos))
    return(.ord_wrap_like(x, tree_from(out, monoids = ms)))
  }

  idx <- .ft_assert_int_indices(i, n)
  if(length(idx) == 0L) {
    return(.ord_wrap_like(x, empty_tree(monoids = ms)))
  }
  idx <- .ord_normalize_selector_positions(idx)
  out <- .ft_prepare_subset_entries(.ft_get_elems_at(x, idx))
  .ord_wrap_like(x, tree_from(out, monoids = ms))
}

# Runtime: O(log n) by index, O(n_lookup) by name.
#' @rdname sub-.ordered_sequence
#' @method [[ ordered_sequence
#' @export
`[[.ordered_sequence` <- function(x, i, ...) {
  entry <- `[[.flexseq`(x, i, ...)
  if(!is.list(entry) || !("item" %in% names(entry))) {
    stop("Malformed ordered_sequence entry.")
  }
  entry$item
}

# Runtime: O(1).
#' @rdname sub-.ordered_sequence
#' @method [<- ordered_sequence
#' @export
`[<-.ordered_sequence` <- function(x, i, value) {
  .ft_stop_ordered_like(x, "[<-", "Replacement indexing is not supported for ordered sequences. Consider converting with as_flexseq().")
}

# Runtime: O(1).
#' @rdname sub-.ordered_sequence
#' @method [[<- ordered_sequence
#' @export
`[[<-.ordered_sequence` <- function(x, i, value) {
  .ft_stop_ordered_like(x, "[[<-", "Replacement indexing is not supported. Consider converting with as_flexseq().")
}


# Runtime: O(n_lookup) via strict single-name lookup.
#' @rdname sub-.ordered_sequence
#' @method $ ordered_sequence
#' @param name Element name (for `$` and `$<-`).
#' @export
`$.ordered_sequence` <- function(x, name) {
  nm <- .ft_dollar_name(substitute(name))
  `[[.ordered_sequence`(x, nm)
}

# Runtime: O(1).
#' @rdname sub-.ordered_sequence
#' @method $<- ordered_sequence
#' @export
`$<-.ordered_sequence` <- function(x, name, value) {
  .ft_stop_ordered_like(x, "$<-", "Replacement indexing is not supported. Consider converting with as_flexseq().")
}
