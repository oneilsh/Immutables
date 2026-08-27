# Parity tests: native C++ peek path vs. R fallback for all 4 relations.
#
# These tests are written BEFORE the C++ peek path exists (Phase 3a Task 2).
# Right now both branches run the R fallback so equality holds trivially.
# After Task 4 wires the native path the tests become the correctness guard.
#
# Helper used: .ivx_with_cpp_scan_enabled(flag, expr)  — defined in helper-ivx.R


# ---- shared large fixture ---------------------------------------------------

make_large_ix <- function() {
  set.seed(42)
  starts <- sort(sample.int(2000L, 300L))
  widths <- sample.int(40L, 300L, replace = TRUE)
  ends   <- starts + widths
  vals   <- sprintf("v%03d", seq_along(starts))
  as_interval_index(as.list(vals), start = starts, end = ends,
                    default_query_bounds = "[]")
}


# ---- point relation ---------------------------------------------------------

test_that("native peek matches R fallback for point relation", {
  ix <- make_large_ix()
  bounds_tokens <- c("[)", "[]", "()", "(]")

  for (bnd in bounds_tokens) {
    for (qpt in c(50L, 500L, 1000L, 1800L)) {
      cpp_v <- .ivx_with_cpp_scan_enabled(TRUE,  peek_point(ix, qpt, bounds = bnd))
      r_v   <- .ivx_with_cpp_scan_enabled(FALSE, peek_point(ix, qpt, bounds = bnd))
      expect_equal(cpp_v, r_v)

      for (as_list_flag in c(TRUE, FALSE)) {
        cpp_a <- .ivx_with_cpp_scan_enabled(TRUE,  peek_all_point(ix, qpt, bounds = bnd, as_list = as_list_flag))
        r_a   <- .ivx_with_cpp_scan_enabled(FALSE, peek_all_point(ix, qpt, bounds = bnd, as_list = as_list_flag))
        expect_equal(cpp_a, r_a)
      }
    }
  }
})


# ---- overlaps relation ------------------------------------------------------

test_that("native peek matches R fallback for overlaps relation", {
  ix <- make_large_ix()
  bounds_tokens <- c("[)", "[]", "()", "(]")

  for (bnd in bounds_tokens) {
    for (qpt in c(50L, 500L, 1000L, 1800L)) {
      qlo <- qpt
      qhi <- qpt + 100L

      cpp_v <- .ivx_with_cpp_scan_enabled(TRUE,  peek_overlaps(ix, qlo, qhi, bounds = bnd))
      r_v   <- .ivx_with_cpp_scan_enabled(FALSE, peek_overlaps(ix, qlo, qhi, bounds = bnd))
      expect_equal(cpp_v, r_v)

      for (as_list_flag in c(TRUE, FALSE)) {
        cpp_a <- .ivx_with_cpp_scan_enabled(TRUE,  peek_all_overlaps(ix, qlo, qhi, bounds = bnd, as_list = as_list_flag))
        r_a   <- .ivx_with_cpp_scan_enabled(FALSE, peek_all_overlaps(ix, qlo, qhi, bounds = bnd, as_list = as_list_flag))
        expect_equal(cpp_a, r_a)
      }
    }
  }
})


# ---- containing relation ----------------------------------------------------

test_that("native peek matches R fallback for containing relation", {
  ix <- make_large_ix()
  bounds_tokens <- c("[)", "[]", "()", "(]")

  for (bnd in bounds_tokens) {
    for (qpt in c(50L, 500L, 1000L, 1800L)) {
      qlo <- qpt
      qhi <- qpt + 100L

      cpp_v <- .ivx_with_cpp_scan_enabled(TRUE,  peek_containing(ix, qlo, qhi, bounds = bnd))
      r_v   <- .ivx_with_cpp_scan_enabled(FALSE, peek_containing(ix, qlo, qhi, bounds = bnd))
      expect_equal(cpp_v, r_v)

      # peek_all_containing returns an interval_index slice (no as_list param)
      cpp_a <- .ivx_with_cpp_scan_enabled(TRUE,  peek_all_containing(ix, qlo, qhi, bounds = bnd))
      r_a   <- .ivx_with_cpp_scan_enabled(FALSE, peek_all_containing(ix, qlo, qhi, bounds = bnd))
      expect_equal(cpp_a, r_a)
    }
  }
})


