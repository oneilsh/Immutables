#SO

# Fast plain-R helpers that bypass lambda.r dispatch overhead (~100-190us/call).
# These are hot-path equivalents of lambda.r-defined functions.

# Runtime: O(1). Fast replacement for node_measure(x, ".size").
.ft_size <- function(x) {
  as.integer(attr(x, "measures", exact = TRUE)[[".size"]])
}

# Runtime: O(1). Fast replacement for node_measure(x, ".named_count").
.ft_named_count <- function(x) {
  as.integer(attr(x, "measures", exact = TRUE)[[".named_count"]])
}

# Runtime: O(1). Fast replacement for .ft_get_name(el) (skips lambda.r dispatch).
.ft_get_name_fast <- function(el) {
  nm <- attr(el, "ft_name", exact = TRUE)
  if(is.null(nm)) return(NULL)
  if(!is.character(nm) || length(nm) != 1L || is.na(nm) || !nzchar(nm)) return(NULL)
  nm
}

# Runtime: O(1). Fast replacement for .ft_set_name(el, name) (skips lambda.r dispatch).
# Caller must pass NULL or a validated non-empty string.
.ft_set_name_fast <- function(el, name) {
  attr(el, "ft_name") <- name
  el
}

# mark a structural tree as a user-facing flexseq object.
# Runtime: O(1).
.as_flexseq <- function(x) {
  if(!inherits(x, "FingerTree")) {
    stop("Expected a structural tree node.")
  }
  class(x) <- unique(c("flexseq", setdiff(class(x), "list")))
  x
}

# restore subtype after shared flexseq operations.
# Runtime: O(1) for flexseq/ordered_sequence/priority_queue, O(n) when
# interval_index restore validation is required.
.ft_restore_subclass <- function(out, source, context = "flexseq operation") {
  if(!inherits(out, "FingerTree")) {
    stop("Expected a structural tree node.")
  }
  if(inherits(source, "interval_index")) {
    return(.ivx_restore_tree(out, template = source, context = context))
  }
  if(inherits(source, "ordered_sequence")) {
    key_type <- attr(source, "oms_key_type", exact = TRUE)
    return(.as_ordered_sequence(out, key_type = key_type))
  }
  if(inherits(source, "priority_queue")) {
    return(.pq_wrap_like(source, out))
  }
  .as_flexseq(out)
}

# identify the concrete ordered-like class for user-facing error messages.
# Runtime: O(1).
.ft_ordered_owner_class <- function(x) {
  cls <- class(x)
  if(length(cls) == 0L) {
    return("ordered_sequence")
  }
  keep <- setdiff(
    cls,
    c(
      "ordered_sequence", "flexseq", "list",
      "FingerTree", "Deep", "Single", "Empty", "Digit", "Node"
    )
  )
  if(length(keep) > 0L) {
    return(keep[[1L]])
  }
  if(inherits(x, "interval_index")) {
    return("interval_index")
  }
  "ordered_sequence"
}

# Runtime: O(1).
.ft_stop_ordered_like <- function(x, fn_name, advice = "Use `insert()`.") {
  target <- .ft_ordered_owner_class(x)
  stop(sprintf("`%s()` is not supported for %s. %s", fn_name, target, advice))
}

# normalize constructor input to list without dropping names.
# Runtime: O(n), where n is number of constructor inputs.
.flexseq_input_list <- function(x) {
  if(is.list(x)) {
    return(x)
  }
  as.list(x)
}

# Runtime: O(1).
.ft_validate_drop_meta <- function(drop_meta) {
  if(!is.logical(drop_meta) || length(drop_meta) != 1L || is.na(drop_meta)) {
    stop("`drop_meta` must be TRUE or FALSE.")
  }
  isTRUE(drop_meta)
}

#' Construct a Persistent Flexible Sequence
#'
#' `flexseq(...)` creates an immutable sequence from `...`, preserving element
#' order and optional names, with efficient persistent updates.
#'
#' It is list-like in payload flexibility (any R object per element), but
#' sequence-oriented in API (`push_*`, `peek_*`, `pop_*`, indexing, split/concat).
#'
#' @param ... Sequence elements.
#' @return A `flexseq` object.
#' @details
#' `flexseq` is the base general-purpose structure in this package.
#' Specialized structures such as `priority_queue`, `ordered_sequence`, and
#' `interval_index` build on related internals but expose narrower semantics.
#'
#' `flexseq` operations are persistent: updates return new objects and do not
#' mutate prior versions.
#' @examples
#' x <- flexseq(1, 2, 3)
#' x
#'
#' y <- push_front(x, 0)
#' y
#' x  # unchanged
#'
#' named <- flexseq(a = 1, b = 2)
#' named
#' named[["a"]]
#' @seealso [as_flexseq()], [priority_queue()], [ordered_sequence()], [interval_index()]
#' @export
flexseq <- function(...) {
  .as_flexseq_build(list(...), monoids = NULL)
}

#' Internal builder dispatched by `as_flexseq()` methods.
#'
# Runtime: O(1) generic dispatch.
#' @noRd
.as_flexseq_build <- function(x, monoids = NULL) {
  UseMethod(".as_flexseq_build")
}

# Runtime: O(n) over element count via linear bulk tree construction.
.as_flexseq_build.default <- function(x, monoids = NULL) {
  t <- tree_from(x, monoids = monoids)
  .as_flexseq(t)
}

#' @method as_flexseq default
#' @export
# Runtime: O(n) over element count via linear bulk tree construction.
as_flexseq.default <- function(x) {
  .as_flexseq_build.default(x, monoids = NULL)
}

#' @method as_flexseq flexseq
#' @export
# Runtime: O(1).
as_flexseq.flexseq <- function(x) {
  x
}

