testthat::test_that("tree construction defaults to .size monoid", {
  t <- as_flexseq(1:3)
  ms <- attr(t, "measures")
  testthat::expect_identical(ms$.size, 3)
  testthat::expect_true(!is.null(attr(t, "monoids")[[".size"]]))

  e <- flexseq()
  testthat::expect_true(e %isa% Empty)
  testthat::expect_identical(attr(e, "measures")$.size, 0)
})

testthat::test_that("flexseq class does not inherit from list and length is element count", {
  t <- as_flexseq(letters[1:5])
  testthat::expect_true("flexseq" %in% class(t))
  testthat::expect_false("list" %in% class(t))
  testthat::expect_identical(length(t), 5L)
})

testthat::test_that("as_flexseq returns payload-only flexseq and rejects extra args", {
  from_default <- as_flexseq(1:3)
  from_flex <- as_flexseq(as_flexseq(1:3))
  testthat::expect_identical(as.list(from_default), as.list(1:3))
  testthat::expect_identical(as.list(from_flex), as.list(1:3))

  # drop_meta was removed; passing it should error (no `...` fallthrough).
  testthat::expect_error(as_flexseq(1:3, drop_meta = TRUE))
  testthat::expect_error(as_flexseq(as_flexseq(1:3), drop_meta = FALSE))
})

testthat::test_that("add_monoids merges and supports overwrite flag", {
  t <- as_flexseq(1:5)
  sum_m <- measure_monoid(function(a, b) a + b, 0, function(el) el)
  t2 <- add_monoids(t, list(sum = sum_m))

  testthat::expect_identical(attr(t2, "measures")$sum, 15)
  testthat::expect_identical(attr(t2, "measures")$.size, 5)

  sum2 <- measure_monoid(function(a, b) a + b + 1, 0, function(el) el)
  testthat::expect_error(
    add_monoids(t2, list(sum = sum2), overwrite = FALSE),
    "already exist"
  )

  t3 <- add_monoids(t2, list(sum = sum2), overwrite = TRUE)
  testthat::expect_true(!identical(attr(t2, "measures")$sum, attr(t3, "measures")$sum))
})

testthat::test_that("monoid specs are normalized to canonical named layout", {
  raw <- list(
    function(a, b) a + b,
    0L,
    function(el) as.integer(el)
  )
  class(raw) <- c("measure_monoid", "MeasureMonoid", "list")

  x <- add_monoids(as_flexseq(1:5), list(sum = raw))
  ms <- attr(x, "monoids", exact = TRUE)
  sum_m <- ms$sum

  testthat::expect_identical(names(sum_m), c("f", "i", "measure"))
  testthat::expect_true(is.function(sum_m$f))
  testthat::expect_true(is.function(sum_m$measure))
  testthat::expect_identical(sum_m$measure(7L), 7L)
})

testthat::test_that("add_monoids blocks reserved monoid names by type", {
  sum_m <- measure_monoid(function(a, b) a + b, 0, function(el) 1L)

  fx <- as_flexseq(1:3)
  testthat::expect_error(
    add_monoids(fx, list(.size = sum_m), overwrite = TRUE),
    "Reserved monoid names cannot be supplied for flexseq"
  )

  pq <- priority_queue("a", "b", priorities = c(2, 1))
  testthat::expect_error(
    add_monoids(pq, list(.pq_min = sum_m), overwrite = TRUE),
    "Reserved monoid names cannot be supplied for priority_queue"
  )

  os <- as_ordered_sequence(list("a", "b"), keys = c(1, 2))
  testthat::expect_error(
    add_monoids(os, list(.oms_max_key = sum_m), overwrite = TRUE),
    "Reserved monoid names cannot be supplied for ordered_sequence"
  )

  ix <- interval_index("a", start = 1, end = 2)
  testthat::expect_error(
    add_monoids(ix, list(.ivx_max_end = sum_m), overwrite = TRUE),
    "Reserved monoid names cannot be supplied for interval_index"
  )
})

testthat::test_that("advanced structures require entry-style measure functions", {
  pq <- priority_queue("a", priorities = 1)
  pq_tuple <- measure_monoid(`+`, 0, function(value, priority) as.numeric(priority))
  testthat::expect_error(add_monoids(pq, list(m = pq_tuple)))

  os <- as_ordered_sequence(list("a"), keys = 1)
  os_tuple <- measure_monoid(`+`, 0, function(value, key) as.numeric(key))
  testthat::expect_error(add_monoids(os, list(m = os_tuple)))

  ix <- as_interval_index(list("a"), start = 1, end = 2)
  ix_tuple <- measure_monoid(`+`, 0, function(value, start, end) as.numeric(end - start))
  testthat::expect_error(add_monoids(ix, list(m = ix_tuple)))
})