# ---- within relation --------------------------------------------------------

test_that("native peek matches R fallback for within relation", {
  ix <- make_large_ix()
  bounds_tokens <- c("[)", "[]", "()", "(]")

  for (bnd in bounds_tokens) {
    for (qpt in c(50L, 500L, 1000L, 1800L)) {
      qlo <- qpt
      qhi <- qpt + 100L

      cpp_v <- .ivx_with_cpp_scan_enabled(TRUE,  peek_within(ix, qlo, qhi, bounds = bnd))
      r_v   <- .ivx_with_cpp_scan_enabled(FALSE, peek_within(ix, qlo, qhi, bounds = bnd))
      expect_equal(cpp_v, r_v)

      # peek_all_within returns an interval_index slice (no as_list param)
      cpp_a <- .ivx_with_cpp_scan_enabled(TRUE,  peek_all_within(ix, qlo, qhi, bounds = bnd))
      r_a   <- .ivx_with_cpp_scan_enabled(FALSE, peek_all_within(ix, qlo, qhi, bounds = bnd))
      expect_equal(cpp_a, r_a)
    }
  }
})


# ---- double-endpoint (floating-point) fixture — point relation --------------

test_that("native peek matches R fallback for point relation with double endpoints", {
  set.seed(7)
  starts_d <- sort(runif(100, min = 0.0, max = 100.0))
  ends_d   <- starts_d + runif(100, 0.1, 5.0)
  vals_d   <- sprintf("d%03d", seq_along(starts_d))
  ix_d <- as_interval_index(as.list(vals_d), start = starts_d, end = ends_d,
                             default_query_bounds = "[]")

  for (qpt in c(5.0, 25.0, 50.0, 90.0)) {
    cpp_v <- .ivx_with_cpp_scan_enabled(TRUE,  peek_point(ix_d, qpt, bounds = "[]"))
    r_v   <- .ivx_with_cpp_scan_enabled(FALSE, peek_point(ix_d, qpt, bounds = "[]"))
    expect_equal(cpp_v, r_v)

    for (as_list_flag in c(TRUE, FALSE)) {
      cpp_a <- .ivx_with_cpp_scan_enabled(TRUE,  peek_all_point(ix_d, qpt, bounds = "[]", as_list = as_list_flag))
      r_a   <- .ivx_with_cpp_scan_enabled(FALSE, peek_all_point(ix_d, qpt, bounds = "[]", as_list = as_list_flag))
      expect_equal(cpp_a, r_a)
    }
  }
})


# ---- empty-result test — query point far outside the value range ------------

test_that("native peek and R fallback agree on empty result for out-of-range point query", {
  ix <- make_large_ix()

  # 9999L is well outside the generated range (max ~2040)
  cpp_v <- .ivx_with_cpp_scan_enabled(TRUE,  peek_point(ix, 9999L, bounds = "[]"))
  r_v   <- .ivx_with_cpp_scan_enabled(FALSE, peek_point(ix, 9999L, bounds = "[]"))
  expect_equal(cpp_v, r_v)        # both should be NULL

  for (as_list_flag in c(TRUE, FALSE)) {
    cpp_a <- .ivx_with_cpp_scan_enabled(TRUE,  peek_all_point(ix, 9999L, bounds = "[]", as_list = as_list_flag))
    r_a   <- .ivx_with_cpp_scan_enabled(FALSE, peek_all_point(ix, 9999L, bounds = "[]", as_list = as_list_flag))
    expect_equal(cpp_a, r_a)      # both should be an empty list / empty result
  }
})
