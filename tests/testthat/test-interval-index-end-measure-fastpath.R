# Parity tests: native C++ fast paths for the .ivx_max_end / .ivx_min_end
# measure monoids must produce payloads identical to the R closure path
# (immutables.use_cpp = FALSE). Same toggle pattern as helper-ivx.R.

.ivx_with_cpp_backend <- function(flag, expr) {
  old <- getOption("immutables.use_cpp", default = TRUE)
  on.exit(options(immutables.use_cpp = old), add = TRUE)
  options(immutables.use_cpp = isTRUE(flag))
  force(expr)
}

.ivx_end_measures <- function(x) {
  ms <- attr(x, "measures")
  list(max_end = ms[[".ivx_max_end"]], min_end = ms[[".ivx_min_end"]])
}

test_that("build: end measures identical across cpp and R backends", {
  starts <- c(5L, 1L, 9L, 3L, 7L, 2L, 8L, 4L, 6L, 10L)
  ends <- starts + c(3L, 10L, 1L, 4L, 2L, 8L, 5L, 1L, 9L, 2L)
  vals <- as.list(letters[1:10])

  ix_cpp <- .ivx_with_cpp_backend(TRUE,
    as_interval_index(vals, start = starts, end = ends))
  ix_r <- .ivx_with_cpp_backend(FALSE,
    as_interval_index(vals, start = starts, end = ends))

  expect_identical(.ivx_end_measures(ix_cpp), .ivx_end_measures(ix_r))
  expect_true(isTRUE(.ivx_end_measures(ix_cpp)$max_end$has))
  expect_identical(.ivx_end_measures(ix_cpp)$max_end$end, max(ends))
  expect_identical(.ivx_end_measures(ix_cpp)$min_end$end, min(ends))
})

test_that("split: end measures identical across cpp and R backends", {
  set.seed(99)
  n <- 200L
  starts <- sort(sample.int(2000L, n))
  ends <- starts + sample.int(50L, n, replace = TRUE)
  vals <- as.list(sprintf("v%03d", seq_len(n)))

  for(idx in c(2L, 37L, 101L, 199L)) {
    s_cpp <- .ivx_with_cpp_backend(TRUE, {
      ix <- as_interval_index(vals, start = starts, end = ends)
      Immutables:::.ivx_split_at_index(ix, idx)
    })
    s_r <- .ivx_with_cpp_backend(FALSE, {
      ix <- as_interval_index(vals, start = starts, end = ends)
      Immutables:::.ivx_split_at_index(ix, idx)
    })
    expect_identical(.ivx_end_measures(s_cpp$left), .ivx_end_measures(s_r$left))
    expect_identical(.ivx_end_measures(s_cpp$right), .ivx_end_measures(s_r$right))
    expect_identical(as.list(s_cpp$left), as.list(s_r$left))
    expect_identical(as.list(s_cpp$right), as.list(s_r$right))
  }
})

test_that("insert: end measures identical across cpp and R backends", {
  starts <- c(10L, 30L, 20L)
  ends <- c(15L, 45L, 22L)
  build <- function() {
    ix <- as_interval_index(as.list(c("a", "b", "c")), start = starts, end = ends)
    ix <- insert(ix, "d", 25L, 99L)
    insert(ix, "e", 5L, 7L)
  }
  ix_cpp <- .ivx_with_cpp_backend(TRUE, build())
  ix_r <- .ivx_with_cpp_backend(FALSE, build())
  expect_identical(.ivx_end_measures(ix_cpp), .ivx_end_measures(ix_r))
  expect_identical(.ivx_end_measures(ix_cpp)$max_end$end, 99L)
  expect_identical(.ivx_end_measures(ix_cpp)$min_end$end, 7L)
})

test_that("queries: results identical across cpp and R backends", {
  set.seed(7)
  n <- 300L
  starts <- sort(sample.int(3000L, n))
  ends <- starts + sample.int(80L, n, replace = TRUE)
  vals <- as.list(sprintf("v%03d", seq_len(n)))
  qlo <- starts[120L]
  qhi <- starts[150L]
  qpt <- starts[150L] + 5L

  run <- function(flag) {
    .ivx_with_cpp_backend(flag, {
      ix <- as_interval_index(vals, start = starts, end = ends,
                              default_query_bounds = "[]")
      list(
        ov  = peek_all_overlaps(ix, qlo, qhi, as_list = TRUE),
        pt  = peek_all_point(ix, qpt, as_list = TRUE),
        pop = {
          r <- pop_all_overlaps(ix, qlo, qhi)
          list(elements = as.list(r$elements), remaining = as.list(r$remaining))
        }
      )
    })
  }

  expect_identical(run(TRUE), run(FALSE))
})

