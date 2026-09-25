# Parity tests: native C++ pop path vs. R fallback for all 4 relations.
#
# These tests are written BEFORE the C++ pop path exists (Phase 3b Task 6).
# Right now both branches run the R fallback so equality holds trivially.
# After Tasks 7+8 wire the native pop path the tests become the correctness guard.
#
# Helper used: .ivx_with_cpp_scan_enabled(flag, expr)  — defined in helper-ivx.R
#
# NOTE: pop ops are persistent — they return a new `$remaining` index and leave
# the input untouched — so a single shared fixture is safe to reuse across every
# cpp/r_fb call and iteration. (Building a fresh index per call cost ~5s for no
# benefit.) Query points are sampled at a low and a high value; all 4 relations
# and all 4 bounds tokens are still exercised.


# ---- shared fixture --------------------------------------------------------

# Deterministic index, built once and reused (pop is non-destructive).
pop_ix <- local({
  set.seed(42)
  starts <- sort(sample.int(2000L, 300L))
  widths <- sample.int(40L, 300L, replace = TRUE)
  ends   <- starts + widths
  vals   <- sprintf("v%03d", seq_along(starts))
  as_interval_index(as.list(vals), start = starts, end = ends,
                    default_query_bounds = "[]")
})


# ---- point relation ---------------------------------------------------------

test_that("native pop matches R fallback for point relation", {
  bounds_tokens <- c("[)", "[]", "()", "(]")

  for (bnd in bounds_tokens) {
    for (qpt in c(500L, 1800L)) {

      # first-hit
      cpp_v <- .ivx_with_cpp_scan_enabled(TRUE,  pop_point(pop_ix, qpt, bounds = bnd))
      r_v   <- .ivx_with_cpp_scan_enabled(FALSE, pop_point(pop_ix, qpt, bounds = bnd))
      expect_equal(cpp_v$value, r_v$value)
      expect_equal(cpp_v$start, r_v$start)
      expect_equal(cpp_v$end,   r_v$end)
      expect_equal(as.list(cpp_v$remaining), as.list(r_v$remaining))

      # all-match
      cpp_a <- .ivx_with_cpp_scan_enabled(TRUE,  pop_all_point(pop_ix, qpt, bounds = bnd))
      r_a   <- .ivx_with_cpp_scan_enabled(FALSE, pop_all_point(pop_ix, qpt, bounds = bnd))
      expect_equal(as.list(cpp_a$elements),  as.list(r_a$elements))
      expect_equal(as.list(cpp_a$remaining), as.list(r_a$remaining))
    }
  }
})


# ---- overlaps relation ------------------------------------------------------

test_that("native pop matches R fallback for overlaps relation", {
  bounds_tokens <- c("[)", "[]", "()", "(]")

  for (bnd in bounds_tokens) {
    for (qpt in c(500L, 1800L)) {
      qlo <- qpt
      qhi <- qpt + 100L

      # first-hit
      cpp_v <- .ivx_with_cpp_scan_enabled(TRUE,  pop_overlapping(pop_ix, qlo, qhi, bounds = bnd))
      r_v   <- .ivx_with_cpp_scan_enabled(FALSE, pop_overlapping(pop_ix, qlo, qhi, bounds = bnd))
      expect_equal(cpp_v$value, r_v$value)
      expect_equal(cpp_v$start, r_v$start)
      expect_equal(cpp_v$end,   r_v$end)
      expect_equal(as.list(cpp_v$remaining), as.list(r_v$remaining))

      # all-match
      cpp_a <- .ivx_with_cpp_scan_enabled(TRUE,  pop_all_overlapping(pop_ix, qlo, qhi, bounds = bnd))
      r_a   <- .ivx_with_cpp_scan_enabled(FALSE, pop_all_overlapping(pop_ix, qlo, qhi, bounds = bnd))
      expect_equal(as.list(cpp_a$elements),  as.list(r_a$elements))
      expect_equal(as.list(cpp_a$remaining), as.list(r_a$remaining))
    }
  }
})


# ---- containing relation ----------------------------------------------------

test_that("native pop matches R fallback for containing relation", {
  bounds_tokens <- c("[)", "[]", "()", "(]")

  for (bnd in bounds_tokens) {
    for (qpt in c(500L, 1800L)) {
      qlo <- qpt
      qhi <- qpt + 100L

      # first-hit
      cpp_v <- .ivx_with_cpp_scan_enabled(TRUE,  pop_containing(pop_ix, qlo, qhi, bounds = bnd))
      r_v   <- .ivx_with_cpp_scan_enabled(FALSE, pop_containing(pop_ix, qlo, qhi, bounds = bnd))
      expect_equal(cpp_v$value, r_v$value)
      expect_equal(cpp_v$start, r_v$start)
      expect_equal(cpp_v$end,   r_v$end)
      expect_equal(as.list(cpp_v$remaining), as.list(r_v$remaining))

      # all-match
      cpp_a <- .ivx_with_cpp_scan_enabled(TRUE,  pop_all_containing(pop_ix, qlo, qhi, bounds = bnd))
      r_a   <- .ivx_with_cpp_scan_enabled(FALSE, pop_all_containing(pop_ix, qlo, qhi, bounds = bnd))
      expect_equal(as.list(cpp_a$elements),  as.list(r_a$elements))
      expect_equal(as.list(cpp_a$remaining), as.list(r_a$remaining))
    }
  }
})


# ---- within relation --------------------------------------------------------

test_that("native pop matches R fallback for within relation", {
  bounds_tokens <- c("[)", "[]", "()", "(]")

  for (bnd in bounds_tokens) {
    for (qpt in c(500L, 1800L)) {
      qlo <- qpt
      qhi <- qpt + 100L

      # first-hit
      cpp_v <- .ivx_with_cpp_scan_enabled(TRUE,  pop_within(pop_ix, qlo, qhi, bounds = bnd))
      r_v   <- .ivx_with_cpp_scan_enabled(FALSE, pop_within(pop_ix, qlo, qhi, bounds = bnd))
      expect_equal(cpp_v$value, r_v$value)
      expect_equal(cpp_v$start, r_v$start)
      expect_equal(cpp_v$end,   r_v$end)
      expect_equal(as.list(cpp_v$remaining), as.list(r_v$remaining))

      # all-match
      cpp_a <- .ivx_with_cpp_scan_enabled(TRUE,  pop_all_within(pop_ix, qlo, qhi, bounds = bnd))
      r_a   <- .ivx_with_cpp_scan_enabled(FALSE, pop_all_within(pop_ix, qlo, qhi, bounds = bnd))
      expect_equal(as.list(cpp_a$elements),  as.list(r_a$elements))
      expect_equal(as.list(cpp_a$remaining), as.list(r_a$remaining))
    }
  }
})
