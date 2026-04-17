testthat::test_that("coro::loop yields flexseq elements in order", {
  s <- as_flexseq(letters[1:5])
  out <- character(0)
  coro::loop(for (x in s) out <- c(out, x))

  testthat::expect_identical(out, letters[1:5])
})

testthat::test_that("coro::loop over empty flexseq iterates zero times", {
  n <- 0L
  coro::loop(for (x in flexseq()) n <- n + 1L)

  testthat::expect_identical(n, 0L)
})

testthat::test_that("coro::loop strips ft_name from yielded elements of named flexseq", {
  s <- as_flexseq(setNames(as.list(1:3), c("a", "b", "c")))
  collected <- list()
  coro::loop(for (x in s) collected <- c(collected, list(x)))

  testthat::expect_length(collected, 3L)
  testthat::expect_identical(unlist(collected), 1:3)
  for(el in collected) {
    testthat::expect_null(attr(el, "ft_name", exact = TRUE))
  }
})

testthat::test_that("iteration does not mutate the source flexseq", {
  s <- as_flexseq(letters[1:5])
  before <- as.list(s)
  coro::loop(for (x in s) invisible(NULL))

  testthat::expect_identical(as.list(s), before)
  testthat::expect_identical(length(s), 5L)
})

testthat::test_that("as_iterator.flexseq is exhausted after one full pass", {
  s <- as_flexseq(1:3)
  it <- coro::as_iterator(s)

  testthat::expect_identical(it(), 1L)
  testthat::expect_identical(it(), 2L)
  testthat::expect_identical(it(), 3L)
  testthat::expect_true(coro::is_exhausted(it()))
  testthat::expect_true(coro::is_exhausted(it()))
})

testthat::test_that("iterator streams across deeper tree structure", {
  vals <- as.list(seq_len(200L))
  s <- as_flexseq(vals)
  out <- integer(0)
  coro::loop(for (x in s) out <- c(out, x))

  testthat::expect_identical(out, seq_len(200L))
})

testthat::test_that("as_iterator.flexseq dispatches via class", {
  s <- as_flexseq(letters[1:3])
  it <- coro::as_iterator(s)

  testthat::expect_type(it, "closure")
  testthat::expect_identical(it(), "a")
})

testthat::test_that("loop() is re-exported from coro and works without coro:: prefix", {
  testthat::expect_identical(loop, coro::loop)

  s <- as_flexseq(1:4)
  out <- integer(0)
  loop(for (x in s) out <- c(out, x))

  testthat::expect_identical(out, 1:4)
})

# ---- ordered_sequence iteration ---------------------------------------------

testthat::test_that("loop over ordered_sequence yields values in key-ascending order", {
  os <- as_ordered_sequence(list("two", "one", "three"), keys = c(2, 1, 3))
  out <- character(0)
  loop(for (v in os) out <- c(out, v))

  testthat::expect_identical(out, c("one", "two", "three"))
})

testthat::test_that("loop over ordered_sequence matches as.list()", {
  os <- as_ordered_sequence(list(10, 20, 30, 40), keys = c(4, 1, 3, 2))
  out <- list()
  loop(for (v in os) out <- c(out, list(v)))

  testthat::expect_identical(out, as.list(os))
})

testthat::test_that("loop over empty ordered_sequence iterates zero times", {
  n <- 0L
  loop(for (v in ordered_sequence()) n <- n + 1L)

  testthat::expect_identical(n, 0L)
})

testthat::test_that("iteration does not mutate the source ordered_sequence", {
  os <- as_ordered_sequence(list("a", "b", "c"), keys = c(1, 2, 3))
  before <- as.list(os)
  loop(for (v in os) invisible(NULL))

  testthat::expect_identical(as.list(os), before)
  testthat::expect_identical(length(os), 3L)
})

testthat::test_that("loop over ordered_sequence yields bare values (no entry wrapper)", {
  os <- as_ordered_sequence(list("x", "y"), keys = c(1, 2))
  collected <- list()
  loop(for (v in os) collected <- c(collected, list(v)))

  # values should be bare strings, not list(value=..., key=...)
  testthat::expect_identical(collected[[1]], "x")
  testthat::expect_identical(collected[[2]], "y")
})

