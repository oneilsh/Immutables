# Wave + clear-wave demo for immutables.
#
# Structures used:
# - priority_queue: schedule add/clear events by time
# - ordered_sequence: active cell set keyed by cell id (insert + pop_key)
# - flexseq: immutable snapshot timeline for animation

load_immutables <- function() {
  if(requireNamespace("pkgload", quietly = TRUE)) {
    pkgload::load_all(".", quiet = TRUE)
    return(invisible(TRUE))
  }
  if(requireNamespace("immutables", quietly = TRUE)) {
    library(immutables)
    return(invisible(TRUE))
  }
  stop("Need either installed 'immutables' or the 'pkgload' package.")
}

wave_complexity_config <- function(complexity = c("simple", "standard", "complex")) {
  complexity <- match.arg(complexity)
  if(identical(complexity, "simple")) {
    return(list(
      complexity = complexity,
      width = 54L,
      height = 32L,
      obstacle_density = 0.20,
      weight_min = 1L,
      weight_max = 5L,
      priority_band = 0,
      clear_lag = 8L,
      seed = 91L,
      max_animation_frames = 160L
    ))
  }
  if(identical(complexity, "complex")) {
    return(list(
      complexity = complexity,
      width = 100L,
      height = 58L,
      obstacle_density = 0.25,
      weight_min = 1L,
      weight_max = 6L,
      priority_band = 0,
      clear_lag = 14L,
      seed = 209L,
      max_animation_frames = 260L
    ))
  }
  list(
    complexity = "standard",
    width = 78L,
    height = 44L,
    obstacle_density = 0.23,
    weight_min = 1L,
    weight_max = 5L,
    priority_band = 0,
    clear_lag = 11L,
    seed = 143L,
    max_animation_frames = 210L
  )
}

resolve_wave_config <- function(
  complexity = c("simple", "standard", "complex"),
  width = NULL,
  height = NULL,
  obstacle_density = NULL,
  weight_min = NULL,
  weight_max = NULL,
  priority_band = NULL,
  clear_lag = NULL,
  seed = NULL,
  max_animation_frames = NULL
) {
  cfg <- wave_complexity_config(match.arg(complexity))
  if(!is.null(width)) cfg$width <- as.integer(width)
  if(!is.null(height)) cfg$height <- as.integer(height)
  if(!is.null(obstacle_density)) cfg$obstacle_density <- as.numeric(obstacle_density)
  if(!is.null(weight_min)) cfg$weight_min <- as.integer(weight_min)
  if(!is.null(weight_max)) cfg$weight_max <- as.integer(weight_max)
  if(!is.null(priority_band)) cfg$priority_band <- as.numeric(priority_band)
  if(!is.null(clear_lag)) cfg$clear_lag <- as.integer(clear_lag)
  if(!is.null(seed)) cfg$seed <- as.integer(seed)
  if(!is.null(max_animation_frames)) cfg$max_animation_frames <- as.integer(max_animation_frames)

  cfg$width <- max(20L, cfg$width)
  cfg$height <- max(16L, cfg$height)
  cfg$obstacle_density <- max(0.05, min(0.35, cfg$obstacle_density))
  cfg$weight_min <- max(1L, cfg$weight_min)
  cfg$weight_max <- max(cfg$weight_min, cfg$weight_max)
  cfg$priority_band <- max(0, cfg$priority_band)
  cfg$clear_lag <- max(2L, cfg$clear_lag)
  cfg
}

cell_id <- function(x, y) {
  paste0(x, ",", y)
}

cell_key <- function(x, y, width) {
  as.integer((y - 1L) * width + x)
}

smooth_noise <- function(m, passes = 2L) {
  w <- nrow(m)
  h <- ncol(m)
  out <- m

  for(p in seq_len(as.integer(max(1L, passes)))) {
    cur <- out
    nxt <- cur
    for(x in 2L:(w - 1L)) {
      for(y in 2L:(h - 1L)) {
        nxt[x, y] <- (
          cur[x, y] * 3 +
          cur[x - 1L, y] + cur[x + 1L, y] + cur[x, y - 1L] + cur[x, y + 1L] +
          0.5 * (cur[x - 1L, y - 1L] + cur[x - 1L, y + 1L] + cur[x + 1L, y - 1L] + cur[x + 1L, y + 1L])
        ) / 9
      }
    }
    out <- nxt
  }

  out
}

rescale01 <- function(x) {
  r <- range(x, na.rm = TRUE)
  if(!is.finite(r[[1L]]) || !is.finite(r[[2L]]) || abs(r[[2L]] - r[[1L]]) < 1e-12) {
    return(matrix(0.5, nrow = nrow(x), ncol = ncol(x)))
  }
  (x - r[[1L]]) / (r[[2L]] - r[[1L]])
}

