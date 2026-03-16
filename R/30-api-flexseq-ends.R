#SO

# Internal: push a pre-prepared element (ft_name already set) without re-checking
# name state. Used by [[<- after all name validation has already been done.
# Runtime: O(log n) tree update.
.ft_push_back_raw <- function(x, element, monoids) {
  out <- if(.ft_cpp_can_use(monoids)) {
    .ft_cpp_add_right(x, element, monoids)
  } else {
    add_right(x, element, monoids)
  }
  .ft_restore_subclass(out, x, context = "push")
}

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
    element_name <- .ft_get_name_fast(element)
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
  element_name <- .ft_get_name_fast(element)
  if(is.null(element_name)) {
    element_name <- .ft_name_from_value(element)
  }
  if(is.null(element_name)) {
    stop("Cannot mix named and unnamed elements (push_back would create mixed named and unnamed tree).")
  }
  .ft_push_back_named_dispatch(x, element, element_name, monoids, context = context)
}

#' Push an Element to the Back
#'
#' Returns a new sequence with `value` appended at the right end.
#'
#' @param x A `flexseq`.
#' @param value Element to append.
#' @return Updated `flexseq`.
#' @details
#' This operation is persistent: `x` is not modified.
#'
#' Elements can be named, but only if all are uniquely named (no missing
#' names). 
#' @examples
#' s <- as_flexseq(letters[1:3])
#' s2 <- push_back(s, "d")
#' s2
#' s  # unchanged
#'
#' n <- as_flexseq(list(two = 2, three = 3))
#' new_el <- 4
#' names(new_el) <- "four"
#' push_back(n, new_el)
#'
#' # Named/unnamed mixes are rejected
#' try(push_back(n, 5))
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

#' Push an Element to the Front
#'
#' Returns a new sequence with `value` prepended at the left end.
#'
#' @param x A `flexseq`.
#' @param value Element to prepend.
#' @return Updated `flexseq`.
#' @details
#' This operation is persistent: `x` is not modified.
#'
#' Elements can be named, but only if all are uniquely named (no missing
#' names). 
#' @examples
#' s <- as_flexseq(letters[2:4])
#' s2 <- push_front(s, "a")
#' s2
#' s  # unchanged
#'
#' n <- as_flexseq(list(two = 2, three = 3))
#' new_el <- 1
#' names(new_el) <- "one"
#' push_front(n, new_el)
#'
#' # Named/unnamed mixes are rejected
#' try(push_front(n, 0))
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
    element_name <- .ft_get_name_fast(element)
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
  element_name <- .ft_get_name_fast(element)
  if(is.null(element_name)) {
    element_name <- .ft_name_from_value(element)
  }
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
    if(is.list(element) && ("value" %in% names(element))) {
      return(element$value)
    }
    return(element)
  }
  if(inherits(x, "ordered_sequence")) {
    if(is.list(element) && ("value" %in% names(element))) {
      return(element$value)
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

#' Peek at the Front Element
#'
#' Returns the first element without modifying the sequence.
#'
#' @param x A `flexseq`.
#' @return First element, or `NULL` when `x` is empty.
#' @details
#' Returns the payload element without modifying `x`.
#' @examples
#' x <- flexseq("a", "b", "c")
#' peek_front(x)
#'
#' peek_front(flexseq())
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

#' Peek at the Back Element
#'
#' Returns the last element without modifying the sequence.
#'
#' @param x A `flexseq`.
#' @return Last element, or `NULL` when `x` is empty.
#' @details
#' Returns the payload element without modifying `x`.
#' @examples
#' x <- flexseq("a", "b", "c")
#' peek_back(x)
#'
#' peek_back(flexseq())
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

#' Peek at an Element by Position
#'
#' Returns the element at a one-based index without modifying the sequence.
#'
#' @param x A `flexseq`.
#' @param index One-based position to read.
#' @return Element at `index`, or `NULL` when `index` is out of bounds.
#' @details
#' Positive integer indices beyond `length(x)` return `NULL`.
#' Invalid indices (`NA`, non-integer, `<= 0`, or length not equal to 1) error.
#' @examples
#' x <- flexseq("a", "b", "c")
#' peek_at(x, 2)
#' peek_at(x, 10)
#'
#' try(peek_at(x, 0))
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

#' Pop the Front Element
#'
#' Returns the first element and the remaining sequence.
#'
#' @param x A `flexseq`.
#' @return A list with fields:
#' - `value`: the first element, or `NULL` when `x` is empty.
#' - `remaining`: the sequence after removing the first element.
#' @details
#' This operation is persistent: `x` is not modified.
#'
#' On empty input, returns a non-throwing miss object with
#' `value = NULL` and `remaining = x`.
#' @examples
#' s <- flexseq("a", "b", "c")
#' out <- pop_front(s)
#' out$value
#' out$remaining
#' s  # unchanged
#'
#' pop_front(flexseq())
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
  n <- .ft_size(x)
  if(n == 0L) {
    return(list(value = NULL, remaining = x))
  }
  ms <- attr(x, "monoids", exact = TRUE)
  if(.ft_cpp_can_use(ms)) {
    s <- .ft_cpp_split_at_index(x, 1L, ms)
    element <- .ft_unwrap_public_value(x, .ft_strip_name(s$value))
    remaining <- if(n == 1L) .ft_empty_same_type(x, context = "pop_front()") else .ft_restore_subclass(s$right, x, context = "pop_front()")
    return(list(value = element, remaining = remaining))
  }
  s <- split_around_by_predicate(x, function(v) v >= 1L, ".size")
  element <- .ft_unwrap_public_value(x, .ft_strip_name(s$value))
  remaining <- if(n == 1L) .ft_empty_same_type(x, context = "pop_front()") else s$right
  list(value = element, remaining = remaining)
}

#' Pop the Back Element
#'
#' Returns the last element and the remaining sequence.
#'
#' @param x A `flexseq`.
#' @return A list with fields:
#' - `value`: the last element, or `NULL` when `x` is empty.
#' - `remaining`: the sequence after removing the last element.
#' @details
#' This operation is persistent: `x` is not modified.
#'
#' On empty input, returns a non-throwing miss object with
#' `value = NULL` and `remaining = x`.
#' @examples
#' s <- flexseq("a", "b", "c")
#' out <- pop_back(s)
#' out$value
#' out$remaining
#' s  # unchanged
#'
#' pop_back(flexseq())
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
  n <- .ft_size(x)
  if(n == 0L) {
    return(list(value = NULL, remaining = x))
  }
  ms <- attr(x, "monoids", exact = TRUE)
  if(.ft_cpp_can_use(ms)) {
    s <- .ft_cpp_split_at_index(x, n, ms)
    element <- .ft_unwrap_public_value(x, .ft_strip_name(s$value))
    remaining <- if(n == 1L) .ft_empty_same_type(x, context = "pop_back()") else .ft_restore_subclass(s$left, x, context = "pop_back()")
    return(list(value = element, remaining = remaining))
  }
  s <- split_around_by_predicate(x, function(v) v >= n, ".size")
  element <- .ft_unwrap_public_value(x, .ft_strip_name(s$value))
  remaining <- if(n == 1L) .ft_empty_same_type(x, context = "pop_back()") else s$left
  list(value = element, remaining = remaining)
}

