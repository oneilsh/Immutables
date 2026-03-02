#SO

# dispatch add-right through C++/R backend and restore class stack.
# Runtime: O(log n) tree update + subclass restoration.
.ft_push_back_dispatch <- function(x, element, monoids, context = "push_back()") {
  out <- if(.ft_cpp_can_use(monoids)) {
    .ft_cpp_add_right(x, element, monoids)
  } else {
    add_right(x, element, monoids)
  }
  .ft_restore_subclass(out, x, context = context)
}

# dispatch named add-right through C++/R backend and restore class stack.
# Runtime: O(log n) tree update + subclass restoration.
.ft_push_back_named_dispatch <- function(x, element, name, monoids, context = "push_back()") {
  out <- if(.ft_cpp_can_use(monoids)) {
    .ft_cpp_add_right_named(x, element, name, monoids)
  } else {
    add_right(x, .ft_set_name(element, name), monoids)
  }
  .ft_restore_subclass(out, x, context = context)
}

# dispatch add-left through C++/R backend and restore class stack.
# Runtime: O(log n) tree update + subclass restoration.
.ft_push_front_dispatch <- function(x, element, monoids, context = "push_front()") {
  out <- if(.ft_cpp_can_use(monoids)) {
    .ft_cpp_add_left(x, element, monoids)
  } else {
    add_left(x, element, monoids)
  }
  .ft_restore_subclass(out, x, context = context)
}

# dispatch named add-left through C++/R backend and restore class stack.
# Runtime: O(log n) tree update + subclass restoration.
.ft_push_front_named_dispatch <- function(x, element, name, monoids, context = "push_front()") {
  out <- if(.ft_cpp_can_use(monoids)) {
    .ft_cpp_add_left_named(x, element, name, monoids)
  } else {
    add_left(x, .ft_set_name(element, name), monoids)
  }
  .ft_restore_subclass(out, x, context = context)
}

# Runtime: O(log n) tree update, with O(1) local name-state checks.
.ft_push_back_impl <- function(x, value, context = "push_back()") {
  monoids <- attr(x, "monoids", exact = TRUE)
  if(is.null(monoids)) {
    stop("Tree has no monoids attribute.")
  }
  measures <- attr(x, "measures", exact = TRUE)
  if(is.null(measures)) {
    stop("Tree has no measures attribute.")
  }
  size <- as.integer(measures[[".size"]])
  named_count <- as.integer(measures[[".named_count"]])
  if(size > 0L && named_count != 0L && named_count != size) {
    stop("Invalid tree name state: mixed named/unnamed elements.")
  }

  element <- value
  if(named_count == 0L) {
    element_name <- .ft_get_name(element)
    if(is.null(element_name)) {
      element_name <- .ft_name_from_value(element)
    }

    # Unnamed tree mode: unnamed element is always fine.
    if(is.null(element_name)) {
      return(.ft_push_back_dispatch(x, element, monoids, context = context))
    }

    # Named element may only seed an empty tree; otherwise it would mix states.
    if(size > 0L) {
      stop("Cannot mix named and unnamed elements (push_back would create mixed named and unnamed tree).")
    }
    return(.ft_push_back_named_dispatch(x, element, element_name, monoids, context = context))
  }

  # Named tree mode: inserted element must carry a usable name.
  element_name <- .ft_effective_name(element)
  if(is.null(element_name)) {
    stop("Cannot mix named and unnamed elements (push_back would create mixed named and unnamed tree).")
  }
  .ft_push_back_named_dispatch(x, element, element_name, monoids, context = context)
}

#' Push an element to the back
#'
#' @param x A `flexseq`.
#' @param value Element to push.
#' @return Updated tree.
#'   If `x` is name-indexed, pushing unnamed elements is invalid.
#' @examples
#' s <- as_flexseq(letters[1:3])
#' s2 <- push_back(s, "d")
#' s2
#'
#' n <- as_flexseq(list(two = 2, three = 3))
#' new_el <- 4
#' names(new_el) <- "four"
#' push_back(n, new_el)
#' @export
# Runtime: O(log n) tree update, with O(1) local name-state checks.
push_back <- function(x, value) {
  if(inherits(x, "ordered_sequence")) {
    .ft_stop_ordered_like(x, "push_back", "Use `insert()`.")
  }
  if(inherits(x, "priority_queue")) {
    stop("`push_back()` is not supported for priority_queue. Cast first with `as_flexseq()`.")
  }
  .ft_push_back_impl(x, value, context = "push_back()")
}

