# ---------------------------------------------------------------------------
# Benchmark helpers for the immutables vignette.
#
# Four families: sequence, queue, priority queue, interval index.
# Each family follows the same pattern:
#   make fixture -> apply operation -> cell (microbenchmark) -> grid (loop)
#
# Shared utilities at the top; family-specific code in blocks below.
# ---------------------------------------------------------------------------

.require_pkg <- function(pkg) {
  if(!requireNamespace(pkg, quietly = TRUE)) {
    stop("Package '", pkg, "' is required for the benchmark vignette.")
  }
  invisible(TRUE)
}

benchmark_should_run <- function() {
  identical(Sys.getenv("IMMUTABLES_RUN_BENCHMARK_VIGNETTE"), "1")
}

benchmark_default_repeats <- function() 10L

# --- Per-family size grids ------------------------------------------------

sequence_benchmark_sizes <- function() {
  as.integer(c(100, 500, 1000, 5000, 10000, 50000, 500000))
}

queue_benchmark_sizes <- function() {
  as.integer(c(100, 500, 1000, 5000, 10000, 50000, 100000))
}

pq_benchmark_sizes <- function() {
  as.integer(c(100, 500, 1000, 5000, 10000, 50000))
}

ivx_benchmark_sizes <- function() {
  as.integer(c(100, 500, 1000, 5000, 10000, 50000))
}

# --- Shared summarize / plot ----------------------------------------------

summarize_benchmark_results <- function(results) {
  keys <- interaction(
    results$family,
    results$implementation,
    results$operation,
    results$n,
    drop = TRUE,
    lex.order = TRUE
  )
  pieces <- lapply(split(results, keys), function(df) {
    data.frame(
      family = df$family[[1L]],
      implementation = df$implementation[[1L]],
      operation = df$operation[[1L]],
      n = df$n[[1L]],
      median_us = stats::median(df$time_us),
      q25_us = stats::quantile(df$time_us, probs = 0.25, names = FALSE),
      q75_us = stats::quantile(df$time_us, probs = 0.75, names = FALSE),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, pieces)
  rownames(out) <- NULL
  out[order(out$family, out$operation, out$implementation, out$n), , drop = FALSE]
}

plot_benchmark_results <- function(summary_results, family, title, log_y = FALSE) {
  .require_pkg("ggplot2")

  plot_data <- summary_results[summary_results$family == family, , drop = FALSE]
  if(nrow(plot_data) == 0L) {
    stop("No results available for family: ", family)
  }

  plot_data$median_ms <- plot_data$median_us / 1000
  plot_data$q25_ms <- plot_data$q25_us / 1000
  plot_data$q75_ms <- plot_data$q75_us / 1000

  p <- ggplot2::ggplot(
    plot_data,
    ggplot2::aes(x = n, y = median_ms, color = implementation, fill = implementation)
  ) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = q25_ms, ymax = q75_ms),
      alpha = 0.15, linewidth = 0, show.legend = FALSE
    ) +
    ggplot2::geom_line(linewidth = 0.6) +
    ggplot2::geom_point(size = 1.6) +
    ggplot2::facet_wrap(~ operation, scales = "free_y") +
    ggplot2::scale_x_log10(labels = scales::label_comma()) +
    ggplot2::labs(
      title = title,
      x = "Number of elements",
      y = "Time (ms)",
      color = "Implementation",
      fill = "Implementation"
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5),
      legend.position = "bottom"
    )

  if(log_y) {
    p <- p + ggplot2::scale_y_log10(labels = scales::label_comma())
  }

  p
}

# ===========================================================================
# SEQUENCE BENCHMARKS
# ===========================================================================

sequence_benchmark_inputs <- function(max_n) {
  if(length(max_n) != 1L || is.na(max_n) || max_n < 2L) {
    stop("`max_n` must be a single integer >= 2.")
  }
  max_n <- as.integer(max_n)
  list(
    values = sprintf("value_%06d", seq_len(max_n)),
    append_value = "value_appended",
    prepend_value = "value_prepended",
    replace_value = "value_replaced"
  )
}

make_sequence_fixture <- function(implementation, values) {
  entries <- as.list(values)
  switch(
    implementation,
    "flexseq" = as_flexseq(entries),
    "base R list" = entries,
    stop("Unknown sequence implementation: ", implementation)
  )
}

