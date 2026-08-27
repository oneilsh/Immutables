#SO

# Runtime: O(1).
# Central type/shape gate for public interval methods.
# **Inputs:** object `x`.
# **Outputs:** invisible TRUE on success; otherwise errors.
# **Used by:** indexing, query API, apply, print, methods.
.ivx_assert_index <- function(x) {
  if(!inherits(x, "interval_index") || !is_structural_node(x)) {
    stop("`x` must be an interval_index.")
  }
  invisible(TRUE)
}

# Runtime: O(1).
# Reads the canonical endpoint domain stored on an interval_index object.
# **Inputs:** `x` interval_index.
# **Outputs:** scalar character endpoint type or NULL.
# **Used by:** insert/query normalization and wrapper restoration.
.ivx_endpoint_type_state <- function(x) {
  attr(x, "ivx_endpoint_type", exact = TRUE)
}

# Runtime: O(1).
# Validates user-facing bound syntax; single source of truth for accepted forms.
# **Inputs:** scalar `bounds` string.
# **Outputs:** normalized bounds string.
# **Used by:** .as_interval_index(), .ivx_resolve_bounds().
.ivx_normalize_bounds <- function(bounds) {
  if(!is.character(bounds) || length(bounds) != 1L || is.na(bounds)) {
    stop("`bounds` must be one of: [), [], (), (].")
  }
  if(!(bounds %in% c("[)", "[]", "()", "(]"))) {
    stop("`bounds` must be one of: [), [], (), (].")
  }
  bounds
}

# Runtime: O(1).
# Decodes bounds string into booleans consumed by query spec builders.
# **Inputs:** scalar `bounds` string.
# **Outputs:** list(include_start=<lgl>, include_end=<lgl>).
# **Used by:** .ivx_spec_* query specification helpers.
.ivx_bounds_flags <- function(bounds) {
  list(
    include_start = identical(substr(bounds, 1L, 1L), "["),
    include_end = identical(substr(bounds, 2L, 2L), "]")
  )
}

# Runtime: O(1).
# Normalizes one endpoint value (scalar, non-missing, compatible type, orderable).
# **Inputs:** endpoint `value`; scalar string `arg_name`; optional scalar `endpoint_type`.
# **Outputs:** list(value=<scalar>, endpoint_type=<scalar character>).
# **Used by:** point-query normalization and interval normalization.
.ivx_normalize_endpoint <- function(value, arg_name, endpoint_type = NULL) {
  if(length(value) != 1L) {
    stop(sprintf("`%s` must be a scalar value.", arg_name))
  }

  na_flag <- suppressWarnings(tryCatch(is.na(value), error = function(e) FALSE))
  if(is.logical(na_flag) && length(na_flag) == 1L && isTRUE(na_flag)) {
    stop(sprintf("`%s` must be non-missing.", arg_name))
  }

  vt <- .ivx_endpoint_type(value)
  if(!is.null(endpoint_type) && !identical(endpoint_type, vt)) {
    stop("Incompatible endpoint type for this interval_index.")
  }

  # Validate orderability for endpoint objects using base Ops.
  .ivx_compare_scalar(value, value, vt)

  list(value = value, endpoint_type = vt)
}

# Runtime: O(1).
# Normalizes start/end pair and enforces start <= end in one place.
# **Inputs:** scalar `start`,`end`; optional scalar `endpoint_type`; arg-name labels.
# **Outputs:** list(start=<scalar>, end=<scalar>, endpoint_type=<scalar character>).
# **Used by:** constructors, insert, relation-query argument validation, entry parse.
.ivx_normalize_interval <- function(start, end, endpoint_type = NULL, start_name = "start", end_name = "end") {
  ns <- .ivx_normalize_endpoint(start, start_name, endpoint_type = endpoint_type)
  ne <- .ivx_normalize_endpoint(end, end_name, endpoint_type = ns$endpoint_type)

  if(.ivx_compare_scalar(ns$value, ne$value, ns$endpoint_type) > 0L) {
    stop("`start` must be <= `end`.")
  }

  list(start = ns$value, end = ne$value, endpoint_type = ns$endpoint_type)
}

