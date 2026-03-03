#SO

#' Indexing for Priority Queues
#'
#' Name-based indexing is supported for reads only. Positional indexing and all
#' replacement indexing are intentionally blocked to preserve queue-first UX.
#'
#' @name sub-.priority_queue
#' @param x A `priority_queue`.
#' @param i Index input. For reads, must be a character name (scalar for `[[`).
#' @param value Replacement value (unsupported).
#' @param ... Unused.
#' @return For `$`/`[[`/`[`: queue payload values or queue subsets by name.
#'   Replacement forms always error.
#' @details
#' `priority_queue` supports name-based read indexing only.
#'
#' - `[`: character vector of names, returns a `priority_queue` subset.
#' - `[[` and `$`: scalar name, return the payload value.
#' - Positional indexing and all replacement indexing forms are unsupported.
#' @examples
#' q <- priority_queue(a = "task-a", b = "task-b", priorities = c(2, 1))
#'
#' q["a"]
#' q[["b"]]
#' q$b
#'
#' try(q[1])
#' try(q$a <- "updated")
NULL

# Runtime: O(k * n_lookup) for short name queries; O(n + k) in map-backed paths.
#' @rdname sub-.priority_queue
#' @method [ priority_queue
#' @export
`[.priority_queue` <- function(x, i, ...) {
  if(missing(i)) {
    return(x)
  }
  if(!is.character(i)) {
    stop("`[.priority_queue` supports character name indexing only. Cast first with `as_flexseq()`.")
  }
  `[.flexseq`(x, i, ...)
}

# Runtime: O(n_lookup) single name lookup + O(log n) element fetch.
#' @rdname sub-.priority_queue
#' @method [[ priority_queue
#' @export
`[[.priority_queue` <- function(x, i, ...) {
  if(!(is.character(i) && length(i) == 1L && !is.na(i))) {
    stop("`[[.priority_queue` supports scalar character names only. Cast first with `as_flexseq()`.")
  }
  entry <- `[[.flexseq`(x, i, ...)
  if(!is.list(entry) || !("item" %in% names(entry))) {
    stop("Malformed priority_queue entry.")
  }
  entry$item
}

# Runtime: O(1).
#' @rdname sub-.priority_queue
#' @method [<- priority_queue
#' @export
`[<-.priority_queue` <- function(x, i, value) {
  stop("`[<-` is not supported for priority_queue. Cast first with `as_flexseq()`.")
}

# Runtime: O(1).
#' @rdname sub-.priority_queue
#' @method [[<- priority_queue
#' @export
`[[<-.priority_queue` <- function(x, i, value) {
  stop("`[[<-` is not supported for priority_queue. Cast first with `as_flexseq()`.")
}

# Runtime: O(n_lookup) single name lookup + O(log n) element fetch.
#' @rdname sub-.priority_queue
#' @method $ priority_queue
#' @param name Element name (for `$` and `$<-`).
#' @export
`$.priority_queue` <- function(x, name) {
  nm <- .ft_dollar_name(substitute(name))
  `[[.priority_queue`(x, nm)
}

# Runtime: O(1).
#' @rdname sub-.priority_queue
#' @method $<- priority_queue
#' @export
`$<-.priority_queue` <- function(x, name, value) {
  stop("`$<-` is not supported for priority_queue. Cast first with `as_flexseq()`.")
}