#' Push an element to the front
#'
#' @param x A `flexseq`.
#' @param value Element to push.
#' @return Updated tree.
#'   If `x` is name-indexed, pushing unnamed elements is invalid.
#' @examples
#' s <- as_flexseq(letters[2:4])
#' s2 <- push_front(s, "a")
#' s2
#'
#' n <- as_flexseq(list(two = 2, three = 3))
#' new_el <- 1
#' names(new_el) <- "one"
#' push_front(n, new_el)
#' @export
# Runtime: O(log n) tree update, with O(1) local name-state checks.
push_front <- function(x, value) {
  if(inherits(x, "ordered_sequence")) {
    .ft_stop_ordered_like(x, "push_front", "Use `insert()`.")
  }
  if(inherits(x, "priority_queue")) {
    stop("`push_front()` is not supported for priority_queue. Cast first with `as_flexseq()`.")
  }

  monoids <- attr(x, "monoids", exact = TRUE)
  if(is.null(monoids)) {
    stop("Tree has no monoids attribute.")
  }
  measures <- attr(x, "measures", exact = TRUE)
  if(is.null(measures)) {
    stop("Tree has no measures attribute.")
  }
  size <- as.integer(measures[[".size"]])
  named_count <- as.integer(measures[[".named_count"]])
  if(size > 0L && named_count != 0L && named_count != size) {
    stop("Invalid tree name state: mixed named/unnamed elements.")
  }

  element <- value
  if(named_count == 0L) {
    element_name <- .ft_get_name(element)
    if(is.null(element_name)) {
      element_name <- .ft_name_from_value(element)
    }

    # Unnamed tree mode: unnamed element is always fine.
    if(is.null(element_name)) {
      return(.ft_push_front_dispatch(x, element, monoids, context = "push_front()"))
    }

    # Named element may only seed an empty tree; otherwise it would mix states.
    if(size > 0L) {
      stop("Cannot mix named and unnamed elements (push_front would create mixed named and unnamed tree).")
    }
    return(.ft_push_front_named_dispatch(x, element, element_name, monoids, context = "push_front()"))
  }

  # Named tree mode: inserted element must carry a usable name.
  element_name <- .ft_effective_name(element)
  if(is.null(element_name)) {
    stop("Cannot mix named and unnamed elements (push_front would create mixed named and unnamed tree).")
  }
  .ft_push_front_named_dispatch(x, element, element_name, monoids, context = "push_front()")
}

# Runtime: O(1) for empty rebuild metadata, class restoration depends on type.
# pop_* on size-1 should return an empty value of the same semantic type, not just raw flexseq.
.ft_empty_same_type <- function(x, context = "pop") {
  monoids <- resolve_tree_monoids(x, required = TRUE)
  empty <- empty_tree(monoids = monoids)
  if(inherits(x, "interval_index")) {
    return(.ivx_wrap_like(x, empty))
  }
  if(inherits(x, "ordered_sequence")) {
    return(.ord_wrap_like(x, empty))
  }
  .ft_restore_subclass(empty, x, context = context)
}

# Runtime: O(1).
.ft_unwrap_public_value <- function(x, element) {
  # Ordered/interval subclasses store internal entry records; public end-ops
  # return payload items to match user-facing sequence semantics.
  if(inherits(x, "interval_index")) {
    if(is.list(element) && ("item" %in% names(element))) {
      return(element$item)
    }
    return(element)
  }
  if(inherits(x, "ordered_sequence")) {
    if(is.list(element) && ("item" %in% names(element))) {
      return(element$item)
    }
    return(element)
  }
  element
}