# Structural wrapper: attaches interval classes + endpoint/bounds attrs.
# **Inputs:** structural tree `x`; optional scalar `endpoint_type`; scalar `bounds`.
# **Outputs:** interval_index wrapper object.
# **Used by:** constructors and restoration/wrap helpers.
.as_interval_index <- function(x, endpoint_type = NULL, bounds = "[)") {
  if(!is_structural_node(x)) {
    stop("Expected a structural tree node.")
  }

  class(x) <- unique(c("interval_index", "ordered_sequence", "flexseq", setdiff(class(x), "list")))
  attr(x, "ivx_endpoint_type") <- endpoint_type
  attr(x, "ivx_bounds") <- .ivx_normalize_bounds(bounds)

  # Keep ordered_sequence key type available only for primitive key classes.
  attr(x, "oms_key_type") <- if(is.null(endpoint_type) || !(endpoint_type %in% c("numeric", "character", "logical"))) {
    NULL
  } else {
    endpoint_type
  }

  x
}

# Runtime: O(1).
# Re-wraps a structural tree with interval metadata inherited from a template.
# **Inputs:** `template` interval_index; structural `tree`; optional endpoint_type/bounds overrides.
# **Outputs:** interval_index wrapper of `tree`.
# **Used by:** mutation/query rebuild paths and empty-like construction.
.ivx_wrap_like <- function(template, tree, endpoint_type = NULL, bounds = NULL) {
  ep <- if(is.null(endpoint_type)) .ivx_endpoint_type_state(template) else endpoint_type
  b <- .ivx_resolve_bounds(template, bounds)
  .as_interval_index(tree, endpoint_type = ep, bounds = b)
}

# Runtime: O(1).
# Validates/canonicalizes one stored entry payload.
# **Inputs:** entry object `entry`; scalar `context`; optional scalar `endpoint_type`.
# **Outputs:** list(entry=<canonical entry>, endpoint_type=<resolved endpoint type>).
# **Used by:** full-tree validation during subclass restore.
.ivx_parse_entry <- function(entry, context = "interval_index", endpoint_type = NULL) {
  if(!is.list(entry)) {
    stop(context, " entries must be named lists with fields: value, start, end (optional: key).")
  }

  nm <- names(entry)
  if(is.null(nm) || any(is.na(nm)) || any(nm == "")) {
    stop(context, " entries must be named lists with fields: value, start, end (optional: key).")
  }
  if(anyDuplicated(nm) > 0L) {
    stop(context, " entry fields must be unique.")
  }

  bad <- setdiff(nm, c("value", "start", "end", "key"))
  if(length(bad) > 0L) {
    stop(context, " entry contains unsupported field(s): ", paste(bad, collapse = ", "))
  }
  if(!("value" %in% nm) || !("start" %in% nm) || !("end" %in% nm)) {
    stop(context, " entries must include `value`, `start`, and `end`.")
  }

  norm <- .ivx_normalize_interval(entry[["start"]], entry[["end"]], endpoint_type = endpoint_type)

  if("key" %in% nm) {
    # Backward/interop tolerance: accept explicit `key`, but require it to match
    # `start` so interval key semantics stay canonical.
    if(.ivx_compare_scalar(entry[["key"]], norm$start, norm$endpoint_type) != 0L) {
      stop(context, " entry `key` must equal `start`.")
    }
  }

  list(
    entry = .ivx_make_entry(entry[["value"]], norm$start, norm$end),
    endpoint_type = norm$endpoint_type
  )
}

# Runtime: O(1) metadata restoration/wrap.
# Interval subclass restoration for trees produced by shared flexseq ops.
# **Inputs:** structural tree `x`; optional `template` interval_index; scalar `context`.
# **Outputs:** interval_index wrapper preserving endpoint_type/bounds metadata.
# **Used by:** .ft_restore_subclass() in core flexseq API.
.ivx_restore_tree <- function(x, template = NULL, context = "interval_index") {
  endpoint_type <- if(is.null(template)) NULL else .ivx_endpoint_type_state(template)
  bounds <- if(is.null(template)) "[)" else .ivx_resolve_bounds(template, NULL)
  .as_interval_index(x, endpoint_type = endpoint_type, bounds = bounds)
}

