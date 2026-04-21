testthat::test_that("viewL and viewR return boundary element and remainder", {
  m_count <- measure_monoid(function(a, b) a + b, 0, function(el) 1)
  t <- add_monoids(as_flexseq(letters[1:5]), list(count = m_count))
  ms <- attr(t, "monoids")

  vl <- Immutables:::viewL(t, ms)
  testthat::expect_identical(vl$value, "a")
  testthat::expect_identical(tree_chars(vl$rest), "bcde")

  vr <- Immutables:::viewR(t, ms)
  testthat::expect_identical(vr$value, "e")
  testthat::expect_identical(tree_chars(vr$rest), "abcd")
})

testthat::test_that("viewL/viewR on Single produce Empty remainder", {
  t <- as_flexseq("x")
  ms <- attr(t, "monoids")

  vl <- Immutables:::viewL(t, ms)
  vr <- Immutables:::viewR(t, ms)

  testthat::expect_identical(vl$value, "x")
  testthat::expect_identical(vr$value, "x")
  testthat::expect_true(vl$rest %isa% Empty)
  testthat::expect_true(vr$rest %isa% Empty)
})

testthat::test_that("deepL/deepR collapse correctly when middle is Empty", {
  ms <- ensure_size_monoids(list(.size = size_measure_monoid()))
  pr <- list()
  sf <- Digit("c", "d")
  t1 <- Immutables:::deepL(pr, measured_empty(ms), sf, ms)
  testthat::expect_identical(tree_chars(t1), "cd")

  pr2 <- Digit("a", "b")
  sf2 <- list()
  t2 <- Immutables:::deepR(pr2, measured_empty(ms), sf2, ms)
  testthat::expect_identical(tree_chars(t2), "ab")
})

testthat::test_that("measured view helpers preserve measures attrs", {
  t <- as_flexseq(letters[1:4])
  ms <- attr(t, "monoids")

  vl <- Immutables:::viewL(t, ms)
  vr <- Immutables:::viewR(t, ms)

  testthat::expect_identical(attr(vl$rest, "measures")$.size, 3)
  testthat::expect_identical(attr(vr$rest, "measures")$.size, 3)
})
