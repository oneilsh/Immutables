# Sweep-line interval demo for the immutables package.
#
# Structures used:
# - interval_index: point overlap queries at each sweep position
# - ordered_sequence: persistent event stream ordered by x-coordinate
# - flexseq: immutable snapshot history for replay/visualization

load_immutables <- function() {
  if(requireNamespace("pkgload", quietly = TRUE)) {
    pkgload::load_all(".", quiet = TRUE)
    return(invisible(TRUE))
  }
  if(requireNamespace("Immutables", quietly = TRUE)) {
    library(Immutables)
    return(invisible(TRUE))
  }
  stop("Need either installed 'Immutables' or the 'pkgload' package.")
}

sweep_complexity_config <- function(complexity = c("simple", "standard", "complex")) {
  complexity <- match.arg(complexity)
  if(identical(complexity, "simple")) {
    return(list(
      complexity = complexity,
      n_tracks = 5L,
      intervals_per_track = 4L,
      x_max = 70L,
      min_len = 8L,
      max_len = 18L,
      min_gap = 2L,
      max_animation_frames = 60L
    ))
  }
  if(identical(complexity, "complex")) {
    return(list(
      complexity = complexity,
      n_tracks = 10L,
      intervals_per_track = 8L,
      x_max = 140L,
      min_len = 10L,
      max_len = 30L,
      min_gap = 2L,
      max_animation_frames = 140L
    ))
  }
  list(
    complexity = "standard",
    n_tracks = 7L,
    intervals_per_track = 6L,
    x_max = 100L,
    min_len = 9L,
    max_len = 24L,
    min_gap = 2L,
    max_animation_frames = 90L
  )
}

resolve_sweep_config <- function(
  complexity = c("simple", "standard", "complex"),
  n_tracks = NULL,
  intervals_per_track = NULL,
  x_max = NULL,
  min_len = NULL,
  max_len = NULL,
  min_gap = NULL,
  max_animation_frames = NULL
) {
  cfg <- sweep_complexity_config(match.arg(complexity))
  if(!is.null(n_tracks)) cfg$n_tracks <- as.integer(n_tracks)
  if(!is.null(intervals_per_track)) cfg$intervals_per_track <- as.integer(intervals_per_track)
  if(!is.null(x_max)) cfg$x_max <- as.integer(x_max)
  if(!is.null(min_len)) cfg$min_len <- as.integer(min_len)
  if(!is.null(max_len)) cfg$max_len <- as.integer(max_len)
  if(!is.null(min_gap)) cfg$min_gap <- as.integer(min_gap)
  if(!is.null(max_animation_frames)) cfg$max_animation_frames <- as.integer(max_animation_frames)
  cfg
}

generate_sweep_intervals <- function(
  n_tracks = 7L,
  intervals_per_track = 6L,
  x_max = 100L,
  min_len = 9L,
  max_len = 24L,
  min_gap = 2L,
  seed = 42L
) {
  stopifnot(n_tracks >= 1L, intervals_per_track >= 1L)
  stopifnot(min_len >= 1L, max_len >= min_len, min_gap >= 0L)
  required_span <- as.integer(intervals_per_track * min_len + (intervals_per_track - 1L) * min_gap)
  if(x_max < required_span) {
    stop("Configuration too dense: need x_max >= ", required_span, " for non-overlapping per-track intervals.")
  }

  set.seed(seed)
  draw_scalar <- function(values) {
    values[[sample.int(length(values), 1L)]]
  }
  draw_partition <- function(total, parts) {
    if(total <= 0L) {
      return(integer(parts))
    }
    as.integer(stats::rmultinom(1L, size = as.integer(total), prob = rep(1, parts)))
  }

  out <- vector("list", n_tracks * intervals_per_track)
  k <- 1L
  for(track in seq_len(n_tracks)) {
    lengths <- integer(intervals_per_track)
    used_len <- 0L
    len_budget <- as.integer(x_max - (intervals_per_track - 1L) * min_gap)

    for(j in seq_len(intervals_per_track)) {
      remaining <- as.integer(intervals_per_track - j)
      min_tail_len <- as.integer(remaining * min_len)
      max_len_here <- as.integer(min(max_len, len_budget - used_len - min_tail_len))
      len <- if(max_len_here > min_len) {
        as.integer(draw_scalar(seq.int(min_len, max_len_here)))
      } else {
        as.integer(min_len)
      }
      lengths[[j]] <- len
      used_len <- as.integer(used_len + len)
    }

    span <- as.integer(sum(lengths) + (intervals_per_track - 1L) * min_gap)
    slack <- as.integer(x_max - span)
    # Randomly distribute free space before, between, and after intervals.
    extra <- draw_partition(slack, intervals_per_track + 1L)

    starts <- integer(intervals_per_track)
    ends <- integer(intervals_per_track)
    starts[[1L]] <- as.integer(1L + extra[[1L]])
    ends[[1L]] <- as.integer(starts[[1L]] + lengths[[1L]])
    if(intervals_per_track > 1L) {
      for(j in 2:intervals_per_track) {
        starts[[j]] <- as.integer(ends[[j - 1L]] + min_gap + extra[[j]])
        ends[[j]] <- as.integer(starts[[j]] + lengths[[j]])
      }
    }

    for(j in seq_len(intervals_per_track)) {
      out[[k]] <- data.frame(
        id = sprintf("T%02d_I%02d", track, j),
        track = as.integer(track),
        start = as.integer(starts[[j]]),
        end = as.integer(ends[[j]]),
        stringsAsFactors = FALSE
      )
      k <- k + 1L
    }
  }

  intervals <- do.call(rbind, out)
  intervals <- intervals[order(intervals$track, intervals$start, intervals$end, intervals$id), , drop = FALSE]
  rownames(intervals) <- NULL
  intervals
}

