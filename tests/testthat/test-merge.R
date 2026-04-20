# ---- merge.flexseq ----------------------------------------------------------

testthat::test_that("merge.flexseq concatenates in order", {
  x <- flexseq("a", "b")
  y <- flexseq("c", "d")
  m <- merge(x, y)

  testthat::expect_identical(as.list(m), list("a", "b", "c", "d"))
  testthat::expect_identical(length(m), 4L)
})

testthat::test_that("merge.flexseq handles empty inputs", {
  testthat::expect_identical(as.list(merge(flexseq(), flexseq("x"))), list("x"))
  testthat::expect_identical(as.list(merge(flexseq("x"), flexseq())), list("x"))
  testthat::expect_identical(length(merge(flexseq(), flexseq())), 0L)
})

# ---- merge.priority_queue ---------------------------------------------------

testthat::test_that("merge.priority_queue combines entries and preserves min/max", {
  a <- priority_queue("x", "y", priorities = c(5, 1))
  b <- priority_queue("z", priorities = 3)
  m <- merge(a, b)

  testthat::expect_identical(length(m), 3L)
  testthat::expect_identical(peek_min(m), "y")
  testthat::expect_identical(peek_max(m), "x")
})

testthat::test_that("merge.priority_queue empty short-circuits", {
  a <- priority_queue("p", priorities = 1)
  testthat::expect_identical(length(merge(priority_queue(), a)), 1L)
  testthat::expect_identical(length(merge(a, priority_queue())), 1L)
  testthat::expect_identical(length(merge(priority_queue(), priority_queue())), 0L)
})

testthat::test_that("merge.priority_queue does not mutate sources", {
  a <- priority_queue("x", "y", priorities = c(5, 1))
  b <- priority_queue("z", priorities = 3)
  merge(a, b)

  testthat::expect_identical(length(a), 2L)
  testthat::expect_identical(length(b), 1L)
})

testthat::test_that("merge.priority_queue errors on priority-type mismatch", {
  a <- priority_queue("x", priorities = 1)          # numeric
  b <- priority_queue("y", priorities = "P1")       # character
  testthat::expect_error(merge(a, b), "priority type")
})

testthat::test_that("merge.priority_queue errors on non-priority_queue y", {
  a <- priority_queue("x", priorities = 1)
  testthat::expect_error(merge(a, flexseq("y")), "priority_queue")
})

# ---- merge.ordered_sequence -------------------------------------------------

testthat::test_that("merge.ordered_sequence produces key-ascending merge", {
  a <- ordered_sequence("a1", "a2", "a3", keys = c(1, 3, 5))
  b <- ordered_sequence("b1", "b2", "b3", keys = c(2, 3, 6))
  m <- merge(a, b)

  testthat::expect_identical(
    unlist(as.list(m)),
    c("a1", "b1", "a2", "b2", "a3", "b3")
  )
  testthat::expect_identical(length(m), 6L)
})

testthat::test_that("merge.ordered_sequence uses left-biased FIFO on tied keys", {
  a <- ordered_sequence("x1", "x2", keys = c(1, 1))
  b <- ordered_sequence("y1", "y2", keys = c(1, 1))
  m <- merge(a, b)

  testthat::expect_identical(unlist(as.list(m)), c("x1", "x2", "y1", "y2"))
  testthat::expect_identical(
    unlist(as.list(peek_all_key(m, 1))),
    c("x1", "x2", "y1", "y2")
  )
})

testthat::test_that("merge.ordered_sequence disjoint fast paths match general path", {
  a <- ordered_sequence("a", "b", "c", keys = c(1, 2, 3))
  b <- ordered_sequence("d", "e", "f", keys = c(4, 5, 6))

  testthat::expect_identical(
    unlist(as.list(merge(a, b))),
    c("a", "b", "c", "d", "e", "f")
  )
  testthat::expect_identical(
    unlist(as.list(merge(b, a))),
    c("a", "b", "c", "d", "e", "f")
  )
})

testthat::test_that("merge.ordered_sequence empty short-circuits", {
  a <- ordered_sequence("x", keys = 1)
  testthat::expect_identical(unlist(as.list(merge(ordered_sequence(), a))), "x")
  testthat::expect_identical(unlist(as.list(merge(a, ordered_sequence()))), "x")
  testthat::expect_identical(length(merge(ordered_sequence(), ordered_sequence())), 0L)
})

testthat::test_that("merge.ordered_sequence preserves min_key/max_key", {
  a <- ordered_sequence("a", "b", keys = c(3, 5))
  b <- ordered_sequence("c", "d", keys = c(1, 7))
  m <- merge(a, b)

  testthat::expect_identical(min_key(m), 1)
  testthat::expect_identical(max_key(m), 7)
})

