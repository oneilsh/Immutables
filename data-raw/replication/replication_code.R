##################################
### Setup - load packages
##################################

library("Immutables")


##################################
### Section 2.1
##################################

fs1 <- as_flexseq(letters[1:10])
fs2 <- push_back(fs1, "z")
length(fs1)
length(fs2)
fs3 <- insert_at(fs2, 8, 4.2)
length(fs3)

fs4 <- fs1[1:5]
unlist(fs4)
fs5 <- pop_back(fs2)
fs5$value
fs5$remaining


##################################
### Section 2.1 (Example: Simulating complex queueing systems)
##################################

set.seed(100)
steps <- 5000
p_arrival <- 0.9
mean_service <- 1
qa <- flexseq(); free_a <- 0
qb <- flexseq(); free_b <- 0
waits <- flexseq()

for (t in seq_len(steps)) {
  if (runif(1) < p_arrival) {
    request <- list(arrival = t)
    if (length(qa) <= length(qb)) qa <- push_back(qa, request)
    else                         qb <- push_back(qb, request)
  }

  if (free_a <= t && length(qa) > 0) {
    nxt <- pop_front(qa)
    qa <- nxt$remaining
    request <- nxt$value
    waits <- push_back(waits, t - request$arrival)
    free_a <- t + rpois(1, mean_service) + 1
  }

  if (free_b <= t && length(qb) > 0) {
    nxt <- pop_front(qb)
    qb <- nxt$remaining
    request <- nxt$value
    waits <- push_back(waits, t - request$arrival)
    free_b <- t + rpois(1, mean_service) + 1
  }
}

summary(unlist(waits))


##################################
### Section 2.2
##################################

pq1 <- as_priority_queue(letters[1:6],
                         priorities = c(2, 1, 3, 1, 9, 7))
peek_min(pq1)
peek_all_min(pq1)
pq2 <- insert(pq1, "z", priority = 10)
pq3 <- pop_max(pq2)
pq3$value
length(pq3$remaining)


##################################
### Section 2.2 (Example: Best-first feature selection)
##################################

set.seed(100)
n <- 10000
p <- 25
X <- matrix(rnorm(n * p), n, p)
y <- 3.5 * X[, 3] - 4 * X[, 7] + rnorm(n)

model <- lm(y ~ 1)
best_features <- numeric(0)
best_aic <- AIC(model)
pq <- priority_queue()
pq <- insert(pq, best_features, priority = best_aic)

models_considered <- 1

while (length(pq) > 0 && models_considered < 1000) {
  current_best <- pop_min(pq)
  pq <- current_best$remaining
  current_best_features <- current_best$value
  current_best_aic <- current_best$priority
  available_features <- setdiff(1:ncol(X), current_best_features)
  for (available_feature in available_features) {
    selected_features <- c(current_best_features, available_feature)
    model <- lm(y ~ X[, selected_features, drop = FALSE])
    pq <- insert(pq, selected_features, priority = AIC(model))

    if (AIC(model) < best_aic) {
      best_features <- selected_features
      best_aic <- AIC(model)
    }

    models_considered <- models_considered + 1
  }
}

best_features


##################################
### Section 2.3
##################################

os1 <- as_ordered_sequence(letters[1:6],
                           keys = c(20, 10, 30, 10, 90, 70))
peek_key(os1, 10)
unlist(peek_all_key(os1, 10))
count_key(os1, 10)
elements_between(os1, 15, 85)
os2 <- insert(os1, "z", key = 100)
os3 <- pop_key(os2, 100)
os3$value
unlist(os3$remaining)


##################################
### Section 2.3 (Example: Scalar matching without replacement)
##################################

set.seed(100)
n_patients <- 200
patients <- data.frame(treated = sample(c(TRUE, FALSE),
                                        n_patients,
                                        prob = c(0.1, 0.9),
                                        replace = TRUE),
                       score = runif(n_patients))

treated_rows <- which(patients$treated)
treated_scores <- patients$score[patients$treated]
untreated_rows <- which(!patients$treated)
untreated_scores <- patients$score[!patients$treated]

