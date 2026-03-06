#SO
# checks for ensuring measures and monoids are present, consistent, and cached
# also constructors for building fingertree components with measures and monoids attached

# check for MeasureMonoid type
# Runtime: O(1).
if(FALSE) is_measure_monoid <- function(r) NULL
is_measure_monoid(r) %::% . : logical
is_measure_monoid(r) %as% inherits(r, "MeasureMonoid")

# a non-empty named list of MeasureMonoid specs
# Runtime: O(k), where k = length(x).
if(FALSE) is_measure_monoid_list <- function(x) NULL
is_measure_monoid_list(x) %::% . : logical
is_measure_monoid_list(x) %as% {
  is.list(x) && length(x) > 0 && all(vapply(x, is_measure_monoid, logical(1)))
}

# normalize monoid fields to canonical named layout (f, i, measure).
# Runtime: O(1).
if(FALSE) .normalize_measure_monoid_spec <- function(r, monoid_name = NULL) NULL
.normalize_measure_monoid_spec(r, monoid_name = NULL) %::% MeasureMonoid : . : MeasureMonoid
.normalize_measure_monoid_spec(r, monoid_name = NULL) %as% {
  lbl <- if(is.null(monoid_name) || is.na(monoid_name) || monoid_name == "") {
    "measure monoid"
  } else {
    paste0("measure monoid `", monoid_name, "`")
  }

  nms <- names(r)
  read_field <- function(key, idx) {
    if(!is.null(nms) && key %in% nms) {
      return(r[[key]])
    }
    if(length(r) >= idx) {
      return(r[[idx]])
    }
    stop(lbl, " must provide fields `f`, `i`, and `measure`.")
  }

  f <- read_field("f", 1L)
  i <- read_field("i", 2L)
  measure <- read_field("measure", 3L)

  if(!is.function(f)) {
    stop(lbl, " field `f` must be a function.")
  }
  if(!is.function(measure)) {
    stop(lbl, " field `measure` must be a function.")
  }

  out <- list(f = f, i = i, measure = measure)
  class(out) <- class(r)
  out
}

# default size measure used for indexing and structural operations
# Runtime: O(1).
if(FALSE) size_measure_monoid <- function() NULL
size_measure_monoid() %::% MeasureMonoid
size_measure_monoid() %as% {
  measure_monoid(function(a, b) a + b, 0, function(el) 1)
}

# default name-count measure used to enforce named/unnamed tree invariants
# Runtime: O(1).
if(FALSE) named_count_measure_monoid <- function() NULL
named_count_measure_monoid() %::% MeasureMonoid
named_count_measure_monoid() %as% {
  measure_monoid(function(a, b) a + b, 0L, function(el) {
    if(isTRUE(.ft_has_name(el))) 1L else 0L
  })
}

# normalize a candidate element name; NULL/NA/"" are treated as missing
# Runtime: O(1).
if(FALSE) .ft_normalize_name <- function(x) NULL
.ft_normalize_name(x) %::% . : .
.ft_normalize_name(x) %as% {
  if(is.null(x) || length(x) == 0L) {
    return(NULL)
  }
  if(length(x) != 1L) {
    stop("Element names must be scalar.")
  }
  nm <- as.character(x)
  if(is.na(nm) || nm == "") {
    return(NULL)
  }
  nm
}

# read the internal element name payload
# Runtime: O(1).
if(FALSE) .ft_get_name <- function(el) NULL
.ft_get_name(el) %::% . : .
.ft_get_name(el) %as% {
  .ft_normalize_name(attr(el, "ft_name", exact = TRUE))
}

# check whether an element carries an internal name
# Runtime: O(1).
if(FALSE) .ft_has_name <- function(el) NULL
.ft_has_name(el) %::% . : logical
.ft_has_name(el) %as% {
  !is.null(.ft_get_name(el))
}

# attach/remove internal element name payload
# Runtime: O(1).
if(FALSE) .ft_set_name <- function(el, name) NULL
.ft_set_name(el, name) %::% . : . : .
.ft_set_name(el, name) %as% {
  nm <- .ft_normalize_name(name)
  if(is.null(nm)) {
    attr(el, "ft_name") <- NULL
    return(el)
  }
  if(is.null(el)) {
    stop("Cannot attach a name to NULL element.")
  }
  attr(el, "ft_name") <- nm
  el
}