#' Concatenate Sequences
#'
#' @method c flexseq
#' @param ... `flexseq` objects.
#' @param recursive Unused; must be `FALSE`.
#' @return A concatenated `flexseq`.
#' @details
#' `c()` is supported for `flexseq` and returns a new concatenated `flexseq`.
#'
#' For `priority_queue`, `ordered_sequence`, and `interval_index`, `c()` is not
#' supported because concatenation can violate structure-specific invariants.
#' Cast first with [as_flexseq()] when sequence-style concatenation is intended,
#' noting that this drops ordering and priority metadata.
#' @examples
#' x <- flexseq("a", "b")
#' y <- flexseq("c", "d")
#' c(x, y)
#'
#' q1 <- priority_queue("a", priorities = 2)
#' q2 <- priority_queue("b", priorities = 1)
#' try(c(q1, q2))
#' c(as_flexseq(q1), as_flexseq(q2))
#'
#' o1 <- ordered_sequence("a", keys = 1)
#' o2 <- ordered_sequence("b", keys = 2)
#' try(c(o1, o2))
#' @export
# Runtime: O(sum(n_i)) worst-case with monoid harmonization.
c.flexseq <- function(..., recursive = FALSE) {
  if(isTRUE(recursive)) {
    stop("`recursive = TRUE` is not supported for flexseq.")
  }
  xs <- list(...)
  if(length(xs) == 0L) {
    return(flexseq())
  }
  out <- xs[[1]]
  for(i in 2:length(xs)) {
    out <- concat_trees(out, xs[[i]])
  }
  .ft_restore_subclass(out, xs[[1]], context = "c()")
}

#' @export
#' @noRd
# Runtime: O(1).
c.priority_queue <- function(..., recursive = FALSE) {
  stop("`c()` is not supported for priority_queue. Cast first with `as_flexseq()`.")
}

#' Merge Two Sequences
#'
#' Returns a new `flexseq` containing all elements of `x` followed by all
#' elements of `y`. Thin wrapper over [c()] for API uniformity across the
#' package's merge methods; `c(x, y)` and `merge(x, y)` are equivalent for
#' `flexseq`.
#'
#' @method merge flexseq
#' @param x A `flexseq`.
#' @param y A `flexseq`.
#' @param ... Unused.
#' @return A new `flexseq`.
#' @details
#' For ordered types (`ordered_sequence`, `interval_index`), `merge()` performs
#' a proper sorted merge respecting keys/intervals — see [merge.ordered_sequence()]
#' and [merge.interval_index()]. For `priority_queue`, see
#' [merge.priority_queue()].
#' @examples
#' x <- flexseq("a", "b")
#' y <- flexseq("c", "d")
#' merge(x, y)
#' @export
# Runtime: O(log(min(m, n))) via concat_trees.
merge.flexseq <- function(x, y, ...) {
  c(x, y)
}

#' Sequence Length
#'
#' @method length flexseq
#' @param x A `flexseq`.
#' @return Number of elements in the sequence.
#' @details
#' Uses cached size metadata and runs in O(1).
#' @examples
#' x <- flexseq("a", "b")
#' length(x)
#'
#' length(flexseq())
#' @export
# Runtime: O(1) using cached `.size` measure.
length.flexseq <- function(x) {
  .ft_size(x)
}

#' Coerce a Sequence to Base List
#'
#' Returns elements in left-to-right sequence order.
#'
#' @method as.list flexseq
#' @param x A `flexseq`.
#' @param ... Unused.
#' @return A base R list of sequence elements.
#' @details
#' Returns payload elements in sequence order. If the sequence is fully named,
#' those names are preserved on the returned list.
#' @examples
#' x <- flexseq("a", "b", "c")
#' as.list(x)
#'
#' n <- flexseq(a = 1, b = 2)
#' as.list(n)
#' @export
# Runtime: O(n) over number of elements.
as.list.flexseq <- function(x, ...) {
  els <- .ft_to_list(x)
  n <- length(els)
  if(n == 0L) {
    return(list())
  }

  out <- vector("list", n)
  nms <- character(n)
  has_names <- FALSE
  for(i in seq_len(n)) {
    el <- els[[i]]
    out[[i]] <- .ft_strip_name(el)
    nm <- .ft_get_name(el)
    if(is.null(nm)) {
      nms[[i]] <- ""
    } else {
      nms[[i]] <- nm
      has_names <- TRUE
    }
  }
  if(has_names) {
    names(out) <- nms
  }
  out
}

#' Coerce a Sequence to an Atomic Vector
#'
#' Convenience wrapper around [base::unlist()] over [as.list()].
#'
#' @method unlist flexseq
#' @param x A `flexseq`.
#' @param recursive Passed through to [base::unlist()].
#' @param use.names Passed through to [base::unlist()].
#' @return An atomic vector built from [as.list.flexseq()].
#' @details
#' For `priority_queue`, this unwraps queue entries to payload items before
#' unlisting (equivalent to `unlist(as.list(x, drop_meta = TRUE), ...)`).
#'
#' Inherited by `ordered_sequence` and `interval_index` through the shared
#' class stack.
#' @examples
#' x <- flexseq(1, 2, 3)
#' unlist(x)
#'
#' q <- priority_queue("a", "b", priorities = c(2, 1))
#' unlist(q)
#' @export
# Runtime: O(n) over number of elements.
unlist.flexseq <- function(x, recursive = TRUE, use.names = TRUE) {
  if(inherits(x, "priority_queue")) {
    return(unlist(as.list(x, drop_meta = TRUE), recursive = recursive, use.names = use.names))
  }
  unlist(as.list(x), recursive = recursive, use.names = use.names)
}
