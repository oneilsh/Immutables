testthat::test_that("read indexing supports [] and [[ with positive integer indices", {
  t <- as_flexseq(1:6)

  testthat::expect_equal(t[[3]], 3)

  s <- t[c(2, 4, 6)]
  testthat::expect_equal(sum(unlist(as.list(s), use.names = FALSE)), 12)
  testthat::expect_identical(attr(s, "measures")$.size, 3)
})

testthat::test_that("read indexing supports duplicates and arbitrary order", {
  t <- as_flexseq(letters[1:5])
  s <- t[c(5, 2, 2, 4)]
  testthat::expect_identical(tree_chars(s), "ebbd")
  testthat::expect_identical(attr(s, "measures")$.size, 4)
})

testthat::test_that("indexing enforces bounds and integer-only indices", {
  r <- measure_monoid(function(a, b) a + b, 0, function(el) el)
  t <- add_monoids(as_flexseq(1:4), list(sum = r))

  testthat::expect_error(t[[0]], "positive integer")
  testthat::expect_error(t[[5]], "out of bounds")
  testthat::expect_error(t[[c(1, 2)]], "\\[\\[ expects exactly one index")
  testthat::expect_error(t[c(1, -2)], "positive integer")
  testthat::expect_error(t[c(1, 2.5)], "integer indices")
})

testthat::test_that("replacement indexing supports [[<- and [<- with recycling semantics", {
  t <- as_flexseq(1:5)

  t2 <- t
  t2[[2]] <- 20
  testthat::expect_identical(sum(unlist(as.list(t2), use.names = FALSE)), 33)
  testthat::expect_identical(t2[[2]], 20)

  t3 <- t
  t3[c(1, 5)] <- list(10, 50)
  testthat::expect_identical(sum(unlist(as.list(t3), use.names = FALSE)), 69)
  testthat::expect_identical(t3[[1]], 10)
  testthat::expect_identical(t3[[5]], 50)

  t4 <- t
  t4[c(1, 2, 3)] <- list(99, 100)
  testthat::expect_identical(t4[[1]], 99)
  testthat::expect_identical(t4[[2]], 100)
  testthat::expect_identical(t4[[3]], 99)
})

testthat::test_that("[[<- keeps monoid attrs and updates one element via split path", {
  sum_m <- measure_monoid(`+`, 0, as.numeric)
  t <- add_monoids(as_flexseq(1:6), list(sum = sum_m))
  t2 <- t
  t2[[4]] <- 99

  testthat::expect_identical(attr(t2, "measures")$.size, 6)
  testthat::expect_identical(attr(t2, "measures")$sum, 116)
  testthat::expect_identical(t2[[4]], 99)
})

testthat::test_that("[[<- with NULL removes one element by index or name", {
  sum_m <- measure_monoid(`+`, 0, as.numeric)
  t <- add_monoids(as_flexseq(1:5), list(sum = sum_m))
  t[[3]] <- NULL
  testthat::expect_identical(attr(t, "measures")$.size, 4)
  testthat::expect_identical(attr(t, "measures")$sum, 12)
  testthat::expect_identical(t[[3]], 4L)

  tn <- as_flexseq(setNames(as.list(1:4), c("a", "b", "c", "d")))
  tn[["c"]] <- NULL
  testthat::expect_identical(attr(tn, "measures")$.size, 3)
  testthat::expect_identical(attr(tn, "measures")$.named_count, 3L)
  testthat::expect_error(tn[["c"]], "Unknown element name")
  testthat::expect_identical(tn[["d"]], 4L)
})

testthat::test_that("[<- applies duplicate indices sequentially (last write wins)", {
  t <- as_flexseq(letters[1:5])
  t[c(2, 2)] <- list("X", "Y")
  testthat::expect_identical(t[[2]], "Y")
})

testthat::test_that("[<- supports arbitrary replacement order", {
  t <- as_flexseq(letters[1:5])
  t[c(5, 1, 4)] <- list("u", "v", "w")
  testthat::expect_identical(t[[1]], "v")
  testthat::expect_identical(t[[4]], "w")
  testthat::expect_identical(t[[5]], "u")
})

