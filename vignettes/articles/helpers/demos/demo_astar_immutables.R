# A* pathfinding demo for the immutables package.
#
# Structures used:
# - priority_queue: A* open set (min by f-score)
# - ordered_sequence: closed/visited set keyed by cell index
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

astar_complexity_config <- function(complexity = c("simple", "standard", "complex")) {
  complexity <- match.arg(complexity)
  if(identical(complexity, "simple")) {
    return(list(
      complexity = complexity,
      width = 21L,
      height = 13L,
      wall_spacing = 6L,
      gap_half_width = 2L,
      gap_stride = 5L,
      maze_seed = 11L,
      max_steps = 1200L
    ))
  }
  if(identical(complexity, "complex")) {
    return(list(
      complexity = complexity,
      width = 49L,
      height = 31L,
      wall_spacing = 3L,
      gap_half_width = 1L,
      gap_stride = 11L,
      maze_seed = 53L,
      max_steps = 20000L
    ))
  }
  list(
    complexity = "standard",
    width = 33L,
    height = 21L,
    wall_spacing = 4L,
    gap_half_width = 1L,
    gap_stride = 7L,
    maze_seed = 29L,
    max_steps = 5000L
  )
}

resolve_demo_config <- function(
  complexity = c("simple", "standard", "complex"),
  width = NULL,
  height = NULL,
  wall_spacing = NULL,
  gap_half_width = NULL,
  gap_stride = NULL,
  maze_seed = NULL,
  max_steps = NULL
) {
  cfg <- astar_complexity_config(match.arg(complexity))

  if(!is.null(width)) {
    cfg$width <- as.integer(width)
  }
  if(!is.null(height)) {
    cfg$height <- as.integer(height)
  }
  if(!is.null(wall_spacing)) {
    cfg$wall_spacing <- as.integer(wall_spacing)
  }
  if(!is.null(gap_half_width)) {
    cfg$gap_half_width <- as.integer(gap_half_width)
  }
  if(!is.null(gap_stride)) {
    cfg$gap_stride <- as.integer(gap_stride)
  }
  if(!is.null(maze_seed)) {
    cfg$maze_seed <- as.integer(maze_seed)
  }
  if(!is.null(max_steps)) {
    cfg$max_steps <- as.integer(max_steps)
  }
  cfg
}

