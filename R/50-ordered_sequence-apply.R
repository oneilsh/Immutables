#SO

# Runtime: O(n) from traversal + ordered bulk rebuild.
.oms_apply_impl <- function(x, f, ..., preserve_custom_monoids = TRUE) {
  .oms_assert_set(x)
  if(!is.function(f)) {
    stop("`FUN` must be a function.")
  }
  if(!is.logical(preserve_custom_monoids) || length(preserve_custom_monoids) != 1L || is.na(preserve_custom_monoids)) {
    stop("`preserve_custom_monoids` must be TRUE or FALSE.")
  }

  entries <- as.list.flexseq(x)
  n <- length(entries)
  if(n == 0L) {
    return(x)
  }

  out <- vector("list", n)
  out_names <- if(is.null(names(entries))) rep("", n) else names(entries)

  for(i in seq_len(n)) {
    e <- entries[[i]]
    cur_name <- out_names[[i]]
    base_args <- list(e$value, e$key)
    dot_args <- list(...)
    call_args <- if(.ft_fun_accepts_n_positional(f, 3L)) {
      c(base_args, list(cur_name), dot_args)
    } else {
      c(base_args, dot_args)
    }
    item2 <- do.call(f, call_args)
    out[[i]] <- .oms_make_entry(value = item2, key_value = e$key)
  }

  if(any(out_names != "")) {
    names(out) <- out_names
  }

  ms <- if(isTRUE(preserve_custom_monoids)) {
    attr(x, "monoids", exact = TRUE)
  } else {
    .oms_merge_monoids(NULL)
  }
  out_tree <- .oms_tree_from_ordered_entries(out, ms)
  .ord_wrap_like(x, out_tree, key_type = .oms_key_type_state(x))
}

#' @method fapply ordered_sequence
#' @export
#' @noRd
fapply.ordered_sequence <- function(X, FUN, ..., preserve_custom_monoids = TRUE) {
  if(!is.function(FUN)) {
    stop("`FUN` must be a function.")
  }
  .oms_apply_impl(X, FUN, ..., preserve_custom_monoids = preserve_custom_monoids)
}
