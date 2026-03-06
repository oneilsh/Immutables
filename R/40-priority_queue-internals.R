#SO

# Runtime: O(1).
.pq_priority_type_state <- function(x) {
  attr(x, "pq_priority_type", exact = TRUE)
}

# Runtime: O(1).
# Normalize/validate one priority scalar and enforce queue-wide type consistency.
# Used by: .pq_make_entry() for constructors and insert paths.
.pq_resolve_priority <- function(priority, priority_type = NULL, arg_name = "priority") {
  # 1) Normalize to package canonical scalar representation.
  norm <- .ft_normalize_scalar_orderable(priority, arg_name = arg_name)

  # 2) Enforce single priority domain for a queue.
  resolved_type <- if(is.null(priority_type)) {
    norm$value_type
  } else if(identical(priority_type, norm$value_type)) {
    priority_type
  } else {
    stop("Incompatible priority type for this priority_queue.")
  }

  list(priority = norm$value, priority_type = resolved_type)
}

# Runtime: O(1).
# Assert queue class/shape at API boundaries.
# Used by: queue ops, print, and apply entry points.
.pq_assert_queue <- function(q) {
  if(!inherits(q, "priority_queue") || !is_structural_node(q)) {
    stop("`q` must be a priority_queue.")
  }
  invisible(TRUE)
}

# Runtime: O(1).
# Build one canonical entry (`list(item, priority)` + optional name) while
# threading the queue priority_type invariant.
# Used by: constructors and insert paths.
.pq_make_entry <- function(item, priority, priority_type = NULL, name = NULL) {
  resolved <- .pq_resolve_priority(priority, priority_type = priority_type)
  out <- list(item = item, priority = resolved$priority)
  list(
    entry = .ft_set_name(out, name),
    priority_type = resolved$priority_type
  )
}

# Runtime: O(1) under fixed monoid set.
# Merge user monoids with required queue monoids and reject reserved-name writes.
# Used by: constructors and fapply rebuild paths.
.pq_merge_monoids <- function(monoids = NULL) {
  user <- if(is.null(monoids)) list() else monoids
  if(length(user) > 0L) {
    bad <- intersect(names(user), c(".size", ".named_count", ".pq_min", ".pq_max"))
    if(length(bad) > 0L) {
      stop(paste0("Reserved monoid names cannot be supplied for priority queues: ", paste(bad, collapse = ", ")))
    }
  }
  c(user, .pq_required_monoids())
}

# Runtime: O(1).
# Attach class + PQ metadata to a structural tree.
# Used by: constructors and .pq_wrap_like().
.as_priority_queue <- function(x, priority_type = NULL) {
  if(!is_structural_node(x)) {
    stop("Expected a structural tree node.")
  }
  class(x) <- unique(c("priority_queue", "flexseq", setdiff(class(x), "list")))
  attr(x, "pq_next_seq") <- NULL
  attr(x, "pq_priority_type") <- priority_type
  x
}

# Runtime: O(1).
# Rewrap a newly-built tree using queue metadata from a template queue.
# Used by: insert/pop/apply/print helpers after structural operations.
.pq_wrap_like <- function(template, tree, priority_type = NULL) {
  resolved_type <- if(is.null(priority_type)) .pq_priority_type_state(template) else priority_type
  .as_priority_queue(tree, priority_type = resolved_type)
}