matches <- flexseq()
treated_seq <- as_ordered_sequence(treated_rows,
                                   keys = treated_scores)
untreated_seq <- as_ordered_sequence(untreated_rows,
                                     keys = untreated_scores)

while (length(treated_seq) > 0) {
  if (length(untreated_seq) == 0L) break

  front_el <- pop_front(treated_seq)
  treated_seq <- front_el$remaining
  treated_pt_score <- front_el$key
  treated_pt_row   <- front_el$value

  match_key <- nearest_key(untreated_seq, treated_pt_score)
  match_el  <- pop_key(untreated_seq, match_key)
  untreated_seq <- match_el$remaining
  untreated_pt_score <- match_el$key
  untreated_pt_row   <- match_el$value

  match_row <- data.frame(treated_pt_row,
                          treated_pt_score,
                          untreated_pt_row,
                          untreated_pt_score)
  matches <- push_back(matches, match_row)
}

match_df <- do.call(rbind, as.list(matches))
head(match_df)


##################################
### Section 2.4
##################################

ix1 <- as_interval_index(c("a", "b", "c"),
                         start = c(1, 2, 4),
                         end = c(3, 4, 5))
peek_point(ix1, 3)
peek_point(ix1, 2, match_at = "start")
ix2 <- insert(ix1, "d", start = 5, end = 6)
ix3 <- pop_all_overlapping(ix2, 3, 4.5)
ix3$elements
unlist(ix3$remaining)


##################################
### Section 2.4 (Example: Hospital occupancy over time)
##################################

set.seed(100)
num_days <- 365
n_patients <- 500

starts <- sample(1:num_days,
                 size = n_patients,
                 replace = TRUE)
ends <- starts + rpois(n_patients, 2)

ages <- pmax(0, rnorm(n_patients, mean = 35, sd = 10))
is_males <- sample(c(0, 1), n_patients, replace = TRUE)
patients <- Map(list, age = ages, is_male = is_males)

ix <- as_interval_index(patients, start = starts, end = ends)

day_stats <- flexseq()

for (day in seq_len(num_days)) {
  present <- peek_all_point(ix, day)
  occupancy <- length(present)

  if (occupancy == 0) {
    stats <- data.frame(day = day, occupancy = 0,
                        mean_age = NA, pct_male = NA)
  } else {
    day_ages <- present |>
      fapply(function(patient, start, end) {
        patient$age
      }) |>
      unlist()

    day_males <- present |>
      fapply(function(patient, start, end) {
        patient$is_male
      }) |>
      unlist()

    stats <- data.frame(day = day,
                        occupancy = occupancy,
                        mean_age = mean(day_ages),
                        pct_male = 100 * mean(day_males))
  }

  day_stats <- push_back(day_stats, stats)
}

stats_df <- do.call(rbind, as.list(day_stats))
head(stats_df)


##################################
### Section 3
##################################

set.seed(42)
tasks <- lapply(1:11, 
                function(i) {
                  list(id = letters[i], 
                  hours = rpois(n = 1, lambda = 5))
                }) |>
         as_flexseq()

total_time_mm <- measure_monoid(`+`, 0, function(el) el$hours)

tasks2 <- add_monoids(tasks, list(total_time = total_time_mm))

plot_structure(tasks2, node_label = function(node) {
  if (node$type == "Element") {
    sprintf("ID: %s, H: %d\nTotal: %d", 
            node$element$id, 
            node$element$hours, 
            node$measures$total_time)
  } else {
    sprintf("Total: %d", node$measures$total_time)
  }
})

split_tasks <- split_by_predicate(tasks2,
                                  predicate = function(m) m > 40,
                                  monoid_name = "total_time")
sapply(as.list(split_tasks$left), function(task) task$id)
sapply(as.list(split_tasks$right), function(task) task$id)


##################################
### Section 3.1 (Example: Subsequence search)
##################################

sequence <- "ACGCGCTCGCGCATAGTCGCGCCTG"
query    <- "CGCGC"

max_seq <- measure_monoid(max, i = -Inf,
                          measure = function(entry) entry$key)
