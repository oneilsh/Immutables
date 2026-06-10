# Regression guard for the iterative bulk node-grouping in the reference tree
# builder (.ft_tree_from_ordered_ref / .ft_measured_nodes_bulk).
#
# The core `measured_nodes()` is a faithful recursive transliteration of
# Hinze & Paterson's `nodes`; safe in Haskell but O(n)-deep on R's C stack. The
# bulk builder fed it the whole ~n-element middle, overflowing the stack for
# large n (~21k frames at n=65536). `.ft_measured_nodes_bulk` groups iteratively
# and must (a) produce byte-identical output to the recursive primitive and
# (b) let the pure-R reference path build at sizes the C++ path targets.

test_that(".ft_measured_nodes_bulk matches recursive measured_nodes exactly", {
  ms <- attr(as_flexseq(as.list(1:4)), "monoids", exact = TRUE)
  for (k in c(2:20, 50L, 99L, 100L, 256L, 1000L)) {
    l <- as.list(seq_len(k))
    expect_identical(
      Immutables:::.ft_measured_nodes_bulk(l, ms),
      Immutables:::measured_nodes(l, ms),
      info = paste("k =", k)
    )
  }
})

.with_use_cpp <- function(flag, expr) {
  old <- options(immutables.use_cpp = isTRUE(flag))
  on.exit(options(old), add = TRUE)
  force(expr)
}

test_that("pure-R reference build survives large n without C stack overflow", {
  # n chosen well past the recursive depth that previously overflowed
  # (~21k frames at 65536). Force the R path with immutables.use_cpp = FALSE.
  n <- 65536L
  x <- .with_use_cpp(FALSE, as_flexseq(as.list(seq_len(n))))
  expect_identical(length(x), n)
  # round-trips correctly at the ends and across a split
  expect_identical(x[[1L]], 1L)
  expect_identical(x[[n]], n)
  expect_identical(as.list(x[1:5]), as.list(1:5))
})

test_that("R-built and C++-built trees agree element-wise at scale", {
  n <- 20000L
  vals <- as.list(seq_len(n))
  x_cpp <- .with_use_cpp(TRUE,  as_flexseq(vals))
  x_r   <- .with_use_cpp(FALSE, as_flexseq(vals))
  expect_identical(as.list(x_cpp), as.list(x_r))
})
