testthat::test_that("locate_by_predicate finds same distinguished element as split_around_by_predicate", {
  t <- as_flexseq(letters[1:8])

  l <- locate_by_predicate(t, function(v) v >= 5, ".size")
  s <- split_around_by_predicate(t, function(v) v >= 5, ".size")

  testthat::expect_true(l$found)
  testthat::expect_identical(l$value, s$value)
})

testthat::test_that("locate_by_predicate metadata for .size is symmetric", {
  t <- as_flexseq(letters[1:6])

  l <- locate_by_predicate(t, function(v) v >= 4, ".size", include_metadata = TRUE)

  testthat::expect_true(l$found)
  testthat::expect_identical(l$value, "d")
  testthat::expect_identical(l$metadata$left_measure, 3)
  testthat::expect_identical(l$metadata$hit_measure, 4)
  testthat::expect_identical(l$metadata$right_measure, 2)
  testthat::expect_identical(l$metadata$index, 4L)
})

testthat::test_that("locate_by_predicate metadata works with non-size monoid and .size index", {
  sum_m <- measure_monoid(`+`, 0, as.numeric)
  t <- add_monoids(as_flexseq(1:6), list(sum = sum_m))

  l <- locate_by_predicate(t, function(v) v >= 10, "sum", include_metadata = TRUE)

  testthat::expect_true(l$found)
  testthat::expect_identical(l$value, 4L)
  testthat::expect_identical(l$metadata$left_measure, 6)
  testthat::expect_identical(l$metadata$hit_measure, 10)
  testthat::expect_identical(l$metadata$right_measure, 11)
  testthat::expect_identical(l$metadata$index, 4L)
})

testthat::test_that("locate_by_predicate returns not-found without reconstruction", {
  t <- as_flexseq(letters[1:5])

  l <- locate_by_predicate(t, function(v) v >= 99, ".size")
  testthat::expect_false(l$found)
  testthat::expect_null(l$value)

  lm <- locate_by_predicate(t, function(v) v >= 99, ".size", include_metadata = TRUE)
  testthat::expect_false(lm$found)
  testthat::expect_null(lm$value)
  testthat::expect_identical(lm$metadata$left_measure, 5)
  testthat::expect_null(lm$metadata$hit_measure)
  testthat::expect_null(lm$metadata$right_measure)
  testthat::expect_null(lm$metadata$index)
})
