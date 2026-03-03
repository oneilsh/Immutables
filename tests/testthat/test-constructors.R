#SO

testthat::test_that("public constructor wrappers align with as_* constructors", {
  fx <- flexseq("a", "b", "c")
  fx_as <- as_flexseq(list("a", "b", "c"))
  testthat::expect_s3_class(fx, "flexseq")
  testthat::expect_equal(as.list(fx), as.list(fx_as))

  pq <- priority_queue(one = "a", two = "b", priorities = c(2, 1))
  pq_as <- as_priority_queue(list(one = "a", two = "b"), priorities = c(2, 1))
  testthat::expect_s3_class(pq, "priority_queue")
  testthat::expect_equal(as.list(pq), as.list(pq_as))
  testthat::expect_equal(peek_min(pq), peek_min(pq_as))
  testthat::expect_equal(peek_max(pq), peek_max(pq_as))

  os <- ordered_sequence(one = "a", two = "b", keys = c(2, 1))
  os_as <- as_ordered_sequence(list(one = "a", two = "b"), keys = c(2, 1))
  testthat::expect_s3_class(os, "ordered_sequence")
  testthat::expect_equal(as.list(os), as.list(os_as))
  testthat::expect_identical(count_key(os, 1), count_key(os_as, 1))
  testthat::expect_identical(count_key(os, 2), count_key(os_as, 2))

  ix <- interval_index(one = "a", two = "b", start = c(2, 1), end = c(4, 3), bounds = "[]")
  ix_as <- as_interval_index(list(one = "a", two = "b"), start = c(2, 1), end = c(4, 3), bounds = "[]")
  testthat::expect_s3_class(ix, "interval_index")
  testthat::expect_equal(as.list(ix), as.list(ix_as))
  ix_entries <- lapply(.ivx_entries(ix), function(e) list(start = e$start, end = e$end))
  ix_as_entries <- lapply(.ivx_entries(ix_as), function(e) list(start = e$start, end = e$end))
  testthat::expect_equal(ix_entries, ix_as_entries)
})

testthat::test_that("constructors enforce required metadata args when elements are supplied", {
  testthat::expect_error(priority_queue("a"), "`priorities` is required")
  testthat::expect_error(as_priority_queue(list("a")), "argument \"priorities\" is missing")

  testthat::expect_error(ordered_sequence("a"), "`keys` is required")
  testthat::expect_error(as_ordered_sequence(list("a")), "argument \"keys\" is missing")

  testthat::expect_error(interval_index("a", end = 2), "`start` is required")
  testthat::expect_error(interval_index("a", start = 1), "`end` is required")
  testthat::expect_error(as_interval_index(list("a"), end = 2), "argument \"start\" is missing")
  testthat::expect_error(as_interval_index(list("a"), start = 1), "argument \"end\" is missing")
})

testthat::test_that("as_flexseq on flexseq is identity-safe for named elements", {
  fx <- flexseq(fx = "x", fy = "y")
  out <- as_flexseq(fx)

  testthat::expect_s3_class(out, "flexseq")
  testthat::expect_identical(as.list(out), as.list(fx))
  testthat::expect_identical(names(as.list(out)), c("fx", "fy"))
})