# validate and normalize monoid set; `.size` and `.named_count` are always present.
# Runtime: O(1) under fixed monoid set.
if(FALSE) ensure_size_monoids <- function(monoids) NULL
ensure_size_monoids(monoids) %::% list : list
ensure_size_monoids(monoids) %as% {
  out <- monoids
  if(!is_measure_monoid_list(out)) {
    stop("`monoids` must be a non-empty named list of MeasureMonoid objects.")
  }
  if(is.null(names(out))) {
    stop("Monoid lists must be named.")
  }
  if(any(is.na(names(out))) || any(names(out) == "")) {
    stop("Monoid list names must be non-empty and non-missing.")
  }
  if(any(duplicated(names(out)))) {
    stop("Monoid list names must be unique.")
  }

  for(nm in names(out)) {
    out[[nm]] <- .normalize_measure_monoid_spec(out[[nm]], monoid_name = nm)
  }

  # reserved monoids are canonicalized so all trees share the same invariants.
  out[[".size"]] <- size_measure_monoid()
  out[[".named_count"]] <- named_count_measure_monoid()
  out
}

# combine a list of measure values with the monoid's associative function
# Runtime: O(k), where k = length(measures).
if(FALSE) combine_measures <- function(measures, r) NULL
combine_measures(measures, r) %::% list : MeasureMonoid : .
combine_measures(measures, r) %as% {
  acc <- r$i
  for(m in measures) {
    acc <- r$f(acc, m)
  }
  acc
}

# Hot-path recursive measure helper used by measure recomputation.
# Avoids repeated typed-wrapper dispatch in deep recursion.
# Runtime: best-case O(1) on cached structural children; worst-case O(n_subtree).
.measure_child_named_fast <- function(x, name, rr) {
  if(is_structural_node(x)) {
    cached <- attr(x, "measures", exact = TRUE)
    if(!is.null(cached) && !is.null(cached[[name]])) {
      return(cached[[name]])
    }

    if(inherits(x, "Empty")) {
      return(rr$i)
    }

    if(inherits(x, "Single")) {
      return(.measure_child_named_fast(.subset2(x, 1), name, rr))
    }

    if(inherits(x, "Deep")) {
      acc <- rr$i
      acc <- rr$f(acc, .measure_child_named_fast(.subset2(x, "prefix"), name, rr))
      acc <- rr$f(acc, .measure_child_named_fast(.subset2(x, "middle"), name, rr))
      acc <- rr$f(acc, .measure_child_named_fast(.subset2(x, "suffix"), name, rr))
      return(acc)
    }

    # Digit / Node2 / Node3
    acc <- rr$i
    for(el in x) {
      acc <- rr$f(acc, .measure_child_named_fast(el, name, rr))
    }
    return(acc)
  }

  rr$measure(x)
}

# recursive helper assuming `ms` has already been validated
# Runtime: best-case O(1) when cached measure is present on structural children;
# worst-case O(n_subtree) when recursive fallback is required.
if(FALSE) measure_child_named_impl <- function(x, ms, name, rr) NULL
measure_child_named_impl(x, ms, name, rr) %::% . : list : character : MeasureMonoid : .
measure_child_named_impl(x, ms, name, rr) %as% {
  .measure_child_named_fast(x, name, rr)
}

# compute all cached measures for a structural node across all monoids
# Runtime: typical O(m * k), where m = number of monoids and k = immediate child
# count of `x` (bounded for in-tree nodes); worst-case O(m * n_subtree) when
# recursive fallback is required.
if(FALSE) measure_children <- function(x, monoids) NULL
measure_children(x, monoids) %::% . : list : list
measure_children(x, monoids) %as% {
  ms <- monoids
  nms <- names(ms)
  out <- vector("list", length(ms))
  for(i in seq_along(nms)) {
    out[[i]] <- .measure_child_named_fast(x, nms[[i]], ms[[i]])
  }
  names(out) <- nms
  out
}

# read a structural-node measure by monoid name
# Runtime: O(1).
if(FALSE) node_measure <- function(x, monoid_name) NULL
node_measure(x, monoid_name) %::% . : character : .
node_measure(x, monoid_name) %as% {
  if(!is_structural_node(x)) {
    stop("node_measure expects a structural node.")
  }
  ms <- attr(x, "measures", exact = TRUE)
  if(is.null(ms) || is.null(ms[[monoid_name]])) {
    stop(paste0("Missing cached measure '", monoid_name, "' on node."))
  }
  ms[[monoid_name]]
}

