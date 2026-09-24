#SO

# Reference concat primitive from Hinze/Paterson finger trees:
# concatenate two trees with an explicit bridge list `ts`.
# Runtime: O(k log n) in the general internal-helper sense where k = length(ts)
# and n is receiving-tree size in repeated edge-insert paths. In package use,
# k is effectively bounded by small digit/node bridge sizes, so this is
# effectively O(log n).
if(FALSE) app3 <- function(e, ts, xs, monoids) NULL
app3(e, ts, xs, monoids) %::% Empty : list : FingerTree : list : FingerTree
app3(e, ts, xs, monoids) %as% add_all_left(xs, ts, monoids)

# Runtime: O(k log n) in the general internal-helper sense where k = length(ts)
# and n is receiving-tree size in repeated edge-insert paths. In package use,
# k is effectively bounded by small digit/node bridge sizes, so this is
# effectively O(log n).
app3(xs, ts, e, monoids) %::% FingerTree : list : Empty : list : FingerTree
app3(xs, ts, e, monoids) %as% add_all_right(xs, ts, monoids)

# Runtime: O(k log n) in the general internal-helper sense where k = length(ts)
# and n is receiving-tree size in repeated edge-insert paths. In package use,
# k is effectively bounded by small digit/node bridge sizes, so this is
# effectively O(log n).
app3(x, ts, xs, monoids) %::% Single : list : FingerTree : list : FingerTree
app3(x, ts, xs, monoids) %as% {
  add_left(add_all_left(xs, ts, monoids), .subset2(x, 1), monoids)
}

# Runtime: O(k log n) in the general internal-helper sense where k = length(ts)
# and n is receiving-tree size in repeated edge-insert paths. In package use,
# k is effectively bounded by small digit/node bridge sizes, so this is
# effectively O(log n).
app3(xs, ts, x, monoids) %::% FingerTree : list : Single : list : FingerTree
app3(xs, ts, x, monoids) %as% {
  add_right(add_all_right(xs, ts, monoids), .subset2(x, 1), monoids)
}

# Runtime: O(log n + k) in balanced usage, where k = length(ts), with recursion
# depth proportional to concatenation spine depth.
app3(xs, ts, ys, monoids) %::% Deep : list : Deep : list : FingerTree
app3(xs, ts, ys, monoids) %as% {
  mid_ts <- measured_nodes(
    c(as.list(.subset2(xs, "suffix")), ts, as.list(.subset2(ys, "prefix"))),
    monoids
  )
  measured_deep(
    .subset2(xs, "prefix"),
    app3(.ft_middle(xs), mid_ts, .ft_middle(ys), monoids),
    .subset2(ys, "suffix"),
    monoids
  )
}

# Runtime: O(log(min(nx, ny))) for balanced trees in normal package use
# (bounded bridge width); more generally follows app3's k-sensitive behavior.
if(FALSE) concat <- function(xs, ys, monoids) NULL
concat(xs, ys, monoids) %::% FingerTree : FingerTree : list : FingerTree
concat(xs, ys, monoids) %as% {
  app3(xs, list(), ys, monoids)
}

# Convert bridge elements into Node2/Node3 only (never Node1), matching the
# reference finger-tree middle-layer shape invariant.
# Runtime: O(k), where k = length(l).
if(FALSE) measured_nodes <- function(l, monoids) NULL
measured_nodes(l, monoids) %::% list : list : list
measured_nodes(l, monoids) %as% {
  if(length(l) < 2L) {
    stop("measured_nodes requires at least two elements.")
  }
  if(length(l) == 2) { return(list(
    measured_node2( l[[1]], l[[2]], monoids )
  ))}
  if(length(l) == 3) { return(list(
    measured_node3( l[[1]], l[[2]], l[[3]], monoids )
  ))}
  if(length(l) == 4) { return(list(
    measured_node2( l[[1]], l[[2]], monoids ),
    measured_node2( l[[3]], l[[4]], monoids )
  ))}

  first = measured_node3( l[[1]], l[[2]], l[[3]], monoids )
  rest = measured_nodes(l[4:length(l)], monoids)
  rest = c(list(first), rest)
  return(rest)
}
