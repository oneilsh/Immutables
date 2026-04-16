# Convex hull demo (monotone chain) for the immutables package.
#
# Structures used:
# - ordered_sequence: sorted point stream by x then y
# - flexseq: persistent lower/upper hull stacks and snapshot timeline

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

hull_complexity_config <- function(complexity = c("simple", "standard", "complex")) {
  complexity <- match.arg(complexity)
  if(identical(complexity, "simple")) {
    return(list(
      complexity = complexity,
      n_points = 55L,
      x_max = 120L,
      y_max = 80L,
      seed = 41L,
      max_animation_frames = 120L
    ))
  }
  if(identical(complexity, "complex")) {
    return(list(
      complexity = complexity,
      n_points = 140L,
      x_max = 220L,
      y_max = 140L,
      seed = 87L,
      max_animation_frames = 220L
    ))
  }
  list(
    complexity = "standard",
    n_points = 90L,
    x_max = 165L,
    y_max = 105L,
    seed = 63L,
    max_animation_frames = 170L
  )
}

resolve_hull_config <- function(
  complexity = c("simple", "standard", "complex"),
  n_points = NULL,
  x_max = NULL,
  y_max = NULL,
  seed = NULL,
  max_animation_frames = NULL
) {
  cfg <- hull_complexity_config(match.arg(complexity))
  if(!is.null(n_points)) cfg$n_points <- as.integer(n_points)
  if(!is.null(x_max)) cfg$x_max <- as.integer(x_max)
  if(!is.null(y_max)) cfg$y_max <- as.integer(y_max)
  if(!is.null(seed)) cfg$seed <- as.integer(seed)
  if(!is.null(max_animation_frames)) cfg$max_animation_frames <- as.integer(max_animation_frames)
  cfg
}

generate_hull_points <- function(n_points = 90L, x_max = 165L, y_max = 105L, seed = 63L) {
  stopifnot(n_points >= 8L, x_max >= 40L, y_max >= 30L)
  set.seed(as.integer(seed))

  cx <- x_max / 2
  cy <- y_max / 2
  theta <- pi / 7
  ctheta <- cos(theta)
  stheta <- sin(theta)

  draw_batch <- function(k) {
    shell <- runif(k) < 0.22
    su <- ifelse(shell, x_max * 0.27, x_max * 0.15)
    sv <- ifelse(shell, y_max * 0.27, y_max * 0.15)

    u <- rnorm(k, mean = 0, sd = su)
    v <- rnorm(k, mean = 0, sd = sv)

    x <- round(cx + (u * ctheta - v * stheta))
    y <- round(cy + (u * stheta + v * ctheta))

    inside <- x >= 2L & x <= (x_max - 1L) & y >= 2L & y <= (y_max - 1L)
    data.frame(
      x = as.integer(x[inside]),
      y = as.integer(y[inside]),
      stringsAsFactors = FALSE
    )
  }

  pts <- data.frame(x = integer(0), y = integer(0), stringsAsFactors = FALSE)
  while(nrow(pts) < n_points) {
    need <- as.integer(n_points - nrow(pts))
    batch <- draw_batch(max(32L, need * 4L))
    if(nrow(batch) == 0L) next
    pts <- rbind(pts, batch)
    key <- paste0(pts$x, ",", pts$y)
    pts <- pts[!duplicated(key), , drop = FALSE]
  }

  pts <- pts[seq_len(n_points), , drop = FALSE]
  pts$id <- sprintf("P%03d", seq_len(nrow(pts)))
  pts
}

orientation <- function(a, b, c) {
  (b$x - a$x) * (c$y - a$y) - (b$y - a$y) * (c$x - a$x)
}

seq_to_point_df <- function(x) {
  if(is.null(x) || length(x) == 0L) {
    return(data.frame(id = character(0), x = numeric(0), y = numeric(0), stringsAsFactors = FALSE))
  }
  el <- as.list(x)
  data.frame(
    id = vapply(el, function(e) e$id, character(1)),
    x = vapply(el, function(e) as.numeric(e$x), numeric(1)),
    y = vapply(el, function(e) as.numeric(e$y), numeric(1)),
    stringsAsFactors = FALSE
  )
}

