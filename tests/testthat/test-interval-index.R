testthat::test_that("interval_index constructor sorts by start and preserves stable duplicate order", {
  ix <- as_interval_index(
    list("c", "a", "b", "d"),
    start = c(2, 1, 2, 2),
    end = c(5, 3, 4, 6)
  )

  testthat::expect_s3_class(ix, "interval_index")
  testthat::expect_equal(as.list(ix), list("a", "c", "b", "d"))
  testthat::expect_identical(length(ix), 4L)

  entries <- .ivx_entries(ix)
  starts <- lapply(entries, function(e) e$start)
  ends <- lapply(entries, function(e) e$end)
  testthat::expect_equal(starts, as.list(c(1, 2, 2, 2)))
  testthat::expect_equal(ends, as.list(c(3, 5, 4, 6)))
})

testthat::test_that("interval_index validates endpoints and bounds", {
  ok <- as_interval_index("p", start = 2, end = 2)
  testthat::expect_s3_class(ok, "interval_index")

  testthat::expect_error(as_interval_index("x", start = 3, end = 2), "start")
  testthat::expect_error(as_interval_index("x", start = 1, end = 2, default_query_bounds = "bad"), "bounds")
})

testthat::test_that("min_endpoint/max_endpoint expose endpoint extrema", {
  ix <- as_interval_index(list("c", "a", "b"), start = c(2, 1, 2), end = c(5, 3, 4))
  testthat::expect_identical(min_endpoint(ix), 1)
  testthat::expect_identical(max_endpoint(ix), 5)

  empty <- interval_index()
  testthat::expect_null(min_endpoint(empty))
  testthat::expect_null(max_endpoint(empty))
})

testthat::test_that("insert is persistent and appends at right edge of equal-start block", {
  ix <- as_interval_index(list("a", "b", "c"), start = c(1, 2, 2), end = c(2, 3, 4))
  ix2 <- insert(ix, "d", start = 2, end = 5)

  testthat::expect_equal(as.list(ix), list("a", "b", "c"))
  testthat::expect_equal(as.list(ix2), list("a", "b", "c", "d"))

  entries <- .ivx_entries(ix2)
  starts <- lapply(entries, function(e) e$start)
  ends <- lapply(entries, function(e) e$end)
  testthat::expect_equal(starts, as.list(c(1, 2, 2, 2)))
  testthat::expect_equal(ends, as.list(c(2, 3, 4, 5)))
})

testthat::test_that("peek_point honors boundary modes", {
  ix <- as_interval_index(
    list("A", "B", "C", "D"),
    start = c(1, 2, 3, 2),
    end = c(2, 3, 4, 2),
    default_query_bounds = "[)"
  )

  testthat::expect_equal(peek_point(ix, 2, bounds = "[)"), "B")
  testthat::expect_equal(as.list(peek_all_point(ix, 2, bounds = "[]")), list("A", "B", "D"))
  testthat::expect_null(peek_point(ix, 2, bounds = "()"))
  testthat::expect_identical(length(peek_all_point(ix, 2, bounds = "()")), 0L)
  testthat::expect_equal(as.list(peek_all_point(ix, 2, bounds = "(]")), list("A"))
})

testthat::test_that("peek overlap/contain/within queries are deterministic", {
  ix <- as_interval_index(
    list("A", "B", "C", "D"),
    start = c(1, 2, 3, 2),
    end = c(2, 3, 4, 2),
    default_query_bounds = "[)"
  )

  testthat::expect_equal(peek_overlaps(ix, 2, 3, bounds = "[)"), "B")
  testthat::expect_equal(as.list(peek_all_overlaps(ix, 2, 3, bounds = "[]")), list("A", "B", "D", "C"))

  jy <- as_interval_index(
    list("outer", "inner", "tail", "point"),
    start = c(1, 2, 2, 3),
    end = c(5, 3, 5, 3),
    default_query_bounds = "[]"
  )

  testthat::expect_equal(peek_containing(jy, 2, 3), "outer")
  testthat::expect_equal(as.list(peek_all_containing(jy, 2, 3)), list("outer", "inner", "tail"))
  testthat::expect_equal(peek_within(jy, 2, 3), "inner")
  testthat::expect_equal(as.list(peek_all_within(jy, 2, 3)), list("inner", "point"))

  testthat::expect_null(peek_overlaps(ix, 9, 10))
  miss <- peek_all_overlaps(ix, 9, 10)
  testthat::expect_s3_class(miss, "interval_index")
  testthat::expect_identical(length(miss), 0L)
})

