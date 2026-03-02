.gc_stress_enabled <- function() {
  gc_stress <- tolower(Sys.getenv("IMMUTABLES_GC_STRESS", unset = "0"))
  gc_stress %in% c("1", "true", "yes", "on")
}

.skip_if_no_gc_stress <- function() {
  if(!isTRUE(.gc_cpp_run$enabled)) {
    testthat::skip("Set IMMUTABLES_GC_STRESS=1 to run GC torture regression.")
  }
}

.run_gc_stress_suite <- function() {
  if(!.gc_stress_enabled()) {
    return(list(enabled = FALSE, setup_error = NULL, results = list()))
  }

  results <- list()
  setup_error <- NULL

  tryCatch({
    old_cpp <- getOption("immutables.use_cpp")
    options(immutables.use_cpp = FALSE)
    on.exit({
      if(is.null(old_cpp)) {
        options(immutables.use_cpp = NULL)
      } else {
        options(immutables.use_cpp = old_cpp)
      }
    }, add = TRUE)

    base_plain <- as_flexseq(as.list(1:8))
    ms <- attr(base_plain, "monoids", exact = TRUE)
    base_names <- paste0("k", seq_len(8))

    x_oms <- as_ordered_sequence(list("aa", "bb", "c", "ddd"), keys = c(2, 2, 1, 3))
    ms_oms <- attr(x_oms, "monoids", exact = TRUE)
    key_type_oms <- attr(x_oms, "oms_key_type", exact = TRUE)
    x_ivx <- as_interval_index(list("a", "b", "c"), start = c(1, 2, 2), end = c(3, 2, 4), bounds = "[]")
    q_num <- priority_queue("a", "b", "c", priorities = c(2, 1, 3))
    q_date <- priority_queue(
      "d1", "d2", "d3",
      priorities = as.Date(c("2020-01-03", "2020-01-01", "2020-01-02"))
    )
    x_ord_num <- as_ordered_sequence(list("aa", "bb", "cc"), keys = c(2, 1, 2))
    x_ord_date <- as_ordered_sequence(
      list("aa", "bb", "cc"),
      keys = as.Date(c("2020-01-02", "2020-01-01", "2020-01-02"))
    )

    options(immutables.use_cpp = TRUE)

    old_torture <- gctorture2(1, inhibit_release = FALSE)
    on.exit(gctorture2(old_torture, inhibit_release = FALSE), add = TRUE)

    step <- function(label, expr) {
      results[[label]] <<- tryCatch(
        {
          force(expr)
          NULL
        },
        error = function(e) conditionMessage(e)
      )
      invisible(NULL)
    }

    t <- NULL
    step("ft_cpp_tree_from", t <- .ft_cpp_tree_from(as.list(1:8), ms))
    step("ft_cpp_tree_from_prepared", .ft_cpp_tree_from_prepared(as.list(1:8), base_names, ms))
    step("ft_cpp_tree_from_sorted", .ft_cpp_tree_from_sorted(as.list(1:8), ms))

    if(is.null(results[["ft_cpp_tree_from"]])) {
      step("ft_cpp_add_right", t <- .ft_cpp_add_right(t, 9, ms))
      step("ft_cpp_add_left", t <- .ft_cpp_add_left(t, 0, ms))
    } else {
      results[["ft_cpp_add_right"]] <- "skipped because ft_cpp_tree_from failed"
      results[["ft_cpp_add_left"]] <- "skipped because ft_cpp_tree_from failed"
    }

    step("ft_cpp_concat", .ft_cpp_concat(base_plain, base_plain, ms))
    step("ft_cpp_locate", .ft_cpp_locate(base_plain, function(v) v >= 4, ms, ".size", 0))
    step("ft_cpp_split_tree", .ft_cpp_split_tree(base_plain, function(v) v >= 4, ms, ".size", 0))

    step("ft_cpp_oms_insert", .ft_cpp_oms_insert(x_oms, list(item = "new", key = 2), ms_oms, key_type_oms))

    step("insert", insert(x_oms, "newer", key = 2))
    step("insert_interval_index", insert(x_ivx, "newer", start = 2, end = 5))
    step("peek_point_interval_index", peek_all_point(x_ivx, 2))
    step("pop_point_interval_index", pop_all_point(x_ivx, 2))
    step("peek_overlaps_interval_index", peek_all_overlaps(x_ivx, 2, 3))
    step("peek_containing_interval_index", peek_all_containing(x_ivx, 2, 3))
    step("peek_within_interval_index", peek_all_within(x_ivx, 2, 3))

    step("pq_numeric_peek_min_max", {
      invisible(peek_min(q_num))
      invisible(peek_max(q_num))
    })
    step("pq_numeric_pop_min_insert", {
      p1 <- pop_min(q_num)
      q2 <- insert(p1$remaining, "x", priority = 1)
      invisible(peek_min(q2))
      invisible(peek_max(q2))
    })
    step("pq_date_peek_pop_insert", {
      invisible(peek_min(q_date))
      invisible(peek_max(q_date))
      p1 <- pop_min(q_date)
      q2 <- insert(p1$remaining, "d4", priority = as.Date("2020-01-05"))
      invisible(peek_min(q2))
      invisible(peek_max(q2))
    })
    step("ordered_bounds_numeric", {
      invisible(lower_bound(x_ord_num, 2))
      invisible(upper_bound(x_ord_num, 2))
    })
    step("ordered_bounds_date", {
      k <- as.Date("2020-01-02")
      invisible(lower_bound(x_ord_date, k))
      invisible(upper_bound(x_ord_date, k))
    })
  }, error = function(e) {
    setup_error <<- conditionMessage(e)
  })

  list(enabled = TRUE, setup_error = setup_error, results = results)
}

