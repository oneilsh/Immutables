testthat::test_that("fapply dispatches for flexseq", {
  x <- as_flexseq(1:4)
  y <- fapply(x, function(v) v * 3)

  testthat::expect_s3_class(y, "flexseq")
  testthat::expect_identical(lapply(.ft_to_list(y), .ft_strip_name), as.list(c(3, 6, 9, 12)))
  testthat::expect_error(fapply(x, 1), "`FUN` must be a function")
})

testthat::test_that("fapply dispatches for priority_queue", {
  q <- priority_queue("a", "bb", "ccc", priorities = c(1, 3, 2))
  q2 <- fapply(q, function(value, priority, name) {
    toupper(value)
  })

  testthat::expect_s3_class(q2, "priority_queue")
  testthat::expect_equal(peek_min(q2), "A")
  testthat::expect_equal(peek_max(q2), "BB")
  testthat::expect_error(fapply(q, 1), "`FUN` must be a function")
})

testthat::test_that("fapply dispatches for ordered_sequence", {
  xs <- as_ordered_sequence(setNames(list("x1", "x2", "x3"), c("a", "b", "c")), keys = c(1, 1, 2))

  xs_item <- fapply(xs, function(value, key, name) {
    toupper(value)
  })
  testthat::expect_s3_class(xs_item, "ordered_sequence")
  testthat::expect_equal(unname(as.list(xs_item)), list("X1", "X2", "X3"))
  testthat::expect_identical(names(as.list(xs_item)), c("a", "b", "c"))

  xs_tagged <- fapply(xs, function(value, key, name) {
    paste(value, key, name, sep = "|")
  })
  testthat::expect_equal(unname(as.list(xs_tagged)), list("x1|1|a", "x2|1|b", "x3|2|c"))
  testthat::expect_identical(names(as.list(xs_tagged)), c("a", "b", "c"))
  testthat::expect_equal(count_key(xs_tagged, 1), 2L)
  testthat::expect_equal(count_key(xs_tagged, 2), 1L)

  testthat::expect_error(fapply(xs, 1), "`FUN` must be a function")
})