subseqs <- ordered_sequence()
subseqs <- add_monoids(subseqs, list(max_seq = max_seq))

for (index in 1:nchar(sequence)) {
  subseq <- substr(sequence, index, index + 7)
  subseqs <- insert(subseqs, index, key = subseq)
}

matches <- ordered_sequence()
first_split <- split_by_predicate(subseqs, function(m) query <= m,
                                  "max_seq")

if (length(first_split$right) > 0) {
  first_entry <- first_split$right[1]
  first_measure <- get_measures(first_entry, "max_seq")[[1]]

  if (startsWith(first_measure, query)) {
    second_split <- split_by_predicate(
      first_split$right,
      function(m) query < m & !startsWith(m, query),
      "max_seq"
    )
    matches <- second_split$left
  }
}

positions <- fapply(matches, function(value, key) value) |> unlist()
positions


##################################
### Section 4
##################################

## NOTE: These benchmarks take several hours to run due to the large number of
## repetitions with garbage collection. Modify the number of repetitions in `repeats`
## and tested values in `sequence_sizes`, `ord_sizes`, `pq_sizes`, and 
## `ivx_sizes` below to produce a subset of results faster.

## The figures in the manuscript are produced as part of a package vignette,
## triggered conditionally based on an environment variable. This 
## code removes that conditional build infrastructure and figure destination 
## but is otherwise exactly that used to produce the benchmark figures.

library(microbenchmark)
library(bench)
library(ggplot2)
library(dplyr)

repeats <- 10L

## Helper functions for plotting
pow2_labels <- function(x) parse(text = paste0("2^", log2(as.numeric(x))))
label_time <- function(x) sub("μ", "µ", scales::label_timespan()(x))


## Helper function for running set of benchmark timings:
## rows: a flexseq to append results to before returning
## impl: a label indicating the implementation, e.g. "base R" or "flexseq"
## op: a label indicating the operation being tested, e.g. "concatenate"
## n: size of the data structure being manipulated (for tracking purposes)
## repeats: the number of repeats to test
## setup: a function that returns a structure to be manipulated
## bench: a function that takes the result of setup and applies an operation to be benchmarked
bench_one <- function(rows, impl, op, n, repeats, setup, bench) {
  state <- setup()
  gc(full = TRUE)
  
  # warmup
  for(i in 1:3) bench(state)
  
  res <- bench::mark(bench(state),
                     min_iterations = repeats,
                     max_iterations = repeats + 0)
  
  times <- unlist(res$time[[1]])
  
  rows <- push_back(rows, data.frame(impl = impl, op = op, n = n, time_s = times))
  return(rows)
}


##############################
### Sequence benchmarks
##############################

# sizes of sequences to test - modify to test fewer
sequence_sizes <- 2^(12 + 0:6)

# we collect result data.frames from bench_one(rows, ) across implementations
# and sizes
rows <- flexseq()

for(n in sequence_sizes) {
  cat("Sequence ops, size ", n, "\n")
  vals <- function() as.list(sprintf("v_%06d", seq_len(n)))
  mid <- as.integer(n / 2)
  flex_setup <- function() list(s = as_flexseq(vals()), mid = mid)
  list_setup <- function() list(s = vals(), mid = mid)
  pair_flex  <- function() list(a = as_flexseq(vals()), b = as_flexseq(vals()))
  pair_list  <- function() list(a = vals(), b = vals())
  
  rows <- bench_one(rows, "flexseq", "enqueue", n, repeats, flex_setup,
                    function(st) push_back(st$s, "d"))
  rows <- bench_one(rows, "flexseq", "dequeue", n, repeats, flex_setup,
                    function(st) pop_front(st$s)$remaining)
  rows <- bench_one(rows, "flexseq", "replace middle", n, repeats, flex_setup,
                    function(st) { s <- st$s; s[[st$mid]] <- "y"; s })
  rows <- bench_one(rows, "flexseq", "remove middle", n, repeats, flex_setup,
                    function(st) pop_at(st$s, st$mid)$remaining)
  rows <- bench_one(rows, "flexseq", "concatenate", n, repeats, pair_flex,
                    function(st) c(st$a, st$b))
  rows <- bench_one(rows, "flexseq", "split at middle", n, repeats, flex_setup,
                    function(st) split_at(st$s, st$mid))
  
  rows <- bench_one(rows, "base R", "enqueue", n, repeats, list_setup,
                    function(st) c(st$s, list("d")))
  rows <- bench_one(rows, "base R", "dequeue", n, repeats, list_setup,
                    function(st) st$s[-1L])
  rows <- bench_one(rows, "base R", "replace middle", n, repeats, list_setup,
                    function(st) { s <- st$s; s[[st$mid]] <- "y"; s })
  rows <- bench_one(rows, "base R", "remove middle", n, repeats, list_setup,
                    function(st) st$s[-st$mid])
  rows <- bench_one(rows, "base R", "concatenate", n, repeats, pair_list,
                    function(st) c(st$a, st$b))
  rows <- bench_one(rows, "base R", "split at middle", n, repeats, list_setup,
                    function(st) list(
                      left = st$s[seq_len(st$mid - 1L)],
                      value = st$s[[st$mid]],
                      right = st$s[(st$mid + 1L):n]
                    ))
}

