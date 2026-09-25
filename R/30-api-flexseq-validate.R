#SO

#' Validate Full Tree Invariants (Debug/Test Utility)
#'
#' Performs expensive full-tree auditing of:
#' - structural attributes (`monoids`/`measures`) consistency
#' - global name-state invariants
#'
#' Intended for debugging and tests, not hot runtime paths.
#'
#' @param t FingerTree.
#' @return `TRUE` invisibly; errors if invariant violations are found.
#' @examples
#' x <- as_flexseq(letters[1:10])
#' validate_tree(x)
#' @export
# Runtime: O(n) full traversal. Intended for debugging/tests.
validate_tree <- function(t) {
  assert_structural_attrs(t)
  .ft_assert_name_state(t)
  invisible(TRUE)
}

#' Validate Name-State Invariants (Debug/Test Utility)
#'
#' Checks that trees are either fully unnamed or fully named with unique,
#' non-empty names.
#'
#' Intended for debugging and tests, not hot runtime paths.
#'
#' @param t FingerTree.
#' @return `TRUE` invisibly; errors if name invariants are violated.
#' @examples
#' x <- as_flexseq(setNames(as.list(letters[1:4]), letters[1:4]))
#' validate_name_state(x)
#' @export
# Runtime: O(n) when tree is named (name collection and uniqueness checks).
validate_name_state <- function(t) {
  .ft_assert_name_state(t)
  invisible(TRUE)
}