make_sweep_snapshot <- function(step, x, active_ids, events_now) {
  list(
    step = as.integer(step),
    x = x,
    active_ids = active_ids,
    n_active = as.integer(length(active_ids)),
    events_now = events_now
  )
}

build_interval_items <- function(intervals) {
  lapply(
    seq_len(nrow(intervals)),
    function(i) {
      list(
        id = intervals$id[[i]],
        track = as.integer(intervals$track[[i]]),
        start = as.integer(intervals$start[[i]]),
        end = as.integer(intervals$end[[i]])
      )
    }
  )
}

build_event_stream <- function(intervals) {
  n <- nrow(intervals)
  items <- vector("list", n * 2L)
  keys <- integer(n * 2L)
  k <- 1L

  for(i in seq_len(n)) {
    id <- intervals$id[[i]]
    tr <- as.integer(intervals$track[[i]])
    st <- as.integer(intervals$start[[i]])
    en <- as.integer(intervals$end[[i]])

    items[[k]] <- list(type = "start", id = id, track = tr, start = st, end = en)
    keys[[k]] <- st
    k <- k + 1L

    items[[k]] <- list(type = "end", id = id, track = tr, start = st, end = en)
    keys[[k]] <- en
    k <- k + 1L
  }

  as_ordered_sequence(items, keys = keys)
}

# Compact core algorithm suitable for article snippets.
sweep_line_core_immutables <- function(intervals, bounds = "[)", track_snapshots = TRUE) {
  load_immutables()

  if(!is.data.frame(intervals)) {
    stop("`intervals` must be a data.frame.")
  }
  needed <- c("id", "track", "start", "end")
  if(!all(needed %in% names(intervals))) {
    stop("`intervals` must include columns: id, track, start, end.")
  }

  items <- build_interval_items(intervals)
  index <- as_interval_index(items, start = intervals$start, end = intervals$end, default_query_bounds = bounds)
  events <- build_event_stream(intervals)

  sweep_points <- sort(unique(c(intervals$start, intervals$end)))
  events_remaining <- events
  snapshots <- if(isTRUE(track_snapshots)) flexseq() else NULL

  step <- 0L
  for(x in sweep_points) {
    # Persistent event stream update using ordered_sequence key pops.
    popped <- pop_all_key(events_remaining, x)
    events_now <- as.list(popped$elements)
    events_remaining <- popped$remaining

    # Active interval query via interval_index.
    active_slice <- peek_all_point(index, x, bounds = bounds)
    active_items <- as.list(active_slice)
    active_ids <- if(length(active_items) == 0L) {
      character(0)
    } else {
      vapply(active_items, function(it) it$id, character(1))
    }

    step <- step + 1L
    if(isTRUE(track_snapshots)) {
      snapshots <- push_back(
        snapshots,
        make_sweep_snapshot(step = step, x = x, active_ids = active_ids, events_now = events_now)
      )
    }
  }

  list(
    intervals = intervals,
    bounds = bounds,
    index = index,
    event_stream = events,
    snapshots = snapshots,
    n_steps = as.integer(length(sweep_points)),
    sweep_points = sweep_points
  )
}