# collect the flexseq of data.frames into one data.frame
seq_results <- do.call(rbind, as.list(rows))

# plot sequence results
sorted_sizes <- sort(unique(seq_results$n))
seq_results$n_cat <- factor(seq_results$n, levels = sorted_sizes)

p_sequence <- ggplot(seq_results, aes(x = n_cat, y = as.numeric(time_s), color = impl)) +
  geom_boxplot() +
  facet_wrap(~ op, scales = "free_y") +
  scale_x_discrete(labels = pow2_labels) +
  labs(
    title = "Sequence Operations",
    x = "Number of elements",
    y = "Time",
    color = "Implementation"
  ) +
  scale_y_log10(labels = label_time, guide = "axis_logticks") +
  scale_color_manual(values = c("base R" = "#fc8d62", "flexseq" = "#66c2a5")) +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5), legend.position = "bottom")

plot(p_sequence)


##############################
### Ordered sequence benchmarks
##############################

ord_sizes <- 2^(14 + 0:6)
rows <- flexseq()

set.seed(99)
max_ord <- max(ord_sizes)
all_ord_keys <- sample.int(max_ord, max_ord, replace = TRUE) # duplicates present
all_ord_vals <- sprintf("e_%06d", seq_len(max_ord))

for(n in ord_sizes) {
  cat("Ordered sequence ops, size ", n, "\n")
  keys <- all_ord_keys[seq_len(n)]
  vals <- all_ord_vals[seq_len(n)]
  sk   <- sort(keys)
  
  # Query key and range bounds derive from the size-n subset so they always
  # land inside the key range; the range window spans a fixed number of keys
  # so result-set size k stays roughly constant (~50) as n grows.
  qk    <- sk[n %/% 2L]
  rlo   <- sk[n %/% 2L]
  rhi   <- sk[min(n, n %/% 2L + 50L)]
  ins_k <- qk
  
  ord_setup  <- function() list(os = as_ordered_sequence(as.list(vals), keys = keys))
  # Naive base R ordered map: a numeric key vector and a parallel value list,
  # sorted by key. All queries are plain linear scans over the real key vector
  # (no binary search, no key encoding), so the baseline is O(n) per op and
  # key-type-agnostic. Values live in a list, as the ordered_sequence stores
  # arbitrary element payloads.
  base_setup <- function() { o <- order(keys); list(k = keys[o], v = as.list(vals[o])) }
  
  rows <- bench_one(rows, "ordered_sequence", "insert", n, repeats, ord_setup,
                    function(st) insert(st$os, "e_new", ins_k))
  rows <- bench_one(rows, "ordered_sequence", "peek key", n, repeats, ord_setup,
                    function(st) peek_key(st$os, qk))
  rows <- bench_one(rows, "ordered_sequence", "pop key", n, repeats, ord_setup,
                    function(st) pop_key(st$os, qk)$remaining)
  rows <- bench_one(rows, "ordered_sequence", "count key", n, repeats, ord_setup,
                    function(st) count_key(st$os, qk))
  rows <- bench_one(rows, "ordered_sequence", "range query", n, repeats, ord_setup,
                    function(st) elements_between(st$os, rlo, rhi))
  rows <- bench_one(rows, "ordered_sequence", "lower bound", n, repeats, ord_setup,
                    function(st) lower_bound(st$os, qk))
  
  rows <- bench_one(rows, "base R", "insert", n, repeats, base_setup,
                    function(st) { p <- sum(st$k <= ins_k)
                    list(k = append(st$k, ins_k, p), v = append(st$v, list("e_new"), after = p)) })
  rows <- bench_one(rows, "base R", "peek key", n, repeats, base_setup,
                    function(st) st$v[[match(qk, st$k)]])
  rows <- bench_one(rows, "base R", "pop key", n, repeats, base_setup,
                    function(st) { i <- match(qk, st$k); list(k = st$k[-i], v = st$v[-i]) })
  rows <- bench_one(rows, "base R", "count key", n, repeats, base_setup,
                    function(st) sum(st$k == qk))
  rows <- bench_one(rows, "base R", "range query", n, repeats, base_setup,
                    function(st) st$v[st$k >= rlo & st$k <= rhi])
  rows <- bench_one(rows, "base R", "lower bound", n, repeats, base_setup,
                    function(st) which.max(st$k >= qk))
}