sequence_apply <- function(
  implementation,
  operation,
  fixture,
  inputs,
  fixture2 = NULL
) {
  n <- length(fixture)
  mid <- as.integer(n / 2L)

  switch(
    implementation,
    "flexseq" = switch(
      operation,
      "append" = push_back(fixture, inputs$append_value),
      "prepend" = push_front(fixture, inputs$prepend_value),
      "get middle" = fixture[[mid]],
      "replace middle" = {
        out <- fixture
        out[[mid]] <- inputs$replace_value
        out
      },
      "remove middle" = pop_at(fixture, mid)$remaining,
      "concatenate" = c(fixture, fixture2),
      "split at middle" = split_at(fixture, mid),
      stop("Unknown sequence operation: ", operation)
    ),
    "base R list" = switch(
      operation,
      "append" = c(fixture, list(inputs$append_value)),
      "prepend" = c(list(inputs$prepend_value), fixture),
      "get middle" = fixture[[mid]],
      "replace middle" = {
        out <- fixture
        out[[mid]] <- inputs$replace_value
        out
      },
      "remove middle" = fixture[-mid],
      "concatenate" = c(fixture, fixture2),
      "split at middle" = list(
        left = fixture[seq_len(mid - 1L)],
        value = fixture[[mid]],
        right = fixture[(mid + 1L):n]
      ),
      stop("Unknown sequence operation: ", operation)
    ),
    stop("Unknown sequence implementation: ", implementation)
  )
}

run_sequence_benchmark_cell <- function(
  implementation, operation, n, inputs,
  repeats = benchmark_default_repeats()
) {
  .require_pkg("microbenchmark")
  n <- as.integer(n)
  repeats <- as.integer(repeats)
  if(n %% 2L != 0L) stop("Sequence benchmark sizes must be even.")

  values <- inputs$values[seq_len(n)]
  fixture <- make_sequence_fixture(implementation, values)

  # Concat needs a second fixture of the same type and size.
  fixture2 <- if(operation == "concatenate") {
    make_sequence_fixture(implementation, values)
  }

  gc(FALSE)
  bm <- suppressWarnings(microbenchmark::microbenchmark(
    sequence_apply(implementation, operation, fixture, inputs, fixture2),
    times = repeats
  ))

  data.frame(
    family = "sequence",
    implementation = implementation,
    operation = operation,
    n = n,
    `repeat` = seq_len(repeats),
    time_us = as.numeric(bm$time) / 1000,
    check.names = FALSE, stringsAsFactors = FALSE
  )
}

run_sequence_benchmark_grid <- function(
  sizes = sequence_benchmark_sizes(),
  repeats = benchmark_default_repeats(),
  inputs = sequence_benchmark_inputs(max(sizes))
) {
  implementations <- c("flexseq", "base R list")
  operations <- c(
    "append", "prepend", "get middle", "replace middle",
    "remove middle", "concatenate", "split at middle"
  )
  rows <- vector("list", length(implementations) * length(operations) * length(sizes))
  idx <- 1L
  for(impl in implementations) {
    for(op in operations) {
      for(n in sizes) {
        rows[[idx]] <- run_sequence_benchmark_cell(impl, op, n, inputs, repeats)
        idx <- idx + 1L
      }
    }
  }
  do.call(rbind, rows)
}

# ===========================================================================
# QUEUE BENCHMARKS
# ===========================================================================

make_queue_fixture <- function(implementation, n) {
  entries <- as.list(rep("queue_item", n))
  switch(
    implementation,
    "flexseq" = as_flexseq(entries),
    "rstackdeque" = {
      .require_pkg("rstackdeque")
      rstackdeque::as.rpqueue(entries)
    },
    "base R list" = entries,
    stop("Unknown queue implementation: ", implementation)
  )
}

queue_apply <- function(implementation, operation, fixture, append_value) {
  switch(
    implementation,
    "flexseq" = switch(
      operation,
      "enqueue" = push_back(fixture, append_value),
      "dequeue" = pop_front(fixture)$remaining,
      stop("Unknown queue operation: ", operation)
    ),
    "rstackdeque" = switch(
      operation,
      "enqueue" = rstackdeque::insert_back(fixture, append_value),
      "dequeue" = rstackdeque::without_front(fixture),
      stop("Unknown queue operation: ", operation)
    ),
    "base R list" = switch(
      operation,
      "enqueue" = c(fixture, list(append_value)),
      "dequeue" = fixture[-1L],
      stop("Unknown queue operation: ", operation)
    ),
    stop("Unknown queue implementation: ", implementation)
  )
}

