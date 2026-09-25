# Regression guard for the iterative bulk node-grouping in the reference tree
# builder (.ft_tree_from_ordered_ref / .ft_measured_nodes_bulk).
#
# The core `measured_nodes()` is a faithful recursive transliteration of
# Hinze & Paterson's `nodes`; safe in Haskell but O(n)-deep on R's C stack. The
# bulk builder fed it the whole ~n-element middle, overflowing the stack for
# large n (~21k frames at n=65536). `.ft_measured_nodes_bulk` groups iteratively
# and must (a) produce byte-identical output to the recursive primitive and
# (b) let the pure-R reference path build at sizes the C++ path targets.

.expect_bulk_matches_recursive <- function(k) {
  ms <- attr(as_flexseq(as.list(1:4)), "monoids", exact = TRUE)
  for (kk in k) {
    l <- as.list(seq_len(kk))
    expect_identical(
      Immutables:::.ft_measured_nodes_bulk(l, ms),
      Immutables:::measured_nodes(l, ms),
      info = paste("k =", kk)
    )
  }
}

# Small/mid sizes cover every 2-3 node-grouping boundary and run everywhere.
test_that(".ft_measured_nodes_bulk matches recursive measured_nodes exactly", {
  .expect_bulk_matches_recursive(c(2:20, 50L, 99L, 100L))
})

# Large spot-checks are gated: the recursive reference is O(n^2) (~35s at
# k = 1000), so run them on dev/CI only. The identity is algebraic and already
# checked at every smaller size above.
test_that(".ft_measured_nodes_bulk matches recursive measured_nodes at large k", {
  skip_on_cran()
  .expect_bulk_matches_recursive(c(256L, 1000L))
})

.with_use_cpp <- function(flag, expr) {
  old <- options(immutables.use_cpp = isTRUE(flag))
  on.exit(options(old), add = TRUE)
  force(expr)
}

test_that("pure-R reference build survives large n without C stack overflow", {
  # Expensive scale/overflow guard (~35s+ at full n): keep at full strength on
  # dev/CI, but skip on CRAN where it would blow the 10-minute check budget.
  skip_on_cran()
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
  # Large-n R/C++ identity (~8s): element-wise agreement is already covered at
  # small n by the k-loop above and by test-cpp-parity.R, so skip on CRAN.
  skip_on_cran()
  n <- 20000L
  vals <- as.list(seq_len(n))
  x_cpp <- .with_use_cpp(TRUE,  as_flexseq(vals))
  x_r   <- .with_use_cpp(FALSE, as_flexseq(vals))
  expect_identical(as.list(x_cpp), as.list(x_r))
})