ord_results <- do.call(rbind, as.list(rows))

# plot ordered sequence results
sorted_sizes <- sort(unique(ord_results$n))
ord_results$n_cat <- factor(ord_results$n, levels = sorted_sizes)

p_ordered <- ggplot(ord_results, aes(x = n_cat, y = as.numeric(time_s), color = impl)) +
  geom_boxplot() +
  facet_wrap(~ op, scales = "free_y") +
  scale_x_discrete(labels = pow2_labels) +
  labs(
    title = "Ordered Sequence Operations",
    x = "Number of elements",
    y = "Time",
    color = "Implementation"
  ) +
  theme_bw() +
  scale_color_manual(values = c("base R" = "#fc8d62", "ordered_sequence" = "#66c2a5")) +
  scale_y_log10(labels = label_time, guide = "axis_logticks") +
  theme(plot.title = element_text(hjust = 0.5), legend.position = "bottom")

plot(p_ordered)


##############################
### Priority queue benchmarks
##############################

pq_sizes <- 2^(12 + 0:6)

rows <- flexseq()

set.seed(42)
max_pq <- max(pq_sizes)
all_pq_vals <- sprintf("val_%06d", seq_len(max_pq))
all_pq_pri  <- runif(max_pq)

for(n in pq_sizes) {
  cat("Priority queue ops, size ", n, "\n")
  pv <- as.list(all_pq_vals[seq_len(n)])
  pw <- all_pq_pri[seq_len(n)]
  pq_setup   <- function() list(pq = as_priority_queue(pv, priorities = pw))
  # Values in a list (arbitrary payloads, as the priority_queue stores);
  # priorities in a numeric vector.
  base_setup <- function() list(v = as.list(all_pq_vals[seq_len(n)]), p = pw)
  
  rows <- bench_one(rows, "priority_queue", "insert",   n, repeats, pq_setup,
                    function(st) insert(st$pq, "val_new", 0.5))
  rows <- bench_one(rows, "priority_queue", "peek max", n, repeats, pq_setup,
                    function(st) peek_max(st$pq))
  rows <- bench_one(rows, "priority_queue", "pop max",  n, repeats, pq_setup,
                    function(st) pop_max(st$pq)$remaining)
  
  rows <- bench_one(rows, "base R", "insert",   n, repeats, base_setup,
                    function(st) list(values = c(st$v, list("val_new")), priorities = c(st$p, 0.5)))
  rows <- bench_one(rows, "base R", "peek max", n, repeats, base_setup,
                    function(st) st$v[[which.max(st$p)]])
  rows <- bench_one(rows, "base R", "pop max",  n, repeats, base_setup,
                    function(st) { i <- which.max(st$p); list(values = st$v[-i], priorities = st$p[-i]) })
}

