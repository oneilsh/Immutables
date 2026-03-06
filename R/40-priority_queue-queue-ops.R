#SO

# Runtime: O(n) over tree size for any non-trivial update (rebind/recompute pass).
#' @method add_monoids priority_queue
#' @export
#' @noRd
add_monoids.priority_queue <- function(t, monoids, overwrite = FALSE) {
  if(length(monoids) > 0L) {
    bad <- intersect(names(monoids), c(".size", ".named_count", ".pq_min", ".pq_max"))
    if(length(bad) > 0L) {
      stop("Reserved monoid names cannot be supplied for priority_queue: ", paste(bad, collapse = ", "))
    }
  }
  add_monoids.flexseq(t, .pq_adapt_user_monoids(monoids), overwrite = overwrite)
}

# Runtime: O(log n) near right edge, with O(1) local name-state checks.
.pq_append_entry <- function(q, entry) {
  ms <- attr(q, "monoids", exact = TRUE)
  if(is.null(ms)) {
    stop("Tree has no monoids attribute.")
  }
  m <- attr(q, "measures", exact = TRUE)
  if(is.null(m)) {
    stop("Tree has no measures attribute.")
  }

  n <- as.integer(m[[".size"]])
  nn <- as.integer(m[[".named_count"]])
  if(n > 0L && nn != 0L && nn != n) {
    stop("Invalid tree name state: mixed named/unnamed elements.")
  }

  nm <- .ft_get_name(entry)
  if(nn == 0L) {
    if(!is.null(nm) && n > 0L) {
      stop("Cannot mix named and unnamed elements (insert would create mixed named and unnamed tree).")
    }
    if(.ft_cpp_can_use(ms)) {
      out <- if(is.null(nm)) .ft_cpp_add_right(q, entry, ms) else .ft_cpp_add_right_named(q, entry, nm, ms)
      return(.pq_wrap_like(q, out))
    }
    entry2 <- if(is.null(nm)) entry else .ft_set_name(entry, nm)
    return(.pq_wrap_like(q, add_right(q, entry2, ms)))
  }

  if(is.null(nm)) {
    stop("Cannot mix named and unnamed elements (insert would create mixed named and unnamed tree).")
  }
  if(.ft_cpp_can_use(ms)) {
    return(.pq_wrap_like(q, .ft_cpp_add_right_named(q, entry, nm, ms)))
  }
  .pq_wrap_like(q, add_right(q, .ft_set_name(entry, nm), ms))
}

# Runtime: O(log n) near right edge.
#' @method insert priority_queue
#' @export
#' @noRd
insert.priority_queue <- function(x, element, priority, name = NULL, ...) {
  q <- x
  .pq_assert_queue(q)
  parsed <- .pq_make_entry(element, priority, priority_type = .pq_priority_type_state(q))
  entry <- parsed$entry

  if(!is.null(name)) {
    entry <- .ft_set_name(entry, name)
  }
  .pq_append_entry(q, entry)
}

# Runtime: O(1).
.pq_empty_like <- function(x) {
  ms <- resolve_tree_monoids(x, required = TRUE)
  .pq_wrap_like(x, empty_tree(monoids = ms))
}

# Runtime: O(k), where k = number of requested positions.
.pq_slice_positions <- function(x, positions) {
  if(length(positions) == 0L) {
    return(.pq_empty_like(x))
  }
  .pq_wrap_like(x, `[.flexseq`(x, as.integer(positions)))
}

# Runtime: O(log n) for single deletion; O(n log n) for multi-position rebuild.
.pq_remove_positions <- function(x, positions) {
  n <- length(x)
  if(length(positions) == 0L) {
    return(x)
  }
  pos <- sort(unique(as.integer(positions)))
  if(length(pos) >= n) {
    return(.pq_empty_like(x))
  }
  if(length(pos) == 1L) {
    idx <- pos[[1L]]
    s <- split_around_by_predicate.flexseq(x, function(v) v >= idx, ".size")
    return(.pq_wrap_like(x, concat_trees(s$left, s$right)))
  }
  keep <- setdiff(seq_len(n), pos)
  .pq_wrap_like(x, `[.flexseq`(x, as.integer(keep)))
}

