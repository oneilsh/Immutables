test_that("peek_all_point as_list returns parallel vectors matching peek_all_point default", {
  ix <- interval_index("a", "b", "c", "d",
                       start = c(1, 2, 4, 6),
                       end   = c(3, 2, 5, 8))

  as_list <- peek_all_point(ix, 2, bounds = "[]", as_list = TRUE)

  # point=2, bounds="[]": entries with start<=2<=end are "a" (1-3) and "b" (2-2)
  expect_named(as_list, c("values", "starts", "ends"), ignore.order = TRUE)
  expect_equal(as_list$values, list("a", "b"))
  expect_equal(as_list$starts, c(1, 2))
  expect_equal(as_list$ends,   c(3, 2))
})

test_that("peek_all_overlaps as_list returns parallel vectors matching default", {
  ix <- interval_index("a", "b", "c", "d",
                       start = c(1, 2, 4, 6),
                       end   = c(3, 2, 5, 8))

  as_list <- peek_all_overlaps(ix, 2, 4, bounds = "[]", as_list = TRUE)

  # low=2 high=4, bounds="[]": overlapping entries are "a" (1-3), "b" (2-2), "c" (4-5)
  expect_named(as_list, c("values", "starts", "ends"), ignore.order = TRUE)
  expect_equal(as_list$values, list("a", "b", "c"))
  expect_equal(as_list$starts, c(1, 2, 4))
  expect_equal(as_list$ends,   c(3, 2, 5))
})

test_that("peek_all_point as_list returns typed empties on miss", {
  ix <- interval_index("a", start = 1, end = 2)
  res <- peek_all_point(ix, 100, bounds = "[]", as_list = TRUE)
  expect_equal(res$values, list())
  expect_equal(length(res$starts), 0L)
  expect_equal(length(res$ends),   0L)
})

test_that("peek_all_point as_list preserves integer endpoint type", {
  ix <- interval_index("a", "b", "c", "d",
                       start = c(1L, 2L, 4L, 6L),
                       end   = c(3L, 2L, 5L, 8L))
  res <- peek_all_point(ix, 2L, bounds = "[]", as_list = TRUE)
  expect_type(res$starts, "integer")
  expect_type(res$ends, "integer")
  expect_equal(res$starts, c(1L, 2L))
  expect_equal(res$ends,   c(3L, 2L))
})

test_that("peek_all_overlaps as_list preserves Date endpoint class", {
  ix <- interval_index("a", "b", "c",
                       start = as.Date(c("2025-01-01", "2025-01-03", "2025-01-10")),
                       end   = as.Date(c("2025-01-02", "2025-01-05", "2025-01-12")))
  qlo <- as.Date("2025-01-04")
  qhi <- as.Date("2025-01-06")
  res <- peek_all_overlaps(ix, qlo, qhi, bounds = "[]", as_list = TRUE)
  # Date endpoints are not in the "numeric" simple domain; should fall back to list.
  expect_type(res$starts, "list")
  expect_true(all(vapply(res$starts, inherits, logical(1), "Date")))
  expect_true(all(vapply(res$ends, inherits, logical(1), "Date")))
})

test_that("peek_all_containing as_list returns parallel vectors matching default", {
  ix <- interval_index("a", "b", "c", "d",
                       start = c(1, 2, 4, 6),
                       end   = c(10, 5, 8, 7))

  as_list <- peek_all_containing(ix, 5, 6, bounds = "[]", as_list = TRUE)

  # query interval [5,6] is contained by "a" (1-10) and "c" (4-8);
  # "d" (6-7) starts after query start so does not contain it.
  expect_named(as_list, c("values", "starts", "ends"), ignore.order = TRUE)
  expect_equal(as_list$values, list("a", "c"))
  expect_equal(as_list$starts, c(1, 4))
  expect_equal(as_list$ends,   c(10, 8))
})

test_that("peek_all_containing as_list matches default slice content", {
  ix <- interval_index("a", "b", "c", "d",
                       start = c(1, 2, 4, 6),
                       end   = c(10, 5, 8, 7))
  slice <- peek_all_containing(ix, 5, 6, bounds = "[]")
  as_list <- peek_all_containing(ix, 5, 6, bounds = "[]", as_list = TRUE)
  expect_equal(as_list$values, as.list(slice))
})

test_that("peek_all_containing as_list returns typed empties on miss", {
  ix <- interval_index("a", start = 1, end = 2)
  res <- peek_all_containing(ix, 100, 200, bounds = "[]", as_list = TRUE)
  expect_equal(res$values, list())
  expect_equal(length(res$starts), 0L)
  expect_equal(length(res$ends),   0L)
})

test_that("peek_all_within as_list returns parallel vectors matching default", {
  ix <- interval_index("a", "b", "c", "d",
                       start = c(1, 3, 4, 6),
                       end   = c(2, 5, 8, 7))

  as_list <- peek_all_within(ix, 3, 8, bounds = "[]", as_list = TRUE)

  # query interval [3,8] contains "b" (3-5), "c" (4-8), "d" (6-7)
  expect_named(as_list, c("values", "starts", "ends"), ignore.order = TRUE)
  expect_equal(as_list$values, list("b", "c", "d"))
  expect_equal(as_list$starts, c(3, 4, 6))
  expect_equal(as_list$ends,   c(5, 8, 7))
})

test_that("peek_all_within as_list matches default slice content", {
  ix <- interval_index("a", "b", "c", "d",
                       start = c(1, 3, 4, 6),
                       end   = c(2, 5, 8, 7))
  slice <- peek_all_within(ix, 3, 8, bounds = "[]")
  as_list <- peek_all_within(ix, 3, 8, bounds = "[]", as_list = TRUE)
  expect_equal(as_list$values, as.list(slice))
})

test_that("peek_all_within as_list returns typed empties on miss", {
  ix <- interval_index("a", start = 1, end = 2)
  res <- peek_all_within(ix, 100, 200, bounds = "[]", as_list = TRUE)
  expect_equal(res$values, list())
  expect_equal(length(res$starts), 0L)
  expect_equal(length(res$ends),   0L)
})

test_that("peek_all_within as_list preserves Date endpoint class", {
  ix <- interval_index("a", "b", "c",
                       start = as.Date(c("2025-01-01", "2025-01-03", "2025-01-10")),
                       end   = as.Date(c("2025-01-02", "2025-01-05", "2025-01-12")))
  qlo <- as.Date("2025-01-01")
  qhi <- as.Date("2025-01-31")
  res <- peek_all_within(ix, qlo, qhi, bounds = "[]", as_list = TRUE)
  expect_type(res$starts, "list")
  expect_true(all(vapply(res$starts, inherits, logical(1), "Date")))
  expect_true(all(vapply(res$ends, inherits, logical(1), "Date")))
})