build_demo_grid <- function(
  width = 33L,
  height = 21L,
  wall_spacing = 4L,
  gap_half_width = 1L,
  gap_stride = 7L,
  maze_seed = NULL
) {
  stopifnot(width >= 10L, height >= 8L)
  stopifnot(wall_spacing >= 2L, gap_half_width >= 0L, gap_stride >= 1L)

  if(!is.null(maze_seed)) {
    set.seed(as.integer(maze_seed))
  }

  # Keep a border wall and carve inside with a recursive backtracking maze.
  blocked <- matrix(TRUE, nrow = width, ncol = height)
  cell_x <- seq.int(2L, width - 1L, by = 2L)
  cell_y <- seq.int(2L, height - 1L, by = 2L)
  if(length(cell_x) == 0L || length(cell_y) == 0L) {
    stop("Grid is too small for maze carving.")
  }

  n_cx <- length(cell_x)
  n_cy <- length(cell_y)
  visited <- matrix(FALSE, nrow = n_cx, ncol = n_cy)
  stack <- matrix(c(1L, 1L), ncol = 2L)
  visited[1L, 1L] <- TRUE
  blocked[cell_x[[1L]], cell_y[[1L]]] <- FALSE
  dirs <- rbind(c(1L, 0L), c(-1L, 0L), c(0L, 1L), c(0L, -1L))

  while(nrow(stack) > 0L) {
    cur <- stack[nrow(stack), ]
    ci <- cur[[1L]]
    cj <- cur[[2L]]
    ord <- sample.int(4L)
    moved <- FALSE

    for(k in ord) {
      ni <- ci + dirs[k, 1L]
      nj <- cj + dirs[k, 2L]
      if(ni < 1L || ni > n_cx || nj < 1L || nj > n_cy || visited[ni, nj]) {
        next
      }

      x1 <- cell_x[[ci]]
      y1 <- cell_y[[cj]]
      x2 <- cell_x[[ni]]
      y2 <- cell_y[[nj]]
      blocked[(x1 + x2) %/% 2L, (y1 + y2) %/% 2L] <- FALSE
      blocked[x2, y2] <- FALSE
      visited[ni, nj] <- TRUE
      stack <- rbind(stack, c(ni, nj))
      moved <- TRUE
      break
    }

    if(!moved) {
      if(nrow(stack) == 1L) {
        stack <- stack[0, , drop = FALSE]
      } else {
        stack <- stack[-nrow(stack), , drop = FALSE]
      }
    }
  }

  # Light braiding: open a subset of separating walls to make the maze less rigid.
  loop_chance <- min(0.25, max(0, as.numeric(gap_half_width) / max(1, as.numeric(wall_spacing) * 2)))
  if(loop_chance > 0) {
    for(x in 2L:(width - 1L)) {
      for(y in 2L:(height - 1L)) {
        if(!blocked[x, y]) {
          next
        }
        horiz <- (!blocked[x - 1L, y] && !blocked[x + 1L, y] && blocked[x, y - 1L] && blocked[x, y + 1L])
        vert <- (!blocked[x, y - 1L] && !blocked[x, y + 1L] && blocked[x - 1L, y] && blocked[x + 1L, y])
        if((horiz || vert) && stats::runif(1L) < loop_chance) {
          blocked[x, y] <- FALSE
        }
      }
    }
  }

  start <- c(2L, 2L)
  goal <- c(width - 1L, height - 1L)
  if(goal[[1L]] %% 2L != 0L) {
    goal[[1L]] <- max(2L, goal[[1L]] - 1L)
  }
  if(goal[[2L]] %% 2L != 0L) {
    goal[[2L]] <- max(2L, goal[[2L]] - 1L)
  }

  ensure_open <- function(coord) {
    x <- coord[[1L]]
    y <- coord[[2L]]
    blocked[x, y] <<- FALSE
    neigh <- rbind(c(x + 1L, y), c(x - 1L, y), c(x, y + 1L), c(x, y - 1L))
    valid <- neigh[, 1L] >= 2L & neigh[, 1L] <= (width - 1L) & neigh[, 2L] >= 2L & neigh[, 2L] <= (height - 1L)
    neigh <- neigh[valid, , drop = FALSE]
    if(nrow(neigh) == 0L) {
      return(invisible(NULL))
    }
    open_neighbor <- vapply(seq_len(nrow(neigh)), function(i) !blocked[neigh[i, 1L], neigh[i, 2L]], logical(1))
    if(!any(open_neighbor)) {
      # Prefer carving toward the center so these forced openings stay natural.
      cx <- as.integer((width + 1L) %/% 2L)
      cy <- as.integer((height + 1L) %/% 2L)
      dist <- abs(neigh[, 1L] - cx) + abs(neigh[, 2L] - cy)
      pick <- order(dist)[[1L]]
      blocked[neigh[pick, 1L], neigh[pick, 2L]] <<- FALSE
    }
    invisible(NULL)
  }

  ensure_open(start)
  ensure_open(goal)
  blocked[1L, ] <- TRUE
  blocked[width, ] <- TRUE
  blocked[, 1L] <- TRUE
  blocked[, height] <- TRUE
  blocked[start[[1L]], start[[2L]]] <- FALSE
  blocked[goal[[1L]], goal[[2L]]] <- FALSE

  wall_idx <- which(blocked, arr.ind = TRUE)
  walls <- data.frame(x = wall_idx[, 1L], y = wall_idx[, 2L])

  list(
    width = width,
    height = height,
    start = node_id(start[[1L]], start[[2L]]),
    goal = node_id(goal[[1L]], goal[[2L]]),
    walls = walls
  )
}

is_blocked <- function(x, y, walls_hash) {
  key <- paste0(x, ",", y)
  isTRUE(walls_hash[[key]])
}

neighbors4 <- function(id, grid, walls_hash) {
  xy <- parse_node_id(id)
  x <- xy[["x"]]
  y <- xy[["y"]]

  cand <- rbind(
    c(x + 1L, y),
    c(x - 1L, y),
    c(x, y + 1L),
    c(x, y - 1L)
  )

  out <- character(0)
  for(i in seq_len(nrow(cand))) {
    nx <- cand[i, 1L]
    ny <- cand[i, 2L]
    if(nx < 1L || nx > grid$width || ny < 1L || ny > grid$height) {
      next
    }
    if(is_blocked(nx, ny, walls_hash)) {
      next
    }
    out <- c(out, node_id(nx, ny))
  }
  out
}

