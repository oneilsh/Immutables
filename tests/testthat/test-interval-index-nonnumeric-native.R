# Parity tests: the native interval-query path (candidate-span bound search +
# native walk) now supports character / Date / POSIXct endpoints, not just
# numeric. Each test compares the fully-native path against the pure-R path and
# requires identical results across all four relations for peek and pop.
#
# "fully native" = immutables.use_cpp + immutables.ivx.cpp_scan both TRUE
# "pure R"       = both FALSE (R bound search via locate_by_predicate + R walk)

.ivx_with_all_cpp <- function(flag, expr) {
  old <- options(immutables.use_cpp = isTRUE(flag),
                 immutables.ivx.cpp_scan = isTRUE(flag))
  on.exit(options(old), add = TRUE)
  force(expr)
}

# Build an index of n non-overlapping-ish intervals over an orderable domain.
# `to_endpoint` maps an integer coordinate to the target endpoint type.
.make_typed_ix <- function(n, to_endpoint, width = 3L) {
  set.seed(7)
  coords <- sort(sample.int(50L * n, n))
  starts <- to_endpoint(coords)
  ends   <- to_endpoint(coords + width)
  as_interval_index(as.list(sprintf("v%04d", seq_len(n))),
                    start = starts, end = ends, default_query_bounds = "[]")
}

# Compare native vs pure-R across all four relations, for both peek and pop.
.expect_relation_parity <- function(to_endpoint, q_lo, q_hi, q_pt) {
  mk <- function() .make_typed_ix(250L, to_endpoint)
  ixn <- .ivx_with_all_cpp(TRUE,  mk())
  ixr <- .ivx_with_all_cpp(FALSE, mk())

  peek_fns <- list(
    point      = function(ix) peek_all_point(ix, q_pt, bounds = "[]", as_list = TRUE),
    overlaps   = function(ix) peek_all_overlaps(ix, q_lo, q_hi, bounds = "[]", as_list = TRUE),
    containing = function(ix) peek_all_containing(ix, q_lo, q_hi, bounds = "[]", as_list = TRUE),
    within     = function(ix) peek_all_within(ix, q_lo, q_hi, bounds = "[]", as_list = TRUE)
  )
  for (nm in names(peek_fns)) {
    f <- peek_fns[[nm]]
    n_res <- .ivx_with_all_cpp(TRUE,  f(ixn))
    r_res <- .ivx_with_all_cpp(FALSE, f(ixr))
    expect_equal(n_res, r_res, info = paste("peek", nm))
  }

  pop_fns <- list(
    point      = function(ix) pop_all_point(ix, q_pt, bounds = "[]"),
    overlaps   = function(ix) pop_all_overlaps(ix, q_lo, q_hi, bounds = "[]"),
    containing = function(ix) pop_all_containing(ix, q_lo, q_hi, bounds = "[]"),
    within     = function(ix) pop_all_within(ix, q_lo, q_hi, bounds = "[]")
  )
  for (nm in names(pop_fns)) {
    f <- pop_fns[[nm]]
    n_res <- .ivx_with_all_cpp(TRUE,  f(ixn))
    r_res <- .ivx_with_all_cpp(FALSE, f(ixr))
    expect_equal(as.list(n_res$elements),  as.list(r_res$elements),  info = paste("pop elements", nm))
    expect_equal(as.list(n_res$remaining), as.list(r_res$remaining), info = paste("pop remaining", nm))
  }
}

test_that("native path engages for non-numeric endpoint types", {
  expect_identical(.ivx_endpoint_kind_code("character"), 3L)
  expect_identical(.ivx_endpoint_kind_code("Date"), 4L)
  expect_identical(.ivx_endpoint_kind_code("POSIXct"), 5L)
  # logical and unknown stay on the R path
  expect_identical(.ivx_endpoint_kind_code("logical"), 0L)

  # bound search returns a non-NA position for the supported types
  ix_chr <- as_interval_index(as.list(letters[1:6]),
                              start = c("a","c","e","g","i","k"),
                              end   = c("b","d","f","h","j","l"))
  expect_identical(Immutables:::.ft_cpp_ivx_bound_index(ix_chr, "f", FALSE), 4L)
  expect_true(is.na(Immutables:::.ft_cpp_ivx_bound_index(ix_chr, TRUE, FALSE)))  # logical key → NA
})

test_that("character endpoints: native matches pure-R for all relations", {
  to_chr <- function(coords) sprintf("p%08d", coords)
  .expect_relation_parity(to_chr,
    q_lo = "p00001000", q_hi = "p00004000", q_pt = "p00002000")
})

test_that("Date endpoints: native matches pure-R for all relations", {
  to_date <- function(coords) as.Date("2000-01-01") + coords
  .expect_relation_parity(to_date,
    q_lo = as.Date("2000-01-01") + 1000L,
    q_hi = as.Date("2000-01-01") + 4000L,
    q_pt = as.Date("2000-01-01") + 2000L)
})

test_that("POSIXct endpoints: native matches pure-R for all relations", {
  base <- as.POSIXct("2000-01-01 00:00:00", tz = "UTC")
  to_ts <- function(coords) base + coords
  .expect_relation_parity(to_ts,
    q_lo = base + 1000L, q_hi = base + 4000L, q_pt = base + 2000L)
})

test_that("non-numeric bound search agrees with R locate across strictness", {
  # Directly exercise .ivx_bound_index_prepared (Phase 1) native vs R for
  # character keys, including the strict / non-strict boundary cases.
  starts <- sprintf("k%03d", c(10L, 20L, 20L, 30L, 40L))
  ix <- as_interval_index(as.list(1:5), start = starts,
                          end = paste0(starts, "z"))
  keys <- sprintf("k%03d", c(5L, 10L, 20L, 25L, 40L, 99L))
  for (key in keys) {
    for (strict in c(TRUE, FALSE)) {
      idx_n <- .ivx_with_all_cpp(TRUE,
        Immutables:::.ivx_bound_index_prepared(ix, key, strict = strict))
      idx_r <- .ivx_with_all_cpp(FALSE,
        Immutables:::.ivx_bound_index_prepared(ix, key, strict = strict))
      expect_identical(idx_n, idx_r, info = paste("key", key, "strict", strict))
    }
  }
})