smooth_blocks <- function(blocked, passes = 2L) {
  w <- nrow(blocked)
  h <- ncol(blocked)
  cur <- blocked
  if(w < 3L || h < 3L) return(cur)

  for(p in seq_len(as.integer(max(1L, passes)))) {
    nxt <- cur
    for(x in 2L:(w - 1L)) {
      for(y in 2L:(h - 1L)) {
        n8 <- sum(cur[(x - 1L):(x + 1L), (y - 1L):(y + 1L)]) - as.integer(cur[x, y])
        if(n8 >= 5L) {
          nxt[x, y] <- TRUE
        } else if(n8 <= 2L) {
          nxt[x, y] <- FALSE
        }
      }
    }
    cur <- nxt
  }
  cur
}

nearest_open_cell <- function(blocked, x0, y0) {
  w <- nrow(blocked)
  h <- ncol(blocked)
  if(!blocked[x0, y0]) return(c(x = x0, y = y0))

  max_r <- max(w, h)
  for(r in seq_len(max_r)) {
    xs <- max(1L, x0 - r):min(w, x0 + r)
    ys <- max(1L, y0 - r):min(h, y0 + r)
    cand <- expand.grid(x = xs, y = ys)
    if(nrow(cand) == 0L) next
    d <- abs(cand$x - x0) + abs(cand$y - y0)
    ord <- order(d)
    cand <- cand[ord, , drop = FALSE]

    for(i in seq_len(nrow(cand))) {
      xi <- as.integer(cand$x[[i]])
      yi <- as.integer(cand$y[[i]])
      if(!blocked[xi, yi]) return(c(x = xi, y = yi))
    }
  }

  stop("No open cell found.")
}

bfs_reachable <- function(blocked, source_x, source_y) {
  w <- nrow(blocked)
  h <- ncol(blocked)

  dist <- matrix(-1L, nrow = w, ncol = h)
  qx <- integer(w * h)
  qy <- integer(w * h)
  head <- 1L
  tail <- 1L

  dist[source_x, source_y] <- 0L
  qx[[tail]] <- source_x
  qy[[tail]] <- source_y

  dirs <- rbind(c(1L, 0L), c(-1L, 0L), c(0L, 1L), c(0L, -1L))

  while(head <= tail) {
    x <- qx[[head]]
    y <- qy[[head]]
    head <- head + 1L

    d0 <- dist[x, y]
    for(k in 1:4) {
      nx <- x + dirs[k, 1L]
      ny <- y + dirs[k, 2L]
      if(nx < 1L || nx > w || ny < 1L || ny > h) next
      if(blocked[nx, ny]) next
      if(dist[nx, ny] >= 0L) next

      dist[nx, ny] <- d0 + 1L
      tail <- tail + 1L
      qx[[tail]] <- nx
      qy[[tail]] <- ny
    }
  }

  idx <- which(dist >= 0L, arr.ind = TRUE)
  data.frame(
    x = as.integer(idx[, 1L]),
    y = as.integer(idx[, 2L]),
    d = as.integer(dist[idx]),
    stringsAsFactors = FALSE
  )
}

dijkstra_reachable <- function(blocked, weights, source_x, source_y) {
  load_immutables()

  w <- nrow(blocked)
  h <- ncol(blocked)
  dist <- matrix(Inf, nrow = w, ncol = h)
  parent <- matrix(NA_character_, nrow = w, ncol = h)
  dist[source_x, source_y] <- 0

  q <- priority_queue()
  q <- insert(
    q,
    element = list(x = as.integer(source_x), y = as.integer(source_y), id = cell_id(source_x, source_y)),
    priority = 0
  )

  dirs <- rbind(c(1L, 0L), c(-1L, 0L), c(0L, 1L), c(0L, -1L))

  while(length(q) > 0L) {
    popped <- pop_min(q)
    cur <- if(!is.null(popped$element)) popped$element else popped$value
    q <- if(!is.null(popped$remaining)) popped$remaining else popped$rest
    if(is.null(cur) || is.null(popped$priority)) break

    x <- as.integer(cur$x)
    y <- as.integer(cur$y)
    d0 <- as.numeric(popped$priority)
    if(d0 > dist[x, y] + 1e-9) next

    for(k in 1:4) {
      nx <- x + dirs[k, 1L]
      ny <- y + dirs[k, 2L]
      if(nx < 1L || nx > w || ny < 1L || ny > h) next
      if(blocked[nx, ny]) next

      step_cost <- as.numeric(weights[nx, ny])
      if(!is.finite(step_cost) || step_cost <= 0) next

      nd <- d0 + step_cost
      if(nd + 1e-9 < dist[nx, ny]) {
        dist[nx, ny] <- nd
        parent[nx, ny] <- cell_id(x, y)
        q <- insert(
          q,
          element = list(x = as.integer(nx), y = as.integer(ny), id = cell_id(nx, ny)),
          priority = nd
        )
      }
    }
  }

  idx <- which(is.finite(dist), arr.ind = TRUE)
  ids <- paste0(idx[, 1L], ",", idx[, 2L])
  parent_ids <- parent[idx]
  data.frame(
    id = ids,
    x = as.integer(idx[, 1L]),
    y = as.integer(idx[, 2L]),
    d = as.numeric(dist[idx]),
    weight = as.numeric(weights[idx]),
    parent = as.character(parent_ids),
    stringsAsFactors = FALSE
  )
}