testthat::test_that("merge.ordered_sequence does not mutate sources", {
  a <- ordered_sequence("a", keys = 1)
  b <- ordered_sequence("b", keys = 2)
  merge(a, b)

  testthat::expect_identical(length(a), 1L)
  testthat::expect_identical(length(b), 1L)
})

testthat::test_that("merge.ordered_sequence errors on key-type mismatch", {
  a <- ordered_sequence("a", keys = 1)       # numeric
  b <- ordered_sequence("b", keys = "x")     # character
  testthat::expect_error(merge(a, b), "key type")
})

testthat::test_that("merge.ordered_sequence rejects interval_index input", {
  os <- ordered_sequence("a", keys = 1)
  ix <- interval_index("a", start = 1, end = 2)
  testthat::expect_error(merge(os, ix), "interval_index")
})

# ---- merge.interval_index ---------------------------------------------------

testthat::test_that("merge.interval_index produces start-ascending merge", {
  a <- interval_index("A1", "A2", start = c(1, 5), end = c(4, 8))
  b <- interval_index("B1", "B2", start = c(3, 7), end = c(6, 10))
  m <- merge(a, b)

  testthat::expect_identical(unlist(as.list(m)), c("A1", "B1", "A2", "B2"))
  testthat::expect_identical(length(m), 4L)
})

testthat::test_that("merge.interval_index uses left-biased FIFO on tied starts", {
  a <- interval_index("X1", "X2", start = c(1, 3), end = c(4, 5))
  b <- interval_index("Y1", "Y2", start = c(3, 5), end = c(6, 7))
  m <- merge(a, b)

  testthat::expect_identical(unlist(as.list(m)), c("X1", "X2", "Y1", "Y2"))
})

testthat::test_that("merge.interval_index disjoint fast paths match general path", {
  a <- interval_index("p", "q", start = c(0, 2), end = c(1, 3))
  b <- interval_index("r", "s", start = c(5, 7), end = c(6, 8))

  testthat::expect_identical(
    unlist(as.list(merge(a, b))),
    c("p", "q", "r", "s")
  )
  testthat::expect_identical(
    unlist(as.list(merge(b, a))),
    c("p", "q", "r", "s")
  )
})

testthat::test_that("merge.interval_index preserves min/max endpoints", {
  a <- interval_index("A", "B", start = c(1, 5), end = c(4, 8))
  b <- interval_index("C", "D", start = c(3, 7), end = c(6, 10))
  m <- merge(a, b)

  testthat::expect_identical(min_endpoint(m), 1)
  testthat::expect_identical(max_endpoint(m), 10)
})

testthat::test_that("merge.interval_index point queries work on merged result", {
  a <- interval_index("A", start = 1, end = 5)
  b <- interval_index("B", start = 2, end = 4)
  m <- merge(a, b)

  testthat::expect_identical(
    unlist(as.list(peek_all_point(m, 3))),
    c("A", "B")
  )
})

testthat::test_that("merge.interval_index empty short-circuits", {
  a <- interval_index("A", start = 1, end = 2)
  testthat::expect_identical(unlist(as.list(merge(interval_index(), a))), "A")
  testthat::expect_identical(unlist(as.list(merge(a, interval_index()))), "A")
  testthat::expect_identical(length(merge(interval_index(), interval_index())), 0L)
})

testthat::test_that("merge.interval_index does not mutate sources", {
  a <- interval_index("A", start = 1, end = 2)
  b <- interval_index("B", start = 3, end = 4)
  merge(a, b)

  testthat::expect_identical(length(a), 1L)
  testthat::expect_identical(length(b), 1L)
})

testthat::test_that("merge.interval_index errors on bounds mismatch", {
  ah <- interval_index("x", start = 1, end = 2, bounds = "[)")
  ac <- interval_index("y", start = 1, end = 2, bounds = "[]")
  testthat::expect_error(merge(ah, ac), "bounds")
})

testthat::test_that("merge.interval_index errors on endpoint-type mismatch", {
  an <- interval_index("a", start = 1, end = 2)             # numeric
  ac <- interval_index("b", start = "p", end = "q")         # character
  testthat::expect_error(merge(an, ac), "endpoint type")
})

testthat::test_that("merge.interval_index errors on non-interval_index y", {
  a <- interval_index("A", start = 1, end = 2)
  testthat::expect_error(merge(a, flexseq("x")), "interval_ind")
})
