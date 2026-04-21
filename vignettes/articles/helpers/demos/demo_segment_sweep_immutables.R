# Line-segment sweep demo for the immutables package.
#
# Structures used:
# - interval_index: active segment query at current sweep x
# - ordered_sequence: persistent event stream keyed by x
# - flexseq: immutable snapshot history

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

segment_sweep_complexity_config <- function(complexity = c("simple", "standard", "complex")) {
  complexity <- match.arg(complexity)
  if(identical(complexity, "simple")) {
    return(list(
      complexity = complexity,
      n_segments = 16L,
      x_max = 120L,
      y_max = 70L,
      min_span = 18L,
      max_span = 52L,
      seed = 42L,
      max_steps = 3000L,
      max_animation_frames = 100L
    ))
  }
  if(identical(complexity, "complex")) {
    return(list(
      complexity = complexity,
      n_segments = 36L,
      x_max = 180L,
      y_max = 100L,
      min_span = 28L,
      max_span = 84L,
      seed = 99L,
      max_steps = 9000L,
      max_animation_frames = 180L
    ))
  }
  list(
    complexity = "standard",
    n_segments = 24L,
    x_max = 145L,
    y_max = 85L,
    min_span = 22L,
    max_span = 68L,
    seed = 67L,
    max_steps = 5000L,
    max_animation_frames = 140L
  )
}

resolve_segment_sweep_config <- function(
  complexity = c("simple", "standard", "complex"),
  n_segments = NULL,
  x_max = NULL,
  y_max = NULL,
  min_span = NULL,
  max_span = NULL,
  seed = NULL,
  max_steps = NULL,
  max_animation_frames = NULL
) {
  cfg <- segment_sweep_complexity_config(match.arg(complexity))
  if(!is.null(n_segments)) cfg$n_segments <- as.integer(n_segments)
  if(!is.null(x_max)) cfg$x_max <- as.integer(x_max)
  if(!is.null(y_max)) cfg$y_max <- as.integer(y_max)
  if(!is.null(min_span)) cfg$min_span <- as.integer(min_span)
  if(!is.null(max_span)) cfg$max_span <- as.integer(max_span)
  if(!is.null(seed)) cfg$seed <- as.integer(seed)
  if(!is.null(max_steps)) cfg$max_steps <- as.integer(max_steps)
  if(!is.null(max_animation_frames)) cfg$max_animation_frames <- as.integer(max_animation_frames)
  cfg
}

generate_segments <- function(
  n_segments = 24L,
  x_max = 145L,
  y_max = 85L,
  min_span = 40L,
  max_span = 110L,
  seed = 67L
) {
  stopifnot(n_segments >= 2L, x_max >= 30L, y_max >= 20L)
  stopifnot(min_span >= 10L, max_span >= min_span)

  set.seed(as.integer(seed))

  out <- vector("list", n_segments)
  for(i in seq_len(n_segments)) {
    span <- sample(seq.int(min_span, min(max_span, x_max - 6L)), 1L)
    x1 <- as.integer(sample.int(x_max - span - 2L, 1L) + 1L)
    x2 <- as.integer(x1 + span)

    y1 <- as.integer(sample(seq.int(2L, y_max - 1L), 1L))
    slope_mode <- sample(c(-1L, 1L), 1L)
    y2_center <- as.integer(y1 + slope_mode * sample(seq.int(8L, max(8L, y_max %/% 2L)), 1L))
    y2_jitter <- sample(seq.int(-15L, 15L), 1L)
    y2 <- as.integer(max(2L, min(y_max - 1L, y2_center + y2_jitter)))

    if(y2 == y1) {
      y2 <- as.integer(max(2L, min(y_max - 1L, y1 + sample(c(-6L, 6L), 1L))))
    }

    out[[i]] <- data.frame(
      id = sprintf("S%02d", i),
      x1 = x1,
      y1 = y1,
      x2 = x2,
      y2 = y2,
      stringsAsFactors = FALSE
    )
  }

  segs <- do.call(rbind, out)
  segs <- segs[order(segs$x1, segs$x2, segs$id), , drop = FALSE]
  rownames(segs) <- NULL
  segs
}

segment_intersection <- function(a, b, eps = 1e-9) {
  p <- c(a$x1, a$y1)
  r <- c(a$x2 - a$x1, a$y2 - a$y1)
  q <- c(b$x1, b$y1)
  s <- c(b$x2 - b$x1, b$y2 - b$y1)

  cross2 <- function(u, v) u[[1L]] * v[[2L]] - u[[2L]] * v[[1L]]
  den <- cross2(r, s)
  if(abs(den) < eps) {
    return(NULL)
  }

  qmp <- c(q[[1L]] - p[[1L]], q[[2L]] - p[[2L]])
  t <- cross2(qmp, s) / den
  u <- cross2(qmp, r) / den

  if(t < -eps || t > 1 + eps || u < -eps || u > 1 + eps) {
    return(NULL)
  }

  x <- p[[1L]] + t * r[[1L]]
  y <- p[[2L]] + t * r[[2L]]
  list(x = x, y = y)
}

