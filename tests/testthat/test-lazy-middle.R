#SO

# Deque operations suspend the recursive part of a push/pop in the middle tree
# (see "Suspended middle trees" in src/ft_cpp.cpp) so amortized O(1) bounds
# hold under persistence. Work is counted via .ft_work_counts() rather than
# timed, so these checks are deterministic. The counters live in the C++
# backend.

.work_during <- function(expr) {
  before <- .ft_work_counts()
  force(expr)
  .ft_work_counts() - before
}

testthat::test_that("reusing the most expensive version costs O(1) amortized per operation", {
  testthat::skip_if_not(.ft_cpp_enabled())

  ops <- list(
    push_front = list(op = function(t, i) push_front(t, i), start = function() flexseq()),
    push_back = list(op = function(t, i) push_back(t, i), start = function() flexseq()),
    pop_front = list(op = function(t, i) pop_front(t)$remaining, start = function() as_flexseq(1:4000)),
    pop_back = list(op = function(t, i) pop_back(t)$remaining, start = function() as_flexseq(1:4000))
  )
  for(nm in names(ops)) {
    op <- ops[[nm]]$op
    versions <- vector("list", 3000L)
    t <- ops[[nm]]$start()
    for(i in seq_along(versions)) {
      t <- op(t, i)
      versions[[i]] <- t
    }

    # the version whose next operation (on a fresh branch) builds the most
    # levels; without suspensions every reuse of it would cost the same
    first_cost <- vapply(versions, function(v) .work_during(op(v, 0L))[["deeps"]], numeric(1))
    worst <- versions[[which.max(first_cost)]]
    reuse_cost <- .work_during(for(i in 1:100) op(worst, i))[["deeps"]] / 100

    testthat::expect_lte(reuse_cost, 3, label = paste(nm, "mean reuse cost"))
  }
})

testthat::test_that("a random persistent deque workload matches a vector model", {
  set.seed(20260924)
  versions <- list(flexseq())
  models <- list(integer(0))
  next_val <- 1L
  n_ops <- 600L

  forced <- .work_during(for(step in seq_len(n_ops)) {
    k <- sample.int(length(versions), 1L)
    t <- versions[[k]]
    m <- models[[k]]
    op <- if(length(m) == 0L) sample(1:2, 1L) else sample.int(4L, 1L)
    if(op == 1L) {
      t <- push_front(t, next_val); m <- c(next_val, m); next_val <- next_val + 1L
    } else if(op == 2L) {
      t <- push_back(t, next_val); m <- c(m, next_val); next_val <- next_val + 1L
    } else if(op == 3L) {
      p <- pop_front(t)
      testthat::expect_identical(p$value, m[[1L]])
      t <- p$remaining; m <- m[-1L]
    } else {
      p <- pop_back(t)
      testthat::expect_identical(p$value, m[[length(m)]])
      t <- p$remaining; m <- m[-length(m)]
    }
    versions[[length(versions) + 1L]] <- t
    models[[length(models) + 1L]] <- m
  })

  for(k in seq_along(versions)) {
    testthat::expect_identical(as.integer(unlist(as.list(versions[[k]]))), models[[k]])
  }
  testthat::expect_lte(forced[["forces"]], n_ops)
})

testthat::test_that("suspended middles survive split, concat and indexing", {
  t <- flexseq()
  for(i in 1:500) t <- push_front(t, i)
  for(i in 1:200) t <- pop_back(t)$remaining
  expected <- 500:201

  s <- split_at(t, 137L)
  testthat::expect_identical(as.integer(unlist(as.list(s$left))), expected[1:136])
  testthat::expect_identical(s$value, expected[[137]])
  testthat::expect_identical(as.integer(unlist(as.list(s$right))), expected[138:300])
  testthat::expect_identical(as.integer(unlist(as.list(c(s$right, s$left)))),
                             c(expected[138:300], expected[1:136]))
  testthat::expect_identical(t[[250]], expected[[250]])
  testthat::expect_identical(length(t), 300L)
})

testthat::test_that("iteration walks trees holding suspended middles", {
  t <- flexseq()
  for(i in 1:500) t <- push_front(t, i)
  seen <- integer(0)
  coro::loop(for(v in t) seen <- c(seen, v))
  testthat::expect_identical(seen, 500:1)
})

testthat::test_that("plot_structure handles trees holding suspended middles", {
  testthat::skip_if_not_installed("igraph")
  t <- flexseq()
  for(i in 1:300) t <- push_front(t, i)
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  testthat::expect_no_error(plot_structure(t))
})
