testthat::test_that("priority_queue constructor and length", {
  q0 <- priority_queue()
  testthat::expect_true(inherits(q0, "priority_queue"))
  testthat::expect_true(inherits(q0, "flexseq"))
  testthat::expect_identical(length(q0), 0L)

  q <- priority_queue("a", "b", "c", priorities = c(3, 1, 2))
  testthat::expect_identical(length(q), 3L)
  testthat::expect_equal(peek_min(q), "b")
  testthat::expect_equal(peek_max(q), "a")
})

testthat::test_that("empty priority_queue scalar peek/pop are non-throwing misses", {
  x <- priority_queue()

  testthat::expect_null(peek_min(x))
  testthat::expect_null(peek_max(x))

  pmin <- pop_min(x)
  pmax <- pop_max(x)
  testthat::expect_null(pmin$element)
  testthat::expect_null(pmin$priority)
  testthat::expect_identical(length(pmin$remaining), 0L)
  testthat::expect_null(pmax$element)
  testthat::expect_null(pmax$priority)
  testthat::expect_identical(length(pmax$remaining), 0L)
})

testthat::test_that("min/max pop uses sequence order on ties", {
  q <- priority_queue("a", "b", "c", "d", priorities = c(2, 1, 1, 2))

  e1 <- pop_min(q)
  testthat::expect_equal(e1$element, "b")
  testthat::expect_equal(e1$priority, 1)

  e2 <- pop_min(e1$remaining)
  testthat::expect_equal(e2$element, "c")
  testthat::expect_equal(e2$priority, 1)

  x1 <- pop_max(q)
  testthat::expect_equal(x1$element, "a")
  testthat::expect_equal(x1$priority, 2)

  x2 <- pop_max(x1$remaining)
  testthat::expect_equal(x2$element, "d")
  testthat::expect_equal(x2$priority, 2)
})

testthat::test_that("bulk extrema helpers return full tie runs", {
  q <- priority_queue("a", "b", "c", "d", priorities = c(2, 1, 1, 2))

  pmin <- peek_all_min(q)
  pmax <- peek_all_max(q)
  testthat::expect_s3_class(pmin, "priority_queue")
  testthat::expect_s3_class(pmax, "priority_queue")
  testthat::expect_equal(lapply(as.list(pmin), function(e) e$item), list("b", "c"))
  testthat::expect_equal(lapply(as.list(pmax), function(e) e$item), list("a", "d"))

  out_min <- pop_all_min(q)
  testthat::expect_s3_class(out_min$elements, "priority_queue")
  testthat::expect_s3_class(out_min$remaining, "priority_queue")
  testthat::expect_equal(lapply(as.list(out_min$elements), function(e) e$item), list("b", "c"))
  testthat::expect_equal(lapply(as.list(out_min$remaining), function(e) e$item), list("a", "d"))

  out_max <- pop_all_max(q)
  testthat::expect_s3_class(out_max$elements, "priority_queue")
  testthat::expect_s3_class(out_max$remaining, "priority_queue")
  testthat::expect_equal(lapply(as.list(out_max$elements), function(e) e$item), list("a", "d"))
  testthat::expect_equal(lapply(as.list(out_max$remaining), function(e) e$item), list("b", "c"))
})

testthat::test_that("bulk extrema single-element removal preserves pq measures", {
  q <- priority_queue("a", "b", "c", priorities = c(3, 1, 2))

  out_min <- pop_all_min(q)
  testthat::expect_equal(lapply(as.list(out_min$elements), function(e) e$item), list("b"))
  testthat::expect_equal(peek_min(out_min$remaining), "c")
  testthat::expect_equal(peek_max(out_min$remaining), "a")
  testthat::expect_no_error(capture.output(print(out_min$remaining)))

  out_max <- pop_all_max(q)
  testthat::expect_equal(lapply(as.list(out_max$elements), function(e) e$item), list("a"))
  testthat::expect_equal(peek_min(out_max$remaining), "b")
  testthat::expect_equal(peek_max(out_max$remaining), "c")
  testthat::expect_no_error(capture.output(print(out_max$remaining)))
})

testthat::test_that("as.list.priority_queue returns entry records in queue sequence order", {
  q <- as_priority_queue(
    setNames(as.list(c("x", "y", "z")), c("kx", "ky", "kz")),
    priorities = c(2, 1, 3)
  )

  out <- as.list(q)
  testthat::expect_type(out, "list")
  testthat::expect_identical(names(out), c("kx", "ky", "kz"))
  testthat::expect_equal(unname(lapply(out, function(e) e$item)), list("x", "y", "z"))
  testthat::expect_equal(unname(lapply(out, function(e) e$priority)), as.list(c(2, 1, 3)))
})

testthat::test_that("insert is persistent and supports names", {
  q <- as_priority_queue(setNames(as.list(c("x", "y")), c("kx", "ky")), priorities = c(5, 1))
  q2 <- insert(q, "z", priority = 1, name = "kz")

  testthat::expect_equal(peek_min(q), "y")
  testthat::expect_equal(peek_min(q2), "y")
  testthat::expect_equal(q2[["kz"]], "z")
  testthat::expect_equal(q2$kz, "z")
  testthat::expect_equal(length(q2), 3L)
})