run_queue_benchmark_cell <- function(
  implementation, operation, n,
  repeats = benchmark_default_repeats()
) {
  .require_pkg("microbenchmark")
  n <- as.integer(n)
  repeats <- as.integer(repeats)
  fixture <- make_queue_fixture(implementation, n)
  append_value <- "queue_item_added"

  gc(FALSE)
  bm <- suppressWarnings(microbenchmark::microbenchmark(
    queue_apply(implementation, operation, fixture, append_value),
    times = repeats
  ))

  data.frame(
    family = "queue",
    implementation = implementation,
    operation = operation,
    n = n,
    `repeat` = seq_len(repeats),
    time_us = as.numeric(bm$time) / 1000,
    check.names = FALSE, stringsAsFactors = FALSE
  )
}

run_queue_benchmark_grid <- function(
  sizes = queue_benchmark_sizes(),
  repeats = benchmark_default_repeats()
) {
  implementations <- c("flexseq", "rstackdeque", "base R list")
  operations <- c("enqueue", "dequeue")
  rows <- vector("list", length(implementations) * length(operations) * length(sizes))
  idx <- 1L
  for(impl in implementations) {
    for(op in operations) {
      for(n in sizes) {
        rows[[idx]] <- run_queue_benchmark_cell(impl, op, n, repeats)
        idx <- idx + 1L
      }
    }
  }
  do.call(rbind, rows)
}

# ===========================================================================
# PRIORITY QUEUE BENCHMARKS
# ===========================================================================

pq_benchmark_inputs <- function(max_n) {
  max_n <- as.integer(max_n)
  set.seed(42)
  list(
    values = sprintf("val_%06d", seq_len(max_n)),
    priorities = runif(max_n),
    insert_value = "val_new",
    insert_priority = 0.5
  )
}

make_pq_fixture <- function(implementation, n, inputs) {
  vals <- as.list(inputs$values[seq_len(n)])
  pris <- inputs$priorities[seq_len(n)]
  switch(
    implementation,
    "priority_queue" = as_priority_queue(vals, priorities = pris),
    "base R" = list(values = inputs$values[seq_len(n)], priorities = pris),
    stop("Unknown priority queue implementation: ", implementation)
  )
}

pq_apply <- function(implementation, operation, fixture, inputs) {
  switch(
    implementation,
    "priority_queue" = switch(
      operation,
      "insert" = insert(fixture, inputs$insert_value, inputs$insert_priority),
      "peek min" = peek_min(fixture),
      "pop min" = pop_min(fixture)$remaining,
      "peek max" = peek_max(fixture),
      "pop max" = pop_max(fixture)$remaining,
      stop("Unknown pq operation: ", operation)
    ),
    "base R" = switch(
      operation,
      "insert" = list(
        values = c(fixture$values, inputs$insert_value),
        priorities = c(fixture$priorities, inputs$insert_priority)
      ),
      "peek min" = fixture$values[which.min(fixture$priorities)],
      "pop min" = {
        idx <- which.min(fixture$priorities)
        list(values = fixture$values[-idx], priorities = fixture$priorities[-idx])
      },
      "peek max" = fixture$values[which.max(fixture$priorities)],
      "pop max" = {
        idx <- which.max(fixture$priorities)
        list(values = fixture$values[-idx], priorities = fixture$priorities[-idx])
      },
      stop("Unknown pq operation: ", operation)
    ),
    stop("Unknown priority queue implementation: ", implementation)
  )
}

run_pq_benchmark_cell <- function(
  implementation, operation, n, inputs,
  repeats = benchmark_default_repeats()
) {
  .require_pkg("microbenchmark")
  n <- as.integer(n)
  repeats <- as.integer(repeats)
  fixture <- make_pq_fixture(implementation, n, inputs)

  gc(FALSE)
  bm <- suppressWarnings(microbenchmark::microbenchmark(
    pq_apply(implementation, operation, fixture, inputs),
    times = repeats
  ))

  data.frame(
    family = "priority_queue",
    implementation = implementation,
    operation = operation,
    n = n,
    `repeat` = seq_len(repeats),
    time_us = as.numeric(bm$time) / 1000,
    check.names = FALSE, stringsAsFactors = FALSE
  )
}

