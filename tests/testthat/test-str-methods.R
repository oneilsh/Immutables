testthat::test_that("str() works for flexseq-like classes with restricted indexing", {
  x <- as_flexseq(list(a = 1, b = 2, c = 3))
  q <- priority_queue(one = 1, two = 2, three = 3, priorities = 1:3)
  os <- ordered_sequence(one = 1, two = 2, three = 3, keys = 1:3)
  ix <- interval_index(
    one = 1, two = 2, three = 3,
    start = c(1, 5, 10),
    end = c(3, 7, 12)
  )

  out_x <- testthat::expect_no_error(utils::capture.output(utils::str(x)))
  out_q <- testthat::expect_no_error(utils::capture.output(utils::str(q)))
  out_os <- testthat::expect_no_error(utils::capture.output(utils::str(os)))
  out_ix <- testthat::expect_no_error(utils::capture.output(utils::str(ix)))

  testthat::expect_true(any(grepl("^List of ", out_x)))
  testthat::expect_true(any(grepl("^List of ", out_q)))
  testthat::expect_true(any(grepl("^List of ", out_os)))
  testthat::expect_true(any(grepl("^List of ", out_ix)))

  blocked_msg <- "supports scalar character names only"
  testthat::expect_false(any(grepl(blocked_msg, out_q, fixed = TRUE)))
  testthat::expect_false(any(grepl(blocked_msg, out_os, fixed = TRUE)))
  testthat::expect_false(any(grepl(blocked_msg, out_ix, fixed = TRUE)))
})

testthat::test_that("print show_custom_monoids displays custom names and root measures only", {
  fx <- add_monoids(
    as_flexseq(as.list(c(1, 2))),
    list(sum_item = measure_monoid(`+`, 0, function(el) as.numeric(el)))
  )
  pq <- add_monoids(
    priority_queue(one = 1, two = 2, priorities = c(2, 1)),
    list(sum_item = measure_monoid(`+`, 0, function(entry) as.numeric(entry$value)))
  )
  os <- add_monoids(
    ordered_sequence(one = 1, two = 2, keys = c(2, 1)),
    list(sum_key = measure_monoid(`+`, 0, function(entry) as.numeric(entry$key)))
  )
  ix <- add_monoids(
    interval_index(one = 1, two = 2, start = c(1, 3), end = c(2, 5)),
    list(width_sum = measure_monoid(`+`, 0, function(entry) as.numeric(entry$end - entry$start)))
  )

  out_fx <- utils::capture.output(print(fx, max_elements = 0, show_custom_monoids = TRUE))
  out_pq <- utils::capture.output(print(pq, max_elements = 0, show_custom_monoids = TRUE))
  out_os <- utils::capture.output(print(os, max_elements = 0, show_custom_monoids = TRUE))
  out_ix <- utils::capture.output(print(ix, max_elements = 0, show_custom_monoids = TRUE))

  testthat::expect_true(any(grepl("Custom monoids + measures:", out_fx, fixed = TRUE)))
  testthat::expect_true(any(grepl("sum_item: 3", out_fx, fixed = TRUE)))
  testthat::expect_false(any(grepl(".size", out_fx, fixed = TRUE)))

  testthat::expect_true(any(grepl("Custom monoids + measures:", out_pq, fixed = TRUE)))
  testthat::expect_true(any(grepl("sum_item: 3", out_pq, fixed = TRUE)))
  testthat::expect_false(any(grepl(".pq_min", out_pq, fixed = TRUE)))
  testthat::expect_false(any(grepl(".pq_max", out_pq, fixed = TRUE)))

  testthat::expect_true(any(grepl("Custom monoids + measures:", out_os, fixed = TRUE)))
  testthat::expect_true(any(grepl("sum_key: 3", out_os, fixed = TRUE)))
  testthat::expect_false(any(grepl(".oms_max_key", out_os, fixed = TRUE)))

  testthat::expect_true(any(grepl("Custom monoids + measures:", out_ix, fixed = TRUE)))
  testthat::expect_true(any(grepl("width_sum: 3", out_ix, fixed = TRUE)))
  testthat::expect_false(any(grepl(".ivx_max_start", out_ix, fixed = TRUE)))
  testthat::expect_false(any(grepl(".ivx_max_end", out_ix, fixed = TRUE)))
  testthat::expect_false(any(grepl(".ivx_min_end", out_ix, fixed = TRUE)))

  out_default <- utils::capture.output(print(fx, max_elements = 0))
  testthat::expect_false(any(grepl("Custom monoids + measures:", out_default, fixed = TRUE)))
})

testthat::test_that("print show_custom_monoids prints <none> with no custom monoids and validates input", {
  plain_fx <- as_flexseq(as.list(c(1, 2)))
  plain_pq <- priority_queue(1, 2, priorities = c(2, 1))
  plain_os <- ordered_sequence(1, 2, keys = c(2, 1))
  plain_ix <- interval_index(1, 2, start = c(1, 3), end = c(2, 5))

  out_fx <- utils::capture.output(print(plain_fx, max_elements = 0, show_custom_monoids = TRUE))
  out_pq <- utils::capture.output(print(plain_pq, max_elements = 0, show_custom_monoids = TRUE))
  out_os <- utils::capture.output(print(plain_os, max_elements = 0, show_custom_monoids = TRUE))
  out_ix <- utils::capture.output(print(plain_ix, max_elements = 0, show_custom_monoids = TRUE))

  testthat::expect_true(any(grepl("Custom monoids + measures: <none>", out_fx, fixed = TRUE)))
  testthat::expect_true(any(grepl("Custom monoids + measures: <none>", out_pq, fixed = TRUE)))
  testthat::expect_true(any(grepl("Custom monoids + measures: <none>", out_os, fixed = TRUE)))
  testthat::expect_true(any(grepl("Custom monoids + measures: <none>", out_ix, fixed = TRUE)))

  testthat::expect_error(print(plain_fx, max_elements = 0, show_custom_monoids = NA), "TRUE or FALSE")
  testthat::expect_error(print(plain_pq, max_elements = 0, show_custom_monoids = 1), "TRUE or FALSE")
})