pq_results <- do.call(rbind, as.list(rows))

# plot priority queue results
sorted_sizes <- sort(unique(pq_results$n))
pq_results$n_cat <- factor(pq_results$n, levels = sorted_sizes)

p_pq <- ggplot(pq_results, aes(x = n_cat, y = as.numeric(time_s), color = impl)) +
  geom_boxplot() +
  facet_wrap(~ op, scales = "free_y") +
  scale_x_discrete(labels = pow2_labels) +
  labs(
    title = "Priority Queue Operations",
    x = "Number of elements",
    y = "Time",
    color = "Implementation"
  ) +
  theme_bw() +
  scale_color_manual(values = c("base R" = "#fc8d62", "priority_queue" = "#66c2a5")) +
  scale_y_log10(labels = label_time, guide = "axis_logticks") +
  theme(plot.title = element_text(hjust = 0.5), legend.position = "bottom")

plot(p_pq)


##############################
### Interval index benchmarks
##############################

library(IRanges)

ivx_sizes <- 2^(12 + 0:6)

rows <- flexseq()

set.seed(123)
max_ivx <- max(ivx_sizes)
all_starts <- sort(sample.int(max_ivx * 10L, max_ivx))
all_widths <- sample.int(100L, max_ivx, replace = TRUE)
all_ends   <- all_starts + all_widths
all_vals   <- sprintf("interval_%06d", seq_len(max_ivx))

