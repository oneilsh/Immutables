#SO

# Runtime: O(1).
.oms_assert_set <- function(x) {
  if(!inherits(x, "ordered_sequence") || !is_structural_node(x)) {
    stop("`x` must be an ordered_sequence.")
  }
  invisible(TRUE)
}

# Runtime: O(1).
.oms_key_type_state <- function(x) {
  attr(x, "oms_key_type", exact = TRUE)
}

# Runtime: O(1).
.as_ordered_sequence <- function(x, key_type) {
  if(!is_structural_node(x)) {
    stop("Expected a structural tree node.")
  }
  class(x) <- unique(c("ordered_sequence", "flexseq", setdiff(class(x), "list")))
  attr(x, "oms_key_type") <- key_type
  x
}

# Runtime: O(1).
.ord_wrap_like <- function(template, tree, key_type = NULL) {
  resolved_key_type <- if(is.null(key_type)) .oms_key_type_state(template) else key_type
  .as_ordered_sequence(tree, key_type = resolved_key_type)
}

# Runtime: O(1).
.oms_validate_key_type <- function(oms_key_type, new_key_type) {
  if(is.null(oms_key_type)) {
    return(new_key_type)
  }
  if(!identical(oms_key_type, new_key_type)) {
    stop("Incompatible key type for this ordered_sequence.")
  }
  oms_key_type
}

# Runtime: O(1).
.oms_empty_tree_like <- function(template) {
  ms <- attr(template, "monoids", exact = TRUE)
  .as_flexseq(measured_empty(ms))
}

# Runtime: O(1).
.oms_coerce_lgl_scalar <- function(v, arg_name) {
  if(!is.logical(v) || length(v) != 1L || is.na(v)) {
    stop(sprintf("`%s` must be TRUE or FALSE.", arg_name))
  }
  isTRUE(v)
}

# Runtime: O(n) in number of selected entries.
.oms_extract_items <- function(entries) {
  lapply(entries, function(e) e$value)
}