choose_goal_cell <- function(reach, width, height, source_x, source_y) {
  src_id <- cell_id(source_x, source_y)
  cand <- reach[reach$id != src_id, , drop = FALSE]
  if(nrow(cand) == 0L) {
    return(list(id = src_id, x = as.integer(source_x), y = as.integer(source_y), d = 0))
  }

  right_gate <- as.integer(round(width * 0.72))
  right <- cand[cand$x >= right_gate, , drop = FALSE]
  if(nrow(right) > 0L) cand <- right

  ymid <- as.numeric(height / 2)
  d_norm <- if(max(cand$d) > min(cand$d)) (cand$d - min(cand$d)) / (max(cand$d) - min(cand$d)) else rep(0, nrow(cand))
  x_norm <- if(max(cand$x) > min(cand$x)) (cand$x - min(cand$x)) / (max(cand$x) - min(cand$x)) else rep(0, nrow(cand))
  y_pen <- abs(cand$y - ymid) / max(1, ymid)
  score <- 0.72 * d_norm + 0.36 * x_norm - 0.12 * y_pen

  i <- which.max(score)
  list(
    id = as.character(cand$id[[i]]),
    x = as.integer(cand$x[[i]]),
    y = as.integer(cand$y[[i]]),
    d = as.numeric(cand$d[[i]])
  )
}

reconstruct_solution_path <- function(reach, source_id, goal_id) {
  if(nrow(reach) == 0L) {
    return(data.frame(id = character(0), x = integer(0), y = integer(0), d = numeric(0), stringsAsFactors = FALSE))
  }

  id_to_row <- setNames(seq_len(nrow(reach)), reach$id)
  parent_map <- setNames(reach$parent, reach$id)

  cur <- as.character(goal_id)
  rev_ids <- character(0)
  seen <- character(0)
  for(i in seq_len(nrow(reach) + 2L)) {
    if(is.na(cur) || !nzchar(cur)) break
    if(!(cur %in% names(id_to_row))) break
    if(cur %in% seen) break
    rev_ids <- c(rev_ids, cur)
    seen <- c(seen, cur)
    if(identical(cur, as.character(source_id))) break
    cur <- as.character(parent_map[[cur]])
  }

  if(length(rev_ids) == 0L || !identical(rev_ids[[length(rev_ids)]], as.character(source_id))) {
    return(data.frame(id = character(0), x = integer(0), y = integer(0), d = numeric(0), stringsAsFactors = FALSE))
  }

  ids <- rev(rev_ids)
  rows <- as.integer(id_to_row[ids])
  out <- reach[rows, c("id", "x", "y", "d"), drop = FALSE]
  rownames(out) <- NULL
  out
}