# ---- interval_index iteration -----------------------------------------------

testthat::test_that("loop over interval_index yields values in interval tree order", {
  ix <- as_interval_index(list("B", "A", "C"), start = c(1, 0, 5), end = c(3, 2, 8))
  out <- character(0)
  loop(for (v in ix) out <- c(out, v))

  testthat::expect_identical(out, c("A", "B", "C"))
})

testthat::test_that("loop over interval_index matches as.list()", {
  ix <- as_interval_index(
    list("p", "q", "r", "s"),
    start = c(10, 1, 5, 3),
    end   = c(20, 4, 8, 7)
  )
  out <- list()
  loop(for (v in ix) out <- c(out, list(v)))

  testthat::expect_identical(out, as.list(ix))
})

testthat::test_that("loop over empty interval_index iterates zero times", {
  n <- 0L
  loop(for (v in interval_index()) n <- n + 1L)

  testthat::expect_identical(n, 0L)
})

testthat::test_that("iteration does not mutate the source interval_index", {
  ix <- as_interval_index(list("a", "b"), start = c(1, 3), end = c(2, 5))
  before <- as.list(ix)
  loop(for (v in ix) invisible(NULL))

  testthat::expect_identical(as.list(ix), before)
  testthat::expect_identical(length(ix), 2L)
})

testthat::test_that("loop over interval_index yields bare values (no entry wrapper)", {
  ix <- as_interval_index(list("x", "y"), start = c(0, 1), end = c(2, 3))
  collected <- list()
  loop(for (v in ix) collected <- c(collected, list(v)))

  testthat::expect_identical(collected[[1]], "x")
  testthat::expect_identical(collected[[2]], "y")
})

# ---- priority_queue iteration -----------------------------------------------

testthat::test_that("loop over priority_queue yields values in priority-ascending order", {
  pq <- priority_queue("a", "b", "c", priorities = c(3, 1, 2))
  out <- character(0)
  loop(for (v in pq) out <- c(out, v))

  testthat::expect_identical(out, c("b", "c", "a"))
})

testthat::test_that("loop over priority_queue yields FIFO within equal priorities", {
  pq <- priority_queue("a", "b", "c", "d", priorities = c(2, 1, 1, 2))
  out <- character(0)
  loop(for (v in pq) out <- c(out, v))

  # priorities: a=2, b=1, c=1, d=2. ascending = 1,1,2,2.
  # FIFO within ties: b before c (both pri 1); a before d (both pri 2).
  testthat::expect_identical(out, c("b", "c", "a", "d"))
})

testthat::test_that("loop over empty priority_queue iterates zero times", {
  n <- 0L
  loop(for (v in priority_queue()) n <- n + 1L)

  testthat::expect_identical(n, 0L)
})

testthat::test_that("iteration does not mutate the source priority_queue", {
  pq <- priority_queue("a", "b", "c", priorities = c(3, 1, 2))
  before_min <- peek_min(pq)
  loop(for (v in pq) invisible(NULL))

  testthat::expect_identical(length(pq), 3L)
  testthat::expect_identical(peek_min(pq), before_min)
})

testthat::test_that("partial priority_queue iteration leaves source untouched", {
  pq <- priority_queue("a", "b", "c", "d", priorities = c(4, 1, 3, 2))
  seen <- character(0)
  loop(for (v in pq) {
    seen <- c(seen, v)
    if(length(seen) == 2L) break
  })

  testthat::expect_identical(seen, c("b", "d"))
  testthat::expect_identical(length(pq), 4L)
})

testthat::test_that("as_iterator.priority_queue is exhausted after one full pass", {
  pq <- priority_queue("x", "y", priorities = c(2, 1))
  it <- coro::as_iterator(pq)

  testthat::expect_identical(it(), "y")
  testthat::expect_identical(it(), "x")
  testthat::expect_true(coro::is_exhausted(it()))
  testthat::expect_true(coro::is_exhausted(it()))
})