testthat::test_that("relation query/pop contracts hold across all bounds tokens", {
  ix <- as_interval_index(
    list("A", "B", "C", "D"),
    start = c(1, 2, 3, 2),
    end = c(2, 3, 4, 2),
    default_query_bounds = "[)"
  )
  vals <- as.list(ix)
  entries <- .ivx_entries(ix)
  starts <- as.numeric(unlist(lapply(entries, function(e) e$start), use.names = FALSE))
  ends <- as.numeric(unlist(lapply(entries, function(e) e$end), use.names = FALSE))

  contains_point <- function(start, end, point, bounds) {
    include_start <- substr(bounds, 1L, 1L) == "["
    include_end <- substr(bounds, 2L, 2L) == "]"
    left_ok <- if(include_start) point >= start else point > start
    right_ok <- if(include_end) point <= end else point < end
    isTRUE(left_ok && right_ok)
  }
  overlaps <- function(a_start, a_end, b_start, b_end, bounds) {
    touching_is_overlap <- identical(bounds, "[]")
    a_before_b <- if(touching_is_overlap) a_end < b_start else a_end <= b_start
    b_before_a <- if(touching_is_overlap) b_end < a_start else b_end <= a_start
    !isTRUE(a_before_b || b_before_a)
  }
  containing <- function(start, end, q_start, q_end, bounds) {
    overlaps(start, end, q_start, q_end, bounds) && start <= q_start && end >= q_end
  }
  within <- function(start, end, q_start, q_end, bounds) {
    overlaps(start, end, q_start, q_end, bounds) && q_start <= start && q_end >= end
  }

  bounds_tokens <- c("[)", "[]", "()", "(]")
  for(bt in bounds_tokens) {
    idx_point <- which(vapply(seq_along(vals), function(i) contains_point(starts[[i]], ends[[i]], 2, bt), logical(1)))
    idx_over <- which(vapply(seq_along(vals), function(i) overlaps(starts[[i]], ends[[i]], 2, 3, bt), logical(1)))
    idx_cont <- which(vapply(seq_along(vals), function(i) containing(starts[[i]], ends[[i]], 2, 3, bt), logical(1)))
    idx_with <- which(vapply(seq_along(vals), function(i) within(starts[[i]], ends[[i]], 2, 3, bt), logical(1)))

    expect_relation <- function(peek_first, peek_all, pop_first, pop_all, idx) {
      expect_all <- vals[idx]
      expect_rest <- vals[setdiff(seq_along(vals), idx)]

      testthat::expect_equal(as.list(peek_all), expect_all)
      if(length(expect_all) == 0L) {
        testthat::expect_null(peek_first)
      } else {
        testthat::expect_equal(peek_first, expect_all[[1L]])
      }

      if(length(expect_all) == 0L) {
        testthat::expect_null(pop_first$value)
        testthat::expect_null(pop_first$start)
        testthat::expect_null(pop_first$end)
        testthat::expect_equal(as.list(pop_first$remaining), vals)
      } else {
        i <- idx[[1L]]
        testthat::expect_equal(pop_first$value, vals[[i]])
        testthat::expect_equal(pop_first$start, starts[[i]])
        testthat::expect_equal(pop_first$end, ends[[i]])
        testthat::expect_equal(as.list(pop_first$remaining), vals[-i])
      }

      testthat::expect_equal(as.list(pop_all$elements), expect_all)
      testthat::expect_equal(as.list(pop_all$remaining), expect_rest)
    }

    expect_relation(
      peek_first = peek_point(ix, 2, bounds = bt),
      peek_all = peek_all_point(ix, 2, bounds = bt),
      pop_first = pop_point(ix, 2, bounds = bt),
      pop_all = pop_all_point(ix, 2, bounds = bt),
      idx = idx_point
    )
    expect_relation(
      peek_first = peek_overlaps(ix, 2, 3, bounds = bt),
      peek_all = peek_all_overlaps(ix, 2, 3, bounds = bt),
      pop_first = pop_overlaps(ix, 2, 3, bounds = bt),
      pop_all = pop_all_overlaps(ix, 2, 3, bounds = bt),
      idx = idx_over
    )
    expect_relation(
      peek_first = peek_containing(ix, 2, 3, bounds = bt),
      peek_all = peek_all_containing(ix, 2, 3, bounds = bt),
      pop_first = pop_containing(ix, 2, 3, bounds = bt),
      pop_all = pop_all_containing(ix, 2, 3, bounds = bt),
      idx = idx_cont
    )
    expect_relation(
      peek_first = peek_within(ix, 2, 3, bounds = bt),
      peek_all = peek_all_within(ix, 2, 3, bounds = bt),
      pop_first = pop_within(ix, 2, 3, bounds = bt),
      pop_all = pop_all_within(ix, 2, 3, bounds = bt),
      idx = idx_with
    )
  }
})