generate_wave_grid <- function(
  width = 78L,
  height = 44L,
  obstacle_density = 0.17,
  weight_min = 1L,
  weight_max = 5L,
  seed = 143L
) {
  stopifnot(width >= 20L, height >= 16L)

  attempt <- 0L
  repeat {
    attempt <- attempt + 1L
    set.seed(as.integer(seed + attempt - 1L))

    raw_a <- matrix(stats::runif(width * height), nrow = width, ncol = height)
    raw_b <- matrix(stats::runif(width * height), nrow = width, ncol = height)
    sm_a <- smooth_noise(raw_a, passes = 3L)
    sm_b <- smooth_noise(raw_b, passes = 5L)

    xg <- matrix(rep(seq(0, 1, length.out = width), height), nrow = width, ncol = height)
    yg <- matrix(rep(seq(0, 1, length.out = height), each = width), nrow = width, ncol = height)
    ridge <- sin(2 * pi * (1.35 * xg + 0.65 * yg + stats::runif(1L, 0, 1))) +
      0.7 * sin(2 * pi * (2.2 * xg - 1.1 * yg + stats::runif(1L, 0, 1)))

    terrain <- 0.48 * rescale01(sm_a) + 0.34 * rescale01(sm_b) + 0.18 * rescale01(ridge)
    rough <- rescale01(0.56 * abs(sm_a - sm_b) + 0.44 * abs(ridge))
    weight_score <- 0.58 * rough + 0.42 * rescale01(terrain)

    th <- as.numeric(stats::quantile(terrain, probs = 1 - obstacle_density, names = FALSE))
    blocked <- terrain >= th
    blocked <- smooth_blocks(blocked, passes = 2L)

    blocked[1L, ] <- TRUE
    blocked[width, ] <- TRUE
    blocked[, 1L] <- TRUE
    blocked[, height] <- TRUE

    # Carve a small source basin so the launch point is visible but not a broad corridor.
    ymid <- as.integer(round(height / 2))
    xr <- 2L:min(6L, width - 1L)
    yr <- max(2L, ymid - 2L):min(height - 1L, ymid + 2L)
    blocked[xr, yr] <- FALSE

    src0 <- c(x = 3L, y = as.integer(round(height / 2)))
    src <- nearest_open_cell(blocked, src0[["x"]], src0[["y"]])
    blocked[src[["x"]], src[["y"]]] <- FALSE

    # Map open-cell terrain scores to the full integer weight range for visible diversity.
    weights <- matrix(NA_integer_, nrow = width, ncol = height)
    open_mask <- !blocked
    score_open <- as.numeric(weight_score[open_mask])
    if(length(score_open) > 0L) {
      if(length(score_open) == 1L) {
        scaled <- 0
      } else {
        scaled <- (rank(score_open, ties.method = "average") - 1) / (length(score_open) - 1)
      }
      mapped <- as.integer(round(weight_min + scaled * (weight_max - weight_min)))
      mapped <- pmax(as.integer(weight_min), pmin(as.integer(weight_max), mapped))
      weights[open_mask] <- mapped
    }
    weights[xr, yr] <- as.integer(weight_min)
    weights[src[["x"]], src[["y"]]] <- as.integer(weight_min)

    reach <- dijkstra_reachable(blocked, weights, src[["x"]], src[["y"]])
    open_n <- sum(!blocked)
    frac <- if(open_n > 0L) nrow(reach) / open_n else 0

    if(frac >= 0.45 || attempt >= 12L) {
      source_id <- cell_id(src[["x"]], src[["y"]])
      goal <- choose_goal_cell(reach, width = width, height = height, source_x = src[["x"]], source_y = src[["y"]])
      solution_path <- reconstruct_solution_path(reach, source_id = source_id, goal_id = goal$id)

      wall_idx <- which(blocked, arr.ind = TRUE)
      walls <- data.frame(x = wall_idx[, 1L], y = wall_idx[, 2L], stringsAsFactors = FALSE)

      base <- expand.grid(x = seq_len(width), y = seq_len(height))
      base$node <- paste0(base$x, ",", base$y)
      wall_node <- paste0(walls$x, ",", walls$y)
      base$is_wall <- base$node %in% wall_node
      base$weight <- as.integer(weights[cbind(base$x, base$y)])
      base$d <- NA_real_
      if(nrow(reach) > 0L) {
        rid <- paste0(reach$x, ",", reach$y)
        mi <- match(rid, base$node)
        keep <- !is.na(mi)
        base$d[mi[keep]] <- as.numeric(reach$d[keep])
      }
      base$reachable <- !is.na(base$d)
      base$is_source <- base$node == source_id
      base$is_goal <- base$node == goal$id
      base$on_solution <- base$node %in% solution_path$id

      return(list(
        width = as.integer(width),
        height = as.integer(height),
        blocked = blocked,
        weights = weights,
        walls = walls,
        base = base,
        source_x = as.integer(src[["x"]]),
        source_y = as.integer(src[["y"]]),
        source_id = source_id,
        goal_x = as.integer(goal$x),
        goal_y = as.integer(goal$y),
        goal_id = as.character(goal$id),
        goal_d = as.numeric(goal$d),
        solution_path = solution_path,
        reachable = reach
      ))
    }
  }
}

build_wave_queues <- function(reachable, clear_lag = 11L, width = 78L) {
  add_q <- priority_queue()
  clear_q <- priority_queue()

  for(i in seq_len(nrow(reachable))) {
    x <- as.integer(reachable$x[[i]])
    y <- as.integer(reachable$y[[i]])
    d <- as.numeric(reachable$d[[i]])
    id <- cell_id(x, y)
    key <- cell_key(x, y, width)

    ev <- list(id = id, x = x, y = y, d = d, key = key)
    add_q <- insert(add_q, element = ev, priority = d)

    cev <- ev
    cev$clear_t <- as.numeric(d + clear_lag)
    clear_q <- insert(clear_q, element = cev, priority = as.numeric(d + clear_lag))
  }

  list(add_q = add_q, clear_q = clear_q)
}

queue_min_priority <- function(queue) {
  if(length(queue) == 0L) return(Inf)
  popped <- pop_min(queue)
  if(is.null(popped$priority)) return(Inf)
  as.numeric(popped$priority)
}

