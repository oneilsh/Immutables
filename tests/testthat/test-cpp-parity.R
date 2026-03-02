with_cpp_mode <- function(flag, expr) {
  old <- getOption("immutables.use_cpp")
  options(immutables.use_cpp = flag)
  on.exit({
    if(is.null(old)) {
      options(immutables.use_cpp = NULL)
    } else {
      options(immutables.use_cpp = old)
    }
  }, add = TRUE)
  force(expr)
}

backend_eval <- function(expr, flag, env = parent.frame()) {
  with_cpp_mode(flag, eval(expr, env))
}

expect_backend_identical <- function(expr, transform = identity, env = parent.frame()) {
  q <- substitute(expr)
  cpp <- transform(backend_eval(q, TRUE, env = env))
  r <- transform(backend_eval(q, FALSE, env = env))
  if(!identical(cpp, r)) {
    diff <- capture.output(all.equal(cpp, r))
    stop(
      paste0(
        "Backend parity mismatch for expression:\n",
        deparse(q),
        "\nDiff:\n",
        paste(diff, collapse = "\n")
      )
    )
  }
  testthat::succeed()
}

expect_wrapper_dispatch <- function(wrapper_name, expr, should_dispatch = TRUE, env = parent.frame()) {
  ns <- asNamespace("immutables")
  flag <- new.env(parent = emptyenv())
  flag$called <- FALSE
  suppressMessages(base::trace(
    what = wrapper_name,
    tracer = bquote(assign("called", TRUE, envir = .(flag))),
    where = ns,
    print = FALSE
  ))
  on.exit(suppressMessages(base::untrace(what = wrapper_name, where = ns)), add = TRUE)
  eval(substitute(expr), envir = env)
  if(should_dispatch) {
    testthat::expect_true(isTRUE(flag$called), info = paste("Expected wrapper dispatch:", wrapper_name))
  } else {
    testthat::expect_false(isTRUE(flag$called), info = paste("Expected no wrapper dispatch:", wrapper_name))
  }
}

snapshot_tree <- function(t) {
  els <- immutables:::.ft_to_list(t)
  vals <- lapply(els, immutables:::.ft_strip_name)
  nms <- vapply(els, function(el) {
    nm <- immutables:::.ft_get_name(el)
    if(is.null(nm)) "" else nm
  }, character(1))
  list(
    class = class(t),
    values = vals,
    names = nms,
    measures = attr(t, "measures", exact = TRUE),
    monoid_names = names(attr(t, "monoids", exact = TRUE))
  )
}

snapshot_split <- function(s) {
  list(
    left = snapshot_tree(s$left),
    elem = immutables:::.ft_strip_name(s$elem),
    right = snapshot_tree(s$right)
  )
}

snapshot_locate <- function(x) {
  list(
    found = x$found,
    elem = if(isTRUE(x$found)) immutables:::.ft_strip_name(x$elem) else NULL,
    index = x$index,
    left_measure = x$left_measure,
    hit_measure = x$hit_measure,
    right_measure = x$right_measure
  )
}

parity_scenarios <- c(
  "MeasureMonoid constructor/use",
  "predicate constructor/use",
  "empty_tree",
  "tree_from",
  "tree_from unnamed",
  "add_monoids",
  "append",
  "append named",
  "prepend",
  "prepend named",
  "concat_trees",
  "split_around_by_predicate",
  "split_by_predicate",
  "locate_by_predicate",
  "peek/pop_at helpers",
  "insert_at helper",
  "[ read (integer/logical/name)",
  "[[ read (integer/name)",
  "[<- replacement (integer/logical/name)",
  "[[<- replacement and deletion",
  "$ read",
  "$<- replacement",
  "ordered_sequence insert",
  "interval_index insert and queries",
  "print.FingerTree output",
  "get_graph_df",
  "validate_tree",
  "validate_name_state"
)

cpp_wrapper_coverage <- list(
  .ft_cpp_add_right = c("append"),
  .ft_cpp_add_right_named = c("append named"),
  .ft_cpp_add_left = c("prepend"),
  .ft_cpp_add_left_named = c("prepend named"),
  .ft_cpp_tree_from = c("tree_from unnamed"),
  .ft_cpp_tree_from_prepared = c("tree_from"),
  .ft_cpp_tree_from_sorted = c("ordered_sequence insert"),
  .ft_cpp_concat = c("concat_trees", "interval_index insert and queries"),
  .ft_cpp_oms_insert = c("ordered_sequence insert"),
  .ft_cpp_locate = c("locate_by_predicate"),
  .ft_cpp_split_tree = c("split_around_by_predicate", "split_by_predicate", "interval_index insert and queries"),
  .ft_cpp_find_name_position = c("$ read", "[ read (integer/logical/name)"),
  .ft_cpp_get_by_index = c("[[ read (integer/name)"),
  .ft_cpp_get_many_by_index = c("[ read (integer/logical/name)"),
  .ft_cpp_name_positions = c("[ read (integer/logical/name)")
)

