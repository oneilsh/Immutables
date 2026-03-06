#SO

# choose the left-most (a) entry on ties
# Runtime: O(1).
.pq_choose_min <- function(a, b) {
  if(!isTRUE(a$has)) {
    return(b)
  }
  if(!isTRUE(b$has)) {
    return(a)
  }
  domain <- .ft_scalar_domain(a$priority)
  cmp <- .ft_scalar_compare_fast(
    a$priority,
    b$priority,
    domain = domain,
    error_message = "Priority values must support scalar ordering with `<` and `>`."
  )
  if(cmp < 0L) {
    return(a)
  }
  if(cmp > 0L) {
    return(b)
  }
  a
}

# choose the left-most (a) entry on ties
# Runtime: O(1).
.pq_choose_max <- function(a, b) {
  if(!isTRUE(a$has)) {
    return(b)
  }
  if(!isTRUE(b$has)) {
    return(a)
  }
  domain <- .ft_scalar_domain(a$priority)
  cmp <- .ft_scalar_compare_fast(
    a$priority,
    b$priority,
    domain = domain,
    error_message = "Priority values must support scalar ordering with `<` and `>`."
  )
  if(cmp > 0L) {
    return(a)
  }
  if(cmp < 0L) {
    return(b)
  }
  a
}

# Runtime: O(1).
pq_min_measure_monoid <- function() {
  measure_monoid(
    .pq_choose_min,
    # `has` distinguishes true identity (empty aggregate) from measured values.
    # We avoid overloading `priority = NULL` as state.
    list(has = FALSE, priority = NULL),
    function(el) {
      list(has = TRUE, priority = el$priority)
    }
  )
}

# Runtime: O(1).
pq_max_measure_monoid <- function() {
  measure_monoid(
    .pq_choose_max,
    # Same sentinel contract as min monoid identity.
    list(has = FALSE, priority = NULL),
    function(el) {
      list(has = TRUE, priority = el$priority)
    }
  )
}

# Runtime: O(1).
.pq_measure_equal <- function(a, b) {
  if(!isTRUE(a$has) && !isTRUE(b$has)) {
    return(TRUE)
  }
  if(!isTRUE(a$has) || !isTRUE(b$has)) {
    return(FALSE)
  }
  domain <- .ft_scalar_domain(a$priority)
  .ft_scalar_equal_fast(
    a$priority,
    b$priority,
    domain = domain,
    error_message = "Priority values must support scalar ordering with `<` and `>`."
  )
}

# Runtime: O(1).
.pq_required_monoids <- function() {
  list(
    .pq_min = pq_min_measure_monoid(),
    .pq_max = pq_max_measure_monoid()
  )
}
