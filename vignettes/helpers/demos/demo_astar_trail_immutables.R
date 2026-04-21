# A* with heuristic trail — demo for the immutables package.
#
# Standard A* search over a weighted terrain grid, augmented with a lagged
# retirement "clear wave": as each cell is expanded from the frontier it
# enters a secondary ordered_sequence (`trail`), and a second priority_queue
# (`clear_q`) schedules its removal at step_expand + lag_base + lag_warp * h.
# Retirement fires lazily whenever the step counter has advanced past a
# scheduled clear. The result is a fading tail behind the A* frontier whose
# shape visibly encodes the heuristic (cells far from the goal linger; cells
# near the goal clear fast).
#
# Structures used:
# - priority_queue: A* open set (min by f = g + h)
# - priority_queue: clear schedule (min by scheduled clear-step)
# - ordered_sequence: closed/visited set (A* correctness)
# - ordered_sequence: trail (currently-visible cells for rendering)
# - flexseq: persistent timeline of snapshots for replay/visualization

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

node_id <- function(x, y) {
  paste0(x, ",", y)
}

parse_node_id <- function(id) {
  parts <- strsplit(id, ",", fixed = TRUE)[[1L]]
  c(x = as.integer(parts[[1L]]), y = as.integer(parts[[2L]]))
}

node_key <- function(id, width) {
  xy <- parse_node_id(id)
  as.integer((xy[["y"]] - 1L) * width + xy[["x"]])
}

manhattan <- function(id_a, id_b) {
  a <- parse_node_id(id_a)
  b <- parse_node_id(id_b)
  abs(a[["x"]] - b[["x"]]) + abs(a[["y"]] - b[["y"]])
}

trail_complexity_config <- function(complexity = c("simple", "standard", "complex")) {
  complexity <- match.arg(complexity)
  if(identical(complexity, "simple")) {
    return(list(
      complexity = complexity,
      width = 46L, height = 28L,
      obstacle_density = 0.18,
      weight_min = 1L, weight_max = 5L,
      seed = 91L,
      max_steps = 4000L
    ))
  }
  if(identical(complexity, "complex")) {
    return(list(
      complexity = complexity,
      width = 92L, height = 54L,
      obstacle_density = 0.22,
      weight_min = 1L, weight_max = 6L,
      seed = 209L,
      max_steps = 20000L
    ))
  }
  list(
    complexity = "standard",
    width = 64L, height = 38L,
    obstacle_density = 0.20,
    weight_min = 1L, weight_max = 5L,
    seed = 143L,
    max_steps = 8000L
  )
}

resolve_trail_config <- function(
  complexity = c("simple", "standard", "complex"),
  width = NULL, height = NULL,
  obstacle_density = NULL,
  weight_min = NULL, weight_max = NULL,
  seed = NULL, max_steps = NULL
) {
  cfg <- trail_complexity_config(match.arg(complexity))
  if(!is.null(width)) cfg$width <- as.integer(width)
  if(!is.null(height)) cfg$height <- as.integer(height)
  if(!is.null(obstacle_density)) cfg$obstacle_density <- as.numeric(obstacle_density)
  if(!is.null(weight_min)) cfg$weight_min <- as.integer(weight_min)
  if(!is.null(weight_max)) cfg$weight_max <- as.integer(weight_max)
  if(!is.null(seed)) cfg$seed <- as.integer(seed)
  if(!is.null(max_steps)) cfg$max_steps <- as.integer(max_steps)

  cfg$width <- max(20L, cfg$width)
  cfg$height <- max(16L, cfg$height)
  cfg$obstacle_density <- max(0.05, min(0.35, cfg$obstacle_density))
  cfg$weight_min <- max(1L, cfg$weight_min)
  cfg$weight_max <- max(cfg$weight_min, cfg$weight_max)
  cfg
}

# -- Terrain helpers (ported from the previous wave-clear demo) -------------