testthat::test_that("[<- keeps structural attrs and custom monoid measures coherent", {
  sum_m <- measure_monoid(`+`, 0, as.numeric)
  t <- add_monoids(as_flexseq(1:5), list(sum = sum_m))
  t[c(2, 4)] <- list(20, 40)

  testthat::expect_identical(attr(t, "measures")$.size, 5)
  testthat::expect_identical(attr(t, "measures")$sum, 69)
  testthat::expect_identical(sum(unlist(as.list(t), use.names = FALSE)), 69)
})

testthat::test_that("[<- zero-length index is a no-op when replacement is empty", {
  t <- as_flexseq(letters[1:5])
  before <- tree_chars(t)
  t2 <- t
  t2[integer(0)] <- list()

  testthat::expect_identical(tree_chars(t2), before)
  testthat::expect_identical(attr(t2, "measures")$.size, attr(t, "measures")$.size)
})

testthat::test_that("size measure is available by default for indexing even if not provided", {
  sum_only <- measure_monoid(function(a, b) a + b, 0, function(el) el)
  t <- add_monoids(as_flexseq(1:3), list(sum = sum_only))
  ms <- attr(t, "measures")
  testthat::expect_identical(ms$.size, 3)
  testthat::expect_equal(t[[2]], 2)
})

testthat::test_that("single-element read indexing follows locate_by_predicate(.size) semantics", {
  t <- as_flexseq(letters[1:8])
  for(i in 1:8) {
    hit <- locate_by_predicate(t, function(v) v >= i, ".size")
    testthat::expect_true(hit$found)
    testthat::expect_identical(t[[i]], hit$value)
  }
})

testthat::test_that("name invariants enforce complete unique naming when names are present", {
  t <- as_flexseq(setNames(as.list(1:4), c("a", "b", "c", "d")))
  testthat::expect_identical(attr(t, "measures")$.size, 4)
  testthat::expect_identical(attr(t, "measures")$.named_count, 4L)

  mixed <- as.list(1:3)
  names(mixed) <- c("x", "", "z")
  testthat::expect_error(as_flexseq(mixed), "Mixed named and unnamed")

  dup <- as.list(1:3)
  names(dup) <- c("x", "x", "z")
  testthat::expect_error(as_flexseq(dup), "must be unique")
})

testthat::test_that("character read indexing returns ordered results and NULL placeholders", {
  t <- as_flexseq(setNames(as.list(1:3), c("a", "b", "c")))
  s <- t[c("c", "missing", "a")]

  testthat::expect_identical(attr(s, "measures")$.size, 3)
  testthat::expect_identical(s[[1]], 3L)
  testthat::expect_null(s[[2]])
  testthat::expect_identical(s[[3]], 1L)
})

testthat::test_that("character lookup paths are equivalent for short and wide queries", {
  vals <- as.list(1:20)
  names(vals) <- paste0("k", seq_len(20))
  t <- as_flexseq(vals)

  q_short <- c("k3", "missing", "k1")
  s_short <- t[q_short]
  exp_short <- lapply(q_short, function(nm) if(nm %in% names(vals)) vals[[nm]] else NULL)
  got_short <- lapply(seq_along(q_short), function(i) s_short[[i]])
  testthat::expect_identical(got_short, exp_short)

  q_wide <- c("k3", "missing", "k1", "k10", "k10", "k20", "missing", "k2", "k19", "k4")
  s_wide <- t[q_wide]
  exp_wide <- lapply(q_wide, function(nm) if(nm %in% names(vals)) vals[[nm]] else NULL)
  got_wide <- lapply(seq_along(q_wide), function(i) s_wide[[i]])
  testthat::expect_identical(got_wide, exp_wide)
})

testthat::test_that("character [[ is strict single-name lookup", {
  t <- as_flexseq(setNames(as.list(letters[1:3]), c("x", "y", "z")))
  testthat::expect_identical(t[["y"]], "b")
  testthat::expect_error(t[["missing"]], "Unknown element name")
})