last_two_points <- function(stack_seq) {
  if(length(stack_seq) < 2L) {
    return(NULL)
  }
  out1 <- pop_back(stack_seq)
  rest1 <- if(!is.null(out1$rest)) out1$rest else out1$remaining
  out2 <- pop_back(rest1)
  el1 <- if(!is.null(out1$element)) out1$element else out1$value
  el2 <- if(!is.null(out2$element)) out2$element else out2$value
  if(is.null(el1) || is.null(el2)) {
    return(NULL)
  }
  list(a = el2, b = el1)
}

make_hull_snapshot <- function(step, phase, note, current_point, lower, upper, hull = NULL, processed = NULL) {
  list(
    step = as.integer(step),
    phase = phase,
    note = note,
    current_point = current_point,
    lower = lower,
    upper = upper,
    hull = hull,
    processed = processed
  )
}

run_monotone_chain_immutables <- function(points, track_snapshots = TRUE) {
  load_immutables()

  if(!all(c("id", "x", "y") %in% names(points))) {
    stop("`points` must include columns: id, x, y")
  }

  dedup_key <- paste0(points$x, ",", points$y)
  pts <- points[!duplicated(dedup_key), c("id", "x", "y"), drop = FALSE]
  rownames(pts) <- NULL

  y_scale <- as.numeric(max(pts$y) + 5L)
  keys <- as.numeric(pts$x) * y_scale + as.numeric(pts$y)
  items <- lapply(
    seq_len(nrow(pts)),
    function(i) list(id = as.character(pts$id[[i]]), x = as.numeric(pts$x[[i]]), y = as.numeric(pts$y[[i]]))
  )
  sorted_seq <- as_ordered_sequence(items, keys = keys)
  sorted_items <- as.list(sorted_seq)

  if(length(sorted_items) <= 1L) {
    hull <- as_flexseq(sorted_items)
    return(list(points = pts, sorted_points = sorted_items, lower = hull, upper = flexseq(), hull = hull, snapshots = if(track_snapshots) as_flexseq(list()) else NULL, steps = 0L))
  }

  lower <- flexseq()
  upper <- flexseq()
  snapshots <- if(isTRUE(track_snapshots)) flexseq() else NULL
  step <- 0L

  if(isTRUE(track_snapshots)) {
    snapshots <- push_back(
      snapshots,
      make_hull_snapshot(step, phase = "start", note = "init", current_point = NULL, lower = lower, upper = upper, processed = integer(0))
    )
  }

  processed_ids <- character(0)

  # Build lower hull.
  for(i in seq_along(sorted_items)) {
    p <- sorted_items[[i]]
    processed_ids <- c(processed_ids, p$id)

    repeat {
      last2 <- last_two_points(lower)
      if(is.null(last2)) break
      turn <- orientation(last2$a, last2$b, p)
      if(turn > 0) break

      lower_pop <- pop_back(lower)
      lower <- if(!is.null(lower_pop$rest)) lower_pop$rest else lower_pop$remaining
      step <- step + 1L
      if(isTRUE(track_snapshots)) {
        snapshots <- push_back(
          snapshots,
          make_hull_snapshot(step, phase = "lower", note = "pop", current_point = p, lower = lower, upper = upper, processed = processed_ids)
        )
      }
    }

    lower <- push_back(lower, p)
    step <- step + 1L
    if(isTRUE(track_snapshots)) {
      snapshots <- push_back(
        snapshots,
        make_hull_snapshot(step, phase = "lower", note = "push", current_point = p, lower = lower, upper = upper, processed = processed_ids)
      )
    }
  }

  # Build upper hull.
  rev_items <- rev(sorted_items)
  processed_upper <- character(0)
  for(i in seq_along(rev_items)) {
    p <- rev_items[[i]]
    processed_upper <- c(processed_upper, p$id)

    repeat {
      last2 <- last_two_points(upper)
      if(is.null(last2)) break
      turn <- orientation(last2$a, last2$b, p)
      if(turn > 0) break

      upper_pop <- pop_back(upper)
      upper <- if(!is.null(upper_pop$rest)) upper_pop$rest else upper_pop$remaining
      step <- step + 1L
      if(isTRUE(track_snapshots)) {
        snapshots <- push_back(
          snapshots,
          make_hull_snapshot(step, phase = "upper", note = "pop", current_point = p, lower = lower, upper = upper, processed = processed_upper)
        )
      }
    }

    upper <- push_back(upper, p)
    step <- step + 1L
    if(isTRUE(track_snapshots)) {
      snapshots <- push_back(
        snapshots,
        make_hull_snapshot(step, phase = "upper", note = "push", current_point = p, lower = lower, upper = upper, processed = processed_upper)
      )
    }
  }

  lower_list <- as.list(lower)
  upper_list <- as.list(upper)
  upper_mid <- if(length(upper_list) > 2L) upper_list[2L:(length(upper_list) - 1L)] else list()
  hull_list <- c(lower_list, upper_mid)
  hull_seq <- as_flexseq(hull_list)

  step <- step + 1L
  if(isTRUE(track_snapshots)) {
    snapshots <- push_back(
      snapshots,
      make_hull_snapshot(step, phase = "done", note = "hull", current_point = NULL, lower = lower, upper = upper, hull = hull_seq, processed = unique(c(processed_ids, processed_upper)))
    )
  }

  list(
    points = pts,
    sorted_points = sorted_items,
    lower = lower,
    upper = upper,
    hull = hull_seq,
    snapshots = snapshots,
    steps = as.integer(step)
  )
}

