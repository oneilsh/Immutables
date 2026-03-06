testthat::test_that("constructor sorts by key and preserves stable duplicate order", {
  xs <- as_ordered_sequence(
    list("bbb", "a", "cc", "dd", "e"),
    keys = c(3, 1, 2, 2, 1)
  )

  testthat::expect_s3_class(xs, "ordered_sequence")
  testthat::expect_equal(as.list(xs), list("a", "e", "cc", "dd", "bbb"))
  testthat::expect_identical(length(xs), 5L)
})

testthat::test_that("insert appends at right edge of equal-key block (FIFO ties)", {
  xs <- as_ordered_sequence(list("bb", "aa", "c"), keys = c(2, 2, 1))
  xs2 <- insert(xs, "dd", key = 2)

  testthat::expect_equal(as.list(xs2), list("c", "bb", "aa", "dd"))
  testthat::expect_equal(peek_key(xs2, 2), "bb")

  out1 <- pop_key(xs2, 2)
  out2 <- pop_key(out1$remaining, 2)
  testthat::expect_equal(out1$element, "bb")
  testthat::expect_equal(out2$element, "aa")
})

testthat::test_that("insert works on R backend when insertion is at right boundary", {
  old_cpp <- getOption("immutables.use_cpp")
  options(immutables.use_cpp = FALSE)
  on.exit({
    if(is.null(old_cpp)) {
      options(immutables.use_cpp = NULL)
    } else {
      options(immutables.use_cpp = old_cpp)
    }
  }, add = TRUE)

  xs <- as_ordered_sequence(list("a", "b"), keys = c(1, 2))
  ys <- insert(xs, "c", key = 3)

  testthat::expect_s3_class(ys, "ordered_sequence")
  testthat::expect_equal(as.list(ys), list("a", "b", "c"))
})

testthat::test_that("insert preserves name state for named ordered_sequence", {
  xs_num <- as_ordered_sequence(
    setNames(as.list(c("a", "b")), c("ka", "kb")),
    keys = c(1, 2)
  )
  v_num <- "c"
  names(v_num) <- "kc"
  ys_num <- insert(xs_num, v_num, key = 2)

  testthat::expect_identical(unname(ys_num[["kc"]]), "c")
  testthat::expect_identical(attr(ys_num, "measures")$.named_count, as.integer(length(ys_num)))
  testthat::expect_true(validate_name_state(ys_num))

  xs_date <- as_ordered_sequence(
    setNames(as.list(c("a", "b")), c("da", "db")),
    keys = as.Date(c("2024-01-01", "2024-01-03"))
  )
  v_date <- "c"
  names(v_date) <- "dc"
  ys_date <- insert(xs_date, v_date, key = as.Date("2024-01-02"))

  testthat::expect_identical(unname(ys_date[["dc"]]), "c")
  testthat::expect_identical(attr(ys_date, "measures")$.named_count, as.integer(length(ys_date)))
  testthat::expect_true(validate_name_state(ys_date))
})

testthat::test_that("insert enforces named/unnamed consistency for ordered_sequence", {
  named <- as_ordered_sequence(
    setNames(as.list(c("a", "b")), c("ka", "kb")),
    keys = c(1, 2)
  )
  testthat::expect_error(
    insert(named, "c", key = 3),
    "mixed named and unnamed"
  )

  unnamed <- as_ordered_sequence(list("a", "b"), keys = c(1, 2))
  v_named <- "c"
  names(v_named) <- "kc"
  testthat::expect_error(
    insert(unnamed, v_named, key = 3),
    "mixed named and unnamed"
  )
})

testthat::test_that("lower_bound and upper_bound behave at boundaries", {
  xs <- as_ordered_sequence(list("bbb", "a", "cc", "dddd"), keys = c(3, 1, 2, 4))

  lb1 <- lower_bound(xs, 2)
  ub1 <- upper_bound(xs, 2)
  lb9 <- lower_bound(xs, 9)

  testthat::expect_true(lb1$found)
  testthat::expect_identical(lb1$index, 2L)
  testthat::expect_equal(lb1$element, "cc")

  testthat::expect_true(ub1$found)
  testthat::expect_identical(ub1$index, 3L)
  testthat::expect_equal(ub1$element, "bbb")

  testthat::expect_false(lb9$found)
  testthat::expect_null(lb9$index)
})

