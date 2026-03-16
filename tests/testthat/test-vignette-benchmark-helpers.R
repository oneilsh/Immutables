helper_env <- new.env(parent = globalenv())
sys.source(
  testthat::test_path("..", "..", "vignettes", "helpers", "flexseq_benchmark_helpers.R"),
  envir = helper_env
)

testthat::test_that("sequence benchmark cell returns expected columns", {
  testthat::skip_if_not_installed("microbenchmark")

  inputs <- helper_env$flexseq_benchmark_inputs(10L)
  out <- helper_env$run_flexseq_sequence_benchmark_cell(
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

  flex_fixture <- helper_env$flexseq_benchmark_make_sequence_fixture("flexseq", values)
  base_fixture <- helper_env$flexseq_benchmark_make_sequence_fixture("base R list", values)

  flex_append <- helper_env$flexseq_benchmark_sequence_apply(
    "flexseq",
    "append",
    flex_fixture,
    append_value = "z",
    replace_value = "y"
  )
  base_append <- helper_env$flexseq_benchmark_sequence_apply(
    "base R list",
    "append",
    base_fixture,
    append_value = "z",
    replace_value = "y"
  )
  testthat::expect_identical(as.list(flex_append), base_append)

  flex_replace <- helper_env$flexseq_benchmark_sequence_apply(
    "flexseq",
    "replace middle",
    flex_fixture,
    append_value = "z",
    replace_value = "y"
  )
  base_replace <- helper_env$flexseq_benchmark_sequence_apply(
    "base R list",
    "replace middle",
    base_fixture,
    append_value = "z",
    replace_value = "y"
  )
  testthat::expect_identical(as.list(flex_replace), base_replace)

  testthat::expect_identical(
    helper_env$flexseq_benchmark_sequence_apply(
      "flexseq",
      "get middle",
      flex_fixture,
      append_value = "z",
      replace_value = "y"
    ),
    helper_env$flexseq_benchmark_sequence_apply(
      "base R list",
      "get middle",
      base_fixture,
      append_value = "z",
      replace_value = "y"
    )
  )

  flex_remove <- helper_env$flexseq_benchmark_sequence_apply(
    "flexseq",
    "remove middle",
    flex_fixture,
    append_value = "z",
    replace_value = "y"
  )
  base_remove <- helper_env$flexseq_benchmark_sequence_apply(
    "base R list",
    "remove middle",
    base_fixture,
    append_value = "z",
    replace_value = "y"
  )
  testthat::expect_identical(as.list(flex_remove), base_remove)
})

testthat::test_that("queue wrappers preserve FIFO behavior across implementations", {
  testthat::skip_if_not_installed("rstackdeque")

  values <- c("a", "b", "c")
  append_value <- "d"
  implementations <- c("flexseq", "rstackdeque", "base R list")

  for(implementation in implementations) {
    fixture <- helper_env$flexseq_benchmark_make_queue_fixture(implementation, values)

    enqueued <- helper_env$flexseq_benchmark_queue_apply(
      implementation,
      "enqueue",
      fixture,
      append_value = append_value
    )
    testthat::expect_identical(as.list(enqueued), as.list(c(values, append_value)))

    dequeued <- helper_env$flexseq_benchmark_queue_apply(
      implementation,
      "dequeue",
      fixture,
      append_value = append_value
    )
    testthat::expect_identical(as.list(dequeued), as.list(values[-1L]))
  }
})
