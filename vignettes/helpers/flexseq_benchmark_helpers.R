.flexseq_benchmark_require <- function(pkg) {
  if(!requireNamespace(pkg, quietly = TRUE)) {
    stop("Package '", pkg, "' is required for the benchmark vignette.")
  }
  invisible(TRUE)
}

flexseq_benchmark_default_sizes <- function() {
  as.integer(c(100, 500, 1000, 5000, 10000, 50000))
}

flexseq_benchmark_default_repeats <- function() {
  30L
}

flexseq_benchmark_should_run <- function() {
  identical(Sys.getenv("IMMUTABLES_RUN_BENCHMARK_VIGNETTE"), "1")
}

flexseq_benchmark_inputs <- function(max_n) {
  if(length(max_n) != 1L || is.na(max_n) || max_n < 2L) {
    stop("`max_n` must be a single integer >= 2.")
  }
  max_n <- as.integer(max_n)
  list(
    sequence_values = sprintf("value_%06d", seq_len(max_n)),
    append_value = sprintf("value_%06d", max_n + 1L),
    replace_value = "value_replaced",
    queue_value = "queue_item",
    queue_append_value = "queue_item_added"
  )
}

.flexseq_benchmark_as_list <- function(x) {
  if(inherits(x, "flexseq")) {
    return(as.list(x))
  }
  as.list(x)
}

flexseq_benchmark_make_sequence_fixture <- function(implementation, values) {
  entries <- as.list(values)
  switch(
    implementation,
    "flexseq" = as_flexseq(entries),
    "base R list" = entries,
    stop("Unknown sequence implementation: ", implementation)
  )
}

flexseq_benchmark_sequence_apply <- function(
  implementation,
  operation,
  fixture,
  append_value,
  replace_value
) {
  n <- length(fixture)
  if(n %% 2L != 0L) {
    stop("Sequence benchmark fixture size must be even.")
  }
  mid <- as.integer(n / 2L)

  switch(
    implementation,
    "flexseq" = switch(
      operation,
      "append" = push_back(fixture, append_value),
      "replace middle" = {
        out <- fixture
        out[[mid]] <- replace_value
        out
      },
      "get middle" = fixture[[mid]],
      "remove middle" = pop_at(fixture, mid)$remaining,
      stop("Unknown sequence operation: ", operation)
    ),
    "base R list" = switch(
      operation,
      "append" = c(fixture, list(append_value)),
      "replace middle" = {
        out <- fixture
        out[[mid]] <- replace_value
        out
      },
      "get middle" = fixture[[mid]],
      "remove middle" = fixture[-mid],
      stop("Unknown sequence operation: ", operation)
    ),
    stop("Unknown sequence implementation: ", implementation)
  )
}

flexseq_benchmark_make_queue_fixture <- function(implementation, values) {
  entries <- as.list(values)
  switch(
    implementation,
    "flexseq" = as_flexseq(entries),
    "rstackdeque" = {
      .flexseq_benchmark_require("rstackdeque")
      rstackdeque::as.rpqueue(entries)
    },
    "base R list" = entries,
    stop("Unknown queue implementation: ", implementation)
  )
}