testthat::test_that("priority_queue disallows sequence-style mutation helpers", {
  q <- priority_queue("b", "c", priorities = c(2, 3))
  testthat::expect_error(push_front(q, list(item = "a", priority = 1)), "Cast first")
  testthat::expect_error(push_back(q, list(item = "d", priority = 4)), "Cast first")
  testthat::expect_error(peek_front(q), "not supported for priority_queue")
  testthat::expect_error(peek_back(q), "not supported for priority_queue")
  testthat::expect_error(peek_at(q, 1), "not supported for priority_queue")
  testthat::expect_error(pop_front(q), "not supported for priority_queue")
  testthat::expect_error(pop_back(q), "not supported for priority_queue")
  testthat::expect_error(pop_at(q, 1), "not supported for priority_queue")
  testthat::expect_error(insert_at(q, 1, "x"), "not supported for priority_queue")
  testthat::expect_error(c(q, q), "Cast first")
})

testthat::test_that("priority_queue character subset is strict on missing names", {
  q <- as_priority_queue(
    setNames(as.list(c("a", "b", "c")), c("ka", "kb", "kc")),
    priorities = c(3, 1, 2)
  )
  s <- q[c("kb", "ka")]

  testthat::expect_s3_class(s, "priority_queue")
  testthat::expect_equal(peek_min(s), "b")
  testthat::expect_error(q[c("kb", "missing")], "Unknown element name")
})

testthat::test_that("priority_queue disallows positional/logical indexing and replacements", {
  q <- priority_queue("a", "b", priorities = c(2, 1))

  testthat::expect_error(q[[1]], "scalar character names only")
  testthat::expect_error(q[1:2], "character name indexing only")
  testthat::expect_error(q[c(TRUE, FALSE)], "character name indexing only")
  testthat::expect_error({ q[[1]] <- list(item = "x", priority = 5) }, "Cast first")
  testthat::expect_error({ q[c(1, 2)] <- list("u", "v") }, "Cast first")
})

testthat::test_that("priority queue carries required monoids", {
  q <- priority_queue(1, 2, priorities = c(10, 20))
  ms <- names(attr(q, "monoids", exact = TRUE))
  testthat::expect_true(all(c(".size", ".named_count", ".pq_min", ".pq_max") %in% ms))
})

testthat::test_that("priority_queue casts down to flexseq explicitly", {
  q_named <- as_priority_queue(setNames(as.list(c("x", "y")), c("kx", "ky")), priorities = c(2, 1))
  x <- as_flexseq(q_named)

  testthat::expect_s3_class(x, "flexseq")
  testthat::expect_false(inherits(x, "priority_queue"))
  testthat::expect_true(all(c(".size", ".named_count") %in% names(attr(x, "monoids", exact = TRUE))))
  testthat::expect_false(".pq_min" %in% names(attr(x, "monoids", exact = TRUE)))
  testthat::expect_false(".pq_max" %in% names(attr(x, "monoids", exact = TRUE)))
  testthat::expect_equal(x[["kx"]]$item, "x")
  testthat::expect_equal(x[["kx"]]$priority, 2)

  x_unnamed <- as_flexseq(priority_queue("x", "y", priorities = c(2, 1)))
  x2 <- push_back(x_unnamed, list(item = "z", priority = 3))
  testthat::expect_s3_class(x2, "flexseq")
  testthat::expect_equal(length(x2), 3L)
})

testthat::test_that("fapply maps priority queue items with read-only metadata", {
  q <- priority_queue("a", "bb", "ccc", priorities = c(1, 3, 2))
  q2 <- fapply(
    q,
    function(item, priority, name) {
      toupper(item)
    }
  )

  testthat::expect_equal(peek_min(q2), "A")
  testthat::expect_equal(peek_max(q2), "BB")
  testthat::expect_identical(length(q2), 3L)

  pmin <- pop_min(q2)
  pmax <- pop_max(q2)
  testthat::expect_identical(pmin$priority, 1)
  testthat::expect_identical(pmax$priority, 3)
})

testthat::test_that("fapply respects sequence order for ties", {
  q <- as_priority_queue(
    c("a", "b", "c"),
    priorities = c(1, 1, 1)
  )
  q2 <- fapply(q, function(item, priority, name) toupper(item))

  # All priorities tie; left-most in sequence wins.
  testthat::expect_equal(peek_min(q2), "A")
  p1 <- pop_min(q2)
  p2 <- pop_min(p1$remaining)
  testthat::expect_equal(p1$element, "A")
  testthat::expect_equal(p2$element, "B")
})

testthat::test_that("fapply preserves priority queue entry names", {
  q <- as_priority_queue(setNames(as.list(c("x", "y")), c("kx", "ky")), priorities = c(2, 1))
  q2 <- fapply(q, function(item, priority, name) {
    paste(name, item, sep = ":")
  })

  testthat::expect_equal(q2[["kx"]], "kx:x")
  testthat::expect_equal(q2[["ky"]], "ky:y")
  testthat::expect_equal(q2$kx, "kx:x")
})

