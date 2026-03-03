#SO

# Applies a payload transform across interval entries while preserving interval
# coordinates and names.
# **Inputs:**
#
# - `x`: interval_index.
# - `f`: function(item, start, end, name, ...) -> new item.
# - `...`: forwarded to `f`.
# - `preserve_custom_monoids`: scalar logical.
# **Outputs:** interval_index with transformed payload items.
# **Used by:** fapply.interval_index().
.ivx_apply_impl <- function(x, f, ..., preserve_custom_monoids = TRUE) {
  .ivx_assert_index(x)
  if(!is.function(f)) {
    stop("`FUN` must be a function.")
  }
  if(!is.logical(preserve_custom_monoids) || length(preserve_custom_monoids) != 1L || is.na(preserve_custom_monoids)) {
    stop("`preserve_custom_monoids` must be TRUE or FALSE.")
  }

  entries <- .ivx_entries(x)
  n <- length(entries)
  if(n == 0L) {
    return(x)
  }

  out_entries <- vector("list", n)

  for(i in seq_len(n)) {
    e <- entries[[i]]
    nm <- attr(e, "ft_name", exact = TRUE)
    if(
      is.null(nm) ||
      length(nm) == 0L ||
      !is.character(nm) ||
      length(nm) != 1L ||
      is.na(nm) ||
      !nzchar(nm)
    ) {
      nm <- .ft_get_name(e)
    }
    cur_name <- if(is.null(nm)) "" else nm

    item2 <- f(e$item, e$start, e$end, cur_name, ...)
    entry2 <- .ivx_make_entry(item2, e$start, e$end)
    out_entries[[i]] <- .ft_set_name(entry2, nm)
  }

  ms <- if(isTRUE(preserve_custom_monoids)) {
    resolve_tree_monoids(x, required = TRUE)
  } else {
    .ivx_merge_monoids(NULL, endpoint_type = .ivx_endpoint_type_state(x))
  }
  out_tree <- .ivx_tree_from_ordered_entries(out_entries, ms)
  .ivx_wrap_like(x, out_tree)
}

# Runtime: O(n) from traversal + ordered bulk rebuild.
# S3 fapply method for interval_index.
# **Inputs:** `X` interval_index; `FUN` transform function; `...`; scalar logical
# `preserve_custom_monoids`.
# **Outputs:** interval_index with transformed payload items.
# **Used by:** public `fapply()` generic dispatch.
#' Apply a Function over Interval Index Entries
#'
#' Applies `FUN` to each entry payload and returns a new `interval_index`.
#'
#' @method fapply interval_index
#' @param X An `interval_index`.
#' @param FUN Function of `(item, start, end, name, ...)` returning the new
#'   payload value.
#' @param preserve_custom_monoids Logical scalar. If `TRUE` (default), preserve
#'   custom added monoids; if `FALSE`, keep only required built-in monoids.
#' @param ... Additional arguments passed to `FUN`.
#' @return A new `interval_index` with transformed payload values.
#' @details
#' Interval coordinates (`start`, `end`) and entry names are not changed by
#' `fapply()`.
#' @examples
#' ix <- interval_index(
#'   one = "a", two = "b", three = "c",
#'   start = c(1, 3, 5), end = c(2, 4, 6)
#' )
#'
#' ix2 <- fapply(ix, function(item, start, end, name) toupper(item))
#' as.list(ix2)
#'
#' # Extra arguments are forwarded to FUN
#' ix3 <- fapply(ix, function(item, start, end, name, suffix) paste0(item, suffix), suffix = "!")
#' as.list(ix3)
#' @export
fapply.interval_index <- function(X, FUN, ..., preserve_custom_monoids = TRUE) {
  if(!is.function(FUN)) {
    stop("`FUN` must be a function.")
  }
  .ivx_apply_impl(X, FUN, ..., preserve_custom_monoids = preserve_custom_monoids)
}
