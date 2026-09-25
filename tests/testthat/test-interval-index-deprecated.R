#SO

# The *_overlaps names were renamed to *_overlapping in 1.2.0. The old names
# remain as deprecated wrappers that warn and forward to the new functions.

.ivx_dep_fixture <- function() {
  interval_index("a", "b", "c", start = c(1, 3, 5), end = c(2, 4, 6))
}

testthat::test_that("peek_overlaps() warns and matches peek_overlapping()", {
  ix <- .ivx_dep_fixture()
  testthat::expect_warning(
    old <- peek_overlaps(ix, 2, 4),
    regexp = "peek_overlapping", class = "deprecatedWarning"
  )
  testthat::expect_identical(old, "b")
  testthat::expect_identical(old, peek_overlapping(ix, 2, 4))

  # bounds passed by name reaches the new function
  edge <- interval_index("a", start = 1, end = 3, default_query_bounds = "[)")
  testthat::expect_warning(
    old_closed <- peek_overlaps(edge, 3, 4, bounds = "[]"),
    class = "deprecatedWarning"
  )
  testthat::expect_identical(old_closed, "a")
  testthat::expect_identical(old_closed, peek_overlapping(edge, 3, 4, bounds = "[]"))
})

testthat::test_that("peek_all_overlaps() warns and matches peek_all_overlapping()", {
  ix <- .ivx_dep_fixture()
  testthat::expect_warning(
    old <- peek_all_overlaps(ix, 2, 5),
    regexp = "peek_all_overlapping", class = "deprecatedWarning"
  )
  testthat::expect_identical(as.list(old), as.list(peek_all_overlapping(ix, 2, 5)))
  testthat::expect_identical(as.list(old), list("b"))

  # as_list is forwarded
  testthat::expect_warning(
    old_list <- peek_all_overlaps(ix, 2, 5, as_list = TRUE),
    class = "deprecatedWarning"
  )
  testthat::expect_identical(old_list, peek_all_overlapping(ix, 2, 5, as_list = TRUE))
})

testthat::test_that("pop_overlaps() warns and matches pop_overlapping()", {
  ix <- .ivx_dep_fixture()
  testthat::expect_warning(
    old <- pop_overlaps(ix, 2, 4),
    regexp = "pop_overlapping", class = "deprecatedWarning"
  )
  new <- pop_overlapping(ix, 2, 4)
  testthat::expect_identical(old$value, "b")
  testthat::expect_identical(old$value, new$value)
  testthat::expect_identical(old$start, new$start)
  testthat::expect_identical(old$end, new$end)
  testthat::expect_identical(as.list(old$remaining), as.list(new$remaining))

  # a miss still returns the miss object rather than erroring
  testthat::expect_warning(
    miss <- pop_overlaps(ix, 100, 200),
    class = "deprecatedWarning"
  )
  testthat::expect_null(miss$value)
  testthat::expect_identical(as.list(miss$remaining), as.list(ix))
})

testthat::test_that("pop_all_overlaps() warns and matches pop_all_overlapping()", {
  ix <- .ivx_dep_fixture()
  testthat::expect_warning(
    old <- pop_all_overlaps(ix, 2, 5),
    regexp = "pop_all_overlapping", class = "deprecatedWarning"
  )
  new <- pop_all_overlapping(ix, 2, 5)
  testthat::expect_identical(as.list(old$elements), as.list(new$elements))
  testthat::expect_identical(as.list(old$remaining), as.list(new$remaining))

  # empty index: no error, empty result
  empty_ix <- as_interval_index(list(), start = numeric(0), end = numeric(0))
  testthat::expect_warning(
    empty_out <- pop_all_overlaps(empty_ix, 1, 5),
    class = "deprecatedWarning"
  )
  testthat::expect_length(empty_out$elements, 0L)
})