compute_intersections <- function(segments) {
  n <- nrow(segments)
  rec <- list()
  k <- 1L
  for(i in seq_len(n - 1L)) {
    for(j in (i + 1L):n) {
      inter <- segment_intersection(segments[i, , drop = FALSE], segments[j, , drop = FALSE])
      if(is.null(inter)) {
        next
      }
      xk <- round(inter$x, 6)
      yk <- round(inter$y, 6)
      if(!is.finite(xk) || !is.finite(yk)) {
        next
      }
      rec[[k]] <- data.frame(
        id1 = segments$id[[i]],
        id2 = segments$id[[j]],
        x = xk,
        y = yk,
        stringsAsFactors = FALSE
      )
      k <- k + 1L
    }
  }

  if(length(rec) == 0L) {
    return(data.frame(id1 = character(0), id2 = character(0), x = numeric(0), y = numeric(0)))
  }

  out <- do.call(rbind, rec)
  key <- paste(out$id1, out$id2, out$x, out$y, sep = "|")
  out <- out[!duplicated(key), , drop = FALSE]
  out <- out[order(out$x, out$y, out$id1, out$id2), , drop = FALSE]
  rownames(out) <- NULL
  out
}

y_at_x <- function(seg, x) {
  if(abs(seg$x2 - seg$x1) < 1e-9) {
    return(as.numeric(seg$y1))
  }
  t <- (x - seg$x1) / (seg$x2 - seg$x1)
  as.numeric(seg$y1 + t * (seg$y2 - seg$y1))
}

build_event_stream <- function(segments, intersections) {
  items <- list()
  keys <- numeric(0)

  for(i in seq_len(nrow(segments))) {
    seg <- segments[i, , drop = FALSE]
    x1 <- round(as.numeric(seg$x1), 6)
    x2 <- round(as.numeric(seg$x2), 6)

    items[[length(items) + 1L]] <- list(
      type = "start",
      segment_id = seg$id[[1L]],
      x = x1,
      y = as.numeric(seg$y1)
    )
    keys <- c(keys, x1)

    items[[length(items) + 1L]] <- list(
      type = "end",
      segment_id = seg$id[[1L]],
      x = x2,
      y = as.numeric(seg$y2)
    )
    keys <- c(keys, x2)
  }

  if(nrow(intersections) > 0L) {
    for(i in seq_len(nrow(intersections))) {
      it <- intersections[i, , drop = FALSE]
      items[[length(items) + 1L]] <- list(
        type = "intersection",
        x = as.numeric(it$x),
        y = as.numeric(it$y),
        id1 = it$id1[[1L]],
        id2 = it$id2[[1L]],
        point = list(x = as.numeric(it$x), y = as.numeric(it$y), id1 = it$id1[[1L]], id2 = it$id2[[1L]])
      )
      keys <- c(keys, as.numeric(it$x))
    }
  }

  as_ordered_sequence(items, keys = keys)
}

make_segment_snapshot <- function(step, x, active, discovered, events_now) {
  list(
    step = as.integer(step),
    x = as.numeric(x),
    active = active,
    discovered = discovered,
    events_now = events_now
  )
}

run_segment_sweep_immutables <- function(segments, max_steps = 5000L, track_snapshots = TRUE) {
  load_immutables()

  segment_items <- lapply(
    seq_len(nrow(segments)),
    function(i) {
      list(
        id = segments$id[[i]],
        x1 = as.numeric(segments$x1[[i]]),
        y1 = as.numeric(segments$y1[[i]]),
        x2 = as.numeric(segments$x2[[i]]),
        y2 = as.numeric(segments$y2[[i]])
      )
    }
  )

  segment_index <- as_interval_index(
    segment_items,
    start = as.numeric(segments$x1),
    end = as.numeric(segments$x2),
    default_query_bounds = "[]"
  )

  intersections <- compute_intersections(segments)
  events_remaining <- build_event_stream(segments, intersections)
  discovered <- ordered_sequence()

  snapshots <- if(isTRUE(track_snapshots)) flexseq() else NULL
  step <- 0L

  if(isTRUE(track_snapshots)) {
    snapshots <- push_back(
      snapshots,
      make_segment_snapshot(step = step, x = min(segments$x1), active = peek_all_point(segment_index, min(segments$x1), bounds = "[]"), discovered = discovered, events_now = list())
    )
  }

  while(length(events_remaining) > 0L && step < max_steps) {
    lb <- lower_bound(events_remaining, -Inf)
    if(!isTRUE(lb$found)) {
      break
    }
    x <- as.numeric(lb$key)

    popped <- pop_all_key(events_remaining, x)
    events_now <- as.list(popped$elements)
    events_remaining <- popped$remaining

    if(length(events_now) > 0L) {
      for(ev in events_now) {
        if(identical(ev$type, "intersection") && !is.null(ev$point)) {
          discovered <- insert(discovered, element = ev$point, key = as.numeric(ev$x))
        }
      }
    }

    active <- peek_all_point(segment_index, x, bounds = "[]")

    step <- step + 1L
    if(isTRUE(track_snapshots)) {
      snapshots <- push_back(
        snapshots,
        make_segment_snapshot(step = step, x = x, active = active, discovered = discovered, events_now = events_now)
      )
    }
  }

  list(
    segments = segments,
    intersections = intersections,
    snapshots = snapshots,
    steps = as.integer(step)
  )
}