run_pq_benchmark_grid <- function(
  sizes = pq_benchmark_sizes(),
  repeats = benchmark_default_repeats(),
  inputs = pq_benchmark_inputs(max(sizes))
) {
  implementations <- c("priority_queue", "base R")
  operations <- c("insert", "peek min", "pop min", "peek max", "pop max")
  rows <- vector("list", length(implementations) * length(operations) * length(sizes))
  idx <- 1L
  for(impl in implementations) {
    for(op in operations) {
      for(n in sizes) {
        rows[[idx]] <- run_pq_benchmark_cell(impl, op, n, inputs, repeats)
        idx <- idx + 1L
      }
    }
  }
  do.call(rbind, rows)
}

# ===========================================================================
# INTERVAL INDEX BENCHMARKS
# ===========================================================================

ivx_benchmark_inputs <- function(max_n) {
  max_n <- as.integer(max_n)
  set.seed(123)
  starts <- sort(sample.int(max_n * 10L, max_n))
  widths <- sample.int(100L, max_n, replace = TRUE)
  ends <- starts + widths

  # Pick a query point near the middle of the range.
  mid_start <- starts[as.integer(max_n / 2L)]
  # Pick a query range that overlaps a modest slice.
  query_lo <- starts[as.integer(max_n * 0.4)]
  query_hi <- starts[as.integer(max_n * 0.5)]

  list(
    values = sprintf("interval_%06d", seq_len(max_n)),
    starts = starts,
    ends = ends,
    query_point = mid_start + 10L,
    query_start = query_lo,
    query_end = query_hi,
    insert_value = "interval_new",
    insert_start = mid_start,
    insert_end = mid_start + 50L
  )
}

make_ivx_fixture <- function(implementation, n, inputs) {
  s <- inputs$starts[seq_len(n)]
  e <- inputs$ends[seq_len(n)]
  v <- inputs$values[seq_len(n)]
  switch(
    implementation,
    "interval_index" = as_interval_index(as.list(v), start = s, end = e, bounds = "[]"),
    "base R" = data.frame(start = s, end = e, value = v, stringsAsFactors = FALSE),
    "IRanges" = {
      .require_pkg("IRanges")
      list(
        iranges = IRanges::IRanges(start = s, end = e),
        values = v
      )
    },
    stop("Unknown interval implementation: ", implementation)
  )
}

ivx_apply <- function(implementation, operation, fixture, inputs) {
  switch(
    implementation,
    "interval_index" = switch(
      operation,
      "insert" = insert(fixture, inputs$insert_value,
                        inputs$insert_start, inputs$insert_end),
      "point query" = peek_point(fixture, inputs$query_point, bounds = "[]"),
      "all point matches" = peek_all_point(fixture, inputs$query_point, bounds = "[]"),
      "overlap query" = peek_all_overlaps(fixture, inputs$query_start,
                                          inputs$query_end, bounds = "[]"),
      stop("Unknown interval operation: ", operation)
    ),
    "base R" = switch(
      operation,
      "insert" = rbind(fixture, data.frame(
        start = inputs$insert_start, end = inputs$insert_end,
        value = inputs$insert_value, stringsAsFactors = FALSE
      )),
      "point query" = {
        p <- inputs$query_point
        hit <- which(fixture$start <= p & p <= fixture$end)
        if(length(hit)) fixture$value[hit[1L]] else NULL
      },
      "all point matches" = {
        p <- inputs$query_point
        fixture[fixture$start <= p & p <= fixture$end, , drop = FALSE]
      },
      "overlap query" = {
        qs <- inputs$query_start
        qe <- inputs$query_end
        fixture[fixture$start <= qe & fixture$end >= qs, , drop = FALSE]
      },
      stop("Unknown interval operation: ", operation)
    ),
    "IRanges" = switch(
      operation,
      "insert" = {
        list(
          iranges = c(fixture$iranges,
                      IRanges::IRanges(start = inputs$insert_start,
                                       end = inputs$insert_end)),
          values = c(fixture$values, inputs$insert_value)
        )
      },
      "point query" = {
        q <- IRanges::IRanges(start = inputs$query_point, width = 1L)
        hits <- IRanges::findOverlaps(q, fixture$iranges)
        sh <- S4Vectors::subjectHits(hits)
        if(length(sh)) fixture$values[sh[1L]] else NULL
      },
      "all point matches" = {
        q <- IRanges::IRanges(start = inputs$query_point, width = 1L)
        hits <- IRanges::findOverlaps(q, fixture$iranges)
        fixture$values[S4Vectors::subjectHits(hits)]
      },
      "overlap query" = {
        q <- IRanges::IRanges(start = inputs$query_start, end = inputs$query_end)
        hits <- IRanges::findOverlaps(q, fixture$iranges)
        fixture$values[S4Vectors::subjectHits(hits)]
      },
      stop("Unknown interval operation: ", operation)
    ),
    stop("Unknown interval implementation: ", implementation)
  )
}