# validate one positional index for public peek/pop-at helpers.
# Runtime: O(1).
.ft_validate_scalar_position <- function(index, n) {
  resolved <- .ft_assert_int_indices(index, n)
  if(length(resolved) != 1L) {
    stop("`index` must be a single positive integer.")
  }
  resolved
}

# validate one positional index for miss-aware public peek/pop-at helpers.
# Returns NULL when index is a valid positive integer but out of bounds.
# Runtime: O(1).
.ft_validate_scalar_position_missable <- function(index, n) {
  if(is.null(index)) {
    stop("Index is required.")
  }
  if(!is.numeric(index) || any(is.na(index)) || any(index != as.integer(index))) {
    stop("Only non-missing integer indices are supported.")
  }
  idx <- as.integer(index)
  if(length(idx) != 1L) {
    stop("`index` must be a single positive integer.")
  }
  if(idx <= 0L) {
    stop("Only positive integer indices are supported.")
  }
  if(idx > n) {
    return(NULL)
  }
  idx
}

# validate one insertion index in [1, n + 1].
# Runtime: O(1).
.ft_validate_scalar_insert_position <- function(index, n) {
  resolved <- .ft_assert_int_indices(index, n + 1L)
  if(length(resolved) != 1L) {
    stop("`index` must be a single positive integer.")
  }
  resolved
}

# normalize insert_at payload into a plain list of elements.
# Runtime: O(k), where k = number of inserted elements.
.ft_coerce_insert_values <- function(values) {
  if(inherits(values, "priority_queue")) {
    stop("`values` cannot be a priority_queue. Cast first with `as_flexseq()`.")
  }
  if(inherits(values, "ordered_sequence")) {
    stop(sprintf(
      "`values` cannot be an ordered sequence subclass (%s). Cast first with `as_flexseq()`.",
      .ft_ordered_owner_class(values)
    ))
  }
  if(inherits(values, "flexseq")) {
    return(as.list(values))
  }
  if(is.list(values)) {
    return(values)
  }
  as.list(values)
}

# enforce global named/unnamed consistency for insert_at.
# Runtime: O(1) from cached size/name counts.
.ft_validate_insert_name_state <- function(x, insert_tree, context = "insert_at()") {
  measures_x <- attr(x, "measures", exact = TRUE)
  measures_insert <- attr(insert_tree, "measures", exact = TRUE)
  if(is.null(measures_x) || is.null(measures_insert)) {
    stop("Tree has no measures attribute.")
  }
  n_x <- as.integer(measures_x[[".size"]])
  nn_x <- as.integer(measures_x[[".named_count"]])
  n_i <- as.integer(measures_insert[[".size"]])
  nn_i <- as.integer(measures_insert[[".named_count"]])

  if((n_x > 0L && nn_x != 0L && nn_x != n_x) || (n_i > 0L && nn_i != 0L && nn_i != n_i)) {
    stop("Invalid tree name state: mixed named/unnamed elements.")
  }
  if(n_x == 0L || n_i == 0L) {
    return(invisible(TRUE))
  }
  x_named <- (nn_x == n_x)
  i_named <- (nn_i == n_i)
  if(x_named != i_named) {
    stop("Cannot mix named and unnamed elements (", context, " would create mixed named and unnamed tree).")
  }
  invisible(TRUE)
}

#' Peek at the front element
#'
#' @param x A `flexseq`.
#' @return Front element, or `NULL` when `x` is empty.
#' @export
# Runtime: O(log n) lookup by scalar index.
peek_front <- function(x) {
  if(inherits(x, "interval_index")) {
    stop("`peek_front()` is not supported for interval_index. Use interval query helpers (`peek_*`, `pop_*`, and `peek_point()` for point lookup).")
  }
  if(inherits(x, "priority_queue")) {
    stop("`peek_front()` is not supported for priority_queue. Use `peek_min()`/`peek_max()`, or cast with `as_flexseq()`.")
  }
  if(!inherits(x, "flexseq")) {
    stop("`x` must be a flexseq.")
  }
  if(length(x) == 0L) {
    return(NULL)
  }
  .ft_unwrap_public_value(x, x[[1L]])
}