pop_events_by_priority_band <- function(queue, anchor_priority, priority_band = 0) {
  out <- list()
  i <- 0L
  q <- queue
  limit <- as.numeric(anchor_priority) + as.numeric(priority_band)

  repeat {
    if(length(q) == 0L) break

    popped <- pop_min(q)
    ev <- if(!is.null(popped$element)) popped$element else popped$value
    pr <- popped$priority
    rem <- if(!is.null(popped$remaining)) popped$remaining else popped$rest

    if(is.null(ev) || is.null(pr)) {
      q <- rem
      break
    }

    if(as.numeric(pr) <= (as.numeric(limit) + 1e-9)) {
      i <- i + 1L
      out[[i]] <- ev
      q <- rem
    } else {
      q <- insert(rem, element = ev, priority = pr)
      break
    }
  }

  list(queue = q, events = out)
}

active_seq_to_df <- function(active_seq) {
  if(length(active_seq) == 0L) {
    return(data.frame(id = character(0), x = integer(0), y = integer(0), d = numeric(0), stringsAsFactors = FALSE))
  }

  el <- as.list(active_seq)
  data.frame(
    id = vapply(el, function(e) as.character(e$id), character(1)),
    x = vapply(el, function(e) as.integer(e$x), integer(1)),
    y = vapply(el, function(e) as.integer(e$y), integer(1)),
    d = vapply(el, function(e) as.numeric(e$d), numeric(1)),
    stringsAsFactors = FALSE
  )
}

events_to_df <- function(events) {
  if(length(events) == 0L) {
    return(data.frame(id = character(0), x = integer(0), y = integer(0), d = numeric(0), stringsAsFactors = FALSE))
  }

  data.frame(
    id = vapply(events, function(e) as.character(e$id), character(1)),
    x = vapply(events, function(e) as.integer(e$x), integer(1)),
    y = vapply(events, function(e) as.integer(e$y), integer(1)),
    d = vapply(events, function(e) as.numeric(e$d), numeric(1)),
    stringsAsFactors = FALSE
  )
}

make_wave_snapshot <- function(step, t_now, active, entering, clearing, add_q, clear_q, goal_reached = FALSE) {
  list(
    step = as.integer(step),
    t_now = as.numeric(t_now),
    active = active,
    entering = entering,
    clearing = clearing,
    add_q_size = as.integer(length(add_q)),
    clear_q_size = as.integer(length(clear_q)),
    active_count = as.integer(length(active)),
    goal_reached = isTRUE(goal_reached)
  )
}

run_wave_clear_immutables <- function(grid, clear_lag = 11L, priority_band = 0, track_snapshots = TRUE) {
  load_immutables()

  qs <- build_wave_queues(
    reachable = grid$reachable,
    clear_lag = clear_lag,
    width = grid$width
  )

  add_q <- qs$add_q
  clear_q <- qs$clear_q
  active <- ordered_sequence()
  snapshots <- if(isTRUE(track_snapshots)) flexseq() else NULL

  step <- 0L
  t_now <- 0L
  peak_active <- 0L
  goal_reached <- FALSE
  goal_reached_step <- NA_integer_
  goal_reached_time <- NA_real_

  if(isTRUE(track_snapshots)) {
    snapshots <- push_back(
      snapshots,
      make_wave_snapshot(
        step = step,
        t_now = t_now,
        active = active,
        entering = events_to_df(list()),
        clearing = events_to_df(list()),
        add_q = add_q,
        clear_q = clear_q,
        goal_reached = goal_reached
      )
    )
  }

  t_guard <- as.numeric(ceiling(max(grid$reachable$d) + clear_lag + 5))
  priority_band <- as.numeric(max(0, priority_band))

  repeat {
    next_add <- queue_min_priority(add_q)
    next_clr <- queue_min_priority(clear_q)
    next_t <- min(next_add, next_clr)

    done <- (length(add_q) == 0L && length(clear_q) == 0L && length(active) == 0L)
    if(done) break
    if(!is.finite(next_t) || next_t > t_guard) break

    t_now <- as.numeric(next_t)

    entering <- list()
    if(is.finite(next_add) && (next_add <= (next_t + 1e-9))) {
      add_out <- pop_events_by_priority_band(add_q, anchor_priority = next_add, priority_band = priority_band)
      add_q <- add_out$queue
      entering <- add_out$events
    }

    if(length(entering) > 0L) {
      for(ev in entering) {
        active <- insert(
          active,
          element = list(id = ev$id, x = as.integer(ev$x), y = as.integer(ev$y), d = as.numeric(ev$d)),
          key = as.integer(ev$key)
        )
      }
    }

    clearing <- list()
    if(is.finite(next_clr) && (next_clr <= (next_t + 1e-9))) {
      clr_out <- pop_events_by_priority_band(clear_q, anchor_priority = next_clr, priority_band = priority_band)
      clear_q <- clr_out$queue
      clearing <- clr_out$events
    }

    if(length(clearing) > 0L) {
      for(ev in clearing) {
        popped <- pop_key(active, as.integer(ev$key))
        active <- popped$remaining
      }
    }

    if(!goal_reached && length(entering) > 0L) {
      entered_ids <- vapply(entering, function(ev) as.character(ev$id), character(1))
      if(any(entered_ids == grid$goal_id)) {
        goal_reached <- TRUE
        goal_reached_time <- as.numeric(t_now)
      }
    }

    step <- step + 1L
    if(goal_reached && is.na(goal_reached_step)) {
      goal_reached_step <- as.integer(step)
    }
    peak_active <- max(peak_active, as.integer(length(active)))

    if(isTRUE(track_snapshots)) {
      snapshots <- push_back(
        snapshots,
        make_wave_snapshot(
          step = step,
          t_now = t_now,
          active = active,
          entering = events_to_df(entering),
          clearing = events_to_df(clearing),
          add_q = add_q,
          clear_q = clear_q,
          goal_reached = goal_reached
        )
      )
    }

    done <- (length(add_q) == 0L && length(clear_q) == 0L && length(active) == 0L)
    if(done) break
  }

  list(
    found = TRUE,
    steps = as.integer(step),
    time_steps = as.integer(ceiling(t_now + 1)),
    peak_active = as.integer(peak_active),
    clear_lag = as.integer(clear_lag),
    priority_band = as.numeric(priority_band),
    goal_reached = goal_reached,
    goal_reached_step = goal_reached_step,
    goal_reached_time = goal_reached_time,
    snapshots = snapshots,
    grid = grid
  )
}

