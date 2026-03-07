#SO

# read-only locate helpers: no reconstruction, only traversal + metadata.

# Runtime: O(1) with cached measures; may recurse for unannotated structural children.
if(FALSE) locate_child_measure <- function(x, ms, monoid_name, mr) NULL
locate_child_measure(x, ms, monoid_name, mr) %::% . : list : character : MeasureMonoid : .
locate_child_measure(x, ms, monoid_name, mr) %as% {
  if(is_structural_node(x)) {
    cached <- attr(x, "measures", exact = TRUE)
    if(!is.null(cached) && !is.null(cached[[monoid_name]])) {
      return(cached[[monoid_name]])
    }
    return(measure_child_named_impl(x, ms, monoid_name, mr))
  }
  mr$measure(x)
}

# Runtime: O(1).
if(FALSE) locate_child_size <- function(x, ms) NULL
locate_child_size(x, ms) %::% . : list : integer
locate_child_size(x, ms) %as% {
  sr <- ms[[".size"]]
  if(is.null(sr)) {
    return(1L)
  }
  out <- if(is_structural_node(x)) {
    as.integer(node_measure(x, ".size"))
  } else {
    as.integer(sr$measure(x))
  }
  if(is.na(out) || out < 0L) {
    stop(".size monoid must produce non-negative integer sizes.")
  }
  out
}

# Runtime: O(k), where k = length(xs).
if(FALSE) locate_sequence_measure <- function(xs, ms, monoid_name, mr) NULL
locate_sequence_measure(xs, ms, monoid_name, mr) %::% list : list : character : MeasureMonoid : .
locate_sequence_measure(xs, ms, monoid_name, mr) %as% {
  if(length(xs) == 0L) {
    return(mr$i)
  }
  acc <- mr$i
  for(el in xs) {
    acc <- mr$f(acc, locate_child_measure(el, ms, monoid_name, mr))
  }
  acc
}

# Runtime: O(k), where k = digit length (<= 4 in normal tree structure).
if(FALSE) locate_digit <- function(p, i, digit, monoids, monoid_name, i_size = 0L) NULL
locate_digit(p, i, digit, monoids, monoid_name, i_size) %::% Function : . : list : list : character : integer : list
locate_digit(p, i, digit, monoids, monoid_name, i_size = 0L) %as% {
  if(length(digit) == 0) {
    stop("locate_digit called with empty digit")
  }

  ms <- monoids
  mr <- ms[[monoid_name]]
  if(is.null(mr)) {
    stop(paste0("Unknown measure monoid '", monoid_name, "'."))
  }
  locate_digit_impl(p, i, digit, ms, mr, monoid_name, i_size)
}

# Runtime: O(k), where k = digit length (<= 4 in normal tree structure).
locate_digit_impl <- function(p, i, digit, ms, mr, monoid_name, i_size = 0L) {
  # `acc` tracks measure strictly before current candidate; `size_before`
  # tracks positional offset for index metadata.
  acc <- i
  size_before <- as.integer(i_size)

  for(idx in seq_along(digit)) {
    el <- digit[[idx]]
    m_el <- locate_child_measure(el, ms, monoid_name, mr)
    n_el <- locate_child_size(el, ms)
    acc_after <- mr$f(acc, m_el)

    if(p(acc_after)) {
      if(is_structural_node(el)) {
        # If the hit is a structural child, recurse into it so `value` is a leaf
        # value and metadata stays consistent with leaf-level locate semantics.
        return(locate_tree_impl_fast(p, acc, el, ms, mr, monoid_name, size_before))
      }

      right <- if(idx == length(digit)) list() else digit[(idx + 1):length(digit)]
      right_measure <- locate_sequence_measure(right, ms, monoid_name, mr)
      return(list(
        found = TRUE,
        value = el,
        left_measure = acc,
        hit_measure = acc_after,
        right_measure = right_measure,
        index = size_before + 1L
      ))
    }

    acc <- acc_after
    size_before <- size_before + n_el
  }

  list(found = FALSE, value = NULL, left_measure = acc, hit_measure = NULL, right_measure = NULL, index = NULL)
}

# Runtime: O(log n) near locate point depth.
if(FALSE) locate_tree_impl <- function(p, i, t, monoids, monoid_name, i_size = 0L) NULL
locate_tree_impl(p, i, t, monoids, monoid_name, i_size) %::% Function : . : . : list : character : integer : list
locate_tree_impl(p, i, t, monoids, monoid_name, i_size = 0L) %as% {
  ms <- monoids
  mr <- ms[[monoid_name]]
  if(is.null(mr)) {
    stop(paste0("Unknown measure monoid '", monoid_name, "'."))
  }
  locate_tree_impl_fast(p, i, t, ms, mr, monoid_name, i_size)
}

# Runtime: O(log n) near locate point depth.
locate_tree_impl_fast <- function(p, i, t, ms, mr, monoid_name, i_size = 0L) {
  if(!is_structural_node(t)) {
    return(locate_digit_impl(p, i, list(t), ms, mr, monoid_name, as.integer(i_size)))
  }

  if(t %isa% Empty) {
    return(list(found = FALSE, value = NULL, left_measure = i, hit_measure = NULL, right_measure = NULL, index = NULL))
  }

  if(t %isa% Single) {
    return(locate_digit_impl(p, i, list(.subset2(t, 1)), ms, mr, monoid_name, as.integer(i_size)))
  }

  if(t %isa% Deep) {
    # Deep(prefix, middle, suffix): use cached subtree measures to determine
    # which branch contains the first predicate flip without scanning all leaves.
    mpr <- node_measure(.subset2(t,"prefix"), monoid_name)
    mm <- node_measure(.subset2(t,"middle"), monoid_name)
    msf <- node_measure(.subset2(t,"suffix"), monoid_name)

    # `vpr` = i <> measure(prefix), `vm` = i <> measure(prefix) <> measure(middle).
    vpr <- mr$f(i, mpr)
    vm <- mr$f(vpr, mm)

    # Positional offsets for index metadata when descending middle/suffix.
    npr <- as.integer(node_measure(.subset2(t,"prefix"), ".size"))
    nm <- as.integer(node_measure(.subset2(t,"middle"), ".size"))

    if(p(vpr)) {
      # Hit is in prefix. Any right-side measure returned by recursion must be
      # extended by full middle and suffix measures from this Deep node.
      res <- locate_tree_impl_fast(p, i, .subset2(t,"prefix"), ms, mr, monoid_name, as.integer(i_size))
      if(res$found) {
        res$right_measure <- mr$f(mr$f(res$right_measure, mm), msf)
      }
      return(res)
    }

    if(p(vm)) {
      # Hit is in middle. Start accumulator at `vpr` and offset index by prefix size.
      res <- locate_tree_impl_fast(p, vpr, .subset2(t,"middle"), ms, mr, monoid_name, as.integer(i_size + npr))
      if(res$found) {
        # Suffix remains entirely to the right of the located element.
        res$right_measure <- mr$f(res$right_measure, msf)
      }
      return(res)
    }

    # Otherwise hit is in suffix: carry full prefix+middle accumulators and
    # positional offset into the suffix recursion.
    return(locate_tree_impl_fast(p, vm, .subset2(t,"suffix"), ms, mr, monoid_name, as.integer(i_size + npr + nm)))
  }

  # Node / Digit structural lists
  locate_digit_impl(p, i, as.list(t), ms, mr, monoid_name, as.integer(i_size))
}
