testthat::test_that("unlist.flexseq mirrors unlist(as.list(.)) for base flexseq", {
  x <- as_flexseq(as.list(1:4))

  testthat::expect_identical(unlist(x), c(1L, 2L, 3L, 4L))
  testthat::expect_identical(
    unlist(x, recursive = FALSE, use.names = FALSE),
    unlist(as.list(x), recursive = FALSE, use.names = FALSE)
  )
})

testthat::test_that("unlist.flexseq forwards use.names behavior", {
  x <- as_flexseq(setNames(as.list(c(10, 20)), c("a", "b")))

  testthat::expect_identical(unlist(x, use.names = TRUE), c(a = 10, b = 20))
  testthat::expect_identical(unlist(x, use.names = FALSE), c(10, 20))
})

testthat::test_that("priority_queue unlist returns payload items", {
  q <- as_priority_queue(
    setNames(as.list(c("x", "y")), c("kx", "ky")),
    priorities = c(2, 1)
  )

  testthat::expect_identical(unlist(q, use.names = TRUE), c(kx = "x", ky = "y"))
  testthat::expect_identical(unlist(q, use.names = FALSE), c("x", "y"))
})

testthat::test_that("as.list.priority_queue supports drop_meta", {
  q <- as_priority_queue(
    setNames(as.list(c("x", "y")), c("kx", "ky")),
    priorities = c(2, 1)
  )

  full <- as.list(q)
  bare <- as.list(q, drop_meta = TRUE)

  testthat::expect_identical(names(full), c("kx", "ky"))
  testthat::expect_identical(full[[1]]$value, "x")
  testthat::expect_identical(full[[1]]$priority, 2)
  testthat::expect_identical(bare, list(kx = "x", ky = "y"))
  testthat::expect_error(as.list(q, drop_meta = NA), "TRUE or FALSE")
})

testthat::test_that("ordered_sequence and interval_index inherit unlist.flexseq", {
  xs <- as_ordered_sequence(
    setNames(list("x1", "x2"), c("a", "b")),
    keys = c(1, 2)
  )
  ix <- as_interval_index(
    setNames(list("i1", "i2"), c("u", "v")),
    start = c(1, 3),
    end = c(2, 5)
  )

  testthat::expect_identical(
    unlist(xs, use.names = TRUE),
    unlist(as.list(xs), use.names = TRUE)
  )
  testthat::expect_identical(
    unlist(ix, recursive = FALSE),
    unlist(as.list(ix), recursive = FALSE)
  )
})