plot_segment_sweep <- function(
  result,
  animate = TRUE,
  outfile = NULL,
  fps = 10,
  max_animation_frames = 140L,
  frame_stride = NULL,
  hold_final_frames = 0L,
  loop = TRUE
) {
  if(is.null(result$snapshots)) {
    stop("No snapshots available. Re-run with `track_snapshots = TRUE`.")
  }
  if(!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Please install 'ggplot2' to visualize snapshots.")
  }

  seg <- result$segments
  seg_ids <- as.character(seg$id)
  seg$id <- factor(seg_ids, levels = seg_ids)
  seg_palette <- stats::setNames(grDevices::hcl.colors(length(seg_ids), palette = "Dark 3"), seg_ids)

  shots <- as.list(result$snapshots)
  nshots <- length(shots)
  if(nshots == 0L) {
    stop("No snapshots to render.")
  }
  final_step <- max(vapply(shots, function(s) as.integer(s$step), integer(1)))

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

  .entries_to_df <- function(entries) {
    if(length(entries) == 0L) {
      return(data.frame(x = numeric(0), y = numeric(0), stringsAsFactors = FALSE))
    }
    do.call(rbind, lapply(entries, function(e) data.frame(x = as.numeric(e$x), y = as.numeric(e$y), stringsAsFactors = FALSE)))
  }

  .frame_plot <- function(shot) {
    active_entries <- as.list(shot$active)
    active_ids <- if(length(active_entries) == 0L) character(0) else vapply(active_entries, function(e) e$id, character(1))
    if(as.integer(shot$step) >= final_step) {
      # Avoid leaving a lingering highlighted segment in the terminal frame.
      active_ids <- character(0)
    }

    seg_inactive <- seg[!(seg$id %in% active_ids), , drop = FALSE]
    seg_active <- seg[seg$id %in% active_ids, , drop = FALSE]

    discovered_entries <- as.list(shot$discovered)
    discovered_df <- .entries_to_df(discovered_entries)

    events_now <- shot$events_now
    new_intersections <- Filter(function(ev) identical(ev$type, "intersection"), events_now)
    new_intersections_df <- if(length(new_intersections) == 0L) {
      data.frame(x = numeric(0), y = numeric(0), stringsAsFactors = FALSE)
    } else {
      do.call(rbind, lapply(new_intersections, function(ev) data.frame(x = as.numeric(ev$x), y = as.numeric(ev$y), stringsAsFactors = FALSE)))
    }

    n_start <- sum(vapply(events_now, function(ev) identical(ev$type, "start"), logical(1)))
    n_end <- sum(vapply(events_now, function(ev) identical(ev$type, "end"), logical(1)))

    ggplot2::ggplot() +
      ggplot2::geom_segment(
        data = seg_inactive,
        ggplot2::aes(x = x1, y = y1, xend = x2, yend = y2),
        color = "#BEB8AB",
        linewidth = 1.3,
        alpha = 0.8
      ) +
      ggplot2::geom_segment(
        data = seg_active,
        ggplot2::aes(x = x1, y = y1, xend = x2, yend = y2, color = id),
        linewidth = 2.3,
        alpha = 0.95,
        show.legend = FALSE
      ) +
      ggplot2::geom_point(
        data = discovered_df,
        ggplot2::aes(x = x, y = y),
        shape = 21,
        stroke = 0.42,
        fill = "#D1495B",
        color = "#111111",
        size = 4.1,
        alpha = 0.95
      ) +
      ggplot2::geom_point(
        data = new_intersections_df,
        ggplot2::aes(x = x, y = y),
        shape = 21,
        stroke = 1.37,
        fill = "#FFE066",
        color = "#111111",
        size = 7.1
      ) +
      ggplot2::geom_vline(xintercept = shot$x, color = "#111111", linewidth = 1.2, linetype = "22") +
      ggplot2::scale_color_manual(values = seg_palette, limits = seg_ids) +
      ggplot2::coord_cartesian(xlim = c(0, max(seg$x2) + 4), ylim = c(0, max(c(seg$y1, seg$y2)) + 4), expand = FALSE) +
      ggplot2::labs(
        title = "Persistent Segment Sweep",
        subtitle = sprintf(
          "x=%.2f | active=%d | intersections=%d",
          shot$x,
          nrow(seg_active),
          nrow(discovered_df)
        ),
        x = "x",
        y = "y"
      ) +
      ggplot2::theme_minimal(base_size = 21) +
      ggplot2::theme(
        panel.grid.minor = ggplot2::element_blank(),
        panel.grid.major = ggplot2::element_line(color = "#E7E2D7", linewidth = 0.4)
      )
  }

  if(isTRUE(animate)) {
    if(!requireNamespace("gifski", quietly = TRUE)) {
      stop("Animation requested but 'gifski' is not installed.")
    }

    hold_final_frames <- max(0L, as.integer(hold_final_frames))
    render_idx <- c(frame_idx, rep(frame_idx[[length(frame_idx)]], hold_final_frames))

    frame_dir <- tempfile("segment-sweep-frames-")
    dir.create(frame_dir, recursive = TRUE, showWarnings = FALSE)
    frame_paths <- file.path(frame_dir, sprintf("frame_%05d.png", seq_along(render_idx)))

    for(i in seq_along(render_idx)) {
      shot <- shots[[render_idx[[i]]]]
      p <- .frame_plot(shot)
      ggplot2::ggsave(
        filename = frame_paths[[i]],
        plot = p,
        width = 1760 / 96,
        height = 790 / 96,
        dpi = 96,
        units = "in"
      )
    }

    if(is.null(outfile)) {
      outfile <- tempfile("segment-sweep-", fileext = ".gif")
    }

    gifski::gifski(
      png_files = frame_paths,
      gif_file = outfile,
      width = 1760,
      height = 790,
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

run_segment_sweep_demo <- function(
  complexity = c("simple", "standard", "complex"),
  n_segments = NULL,
  x_max = NULL,
  y_max = NULL,
  min_span = NULL,
  max_span = NULL,
  seed = NULL,
  max_steps = NULL,
  visualize = TRUE,
  animate = TRUE,
  outfile = NULL,
  fps = 10,
  max_animation_frames = NULL,
  frame_stride = NULL,
  hold_final_frames = 0L,
  loop = TRUE,
  track_snapshots = TRUE
) {
  cfg <- resolve_segment_sweep_config(
    complexity = match.arg(complexity),
    n_segments = n_segments,
    x_max = x_max,
    y_max = y_max,
    min_span = min_span,
    max_span = max_span,
    seed = seed,
    max_steps = max_steps,
    max_animation_frames = max_animation_frames
  )

  segments <- generate_segments(
    n_segments = cfg$n_segments,
    x_max = cfg$x_max,
    y_max = cfg$y_max,
    min_span = cfg$min_span,
    max_span = cfg$max_span,
    seed = cfg$seed
  )

  effective_track <- isTRUE(track_snapshots) || isTRUE(visualize)
  result <- run_segment_sweep_immutables(
    segments = segments,
    max_steps = cfg$max_steps,
    track_snapshots = effective_track
  )

  viz <- NULL
  if(isTRUE(visualize)) {
    viz <- plot_segment_sweep(
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

  list(
    config = cfg,
    steps = result$steps,
    segments = nrow(segments),
    intersections = nrow(result$intersections),
    visualization = viz,
    result = result
  )
}

# Minimal article-friendly wrapper.
run_segment_sweep_paper_core <- function(complexity = c("simple", "standard", "complex")) {
  cfg <- resolve_segment_sweep_config(complexity = match.arg(complexity))
  segments <- generate_segments(
    n_segments = cfg$n_segments,
    x_max = cfg$x_max,
    y_max = cfg$y_max,
    min_span = cfg$min_span,
    max_span = cfg$max_span,
    seed = cfg$seed
  )
  out <- run_segment_sweep_immutables(segments, max_steps = cfg$max_steps, track_snapshots = FALSE)
  list(
    n_segments = nrow(segments),
    intersections = nrow(out$intersections),
    steps = out$steps
  )
}

if(sys.nframe() == 0L) {
  demo <- run_segment_sweep_demo(complexity = "standard", visualize = FALSE, animate = FALSE)
  cat("Segment sweep demo\n")
  cat("Complexity:", demo$config$complexity, "\n")
  cat("Segments:", demo$segments, "\n")
  cat("Intersections:", demo$intersections, "\n")
  cat("Steps:", demo$steps, "\n")
}