.gc_cpp_run <- .run_gc_stress_suite()

.expect_step_ok <- function(label) {
  .skip_if_no_gc_stress()

  if(!is.null(.gc_cpp_run$setup_error)) {
    testthat::fail(sprintf("GC stress suite setup failed: %s", .gc_cpp_run$setup_error))
  }

  err <- .gc_cpp_run$results[[label]]
  if(is.null(err)) {
    testthat::succeed()
  } else {
    testthat::fail(sprintf("%s failed: %s", label, err))
  }
}

testthat::test_that("C++ tree builders survive GC torture", {
  .expect_step_ok("ft_cpp_tree_from")
  .expect_step_ok("ft_cpp_tree_from_prepared")
  .expect_step_ok("ft_cpp_tree_from_sorted")
})

testthat::test_that("C++ core tree ops survive GC torture", {
  .expect_step_ok("ft_cpp_add_right")
  .expect_step_ok("ft_cpp_add_left")
  .expect_step_ok("ft_cpp_concat")
  .expect_step_ok("ft_cpp_locate")
  .expect_step_ok("ft_cpp_split_tree")
})

testthat::test_that("C++ OMS primitives survive GC torture", {
  .expect_step_ok("ft_cpp_oms_insert")
})

testthat::test_that("OMS public APIs survive GC torture", {
  .expect_step_ok("insert")
})

testthat::test_that("interval_index public APIs survive GC torture", {
  .expect_step_ok("insert_interval_index")
  .expect_step_ok("peek_point_interval_index")
  .expect_step_ok("pop_point_interval_index")
  .expect_step_ok("peek_overlaps_interval_index")
  .expect_step_ok("peek_containing_interval_index")
  .expect_step_ok("peek_within_interval_index")
})

testthat::test_that("priority_queue public APIs survive GC torture", {
  .expect_step_ok("pq_numeric_peek_min_max")
  .expect_step_ok("pq_numeric_pop_min_insert")
  .expect_step_ok("pq_date_peek_pop_insert")
})

testthat::test_that("ordered bounds survive GC torture", {
  .expect_step_ok("ordered_bounds_numeric")
  .expect_step_ok("ordered_bounds_date")
})