testthat::test_that("character replacement indexing updates by existing names only", {
  t <- as_flexseq(setNames(as.list(1:4), c("a", "b", "c", "d")))
  t[c("b", "b")] <- list(20, 30)
  testthat::expect_identical(t[["b"]], 30)
  testthat::expect_identical(attr(t, "measures")$.named_count, 4L)

  t[c("a", "c", "d")] <- list(7, 8)
  testthat::expect_identical(t[["a"]], 7)
  testthat::expect_identical(t[["c"]], 8)
  testthat::expect_identical(t[["d"]], 7)

  testthat::expect_error({
    t2 <- t
    t2[c("a", "missing")] <- list(1, 2)
  }, "Unknown element name")
})

testthat::test_that("replacement names win and must remain unique", {
  t <- as_flexseq(setNames(as.list(1:3), c("a", "b", "c")))
  repl <- list(10, 30)
  names(repl) <- c("z", "y")
  t[c("a", "c")] <- repl

  testthat::expect_identical(t[["z"]], 10)
  testthat::expect_identical(t[["y"]], 30)
  testthat::expect_error(t[["a"]], "Unknown element name")

  bad <- list(100, 200)
  names(bad) <- c("k", "k")
  testthat::expect_error({
    t2 <- as_flexseq(setNames(as.list(1:3), c("u", "v", "w")))
    t2[c("u", "v")] <- bad
  }, "must be unique")
})

testthat::test_that("single-name replacement enforces uniqueness without map rebuild semantics change", {
  t <- as_flexseq(setNames(as.list(1:3), c("a", "b", "c")))

  testthat::expect_error({
    t2 <- t
    t2[[1]] <- stats::setNames(9, "b")
  }, "must be unique")

  t3 <- t
  t3[[1]] <- stats::setNames(9, "a")
  testthat::expect_identical(unname(t3[["a"]]), 9)
  testthat::expect_identical(attr(t3, "measures")$.named_count, 3L)
})

testthat::test_that("append and prepend preserve global name-state invariant", {
  unnamed <- as_flexseq(1:3)
  testthat::expect_error(
    push_back(unnamed, stats::setNames(4, "x")),
    "mixed named and unnamed"
  )

  named <- as_flexseq(setNames(as.list(1:3), c("a", "b", "c")))
  testthat::expect_error(push_front(named, 0), "mixed named and unnamed")
})

testthat::test_that("$ provides strict exact-name access and replacement", {
  t <- as_flexseq(setNames(as.list(1:4), c("a", "b", "c", "d")))
  testthat::expect_identical(t$b, 2L)
  testthat::expect_identical(t$b, t[["b"]])
  testthat::expect_error(t$missing, "Unknown element name")

  t$b <- 99
  testthat::expect_identical(t$b, 99)
  testthat::expect_identical(attr(t, "measures")$.named_count, 4L)

  t$b <- NULL
  testthat::expect_identical(attr(t, "measures")$.size, 3)
  testthat::expect_identical(attr(t, "measures")$.named_count, 3L)
  testthat::expect_error(t$b, "Unknown element name")
})

testthat::test_that("logical read indexing supports recycling and rejects NA", {
  t <- as_flexseq(1:5)
  s <- t[c(TRUE, FALSE)]
  testthat::expect_identical(attr(s, "measures")$.size, 3)
  testthat::expect_identical(s[[1]], 1L)
  testthat::expect_identical(s[[2]], 3L)
  testthat::expect_identical(s[[3]], 5L)

  z <- t[logical(0)]
  testthat::expect_identical(attr(z, "measures")$.size, 0)
  testthat::expect_error(t[c(TRUE, NA)], "cannot contain NA")
})

testthat::test_that("logical replacement supports recycling and preserves size", {
  t <- as_flexseq(1:6)
  t[c(TRUE, FALSE, TRUE)] <- list(99)
  testthat::expect_identical(attr(t, "measures")$.size, 6)
  testthat::expect_identical(t[[1]], 99)
  testthat::expect_identical(t[[3]], 99)
  testthat::expect_identical(t[[4]], 99)
  testthat::expect_identical(t[[6]], 99)

  testthat::expect_error({
    t2 <- as_flexseq(1:4)
    t2[c(TRUE, FALSE)] <- list()
  }, "length 0")
})