#' Peek at the back element
#'
#' @param x A `flexseq`.
#' @return Back element, or `NULL` when `x` is empty.
#' @export
# Runtime: O(log n) lookup by scalar index.
peek_back <- function(x) {
  if(inherits(x, "interval_index")) {
    stop("`peek_back()` is not supported for interval_index. Use interval query helpers (`peek_*`, `pop_*`, and `peek_point()` for point lookup).")
  }
  if(inherits(x, "priority_queue")) {
    stop("`peek_back()` is not supported for priority_queue. Use `peek_min()`/`peek_max()`, or cast with `as_flexseq()`.")
  }
  if(!inherits(x, "flexseq")) {
    stop("`x` must be a flexseq.")
  }
  n <- length(x)
  if(n == 0L) {
    return(NULL)
  }
  .ft_unwrap_public_value(x, x[[n]])
}

#' Peek at an element by position
#'
#' @param x A `flexseq`.
#' @param index One-based position to read.
#' @return Element at `index`, or `NULL` when `index` is out of bounds.
#' @export
# Runtime: O(log n) lookup by scalar index.
peek_at <- function(x, index) {
  if(inherits(x, "interval_index")) {
    stop("`peek_at()` is not supported for interval_index. Use interval query helpers (`peek_*`, `pop_*`, and `peek_point()` for point lookup).")
  }
  if(inherits(x, "priority_queue")) {
    stop("`peek_at()` is not supported for priority_queue. Use `peek_min()`/`peek_max()`, or cast with `as_flexseq()`.")
  }
  if(!inherits(x, "flexseq")) {
    stop("`x` must be a flexseq.")
  }
  n <- length(x)
  idx <- .ft_validate_scalar_position_missable(index, n)
  if(is.null(idx)) {
    return(NULL)
  }
  element <- .ft_strip_name(.ft_get_elem_at(x, idx))
  .ft_unwrap_public_value(x, element)
}

#' Pop the front element
#'
#' Returns both the popped element and the remaining sequence.
#'
#' @param x A `flexseq`.
#' @return A list with fields `element` and `remaining`.
#' @examples
#' s <- as_flexseq(letters[1:3])
#' out <- pop_front(s)
#' out$element
#' out$remaining
#' @export
# Runtime: O(log n) for one read plus one subset.
pop_front <- function(x) {
  if(inherits(x, "interval_index")) {
    stop("`pop_front()` is not supported for interval_index. Use interval query helpers (`peek_*`, `pop_*`, and `peek_point()` for point lookup).")
  }
  if(inherits(x, "priority_queue")) {
    stop("`pop_front()` is not supported for priority_queue. Use `pop_min()`/`pop_max()`, or cast with `as_flexseq()`.")
  }
  if(!inherits(x, "flexseq")) {
    stop("`x` must be a flexseq.")
  }
  n <- length(x)
  if(n == 0L) {
    return(list(element = NULL, remaining = x))
  }
  element <- .ft_unwrap_public_value(x, x[[1L]])
  remaining <- if(n == 1L) .ft_empty_same_type(x, context = "pop_front()") else x[seq.int(2L, n)]
  list(element = element, remaining = remaining)
}

#' Pop the back element
#'
#' Returns both the popped element and the remaining sequence.
#'
#' @param x A `flexseq`.
#' @return A list with fields `element` and `remaining`.
#' @examples
#' s <- as_flexseq(letters[1:3])
#' out <- pop_back(s)
#' out$element
#' out$remaining
#' @export
# Runtime: O(log n) for one read plus one subset.
pop_back <- function(x) {
  if(inherits(x, "interval_index")) {
    stop("`pop_back()` is not supported for interval_index. Use interval query helpers (`peek_*`, `pop_*`, and `peek_point()` for point lookup).")
  }
  if(inherits(x, "priority_queue")) {
    stop("`pop_back()` is not supported for priority_queue. Use `pop_min()`/`pop_max()`, or cast with `as_flexseq()`.")
  }
  if(!inherits(x, "flexseq")) {
    stop("`x` must be a flexseq.")
  }
  n <- length(x)
  if(n == 0L) {
    return(list(element = NULL, remaining = x))
  }
  element <- .ft_unwrap_public_value(x, x[[n]])
  remaining <- if(n == 1L) .ft_empty_same_type(x, context = "pop_back()") else x[seq_len(n - 1L)]
  list(element = element, remaining = remaining)
}