testthat::test_that("point queries honor match_at modes on a fixed fixture", {
  ix <- as_interval_index(
    list("A", "B", "C", "D"),
    start = c(1, 2, 3, 2),
    end = c(3, 4, 5, 2),
    default_query_bounds = "[)"
  )

  # match_at = "start": entries whose start == point, FIFO on ties.
  testthat::expect_equal(peek_point(ix, 2, match_at = "start"), "B")
  testthat::expect_equal(as.list(peek_all_point(ix, 2, match_at = "start")), list("B", "D"))
  testthat::expect_null(peek_point(ix, 99, match_at = "start"))

  # match_at = "end": entries whose end == point.
  testthat::expect_equal(peek_point(ix, 3, match_at = "end"), "A")
  testthat::expect_equal(as.list(peek_all_point(ix, 3, match_at = "end")), list("A"))
  testthat::expect_equal(as.list(peek_all_point(ix, 2, match_at = "end")), list("D"))
  testthat::expect_identical(length(peek_all_point(ix, 99, match_at = "end")), 0L)

  # match_at = "either": union of start/end matches, canonical order by start.
  testthat::expect_equal(as.list(peek_all_point(ix, 2, match_at = "either")), list("B", "D"))
  testthat::expect_equal(as.list(peek_all_point(ix, 3, match_at = "either")), list("A", "C"))

  # pop_* shapes match peek semantics and preserve persistence.
  before <- as.list(ix)
  popped_end <- pop_all_point(ix, 3, match_at = "end")
  testthat::expect_equal(as.list(popped_end$elements), list("A"))
  testthat::expect_equal(as.list(popped_end$remaining), list("B", "D", "C"))
  testthat::expect_equal(as.list(ix), before)

  one_start <- pop_point(ix, 2, match_at = "start")
  testthat::expect_equal(one_start$value, "B")
  testthat::expect_equal(one_start$start, 2)
  testthat::expect_equal(one_start$end, 4)
  testthat::expect_equal(as.list(one_start$remaining), list("A", "D", "C"))
  # (sanity: after popping first of B/D at start==2, D is the only remaining start==2 entry)
})

testthat::test_that("match_at = 'interval' preserves default containment semantics", {
  ix <- as_interval_index(
    list("A", "B", "C"),
    start = c(1, 2, 4),
    end = c(3, 2, 5),
    default_query_bounds = "[)"
  )
  testthat::expect_equal(peek_point(ix, 2), peek_point(ix, 2, match_at = "interval"))
  testthat::expect_equal(
    as.list(peek_all_point(ix, 2)),
    as.list(peek_all_point(ix, 2, match_at = "interval"))
  )
})

testthat::test_that("coordinate-equality match_at modes ignore bounds", {
  ix <- as_interval_index(
    list("A", "B", "C"),
    start = c(1, 2, 3),
    end = c(3, 4, 5),
    default_query_bounds = "[)"
  )
  # With match_at = "end", endpoint is a structural coordinate — bounds override
  # has no effect.
  expected <- as.list(peek_all_point(ix, 3, match_at = "end"))
  for(bt in c("[)", "[]", "()", "(]")) {
    testthat::expect_equal(
      as.list(peek_all_point(ix, 3, match_at = "end", bounds = bt)),
      expected
    )
  }
})

testthat::test_that("match_at on empty indices is non-throwing and empty", {
  empty_ix <- interval_index()
  for(m in c("start", "end", "either")) {
    testthat::expect_null(peek_point(empty_ix, 1, match_at = m))
    testthat::expect_identical(length(peek_all_point(empty_ix, 1, match_at = m)), 0L)
    r <- pop_point(empty_ix, 1, match_at = m)
    testthat::expect_null(r$value)
    testthat::expect_null(r$start)
    testthat::expect_null(r$end)
    testthat::expect_identical(length(r$remaining), 0L)
    ra <- pop_all_point(empty_ix, 1, match_at = m)
    testthat::expect_identical(length(ra$elements), 0L)
    testthat::expect_identical(length(ra$remaining), 0L)
  }
})