# Runtime: O(n) scan to collect all tie positions for one extrema value.
.pq_extreme_positions <- function(x, monoid_name) {
  .pq_assert_queue(x)
  if(length(x) == 0L) {
    return(integer(0))
  }
  target <- node_measure(x, monoid_name)
  if(!isTRUE(target$has)) {
    return(integer(0))
  }
  target_priority <- target$priority
  domain <- .ft_scalar_domain(target_priority)
  entries <- .ft_to_list(x)
  idx <- which(vapply(
    entries,
    function(e) {
      .ft_scalar_equal_fast(
        e$priority,
        target_priority,
        domain = domain,
        error_message = "Priority values must support scalar ordering with `<` and `>`."
      )
    },
    logical(1)
  ))
  as.integer(idx)
}

# Runtime: O(log n) near locate point depth.
.pq_peek <- function(x, monoid_name) {
  .pq_assert_queue(x)
  if(length(x) == 0L) {
    return(NULL)
  }

  target <- node_measure(x, monoid_name)
  pred <- function(v) .pq_measure_equal(v, target)
  ctx <- resolve_named_monoid(x, monoid_name)
  ms <- ctx$monoids
  mr <- ctx$monoid
  loc <- if(.ft_cpp_can_use(ms)) {
    .ft_cpp_locate(x, pred, ms, monoid_name, mr$i)
  } else {
    locate_tree_impl_fast(pred, mr$i, x, ms, mr, monoid_name, 0L)
  }
  loc$elem[["item"]]
}

# Runtime: O(log n) near split point depth.
.pq_extract <- function(x, monoid_name) {
  .pq_assert_queue(x)
  if(length(x) == 0L) {
    return(list(element = NULL, priority = NULL, remaining = x))
  }

  target <- node_measure(x, monoid_name)
  pred <- function(v) .pq_measure_equal(v, target)
  ctx <- resolve_named_monoid(x, monoid_name)
  ms <- ctx$monoids
  mr <- ctx$monoid
  s <- if(.ft_cpp_can_use(ms)) {
    .ft_cpp_split_tree(x, pred, ms, monoid_name, mr$i)
  } else {
    split_tree_impl_fast(pred, mr$i, x, ms, mr, monoid_name)
  }

  rest <- concat_trees(s$left, s$right)
  rest <- .pq_wrap_like(x, rest)

  list(
    element = s$elem[["item"]],
    priority = s$elem[["priority"]],
    remaining = rest
  )
}

# Runtime: O(n) due tie-run position scan.
.pq_peek_all <- function(x, monoid_name) {
  .pq_assert_queue(x)
  pos <- .pq_extreme_positions(x, monoid_name)
  .pq_slice_positions(x, pos)
}

# Runtime: O(n log n) worst-case from tie-run extraction + remainder rebuild.
.pq_extract_all <- function(x, monoid_name) {
  .pq_assert_queue(x)
  pos <- .pq_extreme_positions(x, monoid_name)
  if(length(pos) == 0L) {
    return(list(elements = .pq_empty_like(x), remaining = x))
  }
  list(
    elements = .pq_slice_positions(x, pos),
    remaining = .pq_remove_positions(x, pos)
  )
}

# Runtime: O(log n) near locate point depth.
#' Peek Minimum-Priority Element
#'
#' Returns the element at the minimum priority without modifying the queue.
#'
#' @param x A `priority_queue`.
#' @return Element at minimum priority, or `NULL` when `x` is empty.
#' @details
#' Ties are stable: when multiple elements share minimum priority, this returns
#' the earliest element in queue order.
#' @examples
#' x <- priority_queue("a", "b", "c", priorities = c(2, 1, 1))
#' peek_min(x)
#' peek_min(priority_queue())
#' @export
peek_min <- function(x) {
  .pq_peek(x, ".pq_min")
}

# Runtime: O(log n) near locate point depth.
#' Peek Maximum-Priority Element
#'
#' Returns the element at the maximum priority without modifying the queue.
#'
#' @param x A `priority_queue`.
#' @return Element at maximum priority, or `NULL` when `x` is empty.
#' @details
#' Ties are stable: when multiple elements share maximum priority, this returns
#' the earliest element in queue order.
#' @examples
#' x <- priority_queue("a", "b", "c", priorities = c(2, 3, 3))
#' peek_max(x)
#' peek_max(priority_queue())
#' @export
peek_max <- function(x) {
  .pq_peek(x, ".pq_max")
}