testthat::test_that("fapply can drop custom monoids for priority_queue", {
  sum_item <- measure_monoid(`+`, 0, function(el) as.numeric(el$item))
  q <- add_monoids(priority_queue(1, 2, priorities = c(2, 1)), list(sum_item = sum_item))
  q2 <- fapply(q, function(item, priority, name) item * 10, preserve_custom_monoids = FALSE)

  ms <- attr(q2, "monoids", exact = TRUE)
  testthat::expect_true(!is.null(ms[[".size"]]))
  testthat::expect_true(!is.null(ms[[".named_count"]]))
  testthat::expect_true(!is.null(ms[[".pq_min"]]))
  testthat::expect_true(!is.null(ms[[".pq_max"]]))
  testthat::expect_true(is.null(ms[["sum_item"]]))
  testthat::expect_error(node_measure(q2, "sum_item"), "Missing cached measure")
  testthat::expect_equal(peek_min(q2), 20)
})

testthat::test_that("fapply validates priority queue inputs", {
  q <- priority_queue("a", priorities = 1)
  testthat::expect_error(fapply.priority_queue(as_flexseq(1:3), FUN = identity), "`q` must be a priority_queue")
  testthat::expect_error(fapply(q, 1), "`FUN` must be a function")
  testthat::expect_error(fapply(q, identity, preserve_custom_monoids = NA), "`preserve_custom_monoids` must be TRUE or FALSE")
})

testthat::test_that("priority_queue blocks split helpers and allows locate helper", {
  q <- priority_queue("a", "b", priorities = c(2, 1))
  testthat::expect_error(split_by_predicate(q, function(v) v >= 1, ".size"), "Cast first")
  testthat::expect_error(split_around_by_predicate(q, function(v) v >= 1, ".size"), "Cast first")
  testthat::expect_error(split_at(q, 1), "Cast first")

  loc <- locate_by_predicate(q, function(v) v >= 1, ".size", include_metadata = TRUE)
  testthat::expect_true(loc$found)
  testthat::expect_identical(loc$elem$item, "a")
  testthat::expect_identical(loc$metadata$index, 1L)
})

testthat::test_that("priority_queue supports Date priorities with FIFO ties", {
  p <- as.Date(c("2024-01-03", "2024-01-01", "2024-01-01"))
  q <- priority_queue("late", "early1", "early2", priorities = p)

  testthat::expect_equal(peek_min(q), "early1")
  testthat::expect_equal(peek_max(q), "late")

  out1 <- pop_min(q)
  out2 <- pop_min(out1$remaining)
  testthat::expect_equal(out1$element, "early1")
  testthat::expect_equal(out2$element, "early2")
  testthat::expect_s3_class(out1$priority, "Date")
  testthat::expect_true(inherits(out2$priority, "Date"))

  q2 <- insert(q, "early3", priority = as.Date("2024-01-01"))
  testthat::expect_equal(pop_min(pop_min(q2)$remaining)$element, "early2")
})

testthat::test_that("priority_queue supports POSIXct priorities with type-preserving pops", {
  p <- as.POSIXct(
    c("2024-01-01 12:00:00", "2024-01-01 10:00:00", "2024-01-01 10:00:00"),
    tz = "UTC"
  )
  q <- priority_queue("late", "early1", "early2", priorities = p)

  testthat::expect_equal(peek_min(q), "early1")
  out <- pop_min(q)
  testthat::expect_equal(out$element, "early1")
  testthat::expect_s3_class(out$priority, "POSIXct")
  testthat::expect_s3_class(out$priority, "POSIXt")
})

testthat::test_that("priority_queue rejects mixed priority domains and missing priorities", {
  testthat::expect_error(
    as_priority_queue(list("a", "b"), priorities = list(1, "1")),
    "Incompatible priority type"
  )
  testthat::expect_error(
    as_priority_queue(list("a", "b"), priorities = list(1, as.Date("2024-01-01"))),
    "Incompatible priority type"
  )
  testthat::expect_error(
    as_priority_queue(
      list("a", "b"),
      priorities = list(as.Date("2024-01-01"), as.POSIXct("2024-01-01 00:00:00", tz = "UTC"))
    ),
    "Incompatible priority type"
  )

  q_num <- priority_queue("a", priorities = 1)
  q_date <- priority_queue("a", priorities = as.Date("2024-01-01"))
  testthat::expect_error(insert(q_num, "b", priority = "1"), "Incompatible priority type")
  testthat::expect_error(insert(q_num, "b", priority = as.Date("2024-01-01")), "Incompatible priority type")
  testthat::expect_error(
    insert(q_date, "b", priority = as.POSIXct("2024-01-01 00:00:00", tz = "UTC")),
    "Incompatible priority type"
  )

  testthat::expect_error(
    priority_queue("a", priorities = as.Date(NA)),
    "`priority` must be non-missing"
  )
  testthat::expect_error(
    insert(q_date, "b", priority = as.Date(NA)),
    "`priority` must be non-missing"
  )
})