sweep_snapshots_to_df <- function(result) {
  if(is.null(result$snapshots)) {
    stop("No snapshots available. Re-run core with `track_snapshots = TRUE`.")
  }

  intervals <- result$intervals
  shots <- as.list(result$snapshots)
  frames <- vector("list", length(shots))

  for(i in seq_along(shots)) {
    s <- shots[[i]]
    d <- intervals

    d$state <- ifelse(
      d$id %in% s$active_ids,
      "active",
      ifelse(as.integer(d$end) <= as.integer(s$x), "past", "future")
    )

    start_n <- sum(vapply(s$events_now, function(e) identical(e$type, "start"), logical(1)))
    end_n <- sum(vapply(s$events_now, function(e) identical(e$type, "end"), logical(1)))

    d$step <- s$step
    d$sweep_x <- as.integer(s$x)
    d$n_active <- s$n_active
    d$start_events <- as.integer(start_n)
    d$end_events <- as.integer(end_n)

    frames[[i]] <- d
  }

  out <- do.call(rbind, frames)
  out$state <- factor(out$state, levels = c("future", "active", "past"))
  out
}

plot_sweep_line <- function(
  result,
  animate = TRUE,
  outfile = NULL,
  fps = 12,
  max_animation_frames = 90L,
  frame_stride = NULL,
  hold_final_frames = 0L,
  loop = TRUE,
  width_px = 1600L,
  height_px = 832L
) {
  if(!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Please install 'ggplot2' to visualize snapshots.")
  }

  df <- sweep_snapshots_to_df(result)

  .frame_plot <- function(frame_df) {
    meta <- frame_df[1L, c("sweep_x", "n_active", "start_events", "end_events")]
    ggplot2::ggplot(frame_df) +
      ggplot2::geom_segment(
        ggplot2::aes(x = start, xend = end, y = track, yend = track, color = state),
        linewidth = 4.0,
        lineend = "round",
        alpha = 0.95
      ) +
      ggplot2::geom_point(
        ggplot2::aes(x = start, y = track),
        size = 2.0,
        shape = 21,
        stroke = 0.33,
        fill = "white",
        color = "#333333"
      ) +
      ggplot2::geom_point(
        ggplot2::aes(x = end, y = track),
        size = 2.0,
        shape = 21,
        stroke = 0.33,
        fill = "#333333",
        color = "#333333"
      ) +
      ggplot2::geom_vline(xintercept = meta$sweep_x, linewidth = 1.3, color = "#111111", linetype = "22") +
      ggplot2::scale_color_manual(
        values = c(
          future = "#B8B3A7",
          active = "#D1495B",
          past = "#4E9A8A"
        )
      ) +
      ggplot2::scale_y_continuous(
        breaks = sort(unique(frame_df$track)),
        expand = ggplot2::expansion(mult = c(0.015, 0.015))
      ) +
      ggplot2::scale_x_continuous(expand = c(0.01, 0.01)) +
      ggplot2::labs(
        title = "Sweep-Line Interval Activity",
        subtitle = sprintf("x=%s | active=%s", meta$sweep_x, meta$n_active),
        x = "Position",
        y = "Track",
        color = NULL
      ) +
      ggplot2::theme_minimal(base_size = 18) +
      ggplot2::theme(
        panel.grid.minor = ggplot2::element_blank(),
        panel.grid.major.y = ggplot2::element_line(color = "#E8E3D8", linewidth = 0.5),
        legend.position = "top",
        plot.margin = ggplot2::margin(t = 5, r = 12, b = 5, l = 12)
      )
  }

  if(isTRUE(animate)) {
    if(!requireNamespace("gifski", quietly = TRUE)) {
      stop("Animation requested but 'gifski' is not installed.")
    }

    steps <- sort(unique(df$step))
    if(is.null(frame_stride)) {
      frame_stride <- max(1L, as.integer(ceiling(length(steps) / as.integer(max_animation_frames))))
    } else {
      frame_stride <- max(1L, as.integer(frame_stride))
    }
    steps <- steps[seq.int(1L, length(steps), by = frame_stride)]

    hold_final_frames <- max(0L, as.integer(hold_final_frames))
    render_steps <- c(steps, rep(steps[[length(steps)]], hold_final_frames))

    frame_dir <- tempfile("sweep-frames-")
    dir.create(frame_dir, recursive = TRUE, showWarnings = FALSE)
    frame_paths <- file.path(frame_dir, sprintf("frame_%05d.png", seq_along(render_steps)))

    for(i in seq_along(render_steps)) {
      step_i <- render_steps[[i]]
      frame_df <- df[df$step == step_i, , drop = FALSE]
      p <- .frame_plot(frame_df)
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
      outfile <- tempfile("sweep-line-", fileext = ".gif")
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

    return(list(type = "animation", gif = outfile, frame_count = length(render_steps), data = df))
  }

  # Static fallback for quick preview.
  steps <- sort(unique(df$step))
  keep <- unique(round(seq(1, length(steps), length.out = min(12, length(steps)))))
  keep_steps <- steps[keep]
  static_frames <- lapply(keep_steps, function(step_i) .frame_plot(df[df$step == step_i, , drop = FALSE]))

  # Print the final sampled frame to keep output concise in non-interactive runs.
  print(static_frames[[length(static_frames)]])

  list(type = "static", frame_count = length(keep_steps), frames = static_frames, data = df)
}

run_sweep_line_demo <- function(
  complexity = c("simple", "standard", "complex"),
  n_tracks = NULL,
  intervals_per_track = NULL,
  x_max = NULL,
  min_len = NULL,
  max_len = NULL,
  min_gap = NULL,
  seed = 42L,
  visualize = TRUE,
  animate = TRUE,
  outfile = NULL,
  fps = 12,
  max_animation_frames = NULL,
  frame_stride = NULL,
  hold_final_frames = 0L,
  loop = TRUE,
  width_px = 1600L,
  height_px = 832L,
  track_snapshots = TRUE
) {
  cfg <- resolve_sweep_config(
    complexity = match.arg(complexity),
    n_tracks = n_tracks,
    intervals_per_track = intervals_per_track,
    x_max = x_max,
    min_len = min_len,
    max_len = max_len,
    min_gap = min_gap,
    max_animation_frames = max_animation_frames
  )

  intervals <- generate_sweep_intervals(
    n_tracks = cfg$n_tracks,
    intervals_per_track = cfg$intervals_per_track,
    x_max = cfg$x_max,
    min_len = cfg$min_len,
    max_len = cfg$max_len,
    min_gap = cfg$min_gap,
    seed = as.integer(seed)
  )

  effective_track <- isTRUE(track_snapshots) || isTRUE(visualize)
  result <- sweep_line_core_immutables(intervals, bounds = "[)", track_snapshots = effective_track)

  viz <- NULL
  if(isTRUE(visualize)) {
    viz <- plot_sweep_line(
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
    interval_count = nrow(intervals),
    sweep_steps = result$n_steps,
    visualization = viz,
    result = result
  )
}

# Minimal wrapper for article code blocks.
run_sweep_line_paper_core <- function(complexity = c("simple", "standard", "complex"), seed = 42L) {
  cfg <- resolve_sweep_config(complexity = match.arg(complexity))
  intervals <- generate_sweep_intervals(
    n_tracks = cfg$n_tracks,
    intervals_per_track = cfg$intervals_per_track,
    x_max = cfg$x_max,
    min_len = cfg$min_len,
    max_len = cfg$max_len,
    min_gap = cfg$min_gap,
    seed = as.integer(seed)
  )
  out <- sweep_line_core_immutables(intervals, track_snapshots = FALSE)
  list(
    interval_count = nrow(intervals),
    sweep_steps = out$n_steps,
    range_x = c(min(intervals$start), max(intervals$end))
  )
}

if(sys.nframe() == 0L) {
  demo <- run_sweep_line_demo(complexity = "standard", visualize = FALSE, animate = FALSE)
  cat("Sweep-line demo\n")
  cat("Complexity:", demo$config$complexity, "\n")
  cat("Intervals:", demo$interval_count, "\n")
  cat("Sweep steps:", demo$sweep_steps, "\n")
}