# attach canonical monoids + cached measures to a structural node
# Runtime: same as `measure_children()`; typical O(m * k), worst-case
# O(m * n_subtree) under recursive fallback.
if(FALSE) set_measure <- function(x, monoids) NULL
set_measure(x, monoids) %::% . : list : .
set_measure(x, monoids) %as% {
  if(!is_structural_node(x)) {
    return(x)
  }
  ms <- monoids
  attr(x, "monoids") <- ms
  attr(x, "measures") <- measure_children(x, ms)
  x
}

# attach monoids + measures, reusing unchanged cached entries from `previous`.
# only `recompute_names` are recomputed from children.
# Runtime: O(m) to iterate monoid names plus recompute cost for monoids in
# `recompute_names`; recompute is typical O(k) per monoid on measured children
# and worst-case O(n_subtree) per monoid under recursive fallback.
if(FALSE) set_measure_with_reuse <- function(x, previous, monoids, recompute_names) NULL
set_measure_with_reuse(x, previous, monoids, recompute_names) %::% . : . : list : character : .
set_measure_with_reuse(x, previous, monoids, recompute_names) %as% {
  if(!is_structural_node(x)) {
    return(x)
  }

  ms <- monoids
  nms <- names(ms)
  rec <- unique(intersect(recompute_names, nms))
  old <- if(is_structural_node(previous)) attr(previous, "measures", exact = TRUE) else NULL
  has_old <- !is.null(old)
  rec_flags <- rep(FALSE, length(nms))
  names(rec_flags) <- nms
  if(length(rec) > 0L) {
    rec_flags[rec] <- TRUE
  }

  out <- vector("list", length(ms))
  names(out) <- nms
  for(i in seq_along(nms)) {
    nm <- nms[[i]]
    can_reuse <- !rec_flags[[nm]] && has_old && !is.null(old[[nm]])
    if(can_reuse) {
      out[[i]] <- old[[nm]]
    } else {
      out[[i]] <- .measure_child_named_fast(x, nm, ms[[i]])
    }
  }

  attr(x, "monoids") <- ms
  attr(x, "measures") <- out
  x
}

# only used by add_monoids() to add new monoids to the full tree
# persistent structural copy that updates monoid attrs.
# tree shape is preserved; only requested monoid caches are recomputed.
# Runtime: O(n) in subtree size.
if(FALSE) rebind_tree_monoids <- function(x, monoids, recompute_names) NULL
rebind_tree_monoids(x, monoids, recompute_names) %::% . : list : character : .
rebind_tree_monoids(x, monoids, recompute_names) %as% {
  if(!is_structural_node(x)) {
    return(x)
  }

  if(inherits(x, "Empty")) {
    return(set_measure_with_reuse(Empty(), x, monoids, recompute_names))
  }

  if(inherits(x, "Single")) {
    child <- rebind_tree_monoids(.subset2(x, 1), monoids, recompute_names)
    return(set_measure_with_reuse(Single(child), x, monoids, recompute_names))
  }

  if(inherits(x, "Deep")) {
    pr <- rebind_tree_monoids(.subset2(x,"prefix"), monoids, recompute_names)
    m <- rebind_tree_monoids(.subset2(x,"middle"), monoids, recompute_names)
    sf <- rebind_tree_monoids(.subset2(x,"suffix"), monoids, recompute_names)
    return(set_measure_with_reuse(Deep(pr, m, sf), x, monoids, recompute_names))
  }

  # Digit / Node2 / Node3
  out <- lapply(x, rebind_tree_monoids, monoids = monoids, recompute_names = recompute_names)
  class(out) <- class(x)
  set_measure_with_reuse(out, x, monoids, recompute_names)
}

assert_has_monoids(node) %::% . : .
# Runtime: O(1).
if(FALSE) assert_has_monoids <- function(node) NULL
assert_has_monoids(node) %as% {
  if(!is_structural_node(node)) {
    return(invisible(TRUE))
  }
  ms <- attr(node, "monoids", exact = TRUE)
  if(is.null(ms)) {
    stop("Structural node missing `monoids` attribute.")
  }
  if(!is.list(ms) || is.null(names(ms))) {
    stop("Structural node `monoids` must be a named list.")
  }
  if(!all(c(".size", ".named_count") %in% names(ms))) {
    stop("Structural node `monoids` must include reserved monoids `.size` and `.named_count`.")
  }
  invisible(TRUE)
}