plot_hull_snapshots <- function(
  result,
  animate = TRUE,
  outfile = NULL,
  fps = 10,
  max_animation_frames = 170L,
  frame_stride = NULL,
  hold_final_frames = 10L,
  loop = TRUE
) {
  if(is.null(result$snapshots)) {
    stop("No snapshots available. Re-run with `track_snapshots = TRUE`.")
  }
  if(!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Please install 'ggplot2' to visualize snapshots.")
  }

  shots <- as.list(result$snapshots)
  nshots <- length(shots)
  if(nshots == 0L) {
    stop("No snapshots to render.")
  }

  pts <- result$points

  frame_idx <- seq_len(nshots)
  if(is.null(frame_stride)) {
    frame_stride <- max(1L, as.integer(ceiling(nshots / as.integer(max_animation_frames))))
  } else {
    frame_stride <- max(1L, as.integer(frame_stride))
  }
  frame_idx <- frame_idx[seq.int(1L, length(frame_idx), by = frame_stride)]
  if(frame_idx[[length(frame_idx)]] != nshots) {
    frame_idx <- c(frame_idx, nshots)
  }

  .frame_plot <- function(s) {
    lower_df <- seq_to_point_df(s$lower)
    upper_df <- seq_to_point_df(s$upper)
    hull_df <- seq_to_point_df(s$hull)
    current_df <- if(is.null(s$current_point)) data.frame(x = numeric(0), y = numeric(0)) else data.frame(x = s$current_point$x, y = s$current_point$y)

    processed_ids <- if(is.null(s$processed)) character(0) else unique(as.character(s$processed))
    pts$processed <- pts$id %in% processed_ids

    lower_path <- if(nrow(lower_df) >= 2L) lower_df else lower_df[0, , drop = FALSE]
    upper_path <- if(nrow(upper_df) >= 2L) upper_df else upper_df[0, , drop = FALSE]
    if(nrow(hull_df) >= 2L) {
      hull_path <- rbind(hull_df, hull_df[1L, , drop = FALSE])
    } else {
      hull_path <- hull_df[0, , drop = FALSE]
    }

    ggplot2::ggplot() +
      ggplot2::geom_point(
        data = pts,
        ggplot2::aes(x = x, y = y, color = processed),
        size = 1.9,
        alpha = 0.92
      ) +
      ggplot2::scale_color_manual(values = c(`TRUE` = "#5C8A7C", `FALSE` = "#C5BFB3"), guide = "none") +
      ggplot2::geom_path(
        data = lower_path,
        ggplot2::aes(x = x, y = y),
        color = "#2C7BE5",
        linewidth = 1.2,
        lineend = "round",
        linejoin = "round"
      ) +
      ggplot2::geom_path(
        data = upper_path,
        ggplot2::aes(x = x, y = y),
        color = "#2AA876",
        linewidth = 1.2,
        lineend = "round",
        linejoin = "round"
      ) +
      ggplot2::geom_polygon(
        data = hull_df,
        ggplot2::aes(x = x, y = y),
        fill = "#F6C945",
        alpha = if(identical(s$phase, "done")) 0.22 else 0.0,
        color = NA
      ) +
      ggplot2::geom_path(
        data = hull_path,
        ggplot2::aes(x = x, y = y),
        color = "#3E4A56",
        linewidth = if(identical(s$phase, "done")) 0.95 else 0.75,
        alpha = if(nrow(hull_path) >= 2L) 0.9 else 0,
        lineend = "round",
        linejoin = "round"
      ) +
      ggplot2::geom_point(
        data = current_df,
        ggplot2::aes(x = x, y = y),
        shape = 21,
        stroke = 0.8,
        fill = "#F08A24",
        color = "#111111",
        size = 3
      ) +
      ggplot2::labs(
        title = "Persistent Monotone Chain Convex Hull",
        subtitle = sprintf(
          "step=%d | phase=%s | action=%s",
          s$step,
          s$phase,
          s$note
        ),
        x = "x",
        y = "y"
      ) +
      ggplot2::coord_equal() +
      ggplot2::theme_minimal(base_size = 12) +
      ggplot2::theme(
        panel.grid.minor = ggplot2::element_blank(),
        panel.grid.major = ggplot2::element_line(color = "#E8E3D8", linewidth = 0.25)
      )
  }

  if(isTRUE(animate)) {
    if(!requireNamespace("gifski", quietly = TRUE)) {
      stop("Animation requested but 'gifski' is not installed.")
    }

    render_idx <- c(frame_idx, rep(frame_idx[[length(frame_idx)]], as.integer(max(0L, hold_final_frames))))

    frame_dir <- tempfile("hull-frames-")
    dir.create(frame_dir, recursive = TRUE, showWarnings = FALSE)
    frame_paths <- file.path(frame_dir, sprintf("frame_%05d.png", seq_along(render_idx)))

    for(i in seq_along(render_idx)) {
      p <- .frame_plot(shots[[render_idx[[i]]]])
      ggplot2::ggsave(
        filename = frame_paths[[i]],
        plot = p,
        width = 980 / 96,
        height = 620 / 96,
        dpi = 96,
        units = "in"
      )
    }

    if(is.null(outfile)) {
      outfile <- tempfile("convex-hull-", fileext = ".gif")
    }

    gifski::gifski(
      png_files = frame_paths,
      gif_file = outfile,
      width = 980,
      height = 620,
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

run_convex_hull_demo <- function(
  complexity = c("simple", "standard", "complex"),
  n_points = NULL,
  x_max = NULL,
  y_max = NULL,
  seed = NULL,
  visualize = TRUE,
  animate = TRUE,
  outfile = NULL,
  fps = 10,
  max_animation_frames = NULL,
  frame_stride = NULL,
  hold_final_frames = 10L,
  loop = TRUE,
  track_snapshots = TRUE
) {
  cfg <- resolve_hull_config(
    complexity = match.arg(complexity),
    n_points = n_points,
    x_max = x_max,
    y_max = y_max,
    seed = seed,
    max_animation_frames = max_animation_frames
  )

  points <- generate_hull_points(
    n_points = cfg$n_points,
    x_max = cfg$x_max,
    y_max = cfg$y_max,
    seed = cfg$seed
  )

  effective_track <- isTRUE(track_snapshots) || isTRUE(visualize)
  result <- run_monotone_chain_immutables(points, track_snapshots = effective_track)

  viz <- NULL
  if(isTRUE(visualize)) {
    viz <- plot_hull_snapshots(
      result,
      animate = animate,
      outfile = outfile,
      fps = fps,
      max_animation_frames = cfg$max_animation_frames,
      frame_stride = frame_stride,
      hold_final_frames = hold_final_frames,
      loop = loop
    )
  }

  hull_n <- length(result$hull)
  list(
    config = cfg,
    points = nrow(points),
    hull_points = as.integer(hull_n),
    steps = result$steps,
    visualization = viz,
    result = result
  )
}

# Minimal article-friendly wrapper.
run_convex_hull_paper_core <- function(complexity = c("simple", "standard", "complex")) {
  cfg <- resolve_hull_config(complexity = match.arg(complexity))
  points <- generate_hull_points(cfg$n_points, cfg$x_max, cfg$y_max, cfg$seed)
  out <- run_monotone_chain_immutables(points, track_snapshots = FALSE)
  list(
    n_points = nrow(points),
    hull_points = length(out$hull),
    steps = out$steps
  )
}

if(sys.nframe() == 0L) {
  demo <- run_convex_hull_demo(complexity = "standard", visualize = FALSE, animate = FALSE)
  cat("Convex hull demo\n")
  cat("Complexity:", demo$config$complexity, "\n")
  cat("Points:", demo$points, "\n")
  cat("Hull points:", demo$hull_points, "\n")
  cat("Steps:", demo$steps, "\n")
}
