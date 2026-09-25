#SO

# helpers for converting between digits/nodes/trees and for deconstructing trees

# attach canonical monoid set to a constructed subtree
# Runtime: O(1).
if(FALSE) with_tree_monoids <- function(t, monoids) NULL
with_tree_monoids(t, monoids) %::% FingerTree : list : FingerTree
with_tree_monoids(t, monoids) %as% {
  attr(t, "monoids") <- monoids
  t
}

# construct a Digit from a list of elements.
# input: xs list of 1..4 elements (raw elements or nodes), measure monoid r.
# output: measured Digit(xs...) with preserved order.
# note: empty input returns an empty list() sentinel, used by deepL/deepR rebuild logic.
# Runtime: O(k), where k = length(xs) and k <= 4 for in-tree digits.
if(FALSE) build_digit <- function(xs, monoids) NULL
build_digit(xs, monoids) %::% list : list : .
build_digit(xs, monoids) %as% {
  if(length(xs) == 0) {
    return(list())
  }
  do.call(measured_digit, c(unname(xs), list(monoids = monoids)))
}

# build a Deep node from prefix digit, middle tree, and suffix digit.
# input: pr (Digit), m (FingerTree or suspended FTThunk), sf (Digit), measure monoid r.
# output: measured Deep(pr, m, sf).
# Runtime: O(1) with measured children.
if(FALSE) build_deep <- function(pr, m, sf, monoids) NULL
build_deep(pr, m, sf, monoids) %::% Digit : . : Digit : list : Deep
build_deep(pr, m, sf, monoids) %as% with_tree_monoids(measured_deep(pr, m, sf, monoids), monoids)

# convert a small list/digit (size 0..4) into a valid measured FingerTree shape.
# Runtime: O(1), since digit size is bounded (0..4).
if(FALSE) digit_to_tree <- function(d, monoids) NULL
digit_to_tree(d, monoids) %::% list : list : FingerTree
digit_to_tree(d, monoids) %as% {
  n <- length(d)
  if(n == 0) { return(with_tree_monoids(measured_empty(monoids), monoids)) }
  if(n == 1) { return(with_tree_monoids(measured_single(d[[1]], monoids), monoids)) }
  if(n == 2) {
    pr <- build_digit(list(d[[1]]), monoids)
    sf <- build_digit(list(d[[2]]), monoids)
    return(build_deep(pr, measured_empty(monoids), sf, monoids))
  }
  if(n == 3) {
    pr <- build_digit(list(d[[1]], d[[2]]), monoids)
    sf <- build_digit(list(d[[3]]), monoids)
    return(build_deep(pr, measured_empty(monoids), sf, monoids))
  }
  if(n == 4) {
    pr <- build_digit(list(d[[1]], d[[2]]), monoids)
    sf <- build_digit(list(d[[3]], d[[4]]), monoids)
    return(build_deep(pr, measured_empty(monoids), sf, monoids))
  }
  stop("digit_to_tree expects a digit of size 0..4")
}

# convert a Node2/Node3 into a measured Digit of its children.
# Runtime: O(1), since Node arity is bounded (2..3).
if(FALSE) node_to_digit <- function(node, monoids) NULL
node_to_digit(node, monoids) %::% Node : list : Digit
node_to_digit(node, monoids) %as% build_digit(as.list(node), monoids)

# viewL: return leftmost element and the remaining tree
# input: t non-empty FingerTree, measure monoid r.
# output: list(value = leftmost element of t, rest = t without that element).
# Runtime: O(1) amortized, including under persistent reuse of t, since any
# recursion into the middle tree is suspended; O(log n) worst-case.
if(FALSE) viewL <- function(t, monoids) NULL
viewL(t, monoids) %::% FingerTree : list : list
viewL(t, monoids) %as% {
  if(t %isa% Empty) {
    stop("viewL on Empty")
  }
  if(t %isa% Single) {
    return(list(value = .subset2(t, 1), rest = .as_flexseq(with_tree_monoids(measured_empty(monoids), monoids))))
  }
  pr <- .subset2(t,"prefix")
  if(length(pr) > 1) {
    # Fast path: prefix still has elements after popping its head, so no middle
    # rebalancing is needed.
    head <- pr[[1]]
    tail <- pr[2:length(pr)]
    new_pr <- build_digit(tail, monoids)
    return(list(value = head, rest = .as_flexseq(build_deep(new_pr, .subset2(t,"middle"), .subset2(t,"suffix"), monoids))))
  }
  head <- pr[[1]]
  m <- .ft_middle(t)
  if(m %isa% Empty) {
    # Prefix had exactly one element and middle is empty: remaining content is
    # entirely in suffix, so collapse to a minimal tree from that digit.
    return(list(value = head, rest = .as_flexseq(digit_to_tree(.subset2(t,"suffix"), monoids))))
  }
  # Prefix had one element but middle is non-empty: pull the leftmost node from
  # middle, expand it to a digit, and use that as the new prefix.
  list(value = head, rest = rot_left(m, .subset2(t,"suffix"), monoids))
}