testthat::test_that("pop_key/pop_all_key removal by key span", {
  xs <- as_ordered_sequence(list("aa", "bb", "c", "dd", "e"), keys = c(2, 2, 1, 2, 1))

  one <- pop_key(xs, 2)
  testthat::expect_equal(one$element, "aa")
  testthat::expect_equal(as.list(one$remaining), list("c", "e", "bb", "dd"))

  all <- pop_all_key(xs, 2)
  testthat::expect_s3_class(all$elements, "ordered_sequence")
  testthat::expect_equal(as.list(all$elements), list("aa", "bb", "dd"))
  testthat::expect_equal(as.list(all$remaining), list("c", "e"))

  miss_one <- pop_key(xs, 99)
  testthat::expect_null(miss_one$element)
  testthat::expect_equal(as.list(miss_one$remaining), as.list(xs))

  miss_all <- pop_all_key(xs, 99)
  testthat::expect_s3_class(miss_all$elements, "ordered_sequence")
  testthat::expect_identical(length(miss_all$elements), 0L)
  testthat::expect_equal(as.list(miss_all$remaining), as.list(xs))
})

testthat::test_that("elements_between supports inclusivity flags", {
  xs <- as_ordered_sequence(list("a", "bb", "cc", "ddd", "eeee"), keys = c(1, 2, 2, 3, 4))

  e_closed <- elements_between(xs, 2, 3)
  e_open_hi <- elements_between(xs, 2, 3, include_to = FALSE)
  e_open_lo <- elements_between(xs, 2, 3, include_from = FALSE)
  e_miss <- elements_between(xs, 9, 10)

  testthat::expect_equal(e_closed, list("bb", "cc", "ddd"))
  testthat::expect_equal(e_open_hi, list("bb", "cc"))
  testthat::expect_equal(e_open_lo, list("ddd"))
  testthat::expect_equal(e_miss, list())
})

testthat::test_that("peek_key/peek_all_key and pop_key are stable within duplicate key blocks", {
  xs <- as_ordered_sequence(list("a1", "b1", "a2", "a3"), keys = c(1, 2, 1, 1))

  testthat::expect_equal(peek_key(xs, 1), "a1")
  peek_all <- peek_all_key(xs, 1)
  testthat::expect_s3_class(peek_all, "ordered_sequence")
  testthat::expect_equal(as.list(peek_all), list("a1", "a2", "a3"))
  out <- pop_key(xs, 1)
  testthat::expect_equal(out$element, "a1")
  testthat::expect_equal(out$key, 1)
  testthat::expect_equal(as.list(out$remaining), list("a2", "a3", "b1"))

  testthat::expect_null(peek_key(xs, 9))
  testthat::expect_identical(length(peek_all_key(xs, 9)), 0L)
  miss <- pop_key(xs, 9)
  testthat::expect_null(miss$element)
  testthat::expect_null(miss$key)
  testthat::expect_equal(as.list(miss$remaining), as.list(xs))
})

testthat::test_that("count helpers match range and key multiplicities", {
  xs <- as_ordered_sequence(list("a", "bb", "cc", "ddd", "eeee"), keys = c(1, 2, 2, 3, 4))

  testthat::expect_identical(count_key(xs, 2), 2L)
  testthat::expect_identical(count_key(xs, 9), 0L)

  testthat::expect_identical(count_between(xs, 2, 3), 3L)
  testthat::expect_identical(count_between(xs, 2, 3, include_to = FALSE), 2L)
  testthat::expect_identical(count_between(xs, 2, 3, include_from = FALSE), 1L)
  testthat::expect_identical(count_between(xs, 9, 10), 0L)
})