plot_wave_clear_snapshots <- function(
  result,
  animate = TRUE,
  outfile = NULL,
  fps = 10,
  max_animation_frames = 210L,
  frame_stride = NULL,
  hold_final_frames = 12L,
  loop = TRUE,
  width_px = 730L,
  height_px = 410L
) {
  if(is.null(result$snapshots)) {
    stop("No snapshots available. Re-run with `track_snapshots = TRUE`.")
  }
  if(!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Please install 'ggplot2' to visualize snapshots.")
  }

  shots <- as.list(result$snapshots)
  nshots <- length(shots)
  if(nshots == 0L) stop("No snapshots to render.")

  if(is.null(frame_stride)) {
    frame_stride <- max(1L, as.integer(ceiling(nshots / as.integer(max_animation_frames))))
  } else {
    frame_stride <- max(1L, as.integer(frame_stride))
  }

  frame_idx <- seq_len(nshots)
  frame_idx <- frame_idx[seq.int(1L, length(frame_idx), by = frame_stride)]
  if(frame_idx[[length(frame_idx)]] != nshots) {
    frame_idx <- c(frame_idx, nshots)
  }

  base <- result$grid$base
  source_df <- data.frame(x = result$grid$source_x, y = result$grid$source_y)
  goal_df <- data.frame(x = result$grid$goal_x, y = result$grid$goal_y)
  path_all <- result$grid$solution_path
  w_min <- min(base$weight, na.rm = TRUE)
  w_max <- max(base$weight, na.rm = TRUE)
  x_lims <- c(0.5, result$grid$width + 0.5)
  y_lims <- c(result$grid$height + 0.5, 0.5)

  .frame_plot <- function(s) {
    d <- base

    active_df <- active_seq_to_df(s$active)
    akey <- character(0)
    if(nrow(active_df) > 0L) {
      akey <- paste0(active_df$x, ",", active_df$y)
    }

    entering_df <- s$entering
    clearing_df <- s$clearing
    is_active <- d$node %in% akey
    t_now <- as.numeric(s$t_now)
    lag <- as.numeric(result$clear_lag)
    dd <- as.numeric(d$d)
    life_frac <- ifelse(
      d$reachable & is_active & lag > 0,
      pmin(1, pmax(0, (t_now - dd) / lag)),
      NA_real_
    )
    d$active_alpha <- ifelse(is.na(life_frac), NA_real_, 0.18 + 0.62 * life_frac)

    heat_df <- d[!d$is_wall & d$reachable, , drop = FALSE]
    active_df_plot <- d[!d$is_wall & d$reachable & is_active, c("x", "y", "active_alpha"), drop = FALSE]
    unreachable_df <- d[!d$is_wall & !d$reachable, , drop = FALSE]
    wall_df <- d[d$is_wall, , drop = FALSE]
    path_df <- if(isTRUE(s$goal_reached)) path_all else path_all[0, , drop = FALSE]
    goal_hit <- isTRUE(s$goal_reached)

    ggplot2::ggplot() +
      ggplot2::geom_tile(
        data = heat_df,
        ggplot2::aes(x = x, y = y, fill = weight),
        color = "#151515",
        linewidth = 0.08
      ) +
      ggplot2::geom_tile(
        data = active_df_plot,
        ggplot2::aes(x = x, y = y, alpha = active_alpha),
        fill = "#F08A24",
        color = NA,
        show.legend = FALSE
      ) +
      ggplot2::geom_tile(
        data = entering_df,
        ggplot2::aes(x = x, y = y),
        fill = "#F08A24",
        color = NA,
        alpha = 0.96
      ) +
      ggplot2::geom_tile(
        data = clearing_df,
        ggplot2::aes(x = x, y = y),
        fill = "#D1495B",
        color = NA,
        alpha = 0.96
      ) +
      ggplot2::geom_tile(
        data = unreachable_df,
        ggplot2::aes(x = x, y = y),
        fill = "#D7DFEA",
        color = "#151515",
        linewidth = 0.08
      ) +
      ggplot2::geom_tile(
        data = wall_df,
        ggplot2::aes(x = x, y = y),
        fill = "#2A2A2A",
        color = "#2A2A2A",
        linewidth = 0.08
      ) +
      ggplot2::geom_point(
        data = source_df,
        ggplot2::aes(x = x, y = y),
        shape = 8,
        color = "#FFFFFF",
        size = 2.3,
        stroke = 0.6
      ) +
      ggplot2::geom_path(
        data = path_df,
        ggplot2::aes(x = x, y = y),
        color = "#111111",
        linewidth = 1.45,
        lineend = "round",
        linejoin = "round",
        inherit.aes = FALSE
      ) +
      ggplot2::geom_path(
        data = path_df,
        ggplot2::aes(x = x, y = y),
        color = "#FFE066",
        linewidth = 0.88,
        lineend = "round",
        linejoin = "round",
        inherit.aes = FALSE
      ) +
      ggplot2::geom_point(
        data = path_df,
        ggplot2::aes(x = x, y = y),
        color = "#FFE066",
        size = 0.75,
        alpha = 0.94,
        inherit.aes = FALSE
      ) +
      ggplot2::geom_point(
        data = goal_df,
        ggplot2::aes(x = x, y = y),
        shape = 21,
        fill = if(goal_hit) "#2AA876" else "#D1495B",
        color = "#FFFFFF",
        stroke = 0.55,
        size = 2.6,
        inherit.aes = FALSE
      ) +
      ggplot2::scale_alpha_continuous(range = c(0.18, 0.8), limits = c(0, 1), guide = "none") +
      ggplot2::scale_fill_gradientn(
        colours = c("#EFF5FF", "#D5E6FF", "#A8CBF4", "#6EA6E4", "#2C7BE5", "#124C9C"),
        limits = c(w_min, w_max),
        breaks = c(w_min, as.integer(round((w_min + w_max) / 2)), w_max),
        labels = c("light", "mid", "heavy"),
        name = "Terrain Weight"
      ) +
      ggplot2::coord_fixed(xlim = x_lims, ylim = y_lims, expand = FALSE, clip = "on") +
      ggplot2::scale_y_reverse(expand = c(0, 0)) +
      ggplot2::scale_x_continuous(expand = c(0, 0)) +
      ggplot2::labs(
        title = "Persistent Wave With Trailing Clear-Wave",
        subtitle = sprintf(
          "t=%.2f | active=%d | entering=%d | clearing=%d | addQ=%d | clearQ=%d | goal=%s | band=%.2f",
          s$t_now, s$active_count, nrow(entering_df), nrow(clearing_df), s$add_q_size, s$clear_q_size,
          if(goal_hit) "reached" else "searching", result$priority_band
        ),
        x = NULL,
        y = NULL
      ) +
      ggplot2::theme_minimal(base_size = 9) +
      ggplot2::theme(
        panel.grid = ggplot2::element_blank(),
        axis.text = ggplot2::element_blank(),
        axis.ticks = ggplot2::element_blank(),
        legend.position = "bottom"
      )
  }

  if(isTRUE(animate)) {
    if(!requireNamespace("gifski", quietly = TRUE)) {
      stop("Animation requested but 'gifski' is not installed.")
    }

    render_idx <- c(frame_idx, rep(frame_idx[[length(frame_idx)]], as.integer(max(0L, hold_final_frames))))

    frame_dir <- tempfile("wave-clear-frames-")
    dir.create(frame_dir, recursive = TRUE, showWarnings = FALSE)
    frame_paths <- file.path(frame_dir, sprintf("frame_%05d.png", seq_along(render_idx)))

    for(i in seq_along(render_idx)) {
      p <- .frame_plot(shots[[render_idx[[i]]]])
      ggplot2::ggsave(
        filename = frame_paths[[i]],
        plot = p,
        width = as.numeric(width_px) / 96,
        height = as.numeric(height_px) / 96,
        dpi = 96,
        units = "in"
      )
    }

    if(is.null(outfile)) {
      outfile <- tempfile("wave-clear-", fileext = ".gif")
    }

    gifski::gifski(
      png_files = frame_paths,
      gif_file = outfile,
      width = as.integer(width_px),
      height = as.integer(height_px),
      delay = 1 / fps,
      loop = isTRUE(loop),
      progress = FALSE
    )

    return(list(type = "animation", gif = outfile, frame_count = length(render_idx)))
  }

  p <- .frame_plot(shots[[frame_idx[[length(frame_idx)]]]])
  print(p)
  list(type = "static", plot = p, frame_count = length(frame_idx))
}

