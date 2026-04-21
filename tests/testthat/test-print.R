# Snapshot-based tests for the four `print.*` methods.
# Snapshots live in `tests/testthat/_snaps/print/`. On first run testthat
# creates them; subsequent runs diff against them. If you intentionally change
# a print format, accept the new output with `make snapshot-accept` (or
# `testthat::snapshot_accept()` interactively) and commit the updated snapshots.

# --- flexseq -----------------------------------------------------------------

testthat::test_that("print.flexseq handles empty, single, and small named trees", {
  testthat::expect_snapshot(print(flexseq()))
  testthat::expect_snapshot(print(as_flexseq(1)))
  testthat::expect_snapshot(
    print(as_flexseq(setNames(as.list(1:4), letters[1:4])))
  )
})

testthat::test_that("print.flexseq truncates long unnamed trees with head/tail preview", {
  testthat::expect_snapshot(print(as_flexseq(1:12), max_elements = 4))
  # max_elements = 0 shows only the header.
  testthat::expect_snapshot(print(as_flexseq(1:12), max_elements = 0))
})

testthat::test_that("print.flexseq shows custom monoid aggregates when requested", {
  sum_m <- measure_monoid(function(a, b) a + b, 0, function(el) as.numeric(el))
  x <- add_monoids(as_flexseq(1:5), list(sum = sum_m))
  testthat::expect_snapshot(print(x, max_elements = 2, show_custom_monoids = TRUE))
  # With no custom monoids attached, the header still appears.
  testthat::expect_snapshot(
    print(as_flexseq(1:3), max_elements = 0, show_custom_monoids = TRUE)
  )
})

testthat::test_that("print.flexseq rejects invalid arguments with informative errors", {
  testthat::expect_error(print(as_flexseq(1:3), max_elements = -1),
                         "non-negative integer")
  testthat::expect_error(print(as_flexseq(1:3), max_elements = c(1, 2)),
                         "non-negative integer")
  testthat::expect_error(print(as_flexseq(1:3), show_custom_monoids = NA),
                         "TRUE or FALSE")
})

# --- priority_queue ----------------------------------------------------------

testthat::test_that("print.priority_queue handles empty, named, unnamed, and truncated queues", {
  testthat::expect_snapshot(print(priority_queue()))
  testthat::expect_snapshot(
    print(priority_queue(one = 1, two = 2, three = 3, priorities = c(20, 30, 10)))
  )
  testthat::expect_snapshot(
    print(priority_queue(1, 2, 3, priorities = c(2, 1, 3)))
  )
  # Larger queue with truncation.
  big_q <- do.call(priority_queue,
                   c(as.list(letters[1:10]),
                     list(priorities = c(5, 1, 8, 3, 2, 9, 4, 7, 6, 10))))
  testthat::expect_snapshot(print(big_q, max_elements = 4))
})

testthat::test_that("print.priority_queue shows custom monoid aggregates", {
  sum_item <- measure_monoid(function(a, b) a + b, 0,
                             function(entry) as.numeric(entry$value))
  q <- add_monoids(priority_queue(1, 2, 3, priorities = c(2, 1, 3)),
                   list(sum_item = sum_item))
  testthat::expect_snapshot(print(q, max_elements = 0, show_custom_monoids = TRUE))
})

# --- ordered_sequence --------------------------------------------------------

testthat::test_that("print.ordered_sequence handles empty, named, unnamed, and truncated sequences", {
  testthat::expect_snapshot(print(ordered_sequence()))
  testthat::expect_snapshot(
    print(ordered_sequence(one = "a", two = "b", three = "c", keys = c(20, 30, 10)))
  )
  testthat::expect_snapshot(
    print(ordered_sequence("x", "y", "z", keys = c(2, 1, 3)))
  )
  testthat::expect_snapshot(
    print(as_ordered_sequence(letters[1:10], keys = 10:1), max_elements = 4)
  )
})

testthat::test_that("print.ordered_sequence shows custom monoid aggregates", {
  sum_key <- measure_monoid(function(a, b) a + b, 0,
                            function(entry) as.numeric(entry$key))
  ys <- add_monoids(ordered_sequence("a", "b", keys = c(2, 1)),
                    list(sum_key = sum_key))
  testthat::expect_snapshot(print(ys, max_elements = 0, show_custom_monoids = TRUE))
})

# --- interval_index ----------------------------------------------------------

testthat::test_that("print.interval_index handles empty, named, unnamed, and truncated indices", {
  testthat::expect_snapshot(print(interval_index()))
  testthat::expect_snapshot(
    print(interval_index(one = 1, two = 2, three = 3,
                         start = c(20, 30, 10), end = c(25, 37, 24)))
  )
  testthat::expect_snapshot(
    print(interval_index(1, 2, 3, start = c(2, 4, 6), end = c(3, 5, 8),
                         default_query_bounds = "[]"))
  )
  big_ix <- do.call(interval_index,
                    c(as.list(letters[1:10]),
                      list(start = 1:10, end = 2:11)))
  testthat::expect_snapshot(print(big_ix, max_elements = 4))
})

testthat::test_that("print.interval_index shows custom monoid aggregates", {
  width_sum <- measure_monoid(
    function(a, b) a + b, 0,
    function(entry) as.numeric(entry$end - entry$start)
  )
  ix <- add_monoids(
    interval_index(1, 2, start = c(1, 3), end = c(2, 5)),
    list(width_sum = width_sum)
  )
  testthat::expect_snapshot(print(ix, max_elements = 0, show_custom_monoids = TRUE))
})
