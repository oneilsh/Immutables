#SO

# Runtime: O(1).
.ft_cpp_enabled <- function() {
  isTRUE(getOption("immutables.use_cpp", TRUE))
}

# Runtime: O(1).
.ft_cpp_eligible_monoids <- function(monoids) {
  if(is.null(monoids) || !is.list(monoids) || is.null(names(monoids))) {
    return(FALSE)
  }
  TRUE
}

# Runtime: O(1).
.ft_cpp_can_use <- function(monoids) {
  .ft_cpp_enabled() && .ft_cpp_eligible_monoids(monoids)
}

# Runtime: O(1).
.ft_cpp_can_use_oms_insert <- function(monoids, key_type) {
  .ft_cpp_can_use(monoids) && .oms_is_cpp_key_type(key_type)
}

# Runtime: O(log n) near right edge.
.ft_cpp_add_right <- function(t, el, monoids) {
  .Call("ft_cpp_append_right", t, el, monoids, PACKAGE = "Immutables")
}

# Runtime: O(log n) near right edge.
.ft_cpp_add_right_named <- function(t, el, name, monoids) {
  .Call("ft_cpp_append_right_named", t, el, name, monoids, PACKAGE = "Immutables")
}

# Runtime: O(log n) near left edge.
.ft_cpp_add_left <- function(t, el, monoids) {
  .Call("ft_cpp_prepend_left", t, el, monoids, PACKAGE = "Immutables")
}

# Runtime: O(log n) near left edge.
.ft_cpp_add_left_named <- function(t, el, name, monoids) {
  .Call("ft_cpp_prepend_left_named", t, el, name, monoids, PACKAGE = "Immutables")
}

# Runtime: O(n), n = number of elements.
.ft_cpp_tree_from <- function(elements, monoids) {
  .Call("ft_cpp_tree_from", elements, monoids, PACKAGE = "Immutables")
}

# Runtime: O(n), n = number of elements.
.ft_cpp_tree_from_prepared <- function(elements, names, monoids) {
  .Call("ft_cpp_tree_from_prepared", elements, names, monoids, PACKAGE = "Immutables")
}

# Runtime: O(n) over ordered element count.
.ft_cpp_tree_from_sorted <- function(elements, monoids) {
  .Call("ft_cpp_tree_from_sorted", elements, monoids, PACKAGE = "Immutables")
}

# Runtime: O(log n1 + log n2) in the depths/sizes of both input trees.
.ft_cpp_concat <- function(x, y, monoids) {
  .Call("ft_cpp_concat", x, y, monoids, PACKAGE = "Immutables")
}

# Runtime: O(log n) near insertion point depth.
.ft_cpp_oms_insert <- function(x, entry, monoids, key_type) {
  .Call("ft_cpp_oms_insert", x, entry, monoids, key_type, PACKAGE = "Immutables")
}

# Runtime: O(c_pred log n), where c_pred is the cost of one predicate call.
# Structural traversal visits O(log n) nodes; predicate work is per visited node,
.ft_cpp_locate <- function(t, predicate, monoids, monoid_name, accumulator) {
  .Call("ft_cpp_locate", t, predicate, monoids, monoid_name, accumulator, PACKAGE = "Immutables")
}

# Runtime: O(log n * c_pred), where c_pred is the cost of one predicate call.
# As with locate, O(log n) traversal steps each may invoke predicate evaluation.
.ft_cpp_split_tree <- function(t, predicate, monoids, monoid_name, accumulator) {
  .Call("ft_cpp_split_tree", t, predicate, monoids, monoid_name, accumulator, PACKAGE = "Immutables")
}

# Runtime: O(log n). Callback-free index-based split; no R<->C++ predicate overhead.
# idx is a 1-based integer position.
.ft_cpp_split_at_index <- function(t, idx, monoids) {
  .Call("ft_cpp_split_at_index", t, as.integer(idx), monoids, PACKAGE = "Immutables")
}

# Runtime: O(n) worst-case, O(k) until first matched name.
.ft_cpp_find_name_position <- function(t, name) {
  .Call("ft_cpp_find_name_position", t, name, PACKAGE = "Immutables")
}

# Runtime: O(log n) near queried index depth.
.ft_cpp_get_by_index <- function(t, idx) {
  .Call("ft_cpp_get_by_index", t, as.integer(idx), PACKAGE = "Immutables")
}

# Runtime: O(k log n), where k = length(idx_vec).
.ft_cpp_get_many_by_index <- function(t, idx_vec) {
  .Call("ft_cpp_get_many_by_index", t, as.integer(idx_vec), PACKAGE = "Immutables")
}

# Runtime: O(n) in tree size.
.ft_cpp_name_positions <- function(t) {
  .Call("ft_cpp_name_positions", t, PACKAGE = "Immutables")
}

# Native compound interval-index query: walks the candidate subtree leaf-by-leaf
# with .ivx_max_end pruning (where applicable), applying one of the four
# interval-relation predicates (point / overlaps / containing / within) at each
# leaf.
#
# Result shapes:
#   - which = "first": list(matched, matched_indices) — matched is len 0 or 1.
#   - which = "all", with_unmatched = FALSE, as_list = TRUE:
#       list(matched, matched_indices, values, starts_l, ends_l) — caller passes
#       starts_l/ends_l through .ivx_simplify_endpoints (one C-level unlist per
#       axis on numeric endpoints).
#   - which = "all", with_unmatched = FALSE, as_list = FALSE:
#       list(matched, matched_indices, matched_tree) — matched_tree is a bare
#       structural tree built natively from the matched entries; caller wraps
#       it via .ivx_wrap_like(x, matched_tree). Requires `monoids`.
#   - with_unmatched = TRUE: list(matched, matched_indices, unmatched_tree
#       [, matched_tree when which = "all"]). Requires `monoids`. `as_list` is
#       ignored on this branch.
#
# - candidate_tree: pre-partitioned candidate subtree
# - relation_kind:  "point" | "overlaps" | "containing" | "within"
# - qlo, qhi:       scalar query endpoints (equal for point queries)
# - bounds_flags:   list(include_start = <lgl>, include_end = <lgl>)
# - endpoint_kind:  1L = integer, 2L = double/numeric
# - which:          "first" or "all"
# - with_unmatched: logical
# - monoids:        required when the C++ side may build a tree (with_unmatched,
#                   or peek/all + !as_list); otherwise may be NULL.
# - as_list:        logical; only meaningful for peek/all (ignored elsewhere).
.ivx_native_query <- function(candidate_tree, relation_kind, qlo, qhi, bounds_flags,
                              endpoint_kind, which, with_unmatched, monoids,
                              as_list = FALSE) {
  .Call("ft_cpp_ivx_native_query",
        candidate_tree, relation_kind, qlo, qhi,
        bounds_flags, as.integer(endpoint_kind), which,
        isTRUE(with_unmatched), monoids, isTRUE(as_list),
        PACKAGE = "Immutables")
}