assert_measures_match_monoids(node) %::% . : .
# Runtime: O(1) under fixed monoid set.
if(FALSE) assert_measures_match_monoids <- function(node) NULL
assert_measures_match_monoids(node) %as% {
  if(!is_structural_node(node)) {
    return(invisible(TRUE))
  }
  ms <- attr(node, "monoids", exact = TRUE)
  if(is.null(ms)) {
    stop("Structural node missing `monoids` attribute.")
  }
  cached <- attr(node, "measures", exact = TRUE)
  if(is.null(cached)) {
    stop("Structural node missing `measures` attribute.")
  }
  if(is.null(names(cached)) || !setequal(names(cached), names(ms))) {
    stop("Structural node `measures` names must match `monoids` names.")
  }
  invisible(TRUE)
}

assert_structural_attrs(node) %::% . : .
# Runtime: O(n) in subtree size (recursive full walk).
# Intended use: correctness auditing in tests/debugging, not hot paths.
if(FALSE) assert_structural_attrs <- function(node) NULL
assert_structural_attrs(node) %as% {
  if(!is_structural_node(node)) {
    return(invisible(TRUE))
  }

  assert_has_monoids(node)
  assert_measures_match_monoids(node)

  if(node %isa% Single) {
    assert_structural_attrs(.subset2(node, 1))
  } else if(node %isa% Deep) {
    assert_structural_attrs(.subset2(node,"prefix"))
    assert_structural_attrs(.subset2(node,"middle"))
    assert_structural_attrs(.subset2(node,"suffix"))
  } else {
    for(el in node) {
      assert_structural_attrs(el)
    }
  }

  invisible(TRUE)
}

# construct an Empty with cached measures
# Runtime: O(1).
if(FALSE) measured_empty <- function(monoids) NULL
measured_empty(monoids) %::% list : Empty
measured_empty(monoids) %as% {
  e <- Empty()
  set_measure(e, monoids)
}

# construct a Single with cached measures
# Runtime: O(1).
if(FALSE) measured_single <- function(el, monoids) NULL
measured_single(el, monoids) %::% . : list : Single
measured_single(el, monoids) %as% {
  s <- Single(el)
  set_measure(s, monoids)
}

# construct a Digit with cached measures (size 1..4)
# Runtime: O(1).
if(FALSE) measured_digit <- function(a, monoids) NULL
measured_digit(a, monoids) %::% . : list : Digit
measured_digit(a, monoids) %as% {
  d <- Digit(a)
  set_measure(d, monoids)
}

# Runtime: O(1).
measured_digit(a, b, monoids) %::% . : . : list : Digit
measured_digit(a, b, monoids) %as% {
  d <- Digit(a, b)
  set_measure(d, monoids)
}

# Runtime: O(1).
measured_digit(a, b, c, monoids) %::% . : . : . : list : Digit
measured_digit(a, b, c, monoids) %as% {
  d <- Digit(a, b, c)
  set_measure(d, monoids)
}

# Runtime: O(1).
measured_digit(a, b, c, d1, monoids) %::% . : . : . : . : list : Digit
measured_digit(a, b, c, d1, monoids) %as% {
  d <- Digit(a, b, c, d1)
  set_measure(d, monoids)
}

# construct a Node2 with cached measures
# Runtime: O(1).
if(FALSE) measured_node2 <- function(x, y, monoids) NULL
measured_node2(x, y, monoids) %::% . : . : list : Node
measured_node2(x, y, monoids) %as% {
  n <- Node2(x, y)
  set_measure(n, monoids)
}

# construct a Node3 with cached measures
# Runtime: O(1).
if(FALSE) measured_node3 <- function(x, y, z, monoids) NULL
measured_node3(x, y, z, monoids) %::% . : . : . : list : Node
measured_node3(x, y, z, monoids) %as% {
  n <- Node3(x, y, z)
  set_measure(n, monoids)
}

# construct a Deep with cached measures
# Runtime: O(1) with measured children.
if(FALSE) measured_deep <- function(prefix, middle, suffix, monoids) NULL
measured_deep(prefix, middle, suffix, monoids) %::% Digit : FingerTree : Digit : list : Deep
measured_deep(prefix, middle, suffix, monoids) %as% {
  t <- Deep(prefix, middle, suffix)
  set_measure(t, monoids)
}