testthat::test_that("backend parity: coverage map includes all cpp wrappers", {
  ns <- asNamespace("immutables")
  wrappers <- ls(ns, all.names = TRUE)
  wrappers <- wrappers[startsWith(wrappers, ".ft_cpp_")]
  wrappers <- setdiff(
    wrappers,
    c(".ft_cpp_enabled", ".ft_cpp_eligible_monoids", ".ft_cpp_can_use", ".ft_cpp_can_use_oms_insert")
  )

  testthat::expect_setequal(names(cpp_wrapper_coverage), wrappers)

  for(op in names(cpp_wrapper_coverage)) {
    tags <- cpp_wrapper_coverage[[op]]
    for(tag in tags) {
      testthat::expect_true(tag %in% parity_scenarios, info = paste("Missing parity scenario tag:", tag))
    }
  }
})

testthat::test_that("backend parity: forced backend option gates C++ eligibility", {
  ms <- ensure_size_monoids(list(.size = size_measure_monoid()))
  testthat::expect_true(backend_eval(quote(.ft_cpp_can_use(ms)), TRUE))
  testthat::expect_false(backend_eval(quote(.ft_cpp_can_use(ms)), FALSE))
})

testthat::test_that("backend parity: append dispatch respects forced backend mode", {
  backend_eval(
    quote(expect_wrapper_dispatch(".ft_cpp_add_right", {
      t <- as_flexseq(1:6)
      push_back(t, 7)
    }, should_dispatch = TRUE)),
    TRUE
  )

  backend_eval(
    quote(expect_wrapper_dispatch(".ft_cpp_add_right", {
      t <- as_flexseq(1:6)
      push_back(t, 7)
    }, should_dispatch = FALSE)),
    FALSE
  )
})

testthat::test_that("backend parity: MeasureMonoid constructor/use", {
  expect_backend_identical({
    m <- measure_monoid(function(a, b) a + b, 0, as.numeric)
    t <- add_monoids(as_flexseq(1:5), list(sum = m))
    as.integer(node_measure(t, "sum"))
  })
})

testthat::test_that("backend parity: predicate constructor/use", {
  expect_backend_identical({
    p <- predicate(function(v) v >= 3)
    t <- as_flexseq(letters[1:6])
    loc <- locate_by_predicate(t, p, ".size", include_metadata = TRUE)
    snapshot_locate(loc)
  })
})

testthat::test_that("backend parity: empty_tree", {
  expect_backend_identical({
    snapshot_tree(flexseq())
  })
})

testthat::test_that("backend parity: tree_from", {
  expect_backend_identical({
    ms <- list(sum = measure_monoid(function(a, b) a + b, 0, as.numeric))
    snapshot_tree(add_monoids(as_flexseq(setNames(as.list(1:8), letters[1:8])), ms))
  })
})

testthat::test_that("backend parity: tree_from unnamed", {
  expect_backend_identical({
    ms <- list(sum = measure_monoid(function(a, b) a + b, 0, as.numeric))
    snapshot_tree(add_monoids(as_flexseq(as.list(1:8)), ms))
  })
})

testthat::test_that("backend parity: tree_from prepared names type check", {
  ms <- ensure_size_monoids(list(.size = size_measure_monoid()))
  testthat::expect_error(
    .ft_cpp_tree_from_prepared(as.list(1:2), list("a", "b"), ms),
    "character vector"
  )
})

testthat::test_that("backend parity: add_monoids", {
  expect_backend_identical({
    t <- as_flexseq(1:8)
    m <- measure_monoid(function(a, b) a + b, 0, as.numeric)
    snapshot_tree(add_monoids(t, list(sum = m)))
  })
})

testthat::test_that("backend parity: append", {
  expect_backend_identical({
    t <- as_flexseq(1:10)
    t <- push_back(t, 11)
    snapshot_tree(t)
  })
})

testthat::test_that("backend parity: append named", {
  expect_backend_identical({
    t <- as_flexseq(setNames(as.list(1:4), LETTERS[1:4]))
    t <- push_back(t, structure(5, names = "E"))
    snapshot_tree(t)
  })
})

testthat::test_that("backend parity: prepend", {
  expect_backend_identical({
    t <- as_flexseq(1:10)
    t <- push_front(t, 0)
    snapshot_tree(t)
  })
})

testthat::test_that("backend parity: prepend named", {
  expect_backend_identical({
    t <- as_flexseq(setNames(as.list(1:4), LETTERS[1:4]))
    t <- push_front(t, structure(0, names = "Z"))
    snapshot_tree(t)
  })
})