path_from_came_from <- function(came_from, current) {
  path <- current
  cursor <- current
  repeat {
    prev <- came_from[[cursor]]
    if(is.null(prev)) {
      break
    }
    path <- c(prev, path)
    cursor <- prev
  }
  path
}

score_get <- function(scores, id, default = Inf) {
  if(id %in% names(scores)) {
    return(unname(scores[[id]]))
  }
  default
}

score_set <- function(scores, id, value) {
  scores[[id]] <- value
  scores
}

make_snapshot <- function(step, current, open, closed, path = character(0), note = "") {
  list(
    step = as.integer(step),
    current = current,
    open = open,
    closed = closed,
    path = path,
    note = note
  )
}

astar_search_immutables <- function(
  start,
  goal,
  neighbors_fn,
  heuristic_fn,
  key_fn = identity,
  max_steps = 5000L,
  track_snapshots = TRUE,
  snapshot_fn = make_snapshot
) {
  load_immutables()

  open <- priority_queue(start, priorities = heuristic_fn(start, goal))
  closed <- ordered_sequence()

  came_from <- list()
  g_score <- setNames(numeric(0), character(0))
  g_score <- score_set(g_score, start, 0)

  snapshots <- if(isTRUE(track_snapshots)) flexseq() else NULL
  step <- 0L

  if(isTRUE(track_snapshots)) {
    snapshots <- push_back(
      snapshots,
      snapshot_fn(step, current = start, open = open, closed = closed, note = "start")
    )
  }

  while(length(open) > 0L && step < max_steps) {
    popped <- pop_min(open)
    current <- popped$value
    open <- popped$remaining

    if(is.null(current)) {
      break
    }

    # Lazy duplicate handling: skip if already closed.
    current_key <- key_fn(current)
    if(!is.null(peek_key(closed, current_key))) {
      step <- step + 1L
      if(isTRUE(track_snapshots)) {
        snapshots <- push_back(
          snapshots,
          snapshot_fn(step, current = current, open = open, closed = closed, note = "skip-closed")
        )
      }
      next
    }

    if(identical(current, goal)) {
      final_path <- path_from_came_from(came_from, current)
      step <- step + 1L
      if(isTRUE(track_snapshots)) {
        snapshots <- push_back(
          snapshots,
          snapshot_fn(step, current = current, open = open, closed = closed, path = final_path, note = "goal")
        )
      }
      return(list(found = TRUE, path = final_path, snapshots = snapshots, steps = step))
    }

    closed <- insert(closed, element = current, key = current_key)
    current_g <- score_get(g_score, current)

    for(nb in neighbors_fn(current)) {
      nb_key <- key_fn(nb)
      if(!is.null(peek_key(closed, nb_key))) {
        next
      }

      tentative_g <- current_g + 1
      if(tentative_g < score_get(g_score, nb)) {
        came_from[[nb]] <- current
        g_score <- score_set(g_score, nb, tentative_g)
        f_score <- tentative_g + heuristic_fn(nb, goal)
        open <- insert(open, nb, priority = f_score)
      }
    }

    step <- step + 1L
    if(isTRUE(track_snapshots)) {
      snapshots <- push_back(
        snapshots,
        snapshot_fn(step, current = current, open = open, closed = closed, note = "expand")
      )
    }
  }

  list(found = FALSE, path = character(0), snapshots = snapshots, steps = step)
}

run_astar_immutables <- function(grid = build_demo_grid(), max_steps = 5000L, track_snapshots = TRUE) {
  walls_hash <- as.list(rep(TRUE, nrow(grid$walls)))
  names(walls_hash) <- paste0(grid$walls$x, ",", grid$walls$y)

  out <- astar_search_immutables(
    start = grid$start,
    goal = grid$goal,
    neighbors_fn = function(id) neighbors4(id, grid = grid, walls_hash = walls_hash),
    heuristic_fn = manhattan,
    key_fn = function(id) node_key(id, grid$width),
    max_steps = max_steps,
    track_snapshots = track_snapshots
  )
  out$grid <- grid
  out
}

