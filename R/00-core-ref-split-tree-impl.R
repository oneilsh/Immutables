#SO

# core split implementation following Hinze/Paterson 4.4
#
# split_tree_impl returns a distinguished element with left/right context:
#   list(left = FingerTree, value = element, right = FingerTree)
# It assumes:
# - t is non-empty
# - p(i) is FALSE and p(i <> measure(t)) is TRUE for strict split semantics
# The public wrappers relax these preconditions (matching the paper's split).
# Runtime: O(log n) near split point depth.
if(FALSE) split_tree_impl <- function(p, i, t, monoids, monoid_name) NULL
split_tree_impl(p, i, t, monoids, monoid_name) %::% Function : . : FingerTree : list : character : list
split_tree_impl(p, i, t, monoids, monoid_name) %as% {
  ms <- monoids
  mr <- ms[[monoid_name]]
  if(is.null(mr)) {
    stop(paste0("Unknown measure monoid '", monoid_name, "'."))
  }
  split_tree_impl_fast(p, i, t, ms, mr, monoid_name)
}

# Runtime: O(log n) near split point depth.
split_tree_impl_fast <- function(p, i, t, ms, mr, monoid_name) {
  if(t %isa% Empty) {
    stop("split_tree_impl requires a non-empty tree")
  }

  if(t %isa% Single) {
    return(list(
      left = measured_empty(ms),
      value = .subset2(t, 1),
      right = measured_empty(ms)
    ))
  }

  # Deep(pr, m, sf): test where predicate first flips using cached measures.
  vpr <- mr$f(i, node_measure(.subset2(t,"prefix"), monoid_name))
  vm <- mr$f(vpr, node_measure(.subset2(t,"middle"), monoid_name))

  if(p(vpr)) {
    # split occurs in prefix digit
    s <- split_digit_impl(p, i, .subset2(t,"prefix"), ms, mr, monoid_name)
    # Left context is only the prefix fragment strictly before the hit.
    # `digit_to_tree` handles 0..4 elements and returns the smallest valid tree.
    left_tree <- digit_to_tree(s$left, ms)
    # Right context starts with the suffix of the prefix digit, followed by the
    # original middle and suffix. `deepL` preserves Deep invariants when that
    # rebuilt prefix fragment is empty (borrowing from middle or collapsing).
    right_tree <- deepL(build_digit(s$right, ms), .subset2(t,"middle"), .subset2(t,"suffix"), ms)
    return(list(left = left_tree, value = s$value, right = right_tree))
  }

  if(p(vm)) {
    # split occurs in middle tree, then inside the selected Node2/Node3
    # Stage 1: split middle at node granularity. In a valid Deep shape, middle
    # stores Node2/Node3 blocks (not leaf elements), so `sm$value` is that block.
    sm <- split_tree_impl_fast(p, vpr, .subset2(t,"middle"), ms, mr, monoid_name)
    # Accumulator value immediately before the selected middle node.
    inode <- mr$f(vpr, node_measure(sm$left, monoid_name))
    # Stage 2: split inside the selected node to isolate the leaf element.
    # `as.list(sm$value)` exposes node children as a tiny digit (arity 2 or 3).
    sx <- split_digit_impl(p, inode, as.list(sm$value), ms, mr, monoid_name)
    # Rebuild left and right contexts around the isolated hit. deepR/deepL handle
    # empty-edge cases by borrowing from middle when needed.
    left_tree <- deepR(.subset2(t,"prefix"), sm$left, build_digit(sx$left, ms), ms)
    right_tree <- deepL(build_digit(sx$right, ms), sm$right, .subset2(t,"suffix"), ms)
    return(list(left = left_tree, value = sx$value, right = right_tree))
  }

  # split occurs in suffix digit
  s <- split_digit_impl(p, vm, .subset2(t,"suffix"), ms, mr, monoid_name)
  left_tree <- deepR(.subset2(t,"prefix"), .subset2(t,"middle"), build_digit(s$left, ms), ms)
  right_tree <- digit_to_tree(s$right, ms)
  list(left = left_tree, value = s$value, right = right_tree)
}