smooth_noise <- function(m, passes = 2L) {
  w <- nrow(m); h <- ncol(m)
  out <- m
  for(p in seq_len(as.integer(max(1L, passes)))) {
    cur <- out; nxt <- cur
    for(x in 2L:(w - 1L)) {
      for(y in 2L:(h - 1L)) {
        nxt[x, y] <- (
          cur[x, y] * 3 +
          cur[x - 1L, y] + cur[x + 1L, y] + cur[x, y - 1L] + cur[x, y + 1L] +
          0.5 * (cur[x - 1L, y - 1L] + cur[x - 1L, y + 1L] +
                 cur[x + 1L, y - 1L] + cur[x + 1L, y + 1L])
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
  w <- nrow(blocked); h <- ncol(blocked)
  cur <- blocked
  if(w < 3L || h < 3L) return(cur)
  for(p in seq_len(as.integer(max(1L, passes)))) {
    nxt <- cur
    for(x in 2L:(w - 1L)) {
      for(y in 2L:(h - 1L)) {
        n8 <- sum(cur[(x - 1L):(x + 1L), (y - 1L):(y + 1L)]) - as.integer(cur[x, y])
        if(n8 >= 5L) nxt[x, y] <- TRUE
        else if(n8 <= 2L) nxt[x, y] <- FALSE
      }
    }
    cur <- nxt
  }
  cur
}

nearest_open_cell <- function(blocked, x0, y0) {
  w <- nrow(blocked); h <- ncol(blocked)
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
      xi <- as.integer(cand$x[[i]]); yi <- as.integer(cand$y[[i]])
      if(!blocked[xi, yi]) return(c(x = xi, y = yi))
    }
  }
  stop("No open cell found.")
}

# Dijkstra over the weighted grid, used to verify connectivity and pick a goal.
dijkstra_reachable <- function(blocked, weights, source_x, source_y) {
  load_immutables()
  w <- nrow(blocked); h <- ncol(blocked)
  dist <- matrix(Inf, nrow = w, ncol = h)
  dist[source_x, source_y] <- 0

  q <- priority_queue()
  q <- insert(
    q,
    element = list(x = as.integer(source_x), y = as.integer(source_y)),
    priority = 0
  )
  dirs <- rbind(c(1L, 0L), c(-1L, 0L), c(0L, 1L), c(0L, -1L))

  while(length(q) > 0L) {
    popped <- pop_min(q)
    cur <- popped$value
    q <- popped$remaining
    if(is.null(cur) || is.null(popped$priority)) break
    x <- as.integer(cur$x); y <- as.integer(cur$y)
    d0 <- as.numeric(popped$priority)
    if(d0 > dist[x, y] + 1e-9) next

    for(k in 1:4) {
      nx <- x + dirs[k, 1L]; ny <- y + dirs[k, 2L]
      if(nx < 1L || nx > w || ny < 1L || ny > h) next
      if(blocked[nx, ny]) next
      step_cost <- as.numeric(weights[nx, ny])
      if(!is.finite(step_cost) || step_cost <= 0) next
      nd <- d0 + step_cost
      if(nd + 1e-9 < dist[nx, ny]) {
        dist[nx, ny] <- nd
        q <- insert(q, element = list(x = as.integer(nx), y = as.integer(ny)), priority = nd)
      }
    }
  }

  idx <- which(is.finite(dist), arr.ind = TRUE)
  data.frame(
    id = paste0(idx[, 1L], ",", idx[, 2L]),
    x = as.integer(idx[, 1L]),
    y = as.integer(idx[, 2L]),
    d = as.numeric(dist[idx]),
    stringsAsFactors = FALSE
  )
}

# Pick a visually-interesting goal: far from source, biased toward the right
# side of the grid and the middle row.
choose_goal_cell <- function(reach, width, height, source_x, source_y) {
  src_id <- node_id(source_x, source_y)
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

# Build a weighted terrain grid: procedurally-generated per-cell weights
# (1..weight_max) with scattered wall obstacles, plus a source and a goal.
generate_wave_grid <- function(
  width = 64L, height = 38L,
  obstacle_density = 0.20,
  weight_min = 1L, weight_max = 5L,
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

    blocked[1L, ] <- TRUE; blocked[width, ] <- TRUE
    blocked[, 1L] <- TRUE; blocked[, height] <- TRUE

    # Carve a small open basin around the source so it's visible.
    ymid <- as.integer(round(height / 2))
    xr <- 2L:min(6L, width - 1L)
    yr <- max(2L, ymid - 2L):min(height - 1L, ymid + 2L)
    blocked[xr, yr] <- FALSE

    src0 <- c(x = 3L, y = as.integer(round(height / 2)))
    src <- nearest_open_cell(blocked, src0[["x"]], src0[["y"]])
    blocked[src[["x"]], src[["y"]]] <- FALSE

    # Map open-cell terrain scores to integer weights for visible diversity.
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
      source_id <- node_id(src[["x"]], src[["y"]])
      goal <- choose_goal_cell(reach, width = width, height = height,
                               source_x = src[["x"]], source_y = src[["y"]])

      wall_idx <- which(blocked, arr.ind = TRUE)
      walls <- data.frame(x = wall_idx[, 1L], y = wall_idx[, 2L], stringsAsFactors = FALSE)

      return(list(
        width = as.integer(width),
        height = as.integer(height),
        blocked = blocked,
        weights = weights,
        walls = walls,
        start = source_id,
        goal = goal$id,
        source_x = as.integer(src[["x"]]),
        source_y = as.integer(src[["y"]]),
        goal_x = as.integer(goal$x),
        goal_y = as.integer(goal$y)
      ))
    }
  }
}

# Weighted 4-neighbor step. Returns destination id + edge cost = weight of
# destination cell.
weighted_neighbors <- function(id, grid) {
  xy <- parse_node_id(id)
  x <- xy[["x"]]; y <- xy[["y"]]
  cand <- rbind(c(x + 1L, y), c(x - 1L, y), c(x, y + 1L), c(x, y - 1L))
  out <- list()
  for(i in seq_len(nrow(cand))) {
    nx <- cand[i, 1L]; ny <- cand[i, 2L]
    if(nx < 1L || nx > grid$width || ny < 1L || ny > grid$height) next
    if(isTRUE(grid$blocked[nx, ny])) next
    out[[length(out) + 1L]] <- list(
      id = node_id(nx, ny),
      cost = as.numeric(grid$weights[nx, ny])
    )
  }
  out
}

path_from_came_from <- function(came_from, current) {
  path <- current; cursor <- current
  repeat {
    prev <- came_from[[cursor]]
    if(is.null(prev)) break
    path <- c(prev, path); cursor <- prev
  }
  path
}

score_get <- function(scores, id, default = Inf) {
  if(id %in% names(scores)) return(unname(scores[[id]]))
  default
}

score_set <- function(scores, id, value) {
  scores[[id]] <- value
  scores
}

# -- Trail-specific code ----------------------------------------------------

make_trail_snapshot <- function(step, current, open, closed, trail, clear_q,
                                trail_meta, path = character(0), note = "") {
  list(
    step = as.integer(step),
    current = current,
    open = open,
    closed = closed,
    trail = trail,
    clear_q = clear_q,
    trail_meta = trail_meta,
    path = path,
    note = note
  )
}

# A* augmented with a heuristic-warped clear wave, over weighted edges.
#
# Each expanded cell enters both `closed` (correctness) and `trail`
# (visualization), with a retirement scheduled in `clear_q` at priority
# s_clear = s_expand + lag_base + lag_warp * h(cell), where s is the
# expansion-step counter. Retirement fires lazily whenever the current
# step has advanced past a scheduled clear.
#
# Step cost is the weight of the destination cell (min weight = 1, so
# Manhattan remains an admissible heuristic).
astar_trail_search_immutables <- function(
  grid,
  heuristic_fn = NULL,
  max_steps = 5000L,
  lag_base = 3, lag_warp = 0.4,
  track_snapshots = TRUE
) {
  load_immutables()

  start <- grid$start
  goal <- grid$goal
  key_fn <- function(id) node_key(id, grid$width)

  # Default heuristic: Manhattan scaled by the mean open-cell weight. This is
  # (mildly) inadmissible but produces a visibly goal-directed frontier rather
  # than near-Dijkstra expansion; A* may therefore return a near-optimal but
  # not guaranteed optimal path — acceptable for a demo.
  if(is.null(heuristic_fn)) {
    h_scale <- mean(as.numeric(grid$weights[!grid$blocked]), na.rm = TRUE)
    if(!is.finite(h_scale) || h_scale <= 0) h_scale <- 1
    heuristic_fn <- function(a, b) manhattan(a, b) * h_scale
  }

  h_start <- heuristic_fn(start, goal)
  open <- priority_queue(start, priorities = h_start)
  closed <- ordered_sequence()
  trail <- ordered_sequence()
  clear_q <- priority_queue()

  came_from <- list()
  g_score <- setNames(numeric(0), character(0))
  g_score <- score_set(g_score, start, 0)

  trail_meta <- list()

  snapshots <- if(isTRUE(track_snapshots)) flexseq() else NULL
  step <- 0L

  if(isTRUE(track_snapshots)) {
    snapshots <- push_back(
      snapshots,
      make_trail_snapshot(step, current = start, open = open, closed = closed,
                          trail = trail, clear_q = clear_q,
                          trail_meta = trail_meta, note = "start")
    )
  }

  while(length(open) > 0L && step < max_steps) {
    popped <- pop_min(open)
    current <- popped$value
    open <- popped$remaining
    if(is.null(current)) break

    current_key <- key_fn(current)
    if(!is.null(peek_key(closed, current_key))) next

    step <- step + 1L
    closed <- insert(closed, element = current, key = current_key)

    # Enter trail, schedule retirement at step + lag_base + lag_warp * h.
    h_cur <- heuristic_fn(current, goal)
    s_clear <- as.numeric(step) + lag_base + lag_warp * h_cur
    trail <- insert(trail, element = current, key = current_key)
    clear_q <- insert(clear_q, current, priority = s_clear)
    trail_meta[[as.character(current_key)]] <- list(
      id = current, s_expand = as.numeric(step), s_clear = s_clear
    )

    # Retire any trail cells whose scheduled clear has matured.
    while(length(clear_q) > 0L) {
      mp <- min_priority(clear_q)
      if(is.null(mp) || mp > step) break
      done_popped <- pop_min(clear_q)
      done <- done_popped$value
      clear_q <- done_popped$remaining
      done_key <- key_fn(done)
      popped_trail <- pop_key(trail, done_key)
      trail <- popped_trail$remaining
      trail_meta[[as.character(done_key)]] <- NULL
    }

    if(identical(current, goal)) {
      final_path <- path_from_came_from(came_from, current)
      if(isTRUE(track_snapshots)) {
        snapshots <- push_back(
          snapshots,
          make_trail_snapshot(step, current = current, open = open, closed = closed,
                              trail = trail, clear_q = clear_q,
                              trail_meta = trail_meta,
                              path = final_path, note = "goal")
        )
      }
      return(list(found = TRUE, path = final_path, snapshots = snapshots, steps = step))
    }

    # Relax neighbors with weighted edges.
    current_g <- score_get(g_score, current)
    for(nb_info in weighted_neighbors(current, grid)) {
      nb <- nb_info$id
      nb_key <- key_fn(nb)
      if(!is.null(peek_key(closed, nb_key))) next
      tentative_g <- current_g + nb_info$cost
      if(tentative_g < score_get(g_score, nb)) {
        came_from[[nb]] <- current
        g_score <- score_set(g_score, nb, tentative_g)
        f_score <- tentative_g + heuristic_fn(nb, goal)
        open <- insert(open, nb, priority = f_score)
      }
    }

    if(isTRUE(track_snapshots)) {
      snapshots <- push_back(
        snapshots,
        make_trail_snapshot(step, current = current, open = open, closed = closed,
                            trail = trail, clear_q = clear_q,
                            trail_meta = trail_meta, note = "expand")
      )
    }
  }

  list(found = FALSE, path = character(0), snapshots = snapshots, steps = step)
}

# -- Rendering --------------------------------------------------------------

# Build a per-snapshot data frame annotated with state + trail_alpha ramp.
# The `base` argument is the per-cell terrain base (weight, wall flag).
trail_snapshots_to_df <- function(result, grid) {
  if(is.null(result$snapshots)) {
    stop("No snapshots available in `result`. Re-run with `track_snapshots = TRUE`.")
  }
  base <- expand.grid(x = seq_len(grid$width), y = seq_len(grid$height))
  base$node <- paste0(base$x, ",", base$y)
  wall_nodes <- paste0(grid$walls$x, ",", grid$walls$y)
  base$is_wall <- base$node %in% wall_nodes
  base$weight <- as.integer(grid$weights[cbind(base$x, base$y)])

  shots <- as.list(result$snapshots)
  frames <- vector("list", length(shots))

  for(i in seq_along(shots)) {
    shot <- shots[[i]]
    d <- base
    d$trail_alpha <- 0
    d$state <- "empty"
    d$state[d$is_wall] <- "wall"

    trail_nodes <- unlist(as.list(shot$trail), use.names = FALSE)
    if(length(trail_nodes) > 0L) {
      trail_df <- data.frame(node = trail_nodes, stringsAsFactors = FALSE)
      tmeta <- shot$trail_meta
      trail_df$s_expand <- vapply(
        trail_nodes,
        function(id) {
          key <- as.character(node_key(id, grid$width))
          if(is.null(tmeta[[key]])) NA_real_ else tmeta[[key]]$s_expand
        },
        numeric(1)
      )
      trail_df$s_clear <- vapply(
        trail_nodes,
        function(id) {
          key <- as.character(node_key(id, grid$width))
          if(is.null(tmeta[[key]])) NA_real_ else tmeta[[key]]$s_clear
        },
        numeric(1)
      )
      total <- pmax(trail_df$s_clear - trail_df$s_expand, 1e-9)
      spent <- pmax(shot$step - trail_df$s_expand, 0)
      life <- 1 - spent / total
      life <- pmin(pmax(life, 0), 1)
      trail_df$trail_alpha <- 0.25 + 0.70 * life  # visible floor so the trail doesn't fade below background

      m <- match(d$node, trail_df$node)
      hit <- !is.na(m)
      d$state[hit] <- "trail"
      d$trail_alpha[hit] <- trail_df$trail_alpha[m[hit]]
    }

    if(!is.null(shot$current)) {
      d$state[d$node == shot$current] <- "current"
      d$trail_alpha[d$node == shot$current] <- 1
    }

    d$state[d$node == grid$start] <- "start"
    d$state[d$node == grid$goal] <- "goal"

    d$path_rank <- NA_integer_
    if(length(shot$path) > 0L) {
      d$path_rank <- match(d$node, shot$path)
    }

    d$step <- shot$step
    d$note <- shot$note
    frames[[i]] <- d
  }

  out <- do.call(rbind, frames)
  out$state <- factor(
    out$state,
    levels = c("empty", "trail", "current", "start", "goal", "wall")
  )
  out
}

plot_astar_trail_snapshots <- function(
  result, grid,
  animate = TRUE,
  outfile = NULL,
  fps = 12,
  max_animation_frames = 140L,
  frame_stride = NULL,
  hold_final_frames = 8L,
  reveal_hold_frames = NULL,
  loop = TRUE,
  width_px = 840L,
  height_px = 560L
) {
  if(!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Please install 'ggplot2' to visualize snapshots.")
  }
  hold_final_frames <- max(0L, as.integer(hold_final_frames))
  if(is.null(reveal_hold_frames)) reveal_hold_frames <- hold_final_frames
  reveal_hold_frames <- max(0L, as.integer(reveal_hold_frames))

  df <- trail_snapshots_to_df(result, grid)

  trail_color <- "#F08A24"
  path_color  <- "#FFE066"
  path_outline_color <- "#111111"

  w_min <- suppressWarnings(min(df$weight[!df$is_wall], na.rm = TRUE))
  w_max <- suppressWarnings(max(df$weight[!df$is_wall], na.rm = TRUE))
  if(!is.finite(w_min)) w_min <- 1
  if(!is.finite(w_max)) w_max <- 5

  source_df <- data.frame(x = grid$source_x, y = grid$source_y)
  goal_df <- data.frame(x = grid$goal_x, y = grid$goal_y)

  .make_plot <- function(plot_df, caption = NULL, path_layer = c("none", "highlight", "line")) {
    path_layer <- match.arg(path_layer)

    heat_df <- plot_df[!plot_df$is_wall, , drop = FALSE]
    wall_df <- plot_df[plot_df$is_wall, , drop = FALSE]
    trail_df <- plot_df[plot_df$state == "trail", , drop = FALSE]
    current_df <- plot_df[plot_df$state == "current", , drop = FALSE]
    path_df <- plot_df[!is.na(plot_df$path_rank), c("x", "y", "path_rank"), drop = FALSE]
    if(nrow(path_df) > 0L) path_df <- path_df[order(path_df$path_rank), , drop = FALSE]

    p <- ggplot2::ggplot() +
      # Terrain heatmap base.
      ggplot2::geom_tile(
        data = heat_df,
        ggplot2::aes(x = x, y = y, fill = weight),
        color = "#151515",
        linewidth = 0.06
      ) +
      # Wall cells.
      ggplot2::geom_tile(
        data = wall_df,
        ggplot2::aes(x = x, y = y),
        fill = "#2A2A2A",
        color = "#2A2A2A",
        linewidth = 0.06
      )

    # Trail overlay with alpha ramp.
    if(nrow(trail_df) > 0L) {
      p <- p +
        ggplot2::geom_tile(
          data = trail_df,
          ggplot2::aes(x = x, y = y, alpha = trail_alpha),
          fill = trail_color,
          color = NA
        ) +
        ggplot2::scale_alpha_identity()
    }

    # Current cell: bright, opaque.
    if(nrow(current_df) > 0L) {
      p <- p +
        ggplot2::geom_tile(
          data = current_df,
          ggplot2::aes(x = x, y = y),
          fill = trail_color,
          color = "#111111",
          linewidth = 0.25
        )
    }

    # Final path reveal.
    if(identical(path_layer, "line") && nrow(path_df) > 0L) {
      p <- p +
        ggplot2::geom_path(
          data = path_df,
          ggplot2::aes(x = x, y = y, group = 1L),
          inherit.aes = FALSE,
          color = path_outline_color,
          linewidth = 1.45,
          lineend = "round", linejoin = "round"
        ) +
        ggplot2::geom_path(
          data = path_df,
          ggplot2::aes(x = x, y = y, group = 1L),
          inherit.aes = FALSE,
          color = path_color,
          linewidth = 0.85,
          lineend = "round", linejoin = "round"
        )
    }
    if(identical(path_layer, "highlight") && nrow(path_df) > 0L) {
      p <- p +
        ggplot2::geom_point(
          data = path_df,
          ggplot2::aes(x = x, y = y),
          inherit.aes = FALSE,
          color = path_color,
          size = 0.95
        )
    }

    # Source + goal markers.
    p +
      ggplot2::geom_point(
        data = source_df,
        ggplot2::aes(x = x, y = y),
        shape = 8, color = "#FFFFFF", size = 2.3, stroke = 0.6, inherit.aes = FALSE
      ) +
      ggplot2::geom_point(
        data = goal_df,
        ggplot2::aes(x = x, y = y),
        shape = 21,
        fill = if(isTRUE(result$found) && identical(path_layer, "line")) "#2AA876" else "#D1495B",
        color = "#FFFFFF", stroke = 0.55, size = 2.6, inherit.aes = FALSE
      ) +
      ggplot2::scale_fill_gradientn(
        colours = c("#EFF5FF", "#D5E6FF", "#A8CBF4", "#6EA6E4", "#2C7BE5", "#124C9C"),
        limits = c(w_min, w_max),
        name = "Terrain Weight"
      ) +
      ggplot2::coord_equal(expand = FALSE) +
      ggplot2::scale_y_reverse(expand = c(0, 0)) +
      ggplot2::scale_x_continuous(expand = c(0, 0)) +
      ggplot2::labs(
        title = "A* with Heuristic Trail",
        subtitle = if(isTRUE(result$found) && identical(path_layer, "line")) "Path found" else "Searching",
        caption = caption,
        x = NULL, y = NULL, fill = NULL
      ) +
      ggplot2::theme_minimal(base_size = 11) +
      ggplot2::theme(
        panel.grid = ggplot2::element_blank(),
        axis.text = ggplot2::element_blank(),
        axis.ticks = ggplot2::element_blank(),
        legend.position = "bottom",
        plot.margin = ggplot2::margin(t = 6, r = 8, b = 6, l = 8)
      )
  }

  if(isTRUE(animate)) {
    if(!requireNamespace("gifski", quietly = TRUE)) {
      stop("Animation requested but 'gifski' is not installed.")
    }

    forward_steps <- sort(unique(df$step))
    if(is.null(frame_stride)) {
      frame_stride <- max(1L, as.integer(ceiling(length(forward_steps) / as.integer(max_animation_frames))))
    } else {
      frame_stride <- max(1L, as.integer(frame_stride))
    }
    forward_steps <- forward_steps[seq.int(1L, length(forward_steps), by = frame_stride)]
    if(forward_steps[length(forward_steps)] != max(df$step)) {
      forward_steps <- c(forward_steps, max(df$step))
    }

    playback_steps <- c(
      forward_steps,
      rep(max(forward_steps), reveal_hold_frames),
      rep(max(forward_steps), hold_final_frames)
    )
    path_layers <- c(
      rep("none", length(forward_steps)),
      rep("highlight", reveal_hold_frames),
      rep("line", hold_final_frames)
    )

    frame_dir <- tempfile("astar-trail-frames-")
    dir.create(frame_dir, recursive = TRUE, showWarnings = FALSE)
    frame_paths <- file.path(frame_dir, sprintf("frame_%05d.png", seq_along(playback_steps)))

    for(i in seq_along(playback_steps)) {
      step_i <- playback_steps[[i]]
      frame_df <- df[df$step == step_i, , drop = FALSE]
      frame_plot <- .make_plot(
        frame_df,
        caption = paste0("Step: ", step_i),
        path_layer = path_layers[[i]]
      )
      ggplot2::ggsave(
        filename = frame_paths[[i]],
        plot = frame_plot,
        width = as.numeric(width_px) / 96,
        height = as.numeric(height_px) / 96,
        dpi = 96, units = "in"
      )
    }

    if(is.null(outfile)) outfile <- tempfile("astar-trail-", fileext = ".gif")

    gifski::gifski(
      png_files = frame_paths,
      gif_file = outfile,
      width = as.integer(width_px), height = as.integer(height_px),
      delay = 1 / fps,
      loop = isTRUE(loop),
      progress = FALSE
    )

    return(list(
      type = "animation",
      gif = outfile,
      data = df,
      frame_count = length(playback_steps)
    ))
  }

  list(type = "static", data = df)
}

# -- Public entry -----------------------------------------------------------

run_astar_trail_demo <- function(
  complexity = c("simple", "standard", "complex"),
  width = NULL, height = NULL,
  obstacle_density = NULL,
  weight_min = NULL, weight_max = NULL,
  seed = NULL, max_steps = NULL,
  lag_base = 3, lag_warp = 0.4,
  animate = TRUE,
  outfile = NULL,
  fps = 12,
  visualize = TRUE,
  track_snapshots = TRUE,
  max_animation_frames = 140L,
  frame_stride = NULL,
  hold_final_frames = 8L,
  reveal_hold_frames = NULL,
  loop = TRUE,
  width_px = 840L,
  height_px = 560L
) {
  cfg <- resolve_trail_config(
    complexity = match.arg(complexity),
    width = width, height = height,
    obstacle_density = obstacle_density,
    weight_min = weight_min, weight_max = weight_max,
    seed = seed, max_steps = max_steps
  )

  grid <- generate_wave_grid(
    width = cfg$width, height = cfg$height,
    obstacle_density = cfg$obstacle_density,
    weight_min = cfg$weight_min, weight_max = cfg$weight_max,
    seed = cfg$seed
  )

  effective_track <- isTRUE(track_snapshots) || isTRUE(visualize)
  result <- astar_trail_search_immutables(
    grid = grid,
    max_steps = cfg$max_steps,
    lag_base = lag_base, lag_warp = lag_warp,
    track_snapshots = effective_track
  )
  result$grid <- grid

  viz <- NULL
  if(isTRUE(visualize)) {
    viz <- plot_astar_trail_snapshots(
      result, grid,
      animate = animate,
      outfile = outfile,
      fps = fps,
      max_animation_frames = max_animation_frames,
      frame_stride = frame_stride,
      hold_final_frames = hold_final_frames,
      reveal_hold_frames = reveal_hold_frames,
      loop = loop,
      width_px = width_px, height_px = height_px
    )
  }

  list(
    config = cfg,
    found = result$found,
    path_length = length(result$path),
    steps = result$steps,
    path = result$path,
    visualization = viz,
    result = result
  )
}

#if(sys.nframe() == 0L) {
  demo <- run_astar_trail_demo(complexity = "simple", animate = FALSE, visualize = FALSE)
  message(sprintf("astar_trail demo: found=%s path_length=%d steps=%d",
                  demo$found, demo$path_length, demo$steps))
#}