testthat::test_that("match_at point queries match a pure-R oracle across bounds tokens", {
  ix <- as_interval_index(
    list("A", "B", "C", "D", "E"),
    start = c(1, 2, 3, 2, 4),
    end = c(3, 4, 5, 2, 4),
    default_query_bounds = "[)"
  )
  vals <- as.list(ix)
  entries <- .ivx_entries(ix)
  starts <- as.numeric(unlist(lapply(entries, function(e) e$start), use.names = FALSE))
  ends <- as.numeric(unlist(lapply(entries, function(e) e$end), use.names = FALSE))

  for(p in c(1, 2, 3, 4, 5, 99)) {
    # start mode
    idx <- which(starts == p)
    testthat::expect_equal(as.list(peek_all_point(ix, p, match_at = "start")), vals[idx])
    # end mode
    idx <- which(ends == p)
    testthat::expect_equal(as.list(peek_all_point(ix, p, match_at = "end")), vals[idx])
    # either mode — canonical start order
    idx <- which(starts == p | ends == p)
    testthat::expect_equal(as.list(peek_all_point(ix, p, match_at = "either")), vals[idx])
  }
})

testthat::test_that("pop helpers follow first/all contracts and preserve persistence", {
  ix <- as_interval_index(
    list("A", "B", "C", "D"),
    start = c(1, 2, 3, 2),
    end = c(2, 3, 4, 2),
    default_query_bounds = "[]"
  )

  first <- pop_overlaps(ix, 2, 3)
  testthat::expect_equal(first$value, "A")
  testthat::expect_equal(first$start, 1)
  testthat::expect_equal(first$end, 2)
  testthat::expect_s3_class(first$remaining, "interval_index")

  all <- pop_all_overlaps(ix, 2, 3)
  testthat::expect_s3_class(all$elements, "interval_index")
  testthat::expect_equal(as.list(all$elements), list("A", "B", "D", "C"))
  testthat::expect_identical(length(all$remaining), 0L)

  point_first <- pop_point(ix, 2)
  testthat::expect_equal(point_first$value, "A")
  testthat::expect_equal(point_first$start, 1)
  testthat::expect_equal(point_first$end, 2)
  testthat::expect_equal(as.list(point_first$remaining), list("B", "D", "C"))

  point_all <- pop_all_point(ix, 2)
  testthat::expect_s3_class(point_all$elements, "interval_index")
  testthat::expect_equal(as.list(point_all$elements), list("A", "B", "D"))
  testthat::expect_equal(as.list(point_all$remaining), list("C"))

  miss_first <- pop_within(ix, 9, 10)
  testthat::expect_null(miss_first$value)
  testthat::expect_null(miss_first$start)
  testthat::expect_null(miss_first$end)
  testthat::expect_equal(as.list(miss_first$remaining), as.list(ix))

  miss_all <- pop_all_containing(ix, 9, 10)
  testthat::expect_s3_class(miss_all$elements, "interval_index")
  testthat::expect_identical(length(miss_all$elements), 0L)
  testthat::expect_equal(as.list(miss_all$remaining), as.list(ix))

  miss_point_first <- pop_point(ix, 9)
  testthat::expect_null(miss_point_first$value)
  testthat::expect_null(miss_point_first$start)
  testthat::expect_null(miss_point_first$end)
  testthat::expect_equal(as.list(miss_point_first$remaining), as.list(ix))

  miss_point_all <- pop_all_point(ix, 9)
  testthat::expect_s3_class(miss_point_all$elements, "interval_index")
  testthat::expect_identical(length(miss_point_all$elements), 0L)
  testthat::expect_equal(as.list(miss_point_all$remaining), as.list(ix))
})

testthat::test_that("ordered key APIs are blocked on interval_index", {
  ix <- as_interval_index(list("a", "b"), start = c(1, 2), end = c(2, 3))

  testthat::expect_error(lower_bound(ix, 2), "not supported for interval_index")
  testthat::expect_error(upper_bound(ix, 2), "not supported for interval_index")
  testthat::expect_error(peek_key(ix, 2), "not supported for interval_index")
  testthat::expect_error(pop_key(ix, 2), "not supported for interval_index")
  testthat::expect_error(elements_between(ix, 1, 2), "not supported for interval_index")
  testthat::expect_error(count_key(ix, 2), "not supported for interval_index")
  testthat::expect_error(count_between(ix, 1, 2), "not supported for interval_index")
})