testthat::test_that("split helpers preserve ordered_sequence subclass", {
  xs <- as_ordered_sequence(list("a", "bb", "cc", "ddd", "eeee"), keys = c(1, 2, 2, 3, 4))

  s <- split_by_predicate(xs, function(v) v >= 3L, ".size")
  testthat::expect_s3_class(s$left, "ordered_sequence")
  testthat::expect_s3_class(s$right, "ordered_sequence")
  testthat::expect_equal(as.list(s$left), list("a", "bb"))
  testthat::expect_equal(as.list(s$right), list("cc", "ddd", "eeee"))

  sa <- split_around_by_predicate(xs, function(v) v >= 3L, ".size")
  testthat::expect_s3_class(sa$left, "ordered_sequence")
  testthat::expect_s3_class(sa$right, "ordered_sequence")
  testthat::expect_equal(sa$elem$item, "cc")
  testthat::expect_equal(as.list(sa$left), list("a", "bb"))
  testthat::expect_equal(as.list(sa$right), list("ddd", "eeee"))
})

testthat::test_that("order-breaking writes are blocked on ordered types", {
  xs <- as_ordered_sequence(list("a", "b"), keys = c(1, 2))

  testthat::expect_error(c(xs, xs), "not supported")
  testthat::expect_error(push_back(xs, "c"), "not supported")
  testthat::expect_error(push_front(xs, "z"), "not supported")
  testthat::expect_error(insert_at(xs, 1, "z"), "not supported")

  testthat::expect_error({ xs[[1]] <- "z" }, "not supported")
  testthat::expect_error({ xs[1] <- list("z") }, "not supported")
  testthat::expect_error({ xs$a <- "z" }, "not supported")
})

testthat::test_that("ordered replacement blocker messages never leak structural classes", {
  xs <- as_ordered_sequence(list(a = "x", b = "y"), keys = c(1, 2))

  msg1 <- testthat::expect_error({ xs[[1]] <- "z" })$message
  msg2 <- testthat::expect_error({ xs[1] <- list("z") })$message
  msg3 <- testthat::expect_error({ xs$a <- "z" })$message

  testthat::expect_match(msg1, "ordered_sequence")
  testthat::expect_match(msg2, "ordered_sequence")
  testthat::expect_match(msg3, "ordered_sequence")
  testthat::expect_false(grepl("Deep", msg1, fixed = TRUE))
  testthat::expect_false(grepl("Deep", msg2, fixed = TRUE))
  testthat::expect_false(grepl("Deep", msg3, fixed = TRUE))
})

testthat::test_that("ordered subsetting canonicalizes selector order and rejects duplicates", {
  xs <- as_ordered_sequence(
    list(a = "xa", b = "xb", c = "xc", d = "xd"),
    keys = c(1, 2, 3, 4)
  )

  inc <- xs[c(1, 3)]
  testthat::expect_s3_class(inc, "ordered_sequence")
  testthat::expect_equal(as.list(inc), list(a = "xa", c = "xc"))
  testthat::expect_identical(names(as.list(inc)), c("a", "c"))

  by_name <- xs[c("a", "c")]
  testthat::expect_equal(as.list(by_name), list(a = "xa", c = "xc"))
  testthat::expect_identical(names(as.list(by_name)), c("a", "c"))

  testthat::expect_equal(xs[[2]], "xb")
  testthat::expect_equal(xs[["c"]], "xc")
  testthat::expect_equal(xs$c, "xc")

  lgl <- xs[c(TRUE, FALSE)]
  testthat::expect_equal(as.list(lgl), list(a = "xa", c = "xc"))
  testthat::expect_identical(names(as.list(lgl)), c("a", "c"))

  reordered <- NULL
  testthat::expect_warning(
    { reordered <- xs[c(3, 1)] },
    "canonicalizes selector order"
  )
  testthat::expect_equal(as.list(reordered), list(a = "xa", c = "xc"))

  reordered_name <- NULL
  testthat::expect_warning(
    { reordered_name <- xs[c("c", "a")] },
    "canonicalizes selector order"
  )
  testthat::expect_equal(as.list(reordered_name), list(a = "xa", c = "xc"))

  testthat::expect_error(xs[c(2, 2)], "duplicate indices")
  testthat::expect_error(xs[c("a", "a")], "duplicate indices")
  testthat::expect_error(xs[c("a", "missing")], "Unknown element name")
})

