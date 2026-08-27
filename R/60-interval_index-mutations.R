#SO

# Internal insert engine preserving interval ordering by start.
# **Inputs:** `x` interval_index; `entry` canonical entry; optional `endpoint_type`.
# **Outputs:** updated interval_index with inserted entry.
# **Used by:** insert.interval_index().
.ivx_insert_entry <- function(x, entry, endpoint_type = NULL) {
  ep <- if(is.null(endpoint_type)) .ivx_endpoint_type_state(x) else endpoint_type
  ms <- resolve_tree_monoids(x, required = TRUE)
  can_use_cpp_key_insert <- isTRUE(
    .ivx_supports_oms_key_type(ep) &&
      .ft_cpp_can_use(ms) &&
      !is.null(ms[[".oms_max_key"]])
  )

  out <- if(length(x) == 0L) {
    # First insert may need to upgrade required monoids once endpoint type is known.
    # Use one append path here; C++ ordered insert is kept for non-empty trees.
    base <- x
    if(.ivx_supports_oms_key_type(ep) && is.null(ms[[".oms_max_key"]])) {
      monoids0 <- attr(x, "monoids", exact = TRUE)
      user0 <- monoids0[setdiff(
        names(monoids0),
        c(".size", ".named_count", ".ivx_max_start", ".ivx_max_end", ".ivx_min_end", ".oms_max_key")
      )]
      ms0 <- .ivx_merge_monoids(if(length(user0) == 0L) NULL else user0, endpoint_type = ep)
      base <- empty_tree(monoids = ms0)
    }
    .ft_push_back_impl(base, entry, context = "insert()")
  } else if(can_use_cpp_key_insert) {
    .ft_cpp_oms_insert(x, entry, ms, ep)
  } else {
    s <- split_by_predicate(
      x,
      function(v) isTRUE(v$has) && .ivx_compare_scalar(v$start, entry$start, v$endpoint_type) > 0L,
      ".ivx_max_start"
    )
    left_plus <- .ft_push_back_impl(s$left, entry, context = "insert()")
    concat_trees(left_plus, s$right)
  }

  .ivx_wrap_like(x, out, endpoint_type = ep)
}

# Runtime: O(n) over tree size for any non-trivial update (rebind/recompute pass).
# Interval-specific add_monoids guard for reserved monoid names.
# **Inputs:** `t` interval_index-like tree; user `monoids`; scalar logical `overwrite`.
# **Outputs:** interval_index tree with merged monoids.
# **Used by:** public add_monoids() S3 dispatch.
#' @method add_monoids interval_index
#' @export
#' @noRd
add_monoids.interval_index <- function(t, monoids, overwrite = FALSE) {
  if(length(monoids) > 0L) {
    bad <- intersect(names(monoids), c(".size", ".named_count", ".ivx_max_start", ".ivx_max_end", ".ivx_min_end", ".oms_max_key"))
    if(length(bad) > 0L) {
      stop("Reserved monoid names cannot be supplied for interval_index: ", paste(bad, collapse = ", "))
    }
  }
  add_monoids.flexseq(t, monoids, overwrite = overwrite)
}

# Runtime: O(log n) near split point depth.
# Public insert method for interval_index.
# **Inputs:** `x` interval_index; payload `value`; scalar `start`/`end`; optional `name`.
# **Outputs:** updated interval_index.
# **Used by:** users/tests.
#' @method insert interval_index
#' @export
#' @noRd
insert.interval_index <- function(x, value, start, end, name = NULL, ...) {
  .ivx_assert_index(x)

  norm <- .ivx_normalize_interval(start, end, endpoint_type = .ivx_endpoint_type_state(x))
  entry <- .ivx_make_entry(value, norm$start, norm$end)

  if(!is.null(name)) {
    entry <- .ft_set_name(entry, name)
  }

  .ivx_insert_entry(x, entry, endpoint_type = norm$endpoint_type)
}
