# Smoke tests for `plot_structure()`. These verify the plotting code
# executes end-to-end without error across empty / single / small / larger
# inputs and across each finger-tree-backed structure type — they do NOT
# verify the rendered output.

.plot_to_null <- function(expr) {
  grDevices::pdf(tempfile(fileext = ".pdf"))
  on.exit(grDevices::dev.off(), add = TRUE)
  force(expr)
  invisible(NULL)
}

testthat::test_that("plot_structure runs without error on flexseq (empty / single / small / larger / named)", {
  testthat::skip_if_not_installed("igraph")
  testthat::expect_silent(.plot_to_null(plot_structure(flexseq())))
  testthat::expect_silent(.plot_to_null(plot_structure(as_flexseq(1))))
  testthat::expect_silent(.plot_to_null(plot_structure(as_flexseq(1:5))))
  # Larger input to force Deep/Digit/Node branches in graph construction.
  testthat::expect_silent(.plot_to_null(plot_structure(as_flexseq(1:20))))
  # Named input.
  testthat::expect_silent(
    .plot_to_null(plot_structure(as_flexseq(setNames(as.list(1:5), letters[1:5]))))
  )
})

testthat::test_that("plot_structure runs without error on priority_queue", {
  testthat::skip_if_not_installed("igraph")
  testthat::expect_silent(.plot_to_null(plot_structure(priority_queue())))
  testthat::expect_silent(
    .plot_to_null(plot_structure(priority_queue(1, 2, 3, priorities = c(2, 1, 3))))
  )
  big <- do.call(priority_queue,
                 c(as.list(letters[1:15]),
                   list(priorities = seq(15, 1))))
  testthat::expect_silent(.plot_to_null(plot_structure(big)))
})

testthat::test_that("plot_structure runs without error on ordered_sequence", {
  testthat::skip_if_not_installed("igraph")
  testthat::expect_silent(.plot_to_null(plot_structure(ordered_sequence())))
  testthat::expect_silent(
    .plot_to_null(plot_structure(ordered_sequence("a", "b", "c", keys = c(2, 1, 3))))
  )
  testthat::expect_silent(
    .plot_to_null(plot_structure(as_ordered_sequence(letters[1:15], keys = 15:1)))
  )
})

testthat::test_that("plot_structure runs without error on interval_index", {
  testthat::skip_if_not_installed("igraph")
  testthat::expect_silent(.plot_to_null(plot_structure(interval_index())))
  testthat::expect_silent(
    .plot_to_null(plot_structure(interval_index(1, 2, 3, start = c(2, 4, 6), end = c(3, 5, 8))))
  )
  big <- do.call(interval_index,
                 c(as.list(letters[1:15]),
                   list(start = 1:15, end = 2:16)))
  testthat::expect_silent(.plot_to_null(plot_structure(big)))
})

testthat::test_that("plot_structure honors node_label variants and legend = FALSE", {
  testthat::skip_if_not_installed("igraph")
  x <- as_flexseq(1:8)
  testthat::expect_silent(.plot_to_null(plot_structure(x, node_label = "value")))
  testthat::expect_silent(.plot_to_null(plot_structure(x, node_label = "type")))
  testthat::expect_silent(.plot_to_null(plot_structure(x, node_label = "both")))
  testthat::expect_silent(.plot_to_null(plot_structure(x, node_label = "none")))
  testthat::expect_silent(
    .plot_to_null(plot_structure(x, node_label = function(node) node$type))
  )
  testthat::expect_silent(.plot_to_null(plot_structure(x, legend = FALSE)))
  testthat::expect_silent(.plot_to_null(plot_structure(x, title = "A tree", label_edges = TRUE)))
})
