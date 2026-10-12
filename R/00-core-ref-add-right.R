#SO

# Reference (clauses tried in this order, dispatching on the first argument):
#   add_right(e, el, monoids) :: Empty  -> . -> list -> Single
#   add_right(s, el, monoids) :: Single -> . -> list -> Deep
#   add_right(d, el, monoids) :: Digit  -> . -> list -> Digit
#   add_right(d, el, monoids) :: Deep   -> . -> list -> Deep
add_right <- function(t, el, monoids) {
  # Empty: Runtime: O(1).
  if(inherits(t, "Empty")) {
    return(measured_single(el, monoids))
  }

  # Single: Runtime: O(1).
  if(inherits(t, "Single")) {
    return(measured_deep(
      measured_digit(.subset2(t, 1), monoids = monoids),
      measured_empty(monoids),
      measured_digit(el, monoids = monoids),
      monoids
    ))
  }

  # Digit: Runtime: O(k), where k is digit length (bounded by 4 in-tree).
  if(inherits(t, "Digit")) {
    oldclasses <- class(t)
    newd <- c(t, list(el))
    class(newd) <- oldclasses
    return(set_measure(newd, monoids))
  }

  # Deep: symmetric to add_left. Only new nodes get measures.
  # Runtime: O(1) amortized; O(log n) worst-case.
  if(inherits(t, "Deep")) {
    if(length(.subset2(t, "suffix")) == 4) {
      new_suffix <- measured_digit(.subset2(t, "suffix")[[4]], el, monoids = monoids)
      new_middle_node <- measured_node3(.subset2(t, "suffix")[[1]], .subset2(t, "suffix")[[2]], .subset2(t, "suffix")[[3]], monoids)
      new_middle <- lazy_add_right(.ft_middle(t), new_middle_node, monoids)
      return(measured_deep(prefix = .subset2(t, "prefix"), middle = new_middle, suffix = new_suffix, monoids))
    }
    new_suffix <- add_right(.subset2(t, "suffix"), el, monoids)
    return(measured_deep(prefix = .subset2(t, "prefix"), middle = .subset2(t, "middle"), suffix = new_suffix, monoids))
  }

  stop("add_right: unsupported node type: ", paste(class(t), collapse = "/"))
}

# symmetric to lazy_add_left.
# Runtime: O(1).
lazy_add_right <- function(m, node, monoids) {
  if(!inherits(m, "Deep") || length(.subset2(m, "suffix")) < 4L) {
    return(add_right(m, node, monoids))
  }
  .ft_make_thunk(.FT_THUNK_ADD_RIGHT, m, node, list(m, node), monoids)
}

# Runtime: O(k log n), where k = length(els).
# Reference:
#   add_all_right(t, els, monoids) :: FingerTree -> . -> list -> FingerTree
add_all_right <- function(t, els, monoids) {
  for(el in els) {
    t <- add_right(t, el, monoids)
  }
  return(t)
}