test_that("bound index: native search matches R locate path", {
  set.seed(11)
  n <- 500L
  starts <- sort(sample.int(5000L, n))
  ends <- starts + sample.int(60L, n, replace = TRUE)
  ix <- as_interval_index(as.list(seq_len(n)), start = starts, end = ends)

  keys <- c(starts[1L] - 1L, starts[1L], starts[250L], starts[250L] + 1L,
            starts[n], starts[n] + 100L)
  for(key in keys) {
    for(strict in c(TRUE, FALSE)) {
      idx_cpp <- .ivx_with_cpp_backend(TRUE,
        Immutables:::.ivx_bound_index_prepared(ix, key, strict = strict))
      idx_r <- .ivx_with_cpp_backend(FALSE,
        Immutables:::.ivx_bound_index_prepared(ix, key, strict = strict))
      expect_identical(idx_cpp, idx_r)
    }
  }
})

test_that("remove_index_runs: matches list-based removal for varied patterns", {
  set.seed(21)
  n <- 137L
  starts <- sort(sample.int(2000L, n))
  ends <- starts + sample.int(40L, n, replace = TRUE)
  vals <- as.list(sprintf("v%03d", seq_len(n)))
  ix <- as_interval_index(vals, start = starts, end = ends)

  cases <- list(
    integer(0),                 # nothing
    1L,                         # first element
    n,                          # last element
    70L,                        # interior singleton
    5:12,                       # one interior run
    c(1:3, 50:60, 130:137),     # runs touching both ends
    seq(2L, n, by = 2L),        # scattered alternating
    seq_len(n)                  # everything
  )
  for(idx in cases) {
    out <- Immutables:::.ivx_remove_index_runs(ix, idx)
    expect_identical(as.list(out),
                     if(length(idx)) as.list(ix)[-idx] else as.list(ix))
    # the result must remain a queryable interval_index with intact measures
    if(length(out) > 0L) {
      kept_starts <- starts[setdiff(seq_len(n), idx)]
      probe <- kept_starts[[length(kept_starts) %/% 2L + 1L]]
      expect_identical(
        length(peek_all_point(out, probe, bounds = "[]", as_list = TRUE)$values) > 0L,
        TRUE
      )
    }
  }
})

test_that("pop: splice and drain regimes match the R reference path", {
  set.seed(33)
  n <- 600L
  starts <- sort(sample.int(6000L, n))
  vals <- as.list(sprintf("v%03d", seq_len(n)))
  # short non-overlapping intervals: a narrow query matches one contiguous
  # run of positions (splice regime under cpp_scan)
  ends_short <- starts + 3L
  # alternating short/long intervals: a query deep into the index matches
  # scattered positions across a wide candidate window (drain regime)
  ends_mixed <- starts + rep(c(2L, 400L), length.out = n)

  run <- function(flag, ends, f) {
    .ivx_with_cpp_scan_enabled(flag, {
      ix <- as_interval_index(vals, start = starts, end = ends,
                              default_query_bounds = "[]")
      r <- f(ix)
      list(elements = as.list(r$elements), remaining = as.list(r$remaining))
    })
  }

  # Contiguous matches -> splice path.
  qlo1 <- starts[300L]; qhi1 <- starts[304L]
  f1 <- function(ix) pop_all_overlaps(ix, qlo1, qhi1)
  expect_identical(run(TRUE, ends_short, f1), run(FALSE, ends_short, f1))

  # Scattered matches over a wide window -> drain path.
  qlo2 <- starts[550L]; qhi2 <- starts[560L]
  f2 <- function(ix) pop_all_overlaps(ix, qlo2, qhi2)
  expect_identical(run(TRUE, ends_mixed, f2), run(FALSE, ends_mixed, f2))

  # pop first always splices.
  f3 <- function(ix) {
    r <- pop_point(ix, starts[200L] + 1L)
    list(elements = list(r$value, r$start, r$end), remaining = as.list(r$remaining))
  }
  expect_identical(run(TRUE, ends_short, f3), run(FALSE, ends_short, f3))
  expect_identical(run(TRUE, ends_mixed, f3), run(FALSE, ends_mixed, f3))

  # popping everything empties the index.
  f4 <- function(ix) pop_all_overlaps(ix, min(starts), max(ends_short))
  expect_identical(run(TRUE, ends_short, f4), run(FALSE, ends_short, f4))
  expect_identical(length(run(TRUE, ends_short, f4)$remaining), 0L)
})

test_that("Date endpoints: end measures identical across backends", {
  starts <- as.Date("2026-01-01") + c(0, 10, 5)
  ends <- starts + c(3, 2, 30)
  build <- function() {
    ix <- as_interval_index(as.list(c("a", "b", "c")), start = starts, end = ends)
    insert(ix, "d", as.Date("2026-01-04"), as.Date("2026-01-06"))
  }
  ix_cpp <- .ivx_with_cpp_backend(TRUE, build())
  ix_r <- .ivx_with_cpp_backend(FALSE, build())
  expect_identical(.ivx_end_measures(ix_cpp), .ivx_end_measures(ix_r))
})
