helper_env <- new.env(parent = globalenv())
sys.source(
  testthat::test_path("..", "..", "vignettes", "helpers", "benchmark_helpers.R"),
  envir = helper_env
)

# --- Sequence benchmarks --------------------------------------------------

testthat::test_that("sequence benchmark cell returns expected columns", {
  testthat::skip_if_not_installed("microbenchmark")

  inputs <- helper_env$sequence_benchmark_inputs(10L)
  out <- helper_env$run_sequence_benchmark_cell(
    implementation = "flexseq",
    operation = "append",
    n = 10L,
    inputs = inputs,
    repeats = 2L
  )

  testthat::expect_identical(
    names(out),
    c("family", "implementation", "operation", "n", "repeat", "time_us")
  )
  testthat::expect_identical(out$family, c("sequence", "sequence"))
  testthat::expect_identical(out$implementation, c("flexseq", "flexseq"))
  testthat::expect_identical(out$operation, c("append", "append"))
  testthat::expect_identical(out$n, c(10L, 10L))
  testthat::expect_identical(out[["repeat"]], c(1L, 2L))
  testthat::expect_true(all(is.finite(out$time_us)))
})

testthat::test_that("sequence wrappers preserve comparable semantics", {
  values <- letters[1:4]
  inputs <- list(
    append_value = "z",
    prepend_value = "z",
    replace_value = "y"
  )

  flex <- helper_env$make_sequence_fixture("flexseq", values)
  base <- helper_env$make_sequence_fixture("base R list", values)

  # append
  testthat::expect_identical(
    as.list(helper_env$sequence_apply("flexseq", "append", flex, inputs)),
    helper_env$sequence_apply("base R list", "append", base, inputs)
  )

  # prepend
  testthat::expect_identical(
    as.list(helper_env$sequence_apply("flexseq", "prepend", flex, inputs)),
    helper_env$sequence_apply("base R list", "prepend", base, inputs)
  )

  # replace middle
  testthat::expect_identical(
    as.list(helper_env$sequence_apply("flexseq", "replace middle", flex, inputs)),
    helper_env$sequence_apply("base R list", "replace middle", base, inputs)
  )

  # get middle
  testthat::expect_identical(
    helper_env$sequence_apply("flexseq", "get middle", flex, inputs),
    helper_env$sequence_apply("base R list", "get middle", base, inputs)
  )

  # remove middle
  testthat::expect_identical(
    as.list(helper_env$sequence_apply("flexseq", "remove middle", flex, inputs)),
    helper_env$sequence_apply("base R list", "remove middle", base, inputs)
  )

  # concatenate
  flex2 <- helper_env$make_sequence_fixture("flexseq", values)
  base2 <- helper_env$make_sequence_fixture("base R list", values)
  testthat::expect_identical(
    as.list(helper_env$sequence_apply("flexseq", "concatenate", flex, inputs, flex2)),
    helper_env$sequence_apply("base R list", "concatenate", base, inputs, base2)
  )

  # split at middle (3-way: left, value, right)
  flex_split <- helper_env$sequence_apply("flexseq", "split at middle", flex, inputs)
  base_split <- helper_env$sequence_apply("base R list", "split at middle", base, inputs)
  testthat::expect_identical(as.list(flex_split$left), base_split$left)
  testthat::expect_identical(flex_split$value, base_split$value)
  testthat::expect_identical(as.list(flex_split$right), base_split$right)
})

# --- Queue benchmarks -----------------------------------------------------

testthat::test_that("queue wrappers preserve FIFO behavior across implementations", {
  testthat::skip_if_not_installed("rstackdeque")

  implementations <- c("flexseq", "rstackdeque", "base R list")

  for(impl in implementations) {
    fixture <- helper_env$make_queue_fixture(impl, 3L)

    enqueued <- helper_env$queue_apply(impl, "enqueue", fixture, "d")
    testthat::expect_identical(
      as.list(enqueued),
      as.list(c("queue_item", "queue_item", "queue_item", "d"))
    )

    dequeued <- helper_env$queue_apply(impl, "dequeue", fixture, "d")
    testthat::expect_identical(
      as.list(dequeued),
      as.list(c("queue_item", "queue_item"))
    )
  }
})

