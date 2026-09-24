#SO

validate_fingertree_invariants <- function(t) {
  is_homogeneous <- function(xs) {
    if(length(xs) <= 1) {
      return(TRUE)
    }
    kinds <- vapply(xs, is_structural_node, logical(1))
    all(kinds == kinds[[1]])
  }

  walk <- function(x) {
    if(x %isa% Empty) {
      testthat::expect_true(!is.null(attr(x, "monoids")))
      testthat::expect_true(!is.null(attr(x, "measures")))
      return(invisible(TRUE))
    }

    if(x %isa% Single) {
      testthat::expect_identical(length(x), 1L)
      testthat::expect_true(!is.null(attr(x, "monoids")))
      testthat::expect_true(!is.null(attr(x, "measures")))
      return(invisible(TRUE))
    }

    if(x %isa% Deep) {
      testthat::expect_true(length(x$prefix) >= 1 && length(x$prefix) <= 4)
      testthat::expect_true(length(x$suffix) >= 1 && length(x$suffix) <= 4)
      testthat::expect_true(is_homogeneous(x$prefix))
      testthat::expect_true(is_homogeneous(x$suffix))
      testthat::expect_true(!is.null(attr(x, "monoids")))
      testthat::expect_true(!is.null(attr(x, "measures")))
      walk(.ft_middle(x))
      return(invisible(TRUE))
    }

    if(x %isa% Node) {
      testthat::expect_true(length(x) %in% c(2L, 3L))
      testthat::expect_true(is_homogeneous(x))
      testthat::expect_true(!is.null(attr(x, "monoids")))
      testthat::expect_true(!is.null(attr(x, "measures")))
      for(el in x) {
        if(is_structural_node(el)) {
          walk(el)
        }
      }
      return(invisible(TRUE))
    }

    if(x %isa% Digit) {
      testthat::expect_true(length(x) >= 1 && length(x) <= 4)
      testthat::expect_true(is_homogeneous(x))
      testthat::expect_true(!is.null(attr(x, "monoids")))
      testthat::expect_true(!is.null(attr(x, "measures")))
      for(el in x) {
        if(is_structural_node(el)) {
          walk(el)
        }
      }
      return(invisible(TRUE))
    }

    testthat::fail(paste("Unexpected node type:", paste(class(x), collapse = "/")))
  }

  walk(t)
  invisible(TRUE)
}

testthat::test_that("structural invariants hold after mixed updates", {
  mr <- measure_monoid(function(a, b) a + b, 0, function(el) 1)
  t <- add_monoids(flexseq(), list(count = mr))
  for(i in 1:30) {
    if(i %% 2 == 0) {
      t <- push_back(t, letters[i %% 26 + 1])
    } else {
      t <- push_front(t, letters[i %% 26 + 1])
    }
  }
  validate_fingertree_invariants(t)
})

testthat::test_that("structural invariants hold after concat and split", {
  mr <- measure_monoid(function(a, b) a + b, 0, function(el) 1)
  t1 <- add_monoids(as_flexseq(letters[1:12]), list(count = mr))
  t2 <- add_monoids(as_flexseq(letters[13:20]), list(count = mr))
  t <- c(t1, t2)
  validate_fingertree_invariants(t)

  s <- split_by_predicate(t, function(v) v >= 10, ".size")
  validate_fingertree_invariants(s$left)
  validate_fingertree_invariants(s$right)
})

testthat::test_that("measured deep trees retain root measure through updates", {
  mr <- measure_monoid(function(a, b) a + b, 0, function(el) 1)
  t <- add_monoids(as_flexseq(letters[1:10]), list(count = mr))
  t <- push_front(t, "z")
  t <- push_back(t, "y")
  testthat::expect_identical(attr(t, "measures")$.size, 12)
  validate_fingertree_invariants(t)
})
