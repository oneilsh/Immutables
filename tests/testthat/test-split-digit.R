testthat::test_that("split_digit handles first/middle/last boundaries", {
  mr <- measure_monoid(function(a, b) a + b, 0, function(el) 1)
  ms <- ensure_size_monoids(list(count = mr))
  d <- Digit("a", "b", "c")

  s1 <- immutables:::split_digit(function(v) v >= 1, 0, d, ms, "count")
  testthat::expect_identical(s1$value, "a")
  testthat::expect_identical(unclass(s1$left), list())
  testthat::expect_identical(unclass(s1$right), list("b", "c"))

  s2 <- immutables:::split_digit(function(v) v >= 2, 0, d, ms, "count")
  testthat::expect_identical(s2$value, "b")
  testthat::expect_identical(unclass(s2$left), list("a"))
  testthat::expect_identical(unclass(s2$right), list("c"))

  s3 <- immutables:::split_digit(function(v) v >= 3, 0, d, ms, "count")
  testthat::expect_identical(s3$value, "c")
  testthat::expect_identical(unclass(s3$left), list("a", "b"))
  testthat::expect_identical(unclass(s3$right), list())
})

testthat::test_that("split_digit works when digit holds nodes", {
  mr <- measure_monoid(function(a, b) a + b, 0, function(el) 1)
  ms <- ensure_size_monoids(list(count = mr))
  n2 <- Node2("a", "b")
  n3 <- Node3("c", "d", "e")
  d <- Digit(n2, n3)

  s <- immutables:::split_digit(function(v) v >= 3, 0, d, ms, "count")
  testthat::expect_true(s$value %isa% Node)
  testthat::expect_identical(length(s$left), 1L)
  testthat::expect_identical(length(s$right), 0L)
})

testthat::test_that("split_digit errors for invalid preconditions", {
  mr <- measure_monoid(function(a, b) a + b, 0, function(el) 1)
  ms <- ensure_size_monoids(list(count = mr))
  testthat::expect_error(
    immutables:::split_digit(function(v) v >= 1, 0, list(), ms, "count"),
    "empty digit"
  )

  d <- Digit("a", "b")
  testthat::expect_error(
    immutables:::split_digit(function(v) v >= 10, 0, d, ms, "count"),
    "predicate never became true"
  )
})