flexseq_benchmark_queue_apply <- function(implementation, operation, fixture, append_value) {
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

run_flexseq_sequence_benchmark_cell <- function(
  implementation,
  operation,
  n,
  inputs,
  repeats = flexseq_benchmark_default_repeats()
) {
  .flexseq_benchmark_require("microbenchmark")
  n <- as.integer(n)
  repeats <- as.integer(repeats)
  if(n %% 2L != 0L) {
    stop("Sequence benchmark sizes must be even.")
  }
  values <- inputs$sequence_values[seq_len(n)]
  fixture <- flexseq_benchmark_make_sequence_fixture(implementation, values)
  mid <- as.integer(n / 2L)
  append_value <- inputs$append_value
  replace_value <- inputs$replace_value

  gc(FALSE)
  bm <- suppressWarnings(microbenchmark::microbenchmark(
    flexseq_benchmark_sequence_apply(
      implementation = implementation,
      operation = operation,
      fixture = fixture,
      append_value = append_value,
      replace_value = replace_value
    ),
    times = repeats
  ))

  data.frame(
    family = "sequence",
    implementation = implementation,
    operation = operation,
    n = n,
    `repeat` = seq_len(repeats),
    time_us = as.numeric(bm$time) / 1000,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

run_flexseq_queue_benchmark_cell <- function(
  implementation,
  operation,
  n,
  inputs,
  repeats = flexseq_benchmark_default_repeats()
) {
  .flexseq_benchmark_require("microbenchmark")
  n <- as.integer(n)
  repeats <- as.integer(repeats)
  values <- rep(inputs$queue_value, n)
  fixture <- flexseq_benchmark_make_queue_fixture(implementation, values)
  append_value <- inputs$queue_append_value

  gc(FALSE)
  bm <- suppressWarnings(microbenchmark::microbenchmark(
    flexseq_benchmark_queue_apply(
      implementation = implementation,
      operation = operation,
      fixture = fixture,
      append_value = append_value
    ),
    times = repeats
  ))

  data.frame(
    family = "queue",
    implementation = implementation,
    operation = operation,
    n = n,
    `repeat` = seq_len(repeats),
    time_us = as.numeric(bm$time) / 1000,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

run_flexseq_sequence_benchmark_grid <- function(
  sizes = flexseq_benchmark_default_sizes(),
  repeats = flexseq_benchmark_default_repeats(),
  inputs = flexseq_benchmark_inputs(max(sizes))
) {
  implementations <- c("flexseq", "base R list")
  operations <- c("append", "replace middle", "get middle", "remove middle")
  rows <- vector("list", length(implementations) * length(operations) * length(sizes))
  idx <- 1L
  for(implementation in implementations) {
    for(operation in operations) {
      for(n in sizes) {
        rows[[idx]] <- run_flexseq_sequence_benchmark_cell(
          implementation = implementation,
          operation = operation,
          n = n,
          inputs = inputs,
          repeats = repeats
        )
        idx <- idx + 1L
      }
    }
  }
  do.call(rbind, rows)
}

run_flexseq_queue_benchmark_grid <- function(
  sizes = flexseq_benchmark_default_sizes(),
  repeats = flexseq_benchmark_default_repeats(),
  inputs = flexseq_benchmark_inputs(max(sizes))
) {
  implementations <- c("flexseq", "rstackdeque", "base R list")
  operations <- c("enqueue", "dequeue")
  rows <- vector("list", length(implementations) * length(operations) * length(sizes))
  idx <- 1L
  for(implementation in implementations) {
    for(operation in operations) {
      for(n in sizes) {
        rows[[idx]] <- run_flexseq_queue_benchmark_cell(
          implementation = implementation,
          operation = operation,
          n = n,
          inputs = inputs,
          repeats = repeats
        )
        idx <- idx + 1L
      }
    }
  }
  do.call(rbind, rows)
}

summarize_flexseq_benchmark_results <- function(results) {
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

plot_flexseq_benchmark_results <- function(summary_results, family) {
  .flexseq_benchmark_require("ggplot2")

  plot_data <- summary_results[summary_results$family == family, , drop = FALSE]
  if(nrow(plot_data) == 0L) {
    stop("No results available for family: ", family)
  }

  plot_data$median_ms <- plot_data$median_us / 1000
  plot_data$q25_ms <- plot_data$q25_us / 1000
  plot_data$q75_ms <- plot_data$q75_us / 1000

  title <- if(identical(family, "sequence")) {
    "Sequence operations"
  } else {
    "Queue/dequeue operations"
  }

  ggplot2::ggplot(
    plot_data,
    ggplot2::aes(x = n, y = median_ms, color = implementation, fill = implementation)
  ) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = q25_ms, ymax = q75_ms),
      alpha = 0.15,
      linewidth = 0,
      show.legend = FALSE
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
}

run_flexseq_benchmark_vignette <- function(
  sizes = flexseq_benchmark_default_sizes(),
  repeats = flexseq_benchmark_default_repeats()
) {
  inputs <- flexseq_benchmark_inputs(max(sizes))
  raw_results <- rbind(
    run_flexseq_sequence_benchmark_grid(sizes = sizes, repeats = repeats, inputs = inputs),
    run_flexseq_queue_benchmark_grid(sizes = sizes, repeats = repeats, inputs = inputs)
  )
  summary_results <- summarize_flexseq_benchmark_results(raw_results)
  list(
    raw = raw_results,
    summary = summary_results,
    sequence_plot = plot_flexseq_benchmark_results(summary_results, "sequence"),
    queue_plot = plot_flexseq_benchmark_results(summary_results, "queue")
  )
}
