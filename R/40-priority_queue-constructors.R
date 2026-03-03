#SO

# Runtime: O(n) overall (entry normalization + linear sequence construction).
#' Build a Priority Queue from `x` and `priorities`
#'
#' Constructs a queue by pairing each element of `x` with the corresponding
#' value in `priorities`.
#'
#' @param x Elements to enqueue.
#' @param priorities Priorities with the same length as `x`.
#' @return A `priority_queue`.
#' @details
#' `x` is interpreted element-wise (via list coercion). Names on `x` are
#' preserved as queue element names.
#'
#' All priorities must be non-missing and mutually comparable.
#' @examples
#' x <- as_priority_queue(letters[1:4], priorities = c(3, 1, 2, 1))
#' x
#' peek_min(x)
#' peek_max(x)
#'
#' # Names are preserved
#' n <- as_priority_queue(setNames(as.list(1:3), c("a", "b", "c")), priorities = c(2, 1, 3))
#' n[["b"]]
#' @export
as_priority_queue <- function(x, priorities) {
  .as_priority_queue_build(x, priorities = priorities, monoids = NULL)
}

# Runtime: O(n) overall (entry normalization + linear sequence construction).
.as_priority_queue_build <- function(x, priorities, monoids = NULL) {
  x_list <- as.list(x)
  n <- length(x_list)

  p_list <- as.list(priorities)
  if(length(p_list) != n) {
    stop("`priorities` length must match elements length.")
  }

  entries <- vector("list", n)
  priority_type <- NULL
  for(i in seq_len(n)) {
    parsed <- .pq_make_entry(x_list[[i]], p_list[[i]], priority_type = priority_type)
    priority_type <- parsed$priority_type
    entries[[i]] <- parsed$entry
  }

  nm <- names(x)
  if(!is.null(nm) && length(nm) > 0L) {
    if(length(nm) != n) {
      stop("`names` length must match elements length.")
    }
    names(entries) <- nm
  }

  q <- .as_flexseq_build(entries, monoids = .pq_merge_monoids(monoids))
  .as_priority_queue(q, priority_type = priority_type)
}

# Runtime: O(n) overall (entry normalization + linear sequence construction).
#' Construct a Priority Queue
#'
#' Creates a `priority_queue` from elements in `...` and matching
#' `priorities`.
#'
#' @param ... Elements to enqueue.
#' @param priorities Priorities with the same length as `...`.
#' @return A `priority_queue`.
#' @details
#' Empty construction is supported: `priority_queue()` returns an empty queue.
#'
#' If elements are named, names are preserved for name-based reads.
#'
#' Queue operations are exposed through `insert()`, `peek_*()`, `pop_*()`,
#' and `fapply()`.
#' @examples
#' x <- priority_queue("a", "b", "c", priorities = c(2, 1, 2))
#' x
#' peek_min(x)
#'
#' empty_q <- priority_queue()
#' peek_min(empty_q)
#' @export
priority_queue <- function(..., priorities) {
  if(missing(priorities)) {
    priorities <- NULL
  }
  .priority_queue_build(..., priorities = priorities, monoids = NULL)
}

# Runtime: O(n) overall (entry normalization + linear sequence construction).
.priority_queue_build <- function(..., priorities = NULL, monoids = NULL) {
  xs <- list(...)
  n <- length(xs)

  if(n == 0L) {
    if(!is.null(priorities) && length(priorities) > 0L) {
      stop("`priorities` must be empty when no elements are supplied.")
    }
    return(.as_priority_queue(.as_flexseq_build(list(), monoids = .pq_merge_monoids(monoids)), priority_type = NULL))
  }

  if(is.null(priorities)) {
    stop("`priorities` is required when elements are supplied.")
  }

  .as_priority_queue_build(xs, priorities = priorities, monoids = monoids)
}