testthat::test_that("pop helpers preserve ordered class", {
  xs <- as_ordered_sequence(list("x1", "x2", "x3"), keys = c(1, 2, 3))
  pf <- pop_front(xs)
  pb <- pop_back(xs)
  pm <- pop_at(xs, 2)

  testthat::expect_identical(pf$element, "x1")
  testthat::expect_s3_class(pf$remaining, "ordered_sequence")
  testthat::expect_equal(as.list(pf$remaining), list("x2", "x3"))

  testthat::expect_identical(pb$element, "x3")
  testthat::expect_s3_class(pb$remaining, "ordered_sequence")
  testthat::expect_equal(as.list(pb$remaining), list("x1", "x2"))

  testthat::expect_identical(peek_at(xs, 2), "x2")
  testthat::expect_identical(pm$element, "x2")
  testthat::expect_s3_class(pm$remaining, "ordered_sequence")
  testthat::expect_equal(as.list(pm$remaining), list("x1", "x3"))
})

testthat::test_that("fapply dispatches for ordered_sequence and no reset_ties arg", {
  xs <- as_ordered_sequence(setNames(list("x1", "x2", "x3"), c("a", "b", "c")), keys = c(1, 1, 2))

  xs_item <- fapply(xs, function(item, key, name) {
    toupper(item)
  })
  testthat::expect_s3_class(xs_item, "ordered_sequence")
  testthat::expect_equal(unname(as.list(xs_item)), list("X1", "X2", "X3"))
  testthat::expect_identical(names(as.list(xs_item)), c("a", "b", "c"))

  xs_tagged <- fapply(xs, function(item, key, name) {
    paste(item, key, name, sep = "|")
  })
  testthat::expect_equal(unname(as.list(xs_tagged)), list("x1|1|a", "x2|1|b", "x3|2|c"))
  testthat::expect_identical(names(as.list(xs_tagged)), c("a", "b", "c"))
  testthat::expect_equal(count_key(xs_tagged, 1), 2L)
  testthat::expect_equal(count_key(xs_tagged, 2), 1L)
  testthat::expect_equal(peek_key(xs_tagged, 1), "x1|1|a")

  testthat::expect_error(fapply(xs, 1), "`FUN` must be a function")
  testthat::expect_error(fapply(xs, function(item, key, name) item, reset_ties = TRUE), "unused")
})

testthat::test_that("fapply can drop custom monoids for ordered_sequence", {
  sum_item <- measure_monoid(`+`, 0, function(entry) as.numeric(entry$item))
  xs <- add_monoids(as_ordered_sequence(list(10, 20), keys = c(1, 2)), list(sum_item = sum_item))
  xs2 <- fapply(xs, function(item, key, name) item + 1, preserve_custom_monoids = FALSE)

  ms <- attr(xs2, "monoids", exact = TRUE)
  testthat::expect_true(!is.null(ms[[".size"]]))
  testthat::expect_true(!is.null(ms[[".named_count"]]))
  testthat::expect_true(!is.null(ms[[".oms_max_key"]]))
  testthat::expect_true(is.null(ms[["sum_item"]]))
  testthat::expect_error(node_measure(xs2, "sum_item"), "Missing cached measure")
  testthat::expect_equal(as.list(xs2), list(11, 21))
})

testthat::test_that("ordered_sequence custom monoids accept entry measure arguments", {
  xs <- add_monoids(
    as_ordered_sequence(list(10, 20), keys = c(2, 1)),
    list(
      by_key = measure_monoid(`+`, 0, function(entry) as.numeric(entry$key))
    )
  )
  testthat::expect_equal(node_measure(xs, "by_key"), 3)
})

testthat::test_that("ordered_sequence casts down to flexseq explicitly", {
  sum_key <- measure_monoid(`+`, 0, function(entry) entry$key)
  xs <- add_monoids(as_ordered_sequence(
    setNames(list("x", "y"), c("kx", "ky")),
    keys = c(2, 1)
  ), list(sum_key = sum_key))

  fx <- as_flexseq(xs)
  testthat::expect_s3_class(fx, "flexseq")
  testthat::expect_false(inherits(fx, "ordered_sequence"))
  testthat::expect_equal(fx[["kx"]]$item, "x")
  testthat::expect_equal(fx[["kx"]]$key, 2)

  ms <- names(attr(fx, "monoids", exact = TRUE))
  testthat::expect_true(all(c(".size", ".named_count", "sum_key") %in% ms))
  testthat::expect_false(".oms_max_key" %in% ms)
  testthat::expect_identical(node_measure(fx, "sum_key"), 3)
})