testthat::test_that("backend parity: concat_trees", {
  expect_backend_identical({
    t1 <- as_flexseq(1:10)
    t2 <- as_flexseq(11:20)
    snapshot_tree(c(t1, t2))
  })
})

testthat::test_that("backend parity: split_around_by_predicate", {
  expect_backend_identical({
    t <- as_flexseq(letters[1:20])
    snapshot_split(split_around_by_predicate(t, function(v) v >= 8, ".size"))
  })
})

testthat::test_that("backend parity: split_by_predicate", {
  expect_backend_identical({
    t <- as_flexseq(letters[1:20])
    s <- split_by_predicate(t, function(v) v >= 8, ".size")
    list(left = snapshot_tree(s$left), right = snapshot_tree(s$right))
  })
})

testthat::test_that("backend parity: locate_by_predicate", {
  expect_backend_identical({
    t <- as_flexseq(letters[1:20])
    snapshot_locate(locate_by_predicate(t, function(v) v >= 10, ".size", include_metadata = TRUE))
  })
})

testthat::test_that("backend parity: peek/pop_at helpers", {
  expect_backend_identical({
    t <- as_flexseq(setNames(as.list(letters[1:8]), LETTERS[1:8]))
    out <- pop_at(t, 5)
    list(
      peek = peek_at(t, 3),
      popped = out$element,
      remaining = snapshot_tree(out$remaining)
    )
  })
})

testthat::test_that("backend parity: insert_at helper", {
  expect_backend_identical({
    t <- as_flexseq(setNames(as.list(letters[1:8]), LETTERS[1:8]))
    out <- insert_at(t, 4, setNames(as.list(c("x", "y")), c("X1", "X2")))
    snapshot_tree(out)
  })
})

testthat::test_that("backend parity: [ read (integer/logical/name)", {
  expect_backend_identical({
    t <- as_flexseq(setNames(as.list(letters[1:12]), LETTERS[1:12]))
    list(
      int = snapshot_tree(t[c(2, 8, 8, 1)]),
      lgl = snapshot_tree(t[c(TRUE, FALSE, TRUE)]),
      chr = snapshot_tree(t[c("H", "A", "missing", "C")])
    )
  })
})

testthat::test_that("backend parity: [[ read (integer/name)", {
  expect_backend_identical({
    t <- as_flexseq(setNames(as.list(letters[1:12]), LETTERS[1:12]))
    list(int = t[[3]], chr = t[["C"]])
  })
})

testthat::test_that("backend parity: [<- replacement (integer/logical/name)", {
  expect_backend_identical({
    t1 <- as_flexseq(1:12)
    t1[c(2, 5, 5)] <- list(200, 500, 501)
    t1[c(TRUE, FALSE, TRUE)] <- list(9, 8)

    t2 <- as_flexseq(setNames(as.list(letters[1:8]), LETTERS[1:8]))
    t2[c("B", "D")] <- list("bb", "dd")

    list(int_lgl = snapshot_tree(t1), chr = snapshot_tree(t2))
  })
})

testthat::test_that("backend parity: [[<- replacement and deletion", {
  expect_backend_identical({
    t1 <- as_flexseq(1:10)
    t1[[4]] <- 99
    t1[[6]] <- NULL

    t2 <- as_flexseq(setNames(as.list(letters[1:8]), LETTERS[1:8]))
    t2[["C"]] <- structure("cc", names = "Z")
    t2[["E"]] <- NULL

    list(int = snapshot_tree(t1), chr = snapshot_tree(t2))
  })
})

testthat::test_that("backend parity: $ read", {
  expect_backend_identical({
    t <- as_flexseq(setNames(as.list(letters[1:8]), LETTERS[1:8]))
    list(A = t$A, C = t$C)
  })
})

testthat::test_that("backend parity: $<- replacement", {
  expect_backend_identical({
    t <- as_flexseq(setNames(as.list(letters[1:8]), LETTERS[1:8]))
    t$B <- "bbb"
    snapshot_tree(t)
  })
})

testthat::test_that("backend parity: ordered_sequence insert", {
  expect_backend_identical({
    x <- as_ordered_sequence(list("aa", "bb", "c", "ddd"), keys = c(2, 2, 1, 3))
    out <- insert(x, "qq", key = 2)
    as.list(out)
  })
})

testthat::test_that("backend parity: ordered_sequence Date keys use consistent fallback path", {
  expect_backend_identical({
    x <- as_ordered_sequence(
      list("late", "early1", "early2"),
      keys = as.Date(c("2024-01-03", "2024-01-01", "2024-01-01"))
    )
    y <- insert(x, "early3", key = as.Date("2024-01-01"))
    list(
      values = as.list(y),
      lower = lower_bound(y, as.Date("2024-01-01")),
      upper = upper_bound(y, as.Date("2024-01-01"))
    )
  })
})