testthat::test_that("concat_trees unions monoids on shared names", {
  a <- measure_monoid(function(x, y) x + y, 0, function(el) el)
  b <- measure_monoid(function(x, y) x + y, 0, function(el) 1)

  t1 <- add_monoids(as_flexseq(1:2), list(sum = a))
  t2 <- add_monoids(as_flexseq(3:4), list(cnt = b))
  t <- c(t1, t2)
  testthat::expect_true(all(c(".size", "sum", "cnt") %in% names(attr(t, "monoids"))))

  # shared name path: left definition is assumed authoritative
  t3 <- add_monoids(as_flexseq(1:2), list(sum = a))
  t4 <- add_monoids(as_flexseq(3:4), list(sum = measure_monoid(function(x, y) x + y, 0, function(el) 1)))
  t_merged <- c(t3, t4)
  testthat::expect_true("sum" %in% names(attr(t_merged, "monoids")))
})

testthat::test_that("peek/pop helpers work and are persistent", {
  x <- as_flexseq(letters[1:4])

  testthat::expect_identical(peek_front(x), "a")
  testthat::expect_identical(peek_back(x), "d")
  testthat::expect_identical(peek_at(x, 2), "b")

  pf <- pop_front(x)
  testthat::expect_identical(pf$value, "a")
  testthat::expect_identical(as.list(pf$remaining), as.list(letters[2:4]))

  pb <- pop_back(x)
  testthat::expect_identical(pb$value, "d")
  testthat::expect_identical(as.list(pb$remaining), as.list(letters[1:3]))

  pm <- pop_at(x, 3)
  testthat::expect_identical(pm$value, "c")
  testthat::expect_identical(as.list(pm$remaining), as.list(c("a", "b", "d")))

  testthat::expect_identical(as.list(x), as.list(letters[1:4]))
})

testthat::test_that("legacy payload field names are absent after value rename", {
  x <- as_flexseq(letters[1:2])
  out <- pop_front(x)
  testthat::expect_identical(out$value, "a")
  testthat::expect_null(out$element)
})

testthat::test_that("peek/pop helpers return non-throwing miss results on empty input", {
  x <- flexseq()
  testthat::expect_null(peek_front(x))
  testthat::expect_null(peek_back(x))
  testthat::expect_null(peek_at(x, 1))

  pf <- pop_front(x)
  pb <- pop_back(x)
  pa <- pop_at(x, 1)
  testthat::expect_null(pf$value)
  testthat::expect_identical(length(pf$remaining), 0L)
  testthat::expect_null(pb$value)
  testthat::expect_identical(length(pb$remaining), 0L)
  testthat::expect_null(pa$value)
  testthat::expect_identical(length(pa$remaining), 0L)
})

testthat::test_that("peek_at/pop_at validate positional index shape and treat out-of-range as miss", {
  x <- as_flexseq(letters[1:4])
  testthat::expect_error(peek_at(x, 0), "positive integer")
  testthat::expect_null(peek_at(x, 5))
  testthat::expect_error(peek_at(x, c(1, 2)), "single positive integer")

  testthat::expect_error(pop_at(x, 0), "positive integer")
  miss <- pop_at(x, 5)
  testthat::expect_null(miss$value)
  testthat::expect_identical(as.list(miss$remaining), as.list(x))
  testthat::expect_error(pop_at(x, c(1, 2)), "single positive integer")
})

testthat::test_that("insert_at inserts before index and preserves source persistence", {
  x <- as_flexseq(letters[1:4])

  a <- insert_at(x, 1, "z")
  testthat::expect_identical(as.list(a), as.list(c("z", "a", "b", "c", "d")))

  b <- insert_at(x, 3, c("x", "y"))
  testthat::expect_identical(as.list(b), as.list(c("a", "b", "x", "y", "c", "d")))

  c <- insert_at(x, 5, list("q"))
  testthat::expect_identical(as.list(c), as.list(c("a", "b", "c", "d", "q")))

  ins <- as_flexseq(c("m", "n"))
  d <- insert_at(x, 2, ins)
  testthat::expect_identical(as.list(d), as.list(c("a", "m", "n", "b", "c", "d")))

  testthat::expect_identical(as.list(x), as.list(letters[1:4]))
})

testthat::test_that("insert_at validates bounds and supports empty insert payload", {
  x <- as_flexseq(letters[1:4])
  testthat::expect_error(insert_at(x, 0, "z"), "positive integer")
  testthat::expect_error(insert_at(x, 6, "z"), "out of bounds")
  testthat::expect_error(insert_at(x, c(1, 2), "z"), "single positive integer")

  x2 <- insert_at(x, 2, list())
  testthat::expect_identical(as.list(x2), as.list(x))
})

testthat::test_that("insert_at enforces global named/unnamed consistency", {
  unnamed <- as_flexseq(1:3)
  named <- as_flexseq(setNames(as.list(1:3), c("a", "b", "c")))

  testthat::expect_error(
    insert_at(unnamed, 2, setNames(as.list(9), "k")),
    "mixed named and unnamed"
  )
  testthat::expect_error(
    insert_at(named, 2, list(9)),
    "mixed named and unnamed"
  )

  out <- insert_at(named, 2, setNames(as.list(c(9, 8)), c("k1", "k2")))
  testthat::expect_identical(out[["k1"]], 9)
  testthat::expect_identical(out[["k2"]], 8)
  testthat::expect_identical(length(out), 5L)
})