# Minimal article-friendly wrapper:
# run the immutable A* core without visualization/snapshot overhead.
run_astar_paper_core <- function(complexity = c("simple", "standard", "complex"), max_steps = NULL) {
  cfg <- resolve_demo_config(complexity = match.arg(complexity), max_steps = max_steps)
  grid <- build_demo_grid(
    width = cfg$width,
    height = cfg$height,
    wall_spacing = cfg$wall_spacing,
    gap_half_width = cfg$gap_half_width,
    gap_stride = cfg$gap_stride,
    maze_seed = cfg$maze_seed
  )
  out <- run_astar_immutables(grid = grid, max_steps = cfg$max_steps, track_snapshots = FALSE)
  list(
    found = out$found,
    path_length = length(out$path),
    steps = out$steps,
    path = out$path
  )
}

open_nodes_from_queue <- function(open_queue) {
  open_entries <- as.list(open_queue)
  if(length(open_entries) == 0L) {
    return(character(0))
  }
  vapply(
    open_entries,
    function(e) {
      if(is.list(e) && !is.null(e$item)) {
        return(as.character(e$item))
      }
      if(is.list(e) && !is.null(e$value)) {
        return(as.character(e$value))
      }
      as.character(e)
    },
    character(1)
  )
}

snapshots_to_df <- function(result) {
  if(is.null(result$snapshots)) {
    stop("No snapshots available in `result`. Re-run with `track_snapshots = TRUE`.")
  }
  grid <- result$grid
  base <- expand.grid(x = seq_len(grid$width), y = seq_len(grid$height))
  base$node <- paste0(base$x, ",", base$y)
  wall_nodes <- paste0(grid$walls$x, ",", grid$walls$y)

  shots <- as.list(result$snapshots)
  frames <- vector("list", length(shots))

  for(i in seq_along(shots)) {
    shot <- shots[[i]]
    d <- base
    d$state <- ifelse(d$node %in% wall_nodes, "wall", "empty")
    d$path_rank <- NA_integer_

    open_nodes <- open_nodes_from_queue(shot$open)

    closed_nodes <- unlist(as.list(shot$closed), use.names = FALSE)

    d$state[d$node %in% closed_nodes] <- "closed"
    d$state[d$node %in% open_nodes] <- "open"

    if(length(shot$path) > 0L) {
      d$path_rank <- match(d$node, shot$path)
    }
    if(!is.null(shot$current)) {
      d$state[d$node == shot$current] <- "current"
    }

    d$state[d$node == grid$start] <- "start"
    d$state[d$node == grid$goal] <- "goal"

    d$step <- shot$step
    d$note <- shot$note
    frames[[i]] <- d
  }

  out <- do.call(rbind, frames)
  out$state <- factor(
    out$state,
    levels = c("empty", "open", "closed", "current", "start", "goal", "wall")
  )
  out
}

# Summarize per-cell search dynamics from the full persistent snapshot history.
history_cell_metrics <- function(result) {
  if(is.null(result$snapshots)) {
    stop("No snapshots available in `result`. Re-run with `track_snapshots = TRUE`.")
  }
  grid <- result$grid
  base <- expand.grid(x = seq_len(grid$width), y = seq_len(grid$height))
  base$node <- paste0(base$x, ",", base$y)
  nodes <- base$node
  wall_nodes <- paste0(grid$walls$x, ",", grid$walls$y)

  open_hits <- setNames(integer(length(nodes)), nodes)
  closed_hits <- setNames(integer(length(nodes)), nodes)
  current_hits <- setNames(integer(length(nodes)), nodes)
  first_seen <- setNames(rep(NA_integer_, length(nodes)), nodes)

  shots <- as.list(result$snapshots)
  for(i in seq_along(shots)) {
    shot <- shots[[i]]
    step_i <- as.integer(shot$step)
    open_nodes <- open_nodes_from_queue(shot$open)
    closed_nodes <- unlist(as.list(shot$closed), use.names = FALSE)
    current_node <- if(is.null(shot$current)) character(0) else as.character(shot$current)

    if(length(open_nodes) > 0L) {
      open_nodes <- open_nodes[open_nodes %in% nodes]
      if(length(open_nodes) > 0L) {
        open_hits[open_nodes] <- open_hits[open_nodes] + 1L
      }
    }
    if(length(closed_nodes) > 0L) {
      closed_nodes <- closed_nodes[closed_nodes %in% nodes]
      if(length(closed_nodes) > 0L) {
        closed_hits[closed_nodes] <- closed_hits[closed_nodes] + 1L
      }
    }
    if(length(current_node) > 0L) {
      current_node <- current_node[current_node %in% nodes]
      if(length(current_node) > 0L) {
        current_hits[current_node] <- current_hits[current_node] + 1L
      }
    }

    seen_nodes <- unique(c(open_nodes, closed_nodes, current_node))
    if(length(seen_nodes) > 0L) {
      unseen <- seen_nodes[is.na(first_seen[seen_nodes])]
      if(length(unseen) > 0L) {
        first_seen[unseen] <- step_i
      }
    }
  }

  out <- base
  out$wall <- out$node %in% wall_nodes
  out$start <- out$node == result$grid$start
  out$goal <- out$node == result$grid$goal
  out$on_path <- out$node %in% result$path
  out$open_hits <- as.integer(open_hits[out$node])
  out$closed_hits <- as.integer(closed_hits[out$node])
  out$current_hits <- as.integer(current_hits[out$node])
  out$first_seen <- as.integer(first_seen[out$node])
  out$pressure <- as.numeric(out$open_hits) + 0.5 * as.numeric(out$closed_hits) + 2 * as.numeric(out$current_hits)
  out
}