# viewR: return rightmost element and the remaining tree
# input: t non-empty FingerTree, measure monoid r.
# output: list(value = rightmost element of t, rest = t without that element).
# Runtime: O(1) amortized (see viewL); O(log n) worst-case.
if(FALSE) viewR <- function(t, monoids) NULL
viewR(t, monoids) %::% FingerTree : list : list
viewR(t, monoids) %as% {
  if(t %isa% Empty) {
    stop("viewR on Empty")
  }
  if(t %isa% Single) {
    return(list(value = .subset2(t, 1), rest = .as_flexseq(with_tree_monoids(measured_empty(monoids), monoids))))
  }
  sf <- .subset2(t,"suffix")
  if(length(sf) > 1) {
    head <- sf[[length(sf)]]
    tail <- sf[1:(length(sf) - 1)]
    new_sf <- build_digit(tail, monoids)
    return(list(value = head, rest = .as_flexseq(build_deep(.subset2(t,"prefix"), .subset2(t,"middle"), new_sf, monoids))))
  }
  head <- sf[[1]]
  m <- .ft_middle(t)
  if(m %isa% Empty) {
    return(list(value = head, rest = .as_flexseq(digit_to_tree(.subset2(t,"prefix"), monoids))))
  }
  list(value = head, rest = rot_right(.subset2(t,"prefix"), m, monoids))
}

# rot_left: rebuild a Deep whose prefix just emptied, from its non-empty middle
# m and suffix sf: the leftmost node of m becomes the new prefix. Removing that
# node from m is suspended when it would recurse (m's own prefix has one node),
# which keeps viewL amortized O(1) under persistence (Hinze & Paterson's rotL).
# input: m non-empty forced FingerTree of nodes, sf suffix digit, monoids.
# Runtime: O(1).
if(FALSE) rot_left <- function(m, sf, monoids) NULL
rot_left(m, sf, monoids) %::% FingerTree : . : list : FingerTree
rot_left(m, sf, monoids) %as% {
  if(m %isa% Single) {
    new_pr <- node_to_digit(.subset2(m, 1), monoids)
    return(.as_flexseq(build_deep(new_pr, with_tree_monoids(measured_empty(monoids), monoids), sf, monoids)))
  }
  mpr <- .subset2(m, "prefix")
  new_pr <- node_to_digit(mpr[[1]], monoids)
  m_rest <- if(length(mpr) > 1) {
    viewL(m, monoids)$rest
  } else {
    .ft_make_thunk(.FT_THUNK_TAIL_LEFT, m, NULL,
                   list(.subset2(m, "middle"), .subset2(m, "suffix")), monoids)
  }
  .as_flexseq(build_deep(new_pr, m_rest, sf, monoids))
}

# rot_right: mirror of rot_left for a Deep whose suffix just emptied.
# Runtime: O(1).
if(FALSE) rot_right <- function(pr, m, monoids) NULL
rot_right(pr, m, monoids) %::% . : FingerTree : list : FingerTree
rot_right(pr, m, monoids) %as% {
  if(m %isa% Single) {
    new_sf <- node_to_digit(.subset2(m, 1), monoids)
    return(.as_flexseq(build_deep(pr, with_tree_monoids(measured_empty(monoids), monoids), new_sf, monoids)))
  }
  msf <- .subset2(m, "suffix")
  new_sf <- node_to_digit(msf[[length(msf)]], monoids)
  m_rest <- if(length(msf) > 1) {
    viewR(m, monoids)$rest
  } else {
    .ft_make_thunk(.FT_THUNK_INIT_RIGHT, m, NULL,
                   list(.subset2(m, "prefix"), .subset2(m, "middle")), monoids)
  }
  .as_flexseq(build_deep(pr, m_rest, new_sf, monoids))
}

# deepL: rebuild Deep, possibly pulling from middle if prefix is empty
# input: pr digit/list for prefix, m middle FingerTree of nodes (possibly
# suspended), sf suffix digit/list.
# output: a valid FingerTree preserving order; if pr is empty it borrows from m or
# collapses to a tree built from sf.
# Runtime: O(1) amortized.
if(FALSE) deepL <- function(pr, m, sf, monoids) NULL
deepL(pr, m, sf, monoids) %::% . : . : . : list : FingerTree
deepL(pr, m, sf, monoids) %as% {
  if(length(pr) > 0) {
    # Normal Deep reconstruction when prefix is non-empty.
    return(.as_flexseq(build_deep(pr, m, sf, monoids)))
  }
  m <- .ft_force(m)
  if(m %isa% Empty) {
    # Cannot build Deep with empty prefix and empty middle; collapse to suffix.
    return(.as_flexseq(digit_to_tree(sf, monoids)))
  }
  # Restore a non-empty prefix by borrowing the leftmost node from middle.
  rot_left(m, sf, monoids)
}

# deepR: rebuild Deep, possibly pulling from middle if suffix is empty
# input: pr prefix digit/list, m middle FingerTree of nodes (possibly
# suspended), sf suffix digit/list.
# output: a valid FingerTree preserving order; if sf is empty it borrows from m or
# collapses to a tree built from pr.
# Runtime: O(1) amortized.
if(FALSE) deepR <- function(pr, m, sf, monoids) NULL
deepR(pr, m, sf, monoids) %::% . : . : . : list : FingerTree
deepR(pr, m, sf, monoids) %as% {
  if(length(sf) > 0) {
    return(.as_flexseq(build_deep(pr, m, sf, monoids)))
  }
  m <- .ft_force(m)
  if(m %isa% Empty) {
    return(.as_flexseq(digit_to_tree(pr, monoids)))
  }
  rot_right(pr, m, monoids)
}
