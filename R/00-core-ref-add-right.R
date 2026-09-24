#SO

# Runtime: O(1).
if(FALSE) add_right <- function(e, el, monoids) NULL
add_right(e, el, monoids) %::% Empty : . : list : Single
add_right(e, el, monoids) %as% {
  measured_single(el, monoids)
}

# Runtime: O(1).
add_right(s, el, monoids) %::% Single : . : list : Deep
add_right(s, el, monoids) %as% {
  measured_deep(
    measured_digit(.subset2(s, 1), monoids = monoids),
    measured_empty(monoids),
    measured_digit(el, monoids = monoids),
    monoids
  )
}

# Runtime: O(k), where k is digit length (bounded by 4 in-tree).
add_right(d, el, monoids) %::% Digit : . : list : Digit
add_right(d, el, monoids) %as% {
  oldclasses <- class(d)
  newd <- c(d, list(el))
  class(newd) <- oldclasses
  set_measure(newd, monoids)
}

# symmetric to add_left. Only new nodes get measures.
# Runtime: O(log n) worst-case.
add_right(d, el, monoids) %::% Deep : . : list : Deep
add_right(d, el, monoids) %as% {
  if(length(.subset2(d, "suffix")) == 4) {
    new_suffix <- measured_digit(.subset2(d, "suffix")[[4]], el, monoids = monoids)
    new_middle_node <- measured_node3(.subset2(d, "suffix")[[1]], .subset2(d, "suffix")[[2]], .subset2(d, "suffix")[[3]], monoids)
    new_middle <- add_right(.ft_middle(d), new_middle_node, monoids)
    measured_deep(prefix = .subset2(d, "prefix"), middle = new_middle, suffix = new_suffix, monoids)
  } else {
    new_suffix <- add_right(.subset2(d, "suffix"), el, monoids)
    measured_deep(prefix = .subset2(d, "prefix"), middle = .subset2(d, "middle"), suffix = new_suffix, monoids)
  }
}

# Runtime: O(k log n), where k = length(els).
if(FALSE) add_all_right <- function(t, els, monoids) NULL
add_all_right(t, els, monoids) %::% FingerTree : . : list : FingerTree
add_all_right(t, els, monoids) %as% {
  for(el in els) {
    t <- add_right(t, el, monoids)
  }
  return(t)
}