run_wave_clear_demo <- function(
  complexity = c("simple", "standard", "complex"),
  width = NULL,
  height = NULL,
  obstacle_density = NULL,
  weight_min = NULL,
  weight_max = NULL,
  priority_band = NULL,
  clear_lag = NULL,
  seed = NULL,
  visualize = TRUE,
  animate = TRUE,
  outfile = NULL,
  fps = 10,
  max_animation_frames = NULL,
  frame_stride = NULL,
  hold_final_frames = 12L,
  loop = TRUE,
  width_px = 730L,
  height_px = 410L,
  time_compute = TRUE,
  track_snapshots = TRUE
) {
  cfg <- resolve_wave_config(
    complexity = match.arg(complexity),
    width = width,
    height = height,
    obstacle_density = obstacle_density,
    weight_min = weight_min,
    weight_max = weight_max,
    priority_band = priority_band,
    clear_lag = clear_lag,
    seed = seed,
    max_animation_frames = max_animation_frames
  )

  grid <- generate_wave_grid(
    width = cfg$width,
    height = cfg$height,
    obstacle_density = cfg$obstacle_density,
    weight_min = cfg$weight_min,
    weight_max = cfg$weight_max,
    seed = cfg$seed
  )

  effective_track <- isTRUE(track_snapshots) || isTRUE(visualize)
  timing <- NULL
  if(isTRUE(time_compute)) {
    timing <- system.time({
      result <- run_wave_clear_immutables(
        grid = grid,
        clear_lag = cfg$clear_lag,
        priority_band = cfg$priority_band,
        track_snapshots = effective_track
      )
    })
    cat(
      sprintf(
        "Compute time (no render): user=%.3fs system=%.3fs elapsed=%.3fs\n",
        timing[[1L]], timing[[2L]], timing[[3L]]
      )
    )
  } else {
    result <- run_wave_clear_immutables(
      grid = grid,
      clear_lag = cfg$clear_lag,
      priority_band = cfg$priority_band,
      track_snapshots = effective_track
    )
  }

  viz <- NULL
  if(isTRUE(visualize)) {
    viz <- plot_wave_clear_snapshots(
      result,
      animate = animate,
      outfile = outfile,
      fps = fps,
      max_animation_frames = cfg$max_animation_frames,
      frame_stride = frame_stride,
      hold_final_frames = hold_final_frames,
      loop = loop,
      width_px = width_px,
      height_px = height_px
    )
  }

  list(
    config = cfg,
    reachable_cells = nrow(grid$reachable),
    mean_weight = round(mean(grid$reachable$weight, na.rm = TRUE), 3),
    priority_band = cfg$priority_band,
    steps = result$steps,
    peak_active = result$peak_active,
    goal_reached = isTRUE(result$goal_reached),
    goal_reached_step = result$goal_reached_step,
    solution_length = nrow(grid$solution_path),
    compute_timing = if(is.null(timing)) NULL else c(user = timing[[1L]], system = timing[[2L]], elapsed = timing[[3L]]),
    visualization = viz,
    result = result
  )
}

