#SO

# Runtime: O(1).
if(FALSE) add_left <- function(e, el, monoids) NULL
add_left(e, el, monoids) %::% Empty : . : list : Single
add_left(e, el, monoids) %as% {
  measured_single(el, monoids)
}

# Runtime: O(1).
add_left(s, el, monoids) %::% Single : . : list : Deep
add_left(s, el, monoids) %as% {
  measured_deep(
    measured_digit(el, monoids = monoids),
    measured_empty(monoids),
    measured_digit(.subset2(s, 1), monoids = monoids),
    monoids
  )
}

# this is actually a pain, because we implement digits as lists with various attributes
# we can't just c() the element to the list, as we'd get a list(el, old_list), rather than list(el, old_list[[1]], old_list[[2]]), etc.
# We prepend via c(list(el), d) and then restore class attributes.
# Runtime: O(k), where k is digit length (bounded by 4 in-tree),
# so O(1), *assuming* cached measures are available (which should be the case
# by invariant)
add_left(d, el, monoids) %::% Digit : . : list : Digit
add_left(d, el, monoids) %as% {
  oldclasses <- class(d)
  newd <- c(list(el), d)
  class(newd) <- oldclasses
  set_measure(newd, monoids)
}

# if the prefix has 4 elements [p1, p2, p3, p4]: keep el and p1 as the
# new 2-element prefix, pack p2, p3, p4 into a Node3 pushed into the
# middle tree.
# otherwise: simple add to the prefix digit.
# Runtime: O(log n) worst-case.
add_left(d, el, monoids) %::% Deep : . : list : Deep
add_left(d, el, monoids) %as% {
  if(length(.subset2(d, "prefix")) == 4) {
    new_prefix <- measured_digit(el, .subset2(d, "prefix")[[1]], monoids = monoids)
    new_middle_node <- measured_node3(.subset2(d, "prefix")[[2]], .subset2(d, "prefix")[[3]], .subset2(d, "prefix")[[4]], monoids)
    new_middle <- add_left(.ft_middle(d), new_middle_node, monoids)
    measured_deep(prefix = new_prefix, middle = new_middle, suffix = .subset2(d, "suffix"), monoids)
  } else {
    new_prefix <- add_left(.subset2(d, "prefix"), el, monoids)
    measured_deep(prefix = new_prefix, middle = .subset2(d, "middle"), suffix = .subset2(d, "suffix"), monoids)
  }
}

# Runtime: O(k log n), where k = length(els).
if(FALSE) add_all_left <- function(t, els, monoids) NULL
add_all_left(t, els, monoids) %::% FingerTree : . : list : FingerTree
add_all_left(t, els, monoids) %as% {
  for(el in rev(els)) {
    t <- add_left(t, el, monoids)
  }
  return(t)
}