# Fast structural-node classifier for internal traversals.
# **Inputs:** `node` object.
# **Outputs:** scalar logical structural classification.
# **Used by:** .ivx_entries() and query-engine subtree size/traversal logic.
.ivx_is_structural_fast <- function(node) {
  cls <- class(node)
  !is.null(cls) && any(cls %in% c("Empty", "Single", "Deep", "Digit", "Node"))
}

# Runtime: O(n).
# Materializes interval entries in left-to-right order with preallocation.
# **Inputs:** `x` interval_index/structural tree.
# **Outputs:** list of interval entry payload records.
# **Used by:** interval bounds/query/apply paths and query-engine prune fallback.
.ivx_entries <- function(x) {
  ms <- attr(x, "measures", exact = TRUE)
  n <- if(!is.null(ms) && !is.null(ms[[".size"]])) {
    as.integer(ms[[".size"]])
  } else {
    as.integer(node_measure(x, ".size"))
  }

  if(is.na(n) || n <= 0L) {
    return(list())
  }

  st <- new.env(parent = emptyenv())
  st$out <- vector("list", n)
  st$pos <- 1L

  fill <- function(node) {
    if(!.ivx_is_structural_fast(node)) {
      st$out[[st$pos]] <- node
      st$pos <- st$pos + 1L
      return(invisible(NULL))
    }

    if(inherits(node, "Empty")) {
      return(invisible(NULL))
    }
    if(inherits(node, "Single")) {
      fill(.subset2(node, 1L))
      return(invisible(NULL))
    }
    if(inherits(node, "Deep")) {
      fill(.subset2(node, "prefix"))
      fill(.subset2(node, "middle"))
      fill(.subset2(node, "suffix"))
      return(invisible(NULL))
    }

    for(el in node) {
      fill(el)
    }
    invisible(NULL)
  }

  fill(x)
  if(!identical(st$pos, as.integer(n + 1L))) {
    return(.ft_to_list(x))
  }
  st$out
}

# Cache of empty interval_index instances keyed by (endpoint_type, bounds,
# monoid_names). Hot tree-traversal paths call .ivx_empty_like() many times
# per query (e.g. partition early-return branches); recomputing the empty
# tree + wrapping it each call is the dominant per-call constant. The cache
# returns a precomputed empty for the common case (matching configuration)
# and falls through to the slow path otherwise.
.ivx_empty_like_cache <- new.env(parent = emptyenv())

# Runtime: O(1) on cache hit; otherwise builds an empty + wraps once.
# Builds an empty interval_index preserving class/attrs/monoids from template.
# **Inputs:** `template` interval_index.
# **Outputs:** empty interval_index with template metadata.
# **Used by:** query miss/slice helpers and split partitioning.
.ivx_empty_like <- function(template) {
  ep <- attr(template, "ivx_endpoint_type", exact = TRUE)
  b  <- attr(template, "ivx_bounds", exact = TRUE)
  ms <- attr(template, "monoids", exact = TRUE)
  if(!is.null(ms)) {
    key <- paste0(
      if(is.null(ep)) "_" else ep, "|",
      if(is.null(b))  "_" else b,  "|",
      paste(names(ms), collapse = ",")
    )
    cached <- .ivx_empty_like_cache[[key]]
    if(!is.null(cached)) {
      return(cached)
    }
    empty <- .ivx_wrap_like(template, empty_tree(monoids = ms))
    .ivx_empty_like_cache[[key]] <- empty
    return(empty)
  }
  # Fallback (no monoids resolvable): preserve original behavior, error if
  # required is not met.
  ms <- resolve_tree_monoids(template, required = TRUE)
  .ivx_wrap_like(template, empty_tree(monoids = ms))
}

# Runtime: O(1).
# Resolves effective bounds for an operation (override or object default).
# **Inputs:** `x` interval_index; optional scalar `bounds` override.
# **Outputs:** scalar bounds string.
# **Used by:** query API entrypoints, print header, and wrapper restoration.
.ivx_resolve_bounds <- function(x, bounds = NULL) {
  if(!is.null(bounds)) {
    return(.ivx_normalize_bounds(bounds))
  }
  b <- attr(x, "ivx_bounds", exact = TRUE)
  if(is.null(b)) "[)" else b
}