run_wave_clear_paper_core <- function(complexity = c("simple", "standard", "complex")) {
  cfg <- resolve_wave_config(complexity = match.arg(complexity))
  grid <- generate_wave_grid(
    width = cfg$width,
    height = cfg$height,
    obstacle_density = cfg$obstacle_density,
    weight_min = cfg$weight_min,
    weight_max = cfg$weight_max,
    seed = cfg$seed
  )
  out <- run_wave_clear_immutables(
    grid,
    clear_lag = cfg$clear_lag,
    priority_band = cfg$priority_band,
    track_snapshots = FALSE
  )

  list(
    width = cfg$width,
    height = cfg$height,
    reachable_cells = nrow(grid$reachable),
    weight_min = cfg$weight_min,
    weight_max = cfg$weight_max,
    mean_weight = round(mean(grid$reachable$weight, na.rm = TRUE), 3),
    priority_band = cfg$priority_band,
    clear_lag = cfg$clear_lag,
    steps = out$steps,
    peak_active = out$peak_active,
    goal_reached = isTRUE(out$goal_reached),
    goal_reached_step = out$goal_reached_step,
    solution_length = nrow(grid$solution_path)
  )
}

if(sys.nframe() == 0L) {
  demo <- run_wave_clear_demo(complexity = "standard", visualize = FALSE, animate = FALSE)
  cat("Wave clear demo\n")
  cat("Complexity:", demo$config$complexity, "\n")
  cat("Reachable cells:", demo$reachable_cells, "\n")
  cat("Steps:", demo$steps, "\n")
  cat("Peak active:", demo$peak_active, "\n")
  cat("Goal reached:", demo$goal_reached, "\n")
  cat("Goal reached step:", demo$goal_reached_step, "\n")
  cat("Solution length:", demo$solution_length, "\n")
}