testthat::test_that("interval_index indexing preserves class and blocks replacement", {
  ix <- as_interval_index(
    setNames(as.list(c("xa", "xb", "xc")), c("a", "b", "c")),
    start = c(1, 2, 3),
    end = c(2, 3, 4)
  )

  sub <- ix[c(1, 3)]
  testthat::expect_s3_class(sub, "interval_index")
  testthat::expect_equal(as.list(sub), list(a = "xa", c = "xc"))
  testthat::expect_identical(names(as.list(sub)), c("a", "c"))

  testthat::expect_equal(ix[[2]], "xb")
  testthat::expect_equal(ix[["c"]], "xc")
  testthat::expect_equal(ix$b, "xb")

  reordered <- NULL
  testthat::expect_warning(
    { reordered <- ix[c(3, 1)] },
    "canonicalizes selector order"
  )
  testthat::expect_equal(as.list(reordered), list(a = "xa", c = "xc"))

  reordered_name <- NULL
  testthat::expect_warning(
    { reordered_name <- ix[c("b", "a")] },
    "canonicalizes selector order"
  )
  testthat::expect_equal(as.list(reordered_name), list(a = "xa", b = "xb"))

  testthat::expect_error(ix[c(2, 2)], "duplicate indices")
  testthat::expect_error(ix[c("a", "a")], "duplicate indices")

  testthat::expect_error({ ix[[1]] <- "qq" }, "not supported")
  testthat::expect_error({ ix[1] <- list("qq") }, "not supported")
  testthat::expect_error({ ix$b <- "qq" }, "not supported")
})

testthat::test_that("front/back/at peek/pop helpers are blocked on interval_index", {
  ix <- as_interval_index("a", start = 1, end = 2)

  testthat::expect_error(peek_front(ix), "not supported for interval_index")
  testthat::expect_error(peek_back(ix), "not supported for interval_index")
  testthat::expect_error(peek_at(ix, 1), "not supported for interval_index")
  testthat::expect_error(pop_front(ix), "not supported for interval_index")
  testthat::expect_error(pop_back(ix), "not supported for interval_index")
  testthat::expect_error(pop_at(ix, 1), "not supported for interval_index")
})

testthat::test_that("fapply for interval_index updates payload only and keeps interval metadata immutable", {
  ix <- as_interval_index(
    setNames(as.list(c("a", "b", "c")), c("ka", "kb", "kc")),
    start = c(3, 1, 2),
    end = c(4, 2, 3),
    default_query_bounds = "[]"
  )
  b0 <- lapply(.ivx_entries(ix), function(e) list(start = e$start, end = e$end))

  ix2 <- fapply(ix, function(value, start, end, name) {
    toupper(value)
  })
  ix2_noname <- fapply(ix, function(value, start, end) {
    paste0(value, "@", start, "-", end)
  })

  testthat::expect_s3_class(ix2, "interval_index")
  testthat::expect_equal(unname(as.list(ix2)), list("B", "C", "A"))
  testthat::expect_equal(ix2[["kb"]], "B")
  testthat::expect_equal(ix2_noname[["kb"]], "b@1-2")

  b2 <- lapply(.ivx_entries(ix2), function(e) list(start = e$start, end = e$end))
  testthat::expect_equal(unname(lapply(b2, function(e) e$start)), unname(lapply(b0, function(e) e$start)))
  testthat::expect_equal(unname(lapply(b2, function(e) e$end)), unname(lapply(b0, function(e) e$end)))

  testthat::expect_error(fapply(ix, 1), "`FUN` must be a function")

  ix3 <- fapply(ix, function(value, start, end, name) {
    list(old = value, at = c(start, end), nm = name)
  })
  testthat::expect_type(ix3[[1]], "list")
  testthat::expect_named(ix3[[1]], c("old", "at", "nm"))
  b3 <- lapply(.ivx_entries(ix3), function(e) list(start = e$start, end = e$end))
  testthat::expect_equal(unname(lapply(b3, function(e) e$start)), unname(lapply(b0, function(e) e$start)))
  testthat::expect_equal(unname(lapply(b3, function(e) e$end)), unname(lapply(b0, function(e) e$end)))
  testthat::expect_error(fapply(ix, identity, preserve_custom_monoids = NA), "`preserve_custom_monoids` must be TRUE or FALSE")
})

