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

#' Plot a Sequence Tree
#'
#' @method plot flexseq
#' @param x A `flexseq` (or subclass).
#' @param ... Passed to the internal tree plotting routine. The most useful
#'   arguments are `vertex.size`, `edge.width`, `label_edges`, `title`, and
#'   `node_label` (see below). Remaining `...` is passed to
#'   `igraph::plot.igraph`.
#' @details
#' Visualizes the internal finger-tree structure, not a value-level chart.
#' Requires the `igraph` package to be installed (listed in Suggests).
#'
#' `node_label` controls vertex labels. Presets:
#' * `"value"` (default) — payload for elements, blank for structural nodes.
#' * `"type"` — node class (`Element`, `Digit`, `Deep`, `Node2`, `Node3`,
#'   `Single`, `Empty`).
#' * `"both"` — `type` and `value` on separate lines.
#' * `"none"` — no labels.
#'
#' Alternatively, `node_label` accepts a function `function(node)` returning a
#' single character string per vertex. The `node` list has fields:
#' * `id` — internal graph vertex id (string).
#' * `type` — same values as the `"type"` preset.
#' * `label` — the default label (payload for elements, `""` for structural).
#' * `measures` — a named list of accumulated monoid values for the subtree
#'   rooted at this node. For structural nodes these are the cached values;
#'   for element leaves, each entry is the monoid's `measure()` applied to
#'   the leaf entry (so `.size` is 1, and any custom `sum`-like monoid
#'   equals the leaf's own contribution). Keys are monoid names such as
#'   `.size`, `.named_count`, or any custom name added via [add_monoids()].
#' * `element` — for element nodes, the raw leaf entry. Shape depends on the
#'   structure type (see [measure_monoid()] for the entry contract). `NULL`
#'   for structural nodes.
#'
#' Measure values are exposed as-is, including list-valued measures (e.g. the
#' built-in `.pq_min` on `priority_queue` is `list(has, priority)`).
#'
#' @examples
#' x <- flexseq("a", "b", "c")
#' plot(x)
#'
#' \dontrun{
#' # Label every node with its subtree size (leaves contribute 1).
#' plot(as_flexseq(1:10), node_label = function(node) {
#'   paste0(node$type, "\n.size=", node$measures$.size)
#' })
#'
#' # Custom monoid: sum of numeric payloads. Structural nodes show the
#' # subtree total; leaves show their own contribution.
#' sum_monoid <- measure_monoid(`+`, 0, function(el) el)
#' xs <- add_monoids(as_flexseq(c(3, 1, 4, 1, 5, 9, 2, 6)),
#'                   list(sum = sum_monoid))
#' plot(xs, node_label = function(node) {
#'   if(node$type == "Element") sprintf("%g\nΣ=%g", node$element, node$measures$sum)
#'   else sprintf("%s\nΣ=%g", node$type, node$measures$sum)
#' })
#'
#' # List-valued built-in measure: priority_queue's .pq_min tracks the min
#' # priority seen in a subtree as list(has, priority). Unpack in the label.
#' pq <- priority_queue("task-a", "task-b", "task-c",
#'                      priorities = c(5, 1, 3))
#' plot(pq, node_label = function(node) {
#'   m <- node$measures$.pq_min
#'   if(node$type == "Element") {
#'     sprintf("%s\np=%g", node$element$value, node$element$priority)
#'   } else if(isTRUE(m$has)) {
#'     sprintf("%s\nmin=%g", node$type, m$priority)
#'   } else {
#'     node$type
#'   }
#' })
#' }
#' @export
# Runtime: O(n) to build plot graph data.
plot.flexseq <- function(x, ...) {
  plot_structure(x, ...)
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
#' @param s A `flexseq`.
#' @param ... Passed through to [base::unlist()].
#' @return An atomic vector built from [as.list.flexseq()].
#' @details
#' For `priority_queue`, this unwraps queue entries to payload items before
#' unlisting (equivalent to `unlist(as.list(s, drop_meta = TRUE), ...)`).
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
unlist.flexseq <- function(s, ...) {
  if(inherits(s, "priority_queue")) {
    return(unlist(as.list(s, drop_meta = TRUE), ...))
  }
  unlist(as.list(s), ...)
}