# Build rewind step order by popping from the persistent snapshot sequence.
# This demonstrates time-travel playback without mutating the original history.
persistent_rewind_steps <- function(snapshots) {
  if(is.null(snapshots) || length(snapshots) == 0L) {
    return(integer(0))
  }
  rest <- snapshots
  out <- integer(0)
  while(length(rest) > 0L) {
    popped <- pop_back(rest)
    out <- c(out, as.integer(popped$element$step))
    rest <- popped$remaining
  }
  out
}

.astar_has_ggtext <- function() requireNamespace("ggtext", quietly = TRUE)

.astar_color_key_subtitle <- function() {
  if(.astar_has_ggtext()) {
    paste0(
      "<span style='color:#4E9A8A'>frontier</span> &middot; ",
      "<span style='color:#F08A24'>current</span> &middot; ",
      "<span style='color:#C9C3B6'>expanded</span> &middot; ",
      "<span style='color:#D1495B'>start / goal</span>"
    )
  } else {
    "frontier (green) \u00b7 current (orange) \u00b7 expanded (tan) \u00b7 start/goal (red)"
  }
}

.astar_activity_key_subtitle <- function() {
  if(.astar_has_ggtext()) {
    paste0(
      "cell activity: ",
      "<span style='color:#C9C3B6'>low</span> &rarr; ",
      "<span style='color:#F08A24'>high</span>"
    )
  } else {
    "cell activity: low \u2192 high"
  }
}

.astar_subtitle_element <- function() {
  if(.astar_has_ggtext()) ggtext::element_markdown() else ggplot2::element_text()
}

