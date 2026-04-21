testthat::test_that("get_measure returns cached aggregate for a user-attached monoid", {
  sum_m <- measure_monoid(function(a, b) a + b, 0, function(el) el)
  x <- add_monoids(as_flexseq(c(3, 1, 4, 1, 5, 9, 2, 6)), list(sum = sum_m))
  testthat::expect_identical(get_measure(x, "sum"), 31)
})

testthat::test_that("get_measure returns built-in .size as element count", {
  x <- as_flexseq(letters[1:5])
  testthat::expect_identical(get_measure(x, ".size"), 5)
  testthat::expect_identical(get_measure(flexseq(), ".size"), 0)
})

testthat::test_that("get_measure reads list-valued built-in monoids on priority_queue", {
  q <- priority_queue("a", "b", "c", priorities = c(5, 1, 3))
  m_min <- get_measure(q, ".pq_min")
  testthat::expect_true(isTRUE(m_min$has))
  testthat::expect_identical(m_min$priority, 1)

  m_max <- get_measure(q, ".pq_max")
  testthat::expect_true(isTRUE(m_max$has))
  testthat::expect_identical(m_max$priority, 5)
})

testthat::test_that("get_measure aggregate reflects splits via split_by_predicate", {
  sum_m <- measure_monoid(function(a, b) a + b, 0, function(el) el)
  x <- add_monoids(as_flexseq(c(1, 2, 3, 4, 5)), list(sum = sum_m))
  parts <- split_by_predicate(x, function(m) m >= 6, "sum")
  testthat::expect_identical(get_measure(parts$left, "sum") + get_measure(parts$right, "sum"), 15)
})

testthat::test_that("get_measures returns a per-element flexseq", {
  sum_m <- measure_monoid(function(a, b) a + b, 0, function(el) el)
  x <- add_monoids(as_flexseq(c(3, 1, 4, 1, 5, 9)), list(sum = sum_m))
  per <- get_measures(x, "sum")
  testthat::expect_true("flexseq" %in% class(per))
  testthat::expect_identical(length(per), 6L)
  testthat::expect_identical(unlist(as.list(per)), c(3, 1, 4, 1, 5, 9))
})

testthat::test_that("get_measures on an empty flexseq returns an empty flexseq", {
  sum_m <- measure_monoid(function(a, b) a + b, 0, function(el) el)
  x <- add_monoids(flexseq(), list(sum = sum_m))
  per <- get_measures(x, "sum")
  testthat::expect_true("flexseq" %in% class(per))
  testthat::expect_identical(length(per), 0L)
})

testthat::test_that("get_measures on priority_queue yields per-element .pq_min records", {
  q <- priority_queue("a", "b", "c", priorities = c(5, 1, 3))
  per <- get_measures(q, ".pq_min")
  testthat::expect_identical(length(per), 3L)
  rec1 <- as.list(per)[[1]]
  testthat::expect_true(isTRUE(rec1$has))
  testthat::expect_identical(rec1$priority, 5)
})

testthat::test_that("get_measure errors when x is not a finger-tree structure", {
  testthat::expect_error(get_measure(list(), "sum"), "finger-tree structure")
  testthat::expect_error(get_measure(1:3, ".size"), "finger-tree structure")
  testthat::expect_error(get_measures(list(), "sum"), "finger-tree structure")
})

testthat::test_that("get_measure errors when monoid_name is not a single non-empty string", {
  x <- as_flexseq(1:3)
  testthat::expect_error(get_measure(x, 1),              "single non-empty string")
  testthat::expect_error(get_measure(x, c("a", "b")),    "single non-empty string")
  testthat::expect_error(get_measure(x, NA_character_),  "single non-empty string")
  testthat::expect_error(get_measure(x, ""),             "single non-empty string")
  testthat::expect_error(get_measures(x, NA_character_), "single non-empty string")
})

testthat::test_that("get_measure errors when the monoid is not attached", {
  x <- as_flexseq(1:3)
  testthat::expect_error(get_measure(x, "not_attached"), "not attached")
  testthat::expect_error(get_measures(x, "not_attached"), "not attached")
})