#' Pop an element by position
#'
#' Returns both the popped element and the remaining sequence.
#'
#' @param x A `flexseq`.
#' @param index One-based position to remove.
#' @return A list with fields `element` and `remaining`.
#' @examples
#' s <- as_flexseq(letters[1:4])
#' out <- pop_at(s, 3)
#' out$element
#' out$remaining
#' @export
# Runtime: O(log n) for one read plus O(k log n) index subset to rebuild.
pop_at <- function(x, index) {
  if(inherits(x, "interval_index")) {
    stop("`pop_at()` is not supported for interval_index. Use interval query helpers (`peek_*`, `pop_*`, and `peek_point()` for point lookup).")
  }
  if(inherits(x, "priority_queue")) {
    stop("`pop_at()` is not supported for priority_queue. Use `pop_min()`/`pop_max()`, or cast with `as_flexseq()`.")
  }
  if(!inherits(x, "flexseq")) {
    stop("`x` must be a flexseq.")
  }
  n <- length(x)
  idx <- .ft_validate_scalar_position_missable(index, n)
  if(is.null(idx)) {
    return(list(element = NULL, remaining = x))
  }
  selected <- .ft_strip_name(.ft_get_elem_at(x, idx))
  element <- .ft_unwrap_public_value(x, selected)

  remaining <- if(n == 1L) {
    .ft_empty_same_type(x, context = "pop_at()")
  } else if(idx == 1L) {
    x[seq.int(2L, n)]
  } else if(idx == n) {
    x[seq_len(n - 1L)]
  } else {
    x[c(seq_len(idx - 1L), seq.int(idx + 1L, n))]
  }
  list(element = element, remaining = remaining)
}

#' Insert elements at a position
#'
#' Inserts one or more elements before the current element at `index`.
#'
#' @param x A `flexseq`.
#' @param index One-based insertion position in `[1, length(x) + 1]`.
#' @param values Elements to insert. Supports scalar/vector/list/flexseq inputs.
#' @return Updated sequence with inserted elements.
#' @examples
#' s <- as_flexseq(letters[1:4])
#' insert_at(s, 3, c("x", "y"))
#' @export
# Runtime: O(k log k) to build inserted payload + O(log n) split + concat work.
insert_at <- function(x, index, values) {
  if(inherits(x, "ordered_sequence")) {
    .ft_stop_ordered_like(x, "insert_at", "Use `insert()`.")
  }
  if(inherits(x, "priority_queue")) {
    stop("`insert_at()` is not supported for priority_queue. Cast first with `as_flexseq()`.")
  }
  if(!inherits(x, "flexseq")) {
    stop("`x` must be a flexseq.")
  }

  n <- length(x)
  insert_index <- .ft_validate_scalar_insert_position(index, n)
  insert_values <- .ft_coerce_insert_values(values)
  if(length(insert_values) == 0L) {
    return(x)
  }

  monoids <- resolve_tree_monoids(x, required = TRUE)
  insert_tree <- tree_from(insert_values, monoids = monoids)
  .ft_validate_insert_name_state(x, insert_tree, context = "insert_at()")

  out <- if(n == 0L) {
    insert_tree
  } else if(insert_index == 1L) {
    concat_trees(insert_tree, x)
  } else if(insert_index == (n + 1L)) {
    concat_trees(x, insert_tree)
  } else {
    # Split once at insertion boundary, then stitch left + inserted + right.
    split_ctx <- split_by_predicate(x, function(v) v >= insert_index, ".size")
    concat_trees(concat_trees(split_ctx$left, insert_tree), split_ctx$right)
  }
  .ft_restore_subclass(out, x, context = "insert_at()")
}