testthat::test_that("interval_index recomputes user monoids across insert, fapply, and slices", {
  sum_item <- measure_monoid(function(a, b) a + b, 0, function(entry) as.numeric(entry$value))
  width_sum <- measure_monoid(function(a, b) a + b, 0, function(entry) as.numeric(entry$end - entry$start))

  ix <- add_monoids(as_interval_index(
    as.list(c(10, 20, 30)),
    start = c(1, 2, 4),
    end = c(3, 5, 6)
  ), list(sum_item = sum_item, width_sum = width_sum))
  testthat::expect_equal(node_measure(ix, "sum_item"), 60)
  testthat::expect_equal(node_measure(ix, "width_sum"), 7)

  ix2 <- insert(ix, 40, start = 3, end = 4)
  testthat::expect_equal(node_measure(ix2, "sum_item"), 100)
  testthat::expect_equal(node_measure(ix2, "width_sum"), 8)

  ix3 <- fapply(ix2, function(value, start, end, name) value + 1)
  testthat::expect_equal(node_measure(ix3, "sum_item"), 104)
  testthat::expect_equal(node_measure(ix3, "width_sum"), 8)

  overlaps <- peek_all_overlaps(ix3, 2, 3, bounds = "[)")
  testthat::expect_s3_class(overlaps, "interval_index")
  testthat::expect_equal(as.list(overlaps), as.list(c(11, 21)))
  testthat::expect_equal(node_measure(overlaps, "sum_item"), 32)
  testthat::expect_equal(node_measure(overlaps, "width_sum"), 5)

  popped <- pop_all_overlaps(ix3, 2, 3, bounds = "[)")
  testthat::expect_s3_class(popped$elements, "interval_index")
  testthat::expect_s3_class(popped$remaining, "interval_index")
  testthat::expect_equal(node_measure(popped$elements, "sum_item"), 32)
  testthat::expect_equal(node_measure(popped$remaining, "sum_item"), 72)
  testthat::expect_equal(node_measure(popped$elements, "width_sum"), 5)
  testthat::expect_equal(node_measure(popped$remaining, "width_sum"), 3)
})

testthat::test_that("interval_index custom monoids accept entry measure arguments", {
  ix <- add_monoids(
    as_interval_index(as.list(c(10, 20)), start = c(1, 3), end = c(2, 5)),
    list(
      by_width = measure_monoid(`+`, 0, function(entry) as.numeric(entry$end - entry$start))
    )
  )
  testthat::expect_equal(node_measure(ix, "by_width"), 3)
})

testthat::test_that("fapply can drop custom monoids for interval_index", {
  sum_item <- measure_monoid(`+`, 0, function(entry) as.numeric(entry$value))
  ix <- add_monoids(as_interval_index(as.list(c(10, 20)), start = c(1, 3), end = c(2, 5)), list(sum_item = sum_item))
  ix2 <- fapply(ix, function(value, start, end, name) value + 1, preserve_custom_monoids = FALSE)

  ms <- attr(ix2, "monoids", exact = TRUE)
  testthat::expect_true(!is.null(ms[[".size"]]))
  testthat::expect_true(!is.null(ms[[".named_count"]]))
  testthat::expect_true(!is.null(ms[[".ivx_max_start"]]))
  testthat::expect_true(!is.null(ms[[".ivx_max_end"]]))
  testthat::expect_true(!is.null(ms[[".ivx_min_end"]]))
  testthat::expect_true(is.null(ms[["sum_item"]]))
  testthat::expect_error(node_measure(ix2, "sum_item"), "Missing cached measure")
  testthat::expect_equal(as.list(ix2), as.list(c(11, 21)))
})

testthat::test_that("interval_index casts down to flexseq explicitly", {
  width_sum <- measure_monoid(`+`, 0, function(entry) as.numeric(entry$end - entry$start))
  ix <- add_monoids(as_interval_index(
    setNames(list("x", "y"), c("ix", "iy")),
    start = c(1, 3),
    end = c(2, 5)
  ), list(width_sum = width_sum))

  fx <- as_flexseq(ix)
  testthat::expect_s3_class(fx, "flexseq")
  testthat::expect_false(inherits(fx, "interval_index"))
  testthat::expect_equal(fx[["ix"]], "x")
  testthat::expect_equal(fx[["iy"]], "y")

  ms <- names(attr(fx, "monoids", exact = TRUE))
  testthat::expect_true(all(c(".size", ".named_count") %in% ms))
  testthat::expect_false("width_sum" %in% ms)
  testthat::expect_error(node_measure(fx, "width_sum"), "Missing cached measure")
  testthat::expect_false(".ivx_max_start" %in% ms)
  testthat::expect_false(".ivx_max_end" %in% ms)
  testthat::expect_false(".ivx_min_end" %in% ms)
  testthat::expect_false(".oms_max_key" %in% ms)
})