testthat::test_that("backend parity: interval_index insert and queries", {
  expect_backend_identical({
    x <- as_interval_index(
      list("a", "b", "c"),
      start = c(1, 2, 2),
      end = c(3, 2, 4),
      bounds = "[]"
    )
    y <- insert(x, "d", start = 2, end = 5)

    p0 <- pop_point(y, 2)
    p1 <- pop_overlaps(y, 2, 3)
    p2 <- pop_all_within(y, 2, 5)
    bounds_tokens <- c("[)", "[]", "()", "(]")
    bounds_matrix <- lapply(bounds_tokens, function(bt) {
      list(
        token = bt,
        point = as.list(peek_all_point(y, 2, bounds = bt)),
        overlaps = as.list(peek_all_overlaps(y, 2, 3, bounds = bt)),
        containing = as.list(peek_all_containing(y, 2, 3, bounds = bt)),
        within = as.list(peek_all_within(y, 2, 3, bounds = bt)),
        pop_point = as.list(pop_all_point(y, 2, bounds = bt)$elements),
        pop_overlaps = as.list(pop_all_overlaps(y, 2, 3, bounds = bt)$elements),
        pop_containing = as.list(pop_all_containing(y, 2, 3, bounds = bt)$elements),
        pop_within = as.list(pop_all_within(y, 2, 3, bounds = bt)$elements)
      )
    })

    list(
      values = as.list(y),
      bounds = interval_bounds(y),
      bounds_matrix = bounds_matrix,
      point_first = peek_point(y, 2),
      point = as.list(peek_all_point(y, 2)),
      overlaps_first = peek_overlaps(y, 2, 3),
      overlaps = as.list(peek_all_overlaps(y, 2, 3)),
      containing_first = peek_containing(y, 2, 3),
      containing = as.list(peek_all_containing(y, 2, 3)),
      within_first = peek_within(y, 2, 5),
      within = as.list(peek_all_within(y, 2, 5)),
      pop_point_first = list(
        element = p0$element,
        start = p0$start,
        end = p0$end,
        remaining = as.list(p0$remaining)
      ),
      pop_first = list(
        element = p1$element,
        start = p1$start,
        end = p1$end,
        remaining = as.list(p1$remaining)
      ),
      pop_all = list(
        elements = as.list(p2$elements),
        remaining = as.list(p2$remaining)
      )
    )
  })
})

testthat::test_that("backend parity: interval_index user monoid recomputation", {
  expect_backend_identical({
    sum_item <- measure_monoid(function(a, b) a + b, 0, function(el) as.numeric(el$item))
    width_sum <- measure_monoid(function(a, b) a + b, 0, function(el) as.numeric(el$end - el$start))

    x <- add_monoids(as_interval_index(
      as.list(c(10, 20, 30)),
      start = c(1, 2, 4),
      end = c(3, 5, 6)
    ), list(sum_item = sum_item, width_sum = width_sum))
    y <- insert(x, 40, start = 3, end = 4)
    z <- fapply(y, function(item, start, end, name) item + 1)
    s <- peek_all_overlaps(z, 2, 3, bounds = "[)")
    p <- pop_all_overlaps(z, 2, 3, bounds = "[)")

    list(
      base = c(sum_item = node_measure(x, "sum_item"), width_sum = node_measure(x, "width_sum")),
      inserted = c(sum_item = node_measure(y, "sum_item"), width_sum = node_measure(y, "width_sum")),
      applied = c(sum_item = node_measure(z, "sum_item"), width_sum = node_measure(z, "width_sum")),
      slice = c(sum_item = node_measure(s, "sum_item"), width_sum = node_measure(s, "width_sum")),
      pop_element = c(
        sum_item = node_measure(p$elements, "sum_item"),
        width_sum = node_measure(p$elements, "width_sum")
      ),
      pop_remaining = c(
        sum_item = node_measure(p$remaining, "sum_item"),
        width_sum = node_measure(p$remaining, "width_sum")
      ),
      slice_values = as.list(s),
      pop_values = as.list(p$elements),
      remaining_values = as.list(p$remaining)
    )
  })
})

testthat::test_that("backend parity: print.FingerTree output", {
  expect_backend_identical({
    t <- as_flexseq(setNames(as.list(1:10), letters[1:10]))
    capture.output(print(t))
  })
})

testthat::test_that("backend parity: get_graph_df", {
  expect_backend_identical({
    t <- as_flexseq(letters[1:12])
    get_graph_df(t)
  })
})

testthat::test_that("backend parity: validate_tree", {
  expect_backend_identical({
    t <- as_flexseq(letters[1:10])
    isTRUE(validate_tree(t))
  })
})

testthat::test_that("backend parity: validate_name_state", {
  expect_backend_identical({
    t <- as_flexseq(setNames(as.list(letters[1:10]), LETTERS[1:10]))
    isTRUE(validate_name_state(t))
  })
})
