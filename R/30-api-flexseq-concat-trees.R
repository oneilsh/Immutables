#SO

#' Concatenate Two Structural Trees
#'
#' Same-name monoids are assumed equivalent; left-tree definitions win.
#' Missing monoids are added to each side before concatenation.
#'
#' @param x A `flexseq` (left side).
#' @param y A `flexseq` (right side).
#' @return Concatenated tree.
#' @keywords internal
# Runtime: O(nx + ny) when monoid harmonization requires add_monoids passes;
# otherwise concat spine work is near-logarithmic in boundary distance for the
# smaller, O(log(min(nx, ny)))
concat_trees <- function(x, y) {
  mx <- resolve_tree_monoids(x, required = TRUE)
  my <- resolve_tree_monoids(y, required = TRUE)

  shared <- intersect(names(mx), names(my))
  shared <- setdiff(shared, c(".size", ".named_count"))

  left_only <- setdiff(names(mx), names(my))
  left_only <- setdiff(left_only, c(".size", ".named_count"))
  right_only <- setdiff(names(my), names(mx))
  right_only <- setdiff(right_only, c(".size", ".named_count"))

  x2 <- if(length(right_only) > 0) add_monoids(x, my[right_only], overwrite = FALSE) else x
  y2 <- if(length(left_only) > 0) add_monoids(y, mx[left_only], overwrite = FALSE) else y

  merged <- c(mx, my[setdiff(names(my), names(mx))])

  if(.ft_cpp_can_use(merged)) {
    return(.as_flexseq(.ft_cpp_concat(x2, y2, merged)))
  }

  .as_flexseq(concat(x2, y2, merged))
}

# Internal: concat two trees that already share identical monoids.
# Skips monoid harmonization. Uses C++ fast path when available.
# Runtime: O(log(min(n1, n2))) via C++; R fallback is slower.
.ft_concat_same_monoids <- function(x, y, monoids) {
  if(.ft_cpp_can_use(monoids)) {
    return(.ft_cpp_concat(x, y, monoids))
  }
  concat(x, y, monoids)
}
