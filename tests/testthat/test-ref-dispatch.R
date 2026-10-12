# Pins the dispatch behavior of the pure-R reference layer (add_left,
# add_right, app3/concat, measured_digit) independent of the C++ backend.

with_r_backend <- function(expr) {
  old <- getOption("immutables.use_cpp")
  options(immutables.use_cpp = FALSE)
  on.exit(options(immutables.use_cpp = old), add = TRUE)
  force(expr)
}

shape_tree <- function(shape, chars) {
  t <- switch(shape,
    Empty = flexseq(),
    Single = as_flexseq(chars[1]),
    Deep = as_flexseq(chars)
  )
  testthat::expect_true(inherits(t, shape))
  t
}

testthat::test_that("concat dispatch covers every Empty/Single/Deep pairing", {
  with_r_backend({
    left_chars <- letters[1:7]
    right_chars <- LETTERS[1:9]
    for(ls in c("Empty", "Single", "Deep")) {
      for(rs in c("Empty", "Single", "Deep")) {
        x <- shape_tree(ls, left_chars)
        y <- shape_tree(rs, right_chars)
        ms <- attr(x, "monoids")
        out <- Immutables:::.as_flexseq(Immutables:::concat(x, y, ms))
        expected <- paste0(tree_chars(x), tree_chars(y))
        testthat::expect_identical(tree_chars(out), expected, info = paste(ls, rs))
        testthat::expect_true(Immutables:::validate_tree(out), info = paste(ls, rs))
      }
    }
  })
})

testthat::test_that("add_left/add_right dispatch through Empty, Single, and full-digit Deep", {
  with_r_backend({
    t_left <- flexseq()
    t_right <- flexseq()
    ms <- attr(t_left, "monoids")
    for(i in 1:12) {
      t_left <- Immutables:::.as_flexseq(Immutables:::add_left(t_left, letters[i], ms))
      t_right <- Immutables:::.as_flexseq(Immutables:::add_right(t_right, letters[i], ms))
    }
    testthat::expect_identical(tree_chars(t_left), paste0(rev(letters[1:12]), collapse = ""))
    testthat::expect_identical(tree_chars(t_right), paste0(letters[1:12], collapse = ""))
    testthat::expect_true(inherits(t_left, "Deep"))
    testthat::expect_true(inherits(t_right, "Deep"))
    testthat::expect_true(Immutables:::validate_tree(t_left))
    testthat::expect_true(Immutables:::validate_tree(t_right))
  })
})

testthat::test_that("add_left/add_right on a Digit extend the digit", {
  t <- flexseq()
  ms <- attr(t, "monoids")
  d <- Immutables:::Digit("b", "c")
  dl <- Immutables:::add_left(d, "a", ms)
  dr <- Immutables:::add_right(d, "d", ms)
  testthat::expect_true(inherits(dl, "Digit"))
  testthat::expect_identical(unclass(dl)[1:3], list("a", "b", "c"))
  testthat::expect_identical(unclass(dr)[1:3], list("b", "c", "d"))
})

testthat::test_that("measured_digit builds digits of arity 1 to 4", {
  ms <- attr(flexseq(), "monoids")
  for(k in 1:4) {
    args <- c(as.list(letters[seq_len(k)]), list(monoids = ms))
    d <- do.call(Immutables:::measured_digit, args)
    testthat::expect_true(inherits(d, "Digit"), info = k)
    testthat::expect_identical(length(d), k, info = k)
    testthat::expect_false(is.null(attr(d, "measures")), info = k)
  }
  testthat::expect_error(Immutables:::measured_digit(monoids = ms), "1 to 4")
  testthat::expect_error(do.call(Immutables:::measured_digit, c(as.list(letters[1:5]), list(monoids = ms))), "1 to 4")
})

testthat::test_that("reference dispatch errors on unsupported input instead of returning NULL", {
  ms <- attr(flexseq(), "monoids")
  testthat::expect_error(Immutables:::add_left(list(1), "x", ms))
  testthat::expect_error(Immutables:::add_right(list(1), "x", ms))
  testthat::expect_error(Immutables:::app3(list(1), list(), list(2), ms))
})