# --- Priority queue benchmarks --------------------------------------------

testthat::test_that("pq fixture builder produces correct structures", {
  inputs <- helper_env$pq_benchmark_inputs(10L)

  pq <- helper_env$make_pq_fixture("priority_queue", 10L, inputs)
  testthat::expect_s3_class(pq, "priority_queue")
  testthat::expect_equal(length(pq), 10L)

  base <- helper_env$make_pq_fixture("base R", 10L, inputs)
  testthat::expect_true(is.list(base))
  testthat::expect_equal(length(base$values), 10L)
  testthat::expect_equal(length(base$priorities), 10L)
})

testthat::test_that("pq wrappers give equivalent min/max results", {
  inputs <- helper_env$pq_benchmark_inputs(20L)

  pq <- helper_env$make_pq_fixture("priority_queue", 20L, inputs)
  base <- helper_env$make_pq_fixture("base R", 20L, inputs)

  # peek min should return the same value
  pq_min <- helper_env$pq_apply("priority_queue", "peek min", pq, inputs)
  base_min <- helper_env$pq_apply("base R", "peek min", base, inputs)
  testthat::expect_identical(pq_min, base_min)

  # peek max should return the same value
  pq_max <- helper_env$pq_apply("priority_queue", "peek max", pq, inputs)
  base_max <- helper_env$pq_apply("base R", "peek max", base, inputs)
  testthat::expect_identical(pq_max, base_max)

  # pop min should reduce length by 1
  pq_popped <- helper_env$pq_apply("priority_queue", "pop min", pq, inputs)
  testthat::expect_equal(length(pq_popped), 19L)

  base_popped <- helper_env$pq_apply("base R", "pop min", base, inputs)
  testthat::expect_equal(length(base_popped$values), 19L)
})

testthat::test_that("pq benchmark cell returns expected columns", {
  testthat::skip_if_not_installed("microbenchmark")

  inputs <- helper_env$pq_benchmark_inputs(10L)
  out <- helper_env$run_pq_benchmark_cell("priority_queue", "insert", 10L, inputs, repeats = 2L)

  testthat::expect_identical(
    names(out),
    c("family", "implementation", "operation", "n", "repeat", "time_us")
  )
  testthat::expect_identical(unique(out$family), "priority_queue")
})

# --- Interval index benchmarks --------------------------------------------

testthat::test_that("ivx fixture builder produces correct structures", {
  inputs <- helper_env$ivx_benchmark_inputs(20L)

  ix <- helper_env$make_ivx_fixture("interval_index", 20L, inputs)
  testthat::expect_s3_class(ix, "interval_index")
  testthat::expect_equal(length(ix), 20L)

  df <- helper_env$make_ivx_fixture("base R", 20L, inputs)
  testthat::expect_s3_class(df, "data.frame")
  testthat::expect_equal(nrow(df), 20L)
  testthat::expect_true(all(c("start", "end", "value") %in% names(df)))
})

testthat::test_that("ivx point query returns comparable results", {
  inputs <- helper_env$ivx_benchmark_inputs(100L)

  ix <- helper_env$make_ivx_fixture("interval_index", 100L, inputs)
  df <- helper_env$make_ivx_fixture("base R", 100L, inputs)

  ix_hit <- helper_env$ivx_apply("interval_index", "point query", ix, inputs)
  df_hit <- helper_env$ivx_apply("base R", "point query", df, inputs)

  # Both should find a match or both should be NULL.
  if(is.null(ix_hit)) {
    testthat::expect_null(df_hit)
  } else {
    testthat::expect_identical(ix_hit, df_hit)
  }
})

testthat::test_that("ivx benchmark cell returns expected columns", {
  testthat::skip_if_not_installed("microbenchmark")

  inputs <- helper_env$ivx_benchmark_inputs(20L)
  out <- helper_env$run_ivx_benchmark_cell("interval_index", "insert", 20L, inputs, repeats = 2L)

  testthat::expect_identical(
    names(out),
    c("family", "implementation", "operation", "n", "repeat", "time_us")
  )
  testthat::expect_identical(unique(out$family), "interval")
})
