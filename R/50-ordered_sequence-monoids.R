#SO

# Runtime: O(1).
.ft_scalar_domain <- function(v) {
  if(inherits(v, "Date")) {
    return("Date")
  }
  if(inherits(v, "POSIXct")) {
    return("POSIXct")
  }
  if(is.numeric(v)) {
    return("numeric")
  }
  if(is.character(v)) {
    return("character")
  }
  if(is.logical(v)) {
    return("logical")
  }
  cls <- class(v)
  if(length(cls) > 0L) {
    return(paste0("class:", paste(cls, collapse = "/")))
  }
  paste0("typeof:", typeof(v))
}

# Runtime: O(1).
.ft_scalar_is_fast_domain <- function(domain) {
  isTRUE(domain %in% c("numeric", "character", "logical", "Date", "POSIXct"))
}

# Runtime: O(1).
.ft_scalar_compare <- function(a, b, error_message = "Values must support scalar ordering with `<` and `>`.") {
  # Strict comparator for validation-facing paths.
  # Always guards base Ops with tryCatch and shape checks.
  lt <- suppressWarnings(tryCatch(a < b, error = function(e) e))
  gt <- suppressWarnings(tryCatch(a > b, error = function(e) e))

  if(
    inherits(lt, "error") ||
    inherits(gt, "error") ||
    !is.logical(lt) ||
    !is.logical(gt) ||
    length(lt) != 1L ||
    length(gt) != 1L ||
    is.na(lt) ||
    is.na(gt)
  ) {
    stop(error_message)
  }

  if(isTRUE(lt)) {
    return(-1L)
  }
  if(isTRUE(gt)) {
    return(1L)
  }
  0L
}

# Runtime: O(1).
.ft_scalar_compare_fast <- function(a, b, domain = NULL, error_message = "Values must support scalar ordering with `<` and `>`.") {
  # Hot-path comparator used by monoid aggregation and tight scans.
  # For known scalar domains, use direct Ops first; otherwise fallback to
  # the strict comparator above to keep behavior safe for custom classes.
  if(.ft_scalar_is_fast_domain(domain)) {
    lt <- a < b
    gt <- a > b
    if(
      is.logical(lt) &&
      is.logical(gt) &&
      length(lt) == 1L &&
      length(gt) == 1L &&
      !is.na(lt) &&
      !is.na(gt)
    ) {
      if(isTRUE(lt)) {
        return(-1L)
      }
      if(isTRUE(gt)) {
        return(1L)
      }
      return(0L)
    }
  }
  .ft_scalar_compare(a, b, error_message = error_message)
}

# Runtime: O(1).
.ft_scalar_equal_fast <- function(a, b, domain = NULL, error_message = "Values must support scalar ordering with `<` and `>`.") {
  # Equality helper mirrors compare strategy: fast primitive check first, then
  # fallback through comparison semantics.
  if(.ft_scalar_is_fast_domain(domain)) {
    eq <- a == b
    if(is.logical(eq) && length(eq) == 1L && !is.na(eq)) {
      return(isTRUE(eq))
    }
  }
  .ft_scalar_compare_fast(a, b, domain = domain, error_message = error_message) == 0L
}

# Runtime: O(1).
.ft_normalize_scalar_orderable <- function(value, arg_name = "value") {
  # 1) Scalar shape + non-missing checks.
  if(length(value) != 1L) {
    stop(sprintf("`%s` must be a scalar value.", arg_name))
  }
  domain <- .ft_scalar_domain(value)
  if(.ft_scalar_is_fast_domain(domain)) {
    na_flag <- is.na(value)
  } else {
    na_flag <- suppressWarnings(tryCatch(is.na(value), error = function(e) FALSE))
  }
  if(is.logical(na_flag) && length(na_flag) == 1L && isTRUE(na_flag)) {
    stop(sprintf("`%s` must be non-missing.", arg_name))
  }

  # 2) Domain-specific canonical coercion.
  norm_value <- if(identical(domain, "numeric")) {
    as.numeric(value)
  } else if(identical(domain, "character")) {
    as.character(value)
  } else if(identical(domain, "logical")) {
    as.logical(value)
  } else if(identical(domain, "Date")) {
    as.Date(value)
  } else if(identical(domain, "POSIXct")) {
    as.POSIXct(value)
  } else {
    value
  }

  # 3) Confirm the normalized value supports scalar ordering.
  .ft_scalar_compare_fast(
    norm_value,
    norm_value,
    domain = domain,
    error_message = sprintf("`%s` must support scalar ordering with `<` and `>`.", arg_name)
  )
  list(value = norm_value, value_type = domain)
}

# Runtime: O(1).
.oms_key_type <- function(key) {
  .ft_scalar_domain(key)
}

# Runtime: O(1).
.oms_is_cpp_key_type <- function(key_type) {
  isTRUE(key_type %in% c("numeric", "character", "logical"))
}

# Runtime: O(1).
.oms_compare_key <- function(a, b, key_type) {
  .ft_scalar_compare_fast(
    a,
    b,
    domain = key_type,
    error_message = "Ordered keys must support scalar ordering with `<` and `>`."
  )
}

# Runtime: O(1).
.oms_normalize_key <- function(key_value) {
  norm <- .ft_normalize_scalar_orderable(key_value, arg_name = "key")
  list(key = norm$value, key_type = norm$value_type)
}

# Runtime: O(1).
.oms_choose_max_key <- function(a, b) {
  if(!isTRUE(a$has)) {
    return(b)
  }
  if(!isTRUE(b$has)) {
    return(a)
  }
  if(!identical(a$key_type, b$key_type)) {
    stop("Incompatible key types encountered in ordered_sequence measures.")
  }
  cmp <- .oms_compare_key(a$key, b$key, a$key_type)
  if(cmp >= 0L) a else b
}

# Runtime: O(1).
oms_max_key_monoid <- function() {
  measure_monoid(
    .oms_choose_max_key,
    list(has = FALSE, key = NULL, key_type = NULL),
    function(el) {
      list(has = TRUE, key = el$key, key_type = .oms_key_type(el$key))
    }
  )
}

# Runtime: O(1).
.oms_required_monoids <- function() {
  list(
    .oms_max_key = oms_max_key_monoid()
  )
}

# Runtime: O(1).
.oms_merge_monoids <- function(monoids = NULL) {
  user <- if(is.null(monoids)) list() else monoids
  if(length(user) > 0L) {
    bad <- intersect(names(user), c(".size", ".named_count", ".oms_max_key"))
    if(length(bad) > 0L) {
      stop(paste0("Reserved monoid names cannot be supplied for ordered_sequence: ", paste(bad, collapse = ", ")))
    }
  }
  ensure_size_monoids(c(user, .oms_required_monoids()))
}