run_ivx_benchmark_cell <- function(
  implementation, operation, n, inputs,
  repeats = benchmark_default_repeats()
) {
  .require_pkg("microbenchmark")
  n <- as.integer(n)
  repeats <- as.integer(repeats)
  fixture <- make_ivx_fixture(implementation, n, inputs)

  gc(FALSE)
  bm <- suppressWarnings(microbenchmark::microbenchmark(
    ivx_apply(implementation, operation, fixture, inputs),
    times = repeats
  ))

  data.frame(
    family = "interval",
    implementation = implementation,
    operation = operation,
    n = n,
    `repeat` = seq_len(repeats),
    time_us = as.numeric(bm$time) / 1000,
    check.names = FALSE, stringsAsFactors = FALSE
  )
}

run_ivx_benchmark_grid <- function(
  sizes = ivx_benchmark_sizes(),
  repeats = benchmark_default_repeats(),
  inputs = ivx_benchmark_inputs(max(sizes))
) {
  has_iranges <- requireNamespace("IRanges", quietly = TRUE) &&
    requireNamespace("S4Vectors", quietly = TRUE)
  implementations <- c("interval_index", "base R")
  if(has_iranges) implementations <- c(implementations, "IRanges")

  operations <- c("insert", "point query", "all point matches", "overlap query")
  rows <- vector("list", length(implementations) * length(operations) * length(sizes))
  idx <- 1L
  for(impl in implementations) {
    for(op in operations) {
      for(n in sizes) {
        rows[[idx]] <- run_ivx_benchmark_cell(impl, op, n, inputs, repeats)
        idx <- idx + 1L
      }
    }
  }
  do.call(rbind, rows)
}

# ===========================================================================
# ORCHESTRATOR
# ===========================================================================

run_benchmark_vignette <- function(
  sequence_sizes = sequence_benchmark_sizes(),
  queue_sizes = queue_benchmark_sizes(),
  pq_sizes = pq_benchmark_sizes(),
  ivx_sizes = ivx_benchmark_sizes(),
  repeats = benchmark_default_repeats()
) {
  seq_inputs <- sequence_benchmark_inputs(max(sequence_sizes))
  pq_inputs <- pq_benchmark_inputs(max(pq_sizes))
  ivx_inputs <- ivx_benchmark_inputs(max(ivx_sizes))

  raw <- rbind(
    run_sequence_benchmark_grid(sequence_sizes, repeats, seq_inputs),
    run_queue_benchmark_grid(queue_sizes, repeats),
    run_pq_benchmark_grid(pq_sizes, repeats, pq_inputs),
    run_ivx_benchmark_grid(ivx_sizes, repeats, ivx_inputs)
  )

  summary <- summarize_benchmark_results(raw)

  list(
    raw = raw,
    summary = summary,
    sequence_plot = plot_benchmark_results(summary, "sequence",
                                           "Sequence operations"),
    queue_plot = plot_benchmark_results(summary, "queue",
                                        "Queue operations", log_y = TRUE),
    pq_plot = plot_benchmark_results(summary, "priority_queue",
                                     "Priority queue operations", log_y = TRUE),
    ivx_plot = plot_benchmark_results(summary, "interval",
                                      "Interval index queries", log_y = TRUE)
  )
}