for(n in ivx_sizes) {
  cat("Interval ops, size ", n, "\n")
  starts <- all_starts[seq_len(n)]
  ends   <- all_ends[seq_len(n)]
  vals   <- all_vals[seq_len(n)]
  
  # Query and insertion points are derived from the size-n subset so they fall
  # inside the indexed coordinate range at every size, and the overlap window
  # spans a fixed number of starts so result-set size k stays constant
  # (~50 matches) as n grows. (Fixed global points computed from the largest
  # size would fall beyond the data for smaller n, timing only the
  # empty-result path.)
  qpt   <- starts[n %/% 2L]
  qlo   <- starts[n %/% 2L]
  qhi   <- starts[n %/% 2L + 50L]
  ins_s <- starts[n %/% 2L]
  ins_e <- ins_s + 50L
  
  ivx_setup  <- function() list(ix = as_interval_index(as.list(vals), start = starts, end = ends, default_query_bounds = "[]"))
  # Endpoints in a data.frame (the natural interval table); payloads in a
  # parallel list, as the interval_index stores arbitrary value objects.
  df_setup   <- function() list(df = data.frame(start = starts, end = ends), value = as.list(vals))
  
  rows <- bench_one(rows, "interval_index", "insert", n, repeats, ivx_setup,
                    function(st) insert(st$ix, "interval_new", ins_s, ins_e))
  rows <- bench_one(rows, "interval_index", "point query", n, repeats, ivx_setup,
                    function(st) peek_point(st$ix, qpt, bounds = "[]"))
  rows <- bench_one(rows, "interval_index", "all point matches", n, repeats, ivx_setup,
                    function(st) peek_all_point(st$ix, qpt, bounds = "[]", as_list = TRUE))
  rows <- bench_one(rows, "interval_index", "overlap query", n, repeats, ivx_setup,
                    function(st) peek_all_overlapping(st$ix, qlo, qhi, bounds = "[]", as_list = TRUE))
  rows <- bench_one(rows, "interval_index", "within query", n, repeats, ivx_setup,
                    function(st) peek_all_within(st$ix, qlo, qhi, bounds = "[]", as_list = TRUE))
  rows <- bench_one(rows, "interval_index", "remove by overlap", n, repeats, ivx_setup,
                    function(st) pop_all_overlapping(st$ix, qlo, qhi, bounds = "[]")$remaining)
  
  rows <- bench_one(rows, "base R", "insert", n, repeats, df_setup,
                    function(st) list(
                      df = rbind(st$df, data.frame(start = ins_s, end = ins_e)),
                      value = c(st$value, list("interval_new"))
                    ))
  rows <- bench_one(rows, "base R", "point query", n, repeats, df_setup,
                    function(st) {
                      hits <- which(st$df$start <= qpt & qpt <= st$df$end)
                      if(length(hits)) st$value[[hits[1L]]] else NULL
                    })
  rows <- bench_one(rows, "base R", "all point matches", n, repeats, df_setup,
                    function(st) st$value[st$df$start <= qpt & qpt <= st$df$end])
  rows <- bench_one(rows, "base R", "overlap query", n, repeats, df_setup,
                    function(st) st$value[st$df$start <= qhi & st$df$end >= qlo])
  rows <- bench_one(rows, "base R", "within query", n, repeats, df_setup,
                    function(st) st$value[st$df$start >= qlo & st$df$end <= qhi])
  rows <- bench_one(rows, "base R", "remove by overlap", n, repeats, df_setup,
                    function(st) { keep <- !(st$df$start <= qhi & st$df$end >= qlo)
                    list(df = st$df[keep, , drop = FALSE], value = st$value[keep]) })
  
    ir_setup <- function() list(
    ir = IRanges::IRanges(start = starts, end = ends),
    v  = as.list(vals)
  )
  
  rows <- bench_one(rows, "IRanges", "insert", n, repeats, ir_setup,
                    function(st) list(
                      ir = c(st$ir, IRanges::IRanges(start = ins_s, end = ins_e)),
                      v  = c(st$v, list("interval_new"))
                    ))
  rows <- bench_one(rows, "IRanges", "point query", n, repeats, ir_setup,
                    function(st) {
                      hits <- S4Vectors::subjectHits(IRanges::findOverlaps(IRanges::IRanges(start = qpt, width = 1L), st$ir))
                      if(length(hits)) st$v[[hits[1L]]] else NULL
                    })
  rows <- bench_one(rows, "IRanges", "all point matches", n, repeats, ir_setup,
                    function(st) {
                      st$v[S4Vectors::subjectHits(IRanges::findOverlaps(IRanges::IRanges(start = qpt, width = 1L), st$ir))]
                    })
  rows <- bench_one(rows, "IRanges", "overlap query", n, repeats, ir_setup,
                    function(st) {
                      st$v[S4Vectors::subjectHits(IRanges::findOverlaps(IRanges::IRanges(start = qlo, end = qhi), st$ir))]
                    })
  rows <- bench_one(rows, "IRanges", "within query", n, repeats, ir_setup,
                    function(st) {
                      st$v[S4Vectors::queryHits(IRanges::findOverlaps(st$ir, IRanges::IRanges(start = qlo, end = qhi), type = "within"))]
                    })
  rows <- bench_one(rows, "IRanges", "remove by overlap", n, repeats, ir_setup,
                    function(st) {
                      hits <- S4Vectors::subjectHits(IRanges::findOverlaps(IRanges::IRanges(start = qlo, end = qhi), st$ir))
                      keep <- setdiff(seq_along(st$v), hits)
                      list(ir = st$ir[keep], v = st$v[keep])
                    })
}

ivx_results <- do.call(rbind, as.list(rows))

# plot interval index benchmark results
sorted_sizes <- sort(unique(ivx_results$n))
ivx_results$n_cat <- factor(ivx_results$n, levels = sorted_sizes)
ivx_results$impl <- factor(ivx_results$impl, levels = c("base R", "IRanges", "interval_index"))

p_ivx <- ggplot(ivx_results, aes(x = n_cat, y = as.numeric(time_s), color = impl)) +
  geom_boxplot(position = position_dodge()) +
  facet_wrap(~ op, scales = "free_y") +
  scale_x_discrete(labels = pow2_labels) +
  labs(
    title = "Interval Index Queries",
    x = "Number of elements",
    y = "Time",
    color = "Implementation"
  ) +
  theme_bw() +
  scale_color_manual(values = c("base R" = "#fc8d62", "IRanges" = "#8da0cb", "interval_index" = "#66c2a5")) +
  scale_y_log10(labels = label_time, guide = "axis_logticks") +
  theme(plot.title = element_text(hjust = 0.5), legend.position = "bottom")

plot(p_ivx)






