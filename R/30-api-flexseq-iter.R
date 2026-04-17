#SO

#' Iterate over a `flexseq` (coro iterator)
#'
#' Returns a lazy iterator that yields payload elements left-to-right.
#' Use with [loop()] as the canonical iteration form:
#'
#' ```
#' loop(for (x in s) print(x))
#' ```
#'
#' @param x A `flexseq`.
#' @return A `coro` iterator function.
#' @details
#' Iteration uses repeated left-view (`viewL`) and is O(n) total, O(1) amortized
#' per step. The original `x` is not modified; the iterator holds a private
#' cursor over progressively-smaller tails.
#'
#' For named sequences, internal name metadata is stripped from yielded values
#' to match `peek_front(s)` semantics. Access names via [as.list()] when needed.
#'
#' Inherited by `ordered_sequence` and `interval_index`: for those subclasses
#' the yielded value is the unwrapped payload (keys / interval endpoints
#' dropped), in key-ascending / start-position order respectively. See
#' [as_iterator.priority_queue()] for the priority-order override.
#'
#' # Do not use plain `for` directly
#' Writing `for (x in s) ...` (without [loop()]) will not dispatch this method.
#' R's `for` walks the object's underlying list storage at the C level and
#' bypasses S3 `length`/`[[`, so it silently yields raw finger-tree internals
#' (Digit/Empty/Deep nodes) rather than sequence elements. Always wrap with
#' [loop()], or call [as.list()] first for an eager copy.
#' @examples
#' s <- flexseq("a", "b", "c")
#' loop(for (x in s) print(x))
#' @exportS3Method coro::as_iterator
as_iterator.flexseq <- function(x) {
  monoids <- attr(x, "monoids", exact = TRUE)
  if(is.null(monoids)) {
    stop("Tree has no monoids attribute.")
  }
  state <- x
  function() {
    if(length(state) == 0L) {
      return(coro::exhausted())
    }
    step <- viewL(state, monoids)
    state <<- step$rest
    .ft_unwrap_public_value(x, .ft_strip_name(step$value))
  }
}

#' Iterate over a `priority_queue` (coro iterator)
#'
#' Returns a lazy iterator that yields payload elements in priority-ascending
#' order. Use with [loop()]:
#'
#' ```
#' loop(for (x in pq) print(x))
#' ```
#'
#' @param x A `priority_queue`.
#' @return A `coro` iterator function.
#' @details
#' Traversal is driven by repeated [pop_min()]: each step is O(log n), so full
#' traversal is O(n log n). Ties within equal priorities are yielded in FIFO
#' insertion order (inherited from [pop_min()]).
#'
#' The original `x` is not modified; the iterator holds a private cursor and
#' partial iteration (e.g. via `break`) leaves the source intact.
#'
#' Each yielded value is the bare payload (matching [peek_min()]). Use
#' [fapply()] if your callback needs the priority alongside the value, or cast
#' with [as_flexseq()] for insertion-order iteration.
#' @examples
#' pq <- priority_queue("a", "b", "c", priorities = c(3, 1, 2))
#' loop(for (x in pq) print(x))  # "b", "c", "a"
#' @exportS3Method coro::as_iterator
as_iterator.priority_queue <- function(x) {
  state <- x
  function() {
    if(length(state) == 0L) {
      return(coro::exhausted())
    }
    step <- pop_min(state)
    state <<- step$remaining
    step$value
  }
}

#' Iterate over an iterator (re-exported from coro)
#'
#' Re-exported [coro::loop()]. Enables `for`-loop-style iteration over
#' `immutables` structures without needing to load `coro` separately.
#'
#' @param loop A `for` loop expression.
#' @return `NULL`, invisibly. Called for side effects.
#' @seealso [coro::loop()] for full documentation.
#' @examples
#' s <- flexseq(1, 2, 3)
#' loop(for (x in s) print(x))
#' @importFrom coro loop
#' @export
loop <- coro::loop