plot_astar_snapshots <- function(
  result,
  animate = TRUE,
  outfile = NULL,
  fps = 12,
  max_animation_frames = 120L,
  frame_stride = NULL,
  playback = c("forward", "forward_rewind"),
  hold_final_frames = 8L,
  loop = TRUE,
  history_metric = c("none", "pressure", "first_seen", "expansions"),
  history_hold_frames = 12L,
  final_path_reveal = FALSE,
  reveal_hold_frames = NULL
) {
  if(!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Please install 'ggplot2' to visualize snapshots.")
  }
  playback <- match.arg(playback)
  hold_final_frames <- max(0L, as.integer(hold_final_frames))
  history_metric <- match.arg(history_metric)
  history_hold_frames <- max(0L, as.integer(history_hold_frames))
  if(is.null(reveal_hold_frames)) {
    reveal_hold_frames <- hold_final_frames
  }
  reveal_hold_frames <- max(0L, as.integer(reveal_hold_frames))

  df <- snapshots_to_df(result)
  .make_plot <- function(plot_df, caption = NULL, path_layer = c("none", "highlight", "line")) {
    path_layer <- match.arg(path_layer)
    path_color <- "#9A63C7"
    path_highlight_color <- "#F08A24"
    start_goal_color <- "#D1495B"
    path_df <- plot_df[!is.na(plot_df$path_rank), c("x", "y", "path_rank", "state"), drop = FALSE]
    if(nrow(path_df) > 0L) {
      path_df <- path_df[order(path_df$path_rank), , drop = FALSE]
    }

    p <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y, fill = state)) +
      ggplot2::geom_tile(color = "#111111", linewidth = 0.24)

    if((identical(path_layer, "highlight") || identical(path_layer, "line")) && nrow(path_df) > 0L) {
      p <- p +
        ggplot2::geom_point(
          data = path_df,
          ggplot2::aes(x = x, y = y),
          inherit.aes = FALSE,
          color = path_highlight_color,
          size = 2.3
        )
    }

    if(identical(path_layer, "line") && nrow(path_df) > 0L) {
      p <- p +
        ggplot2::geom_path(
          data = path_df,
          ggplot2::aes(x = x, y = y, group = 1L),
          inherit.aes = FALSE,
          color = "#111111",
          linewidth = 2.7,
          lineend = "round",
          linejoin = "round"
        ) +
        ggplot2::geom_path(
          data = path_df,
          ggplot2::aes(x = x, y = y, group = 1L),
          inherit.aes = FALSE,
          color = path_color,
          linewidth = 1.7,
          lineend = "round",
          linejoin = "round"
        )
    }

    p +
      ggplot2::coord_equal() +
      ggplot2::scale_y_reverse(expand = c(0, 0)) +
      ggplot2::scale_x_continuous(expand = c(0, 0)) +
      ggplot2::scale_fill_manual(
        values = c(
          empty = "#F7F4EA",
          open = "#4E9A8A",
          closed = "#C9C3B6",
          current = "#F08A24",
          start = start_goal_color,
          goal = start_goal_color,
          wall = "#2F2F2F"
        )
      ) +
      ggplot2::labs(
        title = if(result$found) "A* with Immutable Structures" else "A* with Immutable Structures (no path)",
        subtitle = .astar_color_key_subtitle(),
        caption = caption,
        x = NULL,
        y = NULL,
        fill = NULL
      ) +
      ggplot2::theme_minimal(base_size = 22) +
      ggplot2::theme(
        panel.grid = ggplot2::element_blank(),
        axis.text = ggplot2::element_blank(),
        axis.ticks = ggplot2::element_blank(),
        legend.position = "none",
        plot.subtitle = .astar_subtitle_element(),
        plot.margin = ggplot2::margin(t = 12, r = 16, b = 12, l = 16)
      )
  }

  p <- .make_plot(df, caption = NULL, path_layer = "line")

  history_df <- if(!identical(history_metric, "none")) history_cell_metrics(result) else NULL
  .make_history_plot <- function(metric_df, metric_name) {
    path_color <- "#9A63C7"
    start_goal_color <- "#D1495B"
    d <- metric_df
    path_df <- d[match(result$path, d$node), c("x", "y"), drop = FALSE]
    path_df <- path_df[stats::complete.cases(path_df), , drop = FALSE]

    title_txt <- "A* with Immutable Structures"
    if(identical(metric_name, "pressure")) {
      d$metric_value <- d$pressure
      subtitle_txt <- .astar_activity_key_subtitle()
    } else if(identical(metric_name, "expansions")) {
      d$metric_value <- as.numeric(d$current_hits)
      subtitle_txt <- "Expansion count across the full immutable timeline"
    } else {
      max_seen <- if(all(is.na(d$first_seen))) 0 else max(d$first_seen, na.rm = TRUE)
      d$metric_value <- ifelse(is.na(d$first_seen), NA_real_, as.numeric(max_seen - d$first_seen + 1L))
      subtitle_txt <- "First-seen timing from the full immutable timeline"
    }

    ggplot2::ggplot(d, ggplot2::aes(x = x, y = y)) +
      ggplot2::geom_tile(ggplot2::aes(fill = metric_value), color = "#111111", linewidth = 0.16) +
      ggplot2::geom_tile(data = d[d$wall, , drop = FALSE], fill = "#2F2F2F", color = "#2F2F2F") +
      ggplot2::geom_path(
        data = path_df,
        ggplot2::aes(x = x, y = y, group = 1L),
        inherit.aes = FALSE,
        color = "#111111",
        linewidth = 3.0,
        lineend = "round",
        linejoin = "round"
      ) +
      ggplot2::geom_path(
        data = path_df,
        ggplot2::aes(x = x, y = y, group = 1L),
        inherit.aes = FALSE,
        color = path_color,
        linewidth = 1.9,
        lineend = "round",
        linejoin = "round"
      ) +
      ggplot2::geom_point(
        data = d[d$start, , drop = FALSE],
        ggplot2::aes(x = x, y = y),
        inherit.aes = FALSE,
        shape = 22,
        fill = start_goal_color,
        color = "#111111",
        stroke = 0.56,
        size = 6.4
      ) +
      ggplot2::geom_point(
        data = d[d$goal, , drop = FALSE],
        ggplot2::aes(x = x, y = y),
        inherit.aes = FALSE,
        shape = 22,
        fill = start_goal_color,
        color = "#111111",
        stroke = 0.56,
        size = 6.4
      ) +
      ggplot2::coord_equal() +
      ggplot2::scale_y_reverse(expand = c(0, 0)) +
      ggplot2::scale_x_continuous(expand = c(0, 0)) +
      ggplot2::scale_fill_gradientn(
        colours = c("#F7F4EA", "#C9C3B6", "#F08A24"),
        na.value = "#F7F4EA"
      ) +
      ggplot2::labs(
        title = title_txt,
        subtitle = subtitle_txt,
        caption = "Computed from immutable snapshot timeline",
        x = NULL,
        y = NULL,
        fill = NULL
      ) +
      ggplot2::theme_minimal(base_size = 22) +
      ggplot2::theme(
        panel.grid = ggplot2::element_blank(),
        axis.text = ggplot2::element_blank(),
        axis.ticks = ggplot2::element_blank(),
        legend.position = "none",
        plot.subtitle = if(identical(metric_name, "pressure")) .astar_subtitle_element() else ggplot2::element_text(),
        plot.margin = ggplot2::margin(t = 12, r = 16, b = 12, l = 16)
      )
  }
  history_plot <- if(!is.null(history_df)) .make_history_plot(history_df, history_metric) else NULL

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

    playback_steps <- forward_steps
    path_layers <- rep("none", length(playback_steps))
    if(isTRUE(final_path_reveal) && identical(playback, "forward")) {
      final_step <- max(forward_steps)
      playback_steps <- c(
        playback_steps,
        rep(final_step, reveal_hold_frames),
        rep(final_step, hold_final_frames)
      )
      path_layers <- c(
        path_layers,
        rep("highlight", reveal_hold_frames),
        rep("line", hold_final_frames)
      )
    } else {
      playback_steps <- c(playback_steps, rep(max(forward_steps), hold_final_frames))
      path_layers <- c(path_layers, rep("line", hold_final_frames))
    }
    if(identical(playback, "forward_rewind")) {
      rewind_steps_all <- persistent_rewind_steps(result$snapshots)
      rewind_steps <- rewind_steps_all[rewind_steps_all %in% forward_steps]
      if(length(rewind_steps) > 0L) {
        rewind_steps <- rewind_steps[rewind_steps != max(forward_steps)]
      }
      playback_steps <- c(playback_steps, rewind_steps)
      path_layers <- c(path_layers, rep("line", length(rewind_steps)))
    }
    extra_history_frames <- if(!is.null(history_plot)) history_hold_frames else 0L

    frame_dir <- tempfile("astar-frames-")
    dir.create(frame_dir, recursive = TRUE, showWarnings = FALSE)
    frame_paths <- file.path(frame_dir, sprintf("frame_%05d.png", seq_len(length(playback_steps) + extra_history_frames)))

    for(i in seq_along(playback_steps)) {
      step_i <- playback_steps[[i]]
      frame_df <- df[df$step == step_i, , drop = FALSE]
      frame_plot <- .make_plot(
        frame_df,
        caption = paste0(
          "Step: ", step_i,
          if(identical(playback, "forward_rewind") && i > length(forward_steps) + hold_final_frames) " (rewind)" else ""
        ),
        path_layer = path_layers[[i]]
      )
      ggplot2::ggsave(
        filename = frame_paths[[i]],
        plot = frame_plot,
        width = 1680 / 96,
        height = 1120 / 96,
        dpi = 96,
        units = "in"
      )
    }
    if(extra_history_frames > 0L) {
      for(i in seq_len(extra_history_frames)) {
        idx <- length(playback_steps) + i
        ggplot2::ggsave(
          filename = frame_paths[[idx]],
          plot = history_plot,
          width = 1680 / 96,
          height = 1120 / 96,
          dpi = 96,
          units = "in"
        )
      }
    }

    if(is.null(outfile)) {
      outfile <- tempfile("astar-demo-", fileext = ".gif")
    }

    gifski::gifski(
      png_files = frame_paths,
      gif_file = outfile,
      width = 1680,
      height = 1120,
      delay = 1 / fps,
      loop = isTRUE(loop),
      progress = FALSE
    )

    return(list(
      type = "animation",
      plot = p,
      history_plot = history_plot,
      gif = outfile,
      data = df,
      frame_count = length(playback_steps) + extra_history_frames
    ))
  }

  # Static fallback: show selected key frames.
  steps <- sort(unique(df$step))
  keep <- unique(round(seq(1, length(steps), length.out = min(12, length(steps)))))
  keep_steps <- steps[keep]
  static_df <- df[df$step %in% keep_steps, , drop = FALSE]

  p_static <- p +
    ggplot2::facet_wrap(~ step, ncol = 4) +
    ggplot2::labs(caption = "Install 'gganimate' for full step-by-step animation.")

  print(p_static)
  list(type = "static", plot = p_static, history_plot = history_plot, data = static_df)
}