#' Pop an Element by Position
#'
#' Returns the selected element and the remaining sequence.
#'
#' @param x A `flexseq`.
#' @param index One-based position to remove.
#' @return A list with fields:
#' - `value`: the element at `index`, or `NULL` when `index` is out of bounds.
#' - `remaining`: the sequence after removing the selected element.
#' @details
#' This operation is persistent: `x` is not modified.
#'
#' Positive integer indices beyond `length(x)` return a non-throwing miss object
#' with `value = NULL` and `remaining = x`.
#' Invalid indices (`NA`, non-integer, `<= 0`, or length not equal to 1) error.
#' @examples
#' x <- flexseq("a", "b", "c", "d")
#' out <- pop_at(x, 3)
#' out$value
#' out$remaining
#' x  # unchanged
#'
#' pop_at(x, 10)
#' try(pop_at(x, 0))
#' @export
# Runtime: O(log n) for split plus O(log n) concat.
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
    return(list(value = NULL, remaining = x))
  }
  ms <- attr(x, "monoids", exact = TRUE)
  if(.ft_cpp_can_use(ms)) {
    s <- .ft_cpp_split_at_index(x, idx, ms)
    element <- .ft_unwrap_public_value(x, .ft_strip_name(s$value))
    remaining <- if(n == 1L) {
      .ft_empty_same_type(x, context = "pop_at()")
    } else {
      .ft_restore_subclass(.ft_cpp_concat(s$left, s$right, ms), x, context = "pop_at()")
    }
    return(list(value = element, remaining = remaining))
  }
  s <- split_around_by_predicate(x, function(v) v >= idx, ".size")
  element <- .ft_unwrap_public_value(x, .ft_strip_name(s$value))
  remaining <- if(n == 1L) {
    .ft_empty_same_type(x, context = "pop_at()")
  } else {
    .ft_restore_subclass(.ft_concat_same_monoids(s$left, s$right, ms), x, context = "pop_at()")
  }
  list(value = element, remaining = remaining)
}

#' Insert Elements at a Position
#'
#' Inserts `values` before the current element at `index`.
#'
#' @param x A `flexseq`.
#' @param index One-based insertion position in `[1, length(x) + 1]`.
#' @param values Values to insert.
#' @return Updated sequence with inserted values.
#' @details
#' `values` is interpreted as a collection of elements to splice in.
#'
#' Common cases:
#' - Atomic vector (`c("x", "y")`): inserts one element per vector entry.
#' - List (`list("x", "y")`): inserts one element per list entry.
#' - `flexseq`: inserts all of its elements.
#' - Empty input (`list()` or `flexseq()`): no change.
#'
#' To insert one composite object (for example, a vector or a list) as a single
#' element, wrap it in `list(...)`.
#'
#' This operation is persistent: `x` is not modified.
#' @examples
#' x <- flexseq("a", "b", "c", "d")
#' insert_at(x, 3, c("x", "y"))
#' insert_at(x, 1, "start")
#' insert_at(x, length(x) + 1, "end")
#'
#' # Insert one vector as a single element
#' insert_at(x, 3, list(c("u", "v")))
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
