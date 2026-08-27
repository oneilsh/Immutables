#SO
# .size and .named_count are priveledged and ensured for all trees.
#
# These resolvers are pervasive in tree hot paths (called several times per
# query); the canonical Haskell-style signatures are preserved as comments,
# with plain R bodies to avoid lambda.r dispatcher overhead in production.

# Reference (Haskell-style, lambda.r):
#   resolve_tree_monoids(t, required = FALSE) :: . -> logical -> .
# Runtime: O(1) fast-path (single attr read).
resolve_tree_monoids <- function(t, required = FALSE) {
  ms <- attr(t, "monoids", exact = TRUE)
  if(isTRUE(required) && is.null(ms)) {
    stop("Tree has no monoids attribute.")
  }
  ms  # NULL or named list
}

# Reference:
#   resolve_named_monoid(t, monoid_name) :: . -> character -> list
# Runtime: O(1) expected (attribute read + named list lookup).
resolve_named_monoid <- function(t, monoid_name) {
  if(!is.character(monoid_name) || length(monoid_name) != 1L ||
     is.na(monoid_name) || monoid_name == "") {
    stop("`monoid_name` must be a single non-empty string.")
  }
  ms <- resolve_tree_monoids(t, required = TRUE)
  mr <- ms[[monoid_name]]
  if(is.null(mr)) {
    stop(paste0("Monoid name `", monoid_name, "` not found in tree monoids."))
  }
  list(monoids = ms, monoid = mr)
}

# Reference:
#   merge_monoid_sets(base, add, overwrite = FALSE) :: list -> list -> logical -> list
# Runtime: O(1) under fixed monoid set.
merge_monoid_sets <- function(base, add, overwrite = FALSE) {
  b <- base
  a <- add

  overlap <- intersect(names(b), names(a))
  overlap <- setdiff(overlap, c(".size", ".named_count"))
  if(length(overlap) > 0L && !isTRUE(overwrite)) {
    stop("Monoid names already exist: ", paste(overlap, collapse = ", "),
         ". Use overwrite = TRUE to replace.")
  }

  if(length(overlap) > 0L && isTRUE(overwrite)) {
    for(nm in overlap) {
      b[[nm]] <- a[[nm]]
    }
  }

  add_only <- setdiff(names(a), names(b))
  if(length(add_only) > 0L) {
    b <- c(b, a[add_only])
  }
  b
}