run_astar_demo <- function(
  complexity = c("simple", "standard", "complex"),
  width = NULL,
  height = NULL,
  wall_spacing = NULL,
  gap_half_width = NULL,
  gap_stride = NULL,
  maze_seed = NULL,
  max_steps = NULL,
  animate = TRUE,
  outfile = NULL,
  fps = 12,
  visualize = TRUE,
  track_snapshots = TRUE,
  max_animation_frames = 120L,
  frame_stride = NULL,
  playback = c("forward", "forward_rewind"),
  hold_final_frames = 8L,
  loop = TRUE,
  history_metric = c("none", "pressure", "first_seen", "expansions"),
  history_hold_frames = 12L,
  final_path_reveal = FALSE,
  reveal_hold_frames = NULL
) {
  playback <- match.arg(playback)
  history_metric <- match.arg(history_metric)
  cfg <- resolve_demo_config(
    complexity = match.arg(complexity),
    width = width,
    height = height,
    wall_spacing = wall_spacing,
    gap_half_width = gap_half_width,
    gap_stride = gap_stride,
    maze_seed = maze_seed,
    max_steps = max_steps
  )

  grid <- build_demo_grid(
    width = cfg$width,
    height = cfg$height,
    wall_spacing = cfg$wall_spacing,
    gap_half_width = cfg$gap_half_width,
    gap_stride = cfg$gap_stride,
    maze_seed = cfg$maze_seed
  )
  effective_track <- isTRUE(track_snapshots) || isTRUE(visualize)
  result <- run_astar_immutables(grid = grid, max_steps = cfg$max_steps, track_snapshots = effective_track)

  viz <- NULL
  if(isTRUE(visualize)) {
    viz <- plot_astar_snapshots(
      result,
      animate = animate,
      outfile = outfile,
      fps = fps,
      max_animation_frames = max_animation_frames,
      frame_stride = frame_stride,
      playback = playback,
      hold_final_frames = hold_final_frames,
      loop = loop,
      history_metric = history_metric,
      history_hold_frames = history_hold_frames,
      final_path_reveal = final_path_reveal,
      reveal_hold_frames = reveal_hold_frames
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
  demo <- run_astar_demo(
    complexity = "complex",
    animate = TRUE,
    visualize = TRUE,
    outfile = "meta/astar_simple.gif",
    max_animation_frames = 90L
  )
  cat("Complexity:", demo$config$complexity, "\n")
  cat("Grid:", demo$config$width, "x", demo$config$height, "\n")
  cat("A* found path:", demo$found, "\n")
  cat("Path length:", demo$path_length, "\n")
  cat("Snapshots:", demo$steps, "\n")
  if(!is.null(demo$visualization$frame_count)) {
    cat("Animation frames:", demo$visualization$frame_count, "\n")
  }
  if(!is.null(demo$visualization$gif)) {
    cat("Animation GIF:", demo$visualization$gif, "\n")
  }
#}