testthat::test_that("ordered_sequence supports Date keys with stable tie handling", {
  keys <- as.Date(c("2024-01-03", "2024-01-01", "2024-01-01", "2024-01-02"))
  xs <- as_ordered_sequence(list("c", "a1", "a2", "b"), keys = keys)

  testthat::expect_equal(as.list(xs), list("a1", "a2", "b", "c"))
  testthat::expect_equal(peek_key(xs, as.Date("2024-01-01")), "a1")

  lb <- lower_bound(xs, as.Date("2024-01-01"))
  ub <- upper_bound(xs, as.Date("2024-01-01"))
  testthat::expect_true(lb$found)
  testthat::expect_identical(lb$index, 1L)
  testthat::expect_equal(lb$element, "a1")
  testthat::expect_s3_class(lb$key, "Date")
  testthat::expect_true(ub$found)
  testthat::expect_identical(ub$index, 3L)
  testthat::expect_equal(ub$element, "b")

  out <- pop_key(xs, as.Date("2024-01-01"))
  testthat::expect_equal(out$element, "a1")
  testthat::expect_s3_class(out$key, "Date")
  testthat::expect_equal(as.list(out$remaining), list("a2", "b", "c"))

  ys <- insert(xs, "a3", key = as.Date("2024-01-01"))
  testthat::expect_equal(as.list(ys), list("a1", "a2", "a3", "b", "c"))
})

testthat::test_that("ordered_sequence supports POSIXct keys with stable tie handling", {
  keys <- as.POSIXct(
    c("2024-01-01 12:00:00", "2024-01-01 10:00:00", "2024-01-01 10:00:00"),
    tz = "UTC"
  )
  xs <- as_ordered_sequence(list("late", "early1", "early2"), keys = keys)

  testthat::expect_equal(as.list(xs), list("early1", "early2", "late"))
  testthat::expect_equal(peek_key(xs, as.POSIXct("2024-01-01 10:00:00", tz = "UTC")), "early1")

  out1 <- pop_key(xs, as.POSIXct("2024-01-01 10:00:00", tz = "UTC"))
  out2 <- pop_key(out1$remaining, as.POSIXct("2024-01-01 10:00:00", tz = "UTC"))
  testthat::expect_equal(out1$element, "early1")
  testthat::expect_equal(out2$element, "early2")
  testthat::expect_s3_class(out1$key, "POSIXct")
})

testthat::test_that("ordered_sequence rejects mixed key domains and missing keys", {
  testthat::expect_error(
    as_ordered_sequence(list("a", "b"), keys = list(1, "1")),
    "Incompatible key type"
  )
  testthat::expect_error(
    as_ordered_sequence(list("a", "b"), keys = list(1, as.Date("2024-01-01"))),
    "Incompatible key type"
  )
  testthat::expect_error(
    as_ordered_sequence(
      list("a", "b"),
      keys = list(as.Date("2024-01-01"), as.POSIXct("2024-01-01 00:00:00", tz = "UTC"))
    ),
    "Incompatible key type"
  )

  xs_num <- as_ordered_sequence(list("a"), keys = 1)
  xs_date <- as_ordered_sequence(list("a"), keys = as.Date("2024-01-01"))
  testthat::expect_error(insert(xs_num, "b", key = "1"), "Incompatible key type")
  testthat::expect_error(insert(xs_num, "b", key = as.Date("2024-01-01")), "Incompatible key type")
  testthat::expect_error(
    insert(xs_date, "b", key = as.POSIXct("2024-01-01 00:00:00", tz = "UTC")),
    "Incompatible key type"
  )

  testthat::expect_error(
    as_ordered_sequence(list("a"), keys = as.Date(NA)),
    "`key` must be non-missing"
  )
  testthat::expect_error(
    insert(xs_date, "b", key = as.Date(NA)),
    "`key` must be non-missing"
  )
})