# Runtime: O(n) due tie-run scan.
#' Peek All Minimum-Priority Elements
#'
#' Returns the full minimum-priority tie run as a `priority_queue`.
#'
#' @param x A `priority_queue`.
#' @return A `priority_queue` containing all minimum-priority elements in stable
#'   queue order. Returns an empty queue when `x` is empty.
#' @details
#' The return is another `priority_queue()`, use `as.list()` to convert 
#' the result to a standard R list.
#' @examples
#' x <- priority_queue("a", "b", "c", priorities = c(2, 1, 1))
#' peek_all_min(x)
#' @export
peek_all_min <- function(x) {
  .pq_peek_all(x, ".pq_min")
}

# Runtime: O(n) due tie-run scan.
#' Peek All Maximum-Priority Elements
#'
#' Returns the full maximum-priority tie run as a `priority_queue`.
#'
#' @param x A `priority_queue`.
#' @return A `priority_queue` containing all maximum-priority elements in stable
#'   queue order. Returns an empty queue when `x` is empty.
#' @details
#' The return is another `priority_queue()`, use `as.list()` to convert 
#' the result to a standard R list.
#' @examples
#' x <- priority_queue("a", "b", "c", priorities = c(2, 3, 3))
#' peek_all_max(x)
#' @export
peek_all_max <- function(x) {
  .pq_peek_all(x, ".pq_max")
}

# Runtime: O(log n) near split point depth.
#' Pop Minimum-Priority Element
#'
#' Removes one minimum-priority element and returns it with the remaining queue.
#'
#' @param x A `priority_queue`.
#' @return A list with fields:
#' - `element`: removed element, or `NULL` when `x` is empty.
#' - `priority`: removed priority, or `NULL` when `x` is empty.
#' - `remaining`: queue after removal.
#' @details
#' Ties are stable: when multiple elements share minimum priority, the earliest
#' element in queue order is removed.
#' @examples
#' x <- priority_queue("a", "b", "c", priorities = c(2, 1, 1))
#' out <- pop_min(x)
#' out$element
#' out$priority
#' out$remaining
#' pop_min(priority_queue())
#' @export
pop_min <- function(x) {
  .pq_extract(x, ".pq_min")
}

# Runtime: O(log n) near split point depth.
#' Pop Maximum-Priority Element
#'
#' Removes one maximum-priority element and returns it with the remaining queue.
#'
#' @param x A `priority_queue`.
#' @return A list with fields:
#' - `element`: removed element, or `NULL` when `x` is empty.
#' - `priority`: removed priority, or `NULL` when `x` is empty.
#' - `remaining`: queue after removal.
#' @details
#' Ties are stable: when multiple elements share maximum priority, the earliest
#' element in queue order is removed.
#' @examples
#' x <- priority_queue("a", "b", "c", priorities = c(2, 3, 3))
#' out <- pop_max(x)
#' out$element
#' out$priority
#' out$remaining
#' pop_max(priority_queue())
#' @export
pop_max <- function(x) {
  .pq_extract(x, ".pq_max")
}

# Runtime: O(n log n) worst-case.
#' Pop All Minimum-Priority Elements
#'
#' Removes the full minimum-priority tie run.
#'
#' @param x A `priority_queue`.
#' @return A list with fields:
#' - `elements`: `priority_queue` of removed minimum-priority elements.
#' - `remaining`: queue after removal.
#' @details
#' The return `elements` is another `priority_queue()`, use `as.list()` to 
#' convert the result to a standard R list.
#' @examples
#' x <- priority_queue("a", "b", "c", priorities = c(2, 1, 1))
#' out <- pop_all_min(x)
#' out$elements
#' out$remaining
#' @export
pop_all_min <- function(x) {
  .pq_extract_all(x, ".pq_min")
}

# Runtime: O(n log n) worst-case.
#' Pop All Maximum-Priority Elements
#'
#' Removes the full maximum-priority tie run.
#'
#' @param x A `priority_queue`.
#' @return A list with fields:
#' - `elements`: `priority_queue` of removed maximum-priority elements.
#' - `remaining`: queue after removal.
#' @details
#' The return `elements` is another `priority_queue()`, use `as.list()` to 
#' convert the result to a standard R list.
#' @examples
#' x <- priority_queue("a", "b", "c", priorities = c(2, 3, 3))
#' out <- pop_all_max(x)
#' out$elements
#' out$remaining
#' @export
pop_all_max <- function(x) {
  .pq_extract_all(x, ".pq_max")
}
