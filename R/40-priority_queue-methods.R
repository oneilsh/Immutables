#SO

#' @method as_flexseq priority_queue
#' @export
# Runtime: O(n) from list materialization + linear rebuild.
as_flexseq.priority_queue <- function(x) {
  entries <- as.list(x, drop_meta = TRUE)
  .as_flexseq_build.default(entries, monoids = NULL)
}

#' Coerce Priority Queue to List
#'
#' Returns queue entries as a plain list of records with fields `value` and
#' `priority`, in queue sequence order.
#'
#' @method as.list priority_queue
#' @param x A `priority_queue`.
#' @param ... Unused.
#' @param drop_meta Logical scalar. When `FALSE` (default), returns full queue
#'   entry records (`value` + `priority`). When `TRUE`, returns payload values
#'   only.
#' @return A plain list of queue entry records (`drop_meta = FALSE`) or payload
#'   values (`drop_meta = TRUE`).
#' @details
#' Each returned entry is a record with fields `value` and `priority`.
#' Entry names (when present) are preserved on the returned list.
#' @examples
#' q <- priority_queue("a", "b", priorities = c(2, 1))
#' as.list(q)
#' as.list(q, drop_meta = TRUE)
#' @export
# Runtime: O(n).
as.list.priority_queue <- function(x, ..., drop_meta = FALSE) {
  .pq_assert_queue(x)
  drop_flag <- .ft_validate_drop_meta(drop_meta)
  entries <- as.list.flexseq(x, ...)
  if(!drop_flag) {
    return(entries)
  }

  values <- lapply(entries, function(e) e$value)
  names(values) <- names(entries)
  values
}

#' Plot a Priority Queue Tree
#'
#' @method plot priority_queue
#' @param x A `priority_queue`.
#' @param ... Passed to the internal tree plotting routine.
#' @details
#' Visualizes the internal finger-tree structure backing the queue.
#' @examples
#' q <- priority_queue("a", "b", "c", priorities = c(2, 1, 3))
#' plot(q)
#' @export
# Runtime: O(n) to build plot graph data.
plot.priority_queue <- function(x, ...) {
  plot.flexseq(x, ...)
}

#' Priority Queue Length
#'
#' @method length priority_queue
#' @param x A `priority_queue`.
#' @return Integer length.
#' @details
#' Uses cached size metadata and runs in O(1).
#' @examples
#' q <- priority_queue("a", "b", priorities = c(2, 1))
#' length(q)
#'
#' length(priority_queue())
#' @export
length.priority_queue <- function(x) {
  as.integer(node_measure(x, ".size"))
}
