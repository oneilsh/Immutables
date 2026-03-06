#SO

# Runtime: O(1).
# Determines endpoint scalar domain tag.
# **Inputs:** scalar endpoint `v`.
# **Outputs:** scalar character domain tag.
# **Used by:** endpoint normalization and monoid measure functions.
.ivx_endpoint_type <- function(v) {
  .ft_scalar_domain(v)
}

# Runtime: O(1).
# Safe scalar comparator with defensive error messaging.
# **Inputs:** scalar `a`,`b`; optional `endpoint_type`.
# **Outputs:** integer in {-1,0,1}.
# **Used by:** normalization and fallback relation predicates.
.ivx_compare_scalar <- function(a, b, endpoint_type = NULL) {
  .ft_scalar_compare(
    a,
    b,
    error_message = "Interval endpoints must support scalar ordering with `<` and `>`."
  )
}

# Runtime: O(1).
# Checks whether endpoint domain can use fast comparator branches.
# **Inputs:** scalar character `endpoint_type`.
# **Outputs:** scalar logical.
# **Used by:** query spec leaf matcher selection.
.ivx_is_fast_endpoint_type <- function(endpoint_type) {
  .ft_scalar_is_fast_domain(endpoint_type)
}

# Runtime: O(1).
# Fast scalar comparator for known fast scalar domains.
# **Inputs:** scalar `a`,`b`; optional `endpoint_type`.
# **Outputs:** integer in {-1,0,1}.
# **Used by:** monoid reducers and bound queries.
.ivx_compare_scalar_fast <- function(a, b, endpoint_type = NULL) {
  .ft_scalar_compare_fast(
    a,
    b,
    domain = endpoint_type,
    error_message = "Interval endpoints must support scalar ordering with `<` and `>`."
  )
}

# Runtime: O(1).
# Monoid reducer selecting max `start` summary.
# **Inputs:** monoid state lists `a`,`b`.
# **Outputs:** monoid state list with greatest start.
# **Used by:** .ivx_max_start_monoid().
.ivx_choose_max_start <- function(a, b) {
  if(!isTRUE(a$has)) {
    return(b)
  }
  if(!isTRUE(b$has)) {
    return(a)
  }
  if(!identical(a$endpoint_type, b$endpoint_type)) {
    stop("Incompatible endpoint types encountered in interval_index measures.")
  }
  cmp <- .ivx_compare_scalar_fast(a$start, b$start, endpoint_type = a$endpoint_type)
  if(cmp >= 0L) a else b
}

# Runtime: O(1).
# Measure monoid for subtree max start endpoint.
# **Inputs:** none.
# **Outputs:** MeasureMonoid object.
# **Used by:** .ivx_merge_monoids() required set.
.ivx_max_start_monoid <- function() {
  measure_monoid(
    .ivx_choose_max_start,
    list(has = FALSE, start = NULL, endpoint_type = NULL),
    function(el) {
      list(
        has = TRUE,
        start = el$start,
        endpoint_type = .ivx_endpoint_type(el$start)
      )
    }
  )
}

# Runtime: O(1).
# Monoid reducer selecting max `end` summary.
# **Inputs:** monoid state lists `a`,`b`.
# **Outputs:** monoid state list with greatest end.
# **Used by:** .ivx_max_end_monoid().
.ivx_choose_max_end <- function(a, b) {
  if(!isTRUE(a$has)) {
    return(b)
  }
  if(!isTRUE(b$has)) {
    return(a)
  }
  if(!identical(a$endpoint_type, b$endpoint_type)) {
    stop("Incompatible endpoint types encountered in interval_index measures.")
  }
  cmp <- .ivx_compare_scalar_fast(a$end, b$end, endpoint_type = a$endpoint_type)
  if(cmp >= 0L) a else b
}

# Runtime: O(1).
# Measure monoid for subtree max end endpoint.
# **Inputs:** none.
# **Outputs:** MeasureMonoid object.
# **Used by:** .ivx_merge_monoids() required set.
.ivx_max_end_monoid <- function() {
  measure_monoid(
    .ivx_choose_max_end,
    list(has = FALSE, end = NULL, endpoint_type = NULL),
    function(el) {
      list(
        has = TRUE,
        end = el$end,
        endpoint_type = .ivx_endpoint_type(el$end)
      )
    }
  )
}

# Runtime: O(1).
# Monoid reducer selecting min `end` summary.
# **Inputs:** monoid state lists `a`,`b`.
# **Outputs:** monoid state list with smallest end.
# **Used by:** .ivx_min_end_monoid().
.ivx_choose_min_end <- function(a, b) {
  if(!isTRUE(a$has)) {
    return(b)
  }
  if(!isTRUE(b$has)) {
    return(a)
  }
  if(!identical(a$endpoint_type, b$endpoint_type)) {
    stop("Incompatible endpoint types encountered in interval_index measures.")
  }
  cmp <- .ivx_compare_scalar_fast(a$end, b$end, endpoint_type = a$endpoint_type)
  if(cmp <= 0L) a else b
}

# Runtime: O(1).
# Measure monoid for subtree min end endpoint.
# **Inputs:** none.
# **Outputs:** MeasureMonoid object.
# **Used by:** .ivx_merge_monoids() required set.
.ivx_min_end_monoid <- function() {
  measure_monoid(
    .ivx_choose_min_end,
    list(has = FALSE, end = NULL, endpoint_type = NULL),
    function(el) {
      list(
        has = TRUE,
        end = el$end,
        endpoint_type = .ivx_endpoint_type(el$end)
      )
    }
  )
}

# Runtime: O(1).
# Reports whether interval endpoint type can reuse ordered key monoids.
# **Inputs:** scalar character `endpoint_type`.
# **Outputs:** scalar logical.
# **Used by:** insert/build monoid assembly.
.ivx_supports_oms_key_type <- function(endpoint_type) {
  isTRUE(endpoint_type %in% c("numeric", "character", "logical"))
}

# Runtime: O(m), where m = number of user-supplied monoids.
# Merges user monoids with required interval (and optional ordered-key) monoids.
# **Inputs:** optional user `monoids`; optional scalar `endpoint_type`.
# **Outputs:** normalized monoid list including reserved required monoids.
# **Used by:** constructors, insert on empty, apply when dropping custom monoids.
.ivx_merge_monoids <- function(monoids = NULL, endpoint_type = NULL) {
  user <- if(is.null(monoids)) list() else monoids
  if(length(user) > 0L) {
    bad <- intersect(names(user), c(".size", ".named_count", ".ivx_max_start", ".ivx_max_end", ".ivx_min_end", ".oms_max_key"))
    if(length(bad) > 0L) {
      stop(paste0("Reserved monoid names cannot be supplied for interval_index: ", paste(bad, collapse = ", ")))
    }
  }

  req <- list(
    .ivx_max_start = .ivx_max_start_monoid(),
    .ivx_max_end = .ivx_max_end_monoid(),
    .ivx_min_end = .ivx_min_end_monoid()
  )
  if(.ivx_supports_oms_key_type(endpoint_type)) {
    req <- c(req, .oms_required_monoids())
  }
  ensure_size_monoids(c(user, req))
}
