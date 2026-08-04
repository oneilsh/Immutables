# Fortune-style Voronoi frontier (beach-line) visualization for immutables.
#
# Structures used:
# - priority_queue: site-event queue keyed by x-position
# - ordered_sequence: active frontier site registry
# - flexseq: persistent snapshot and breakpoint-trail history

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

fortune_complexity_config <- function(complexity = c("simple", "standard", "complex")) {
  complexity <- match.arg(complexity)
  if(identical(complexity, "simple")) {
    return(list(
      complexity = complexity,
      n_sites = 16L,
      x_max = 220L,
      y_max = 110L,
      seed = 141L,
      n_frames = 320L,
      y_resolution = 360L,
      sweep_tail = 2.2,
      max_animation_frames = 420L
    ))
  }
  if(identical(complexity, "complex")) {
    return(list(
      complexity = complexity,
      n_sites = 40L,
      x_max = 400L,
      y_max = 220L,
      seed = 909L,
      n_frames = 620L,
      y_resolution = 560L,
      sweep_tail = 2.2,
      max_animation_frames = 760L
    ))
  }
  list(
    complexity = "standard",
    n_sites = 16L,
    x_max = 320L,
    y_max = 180L,
    seed = 503L,
    n_frames = 225L,
    y_resolution = 460L,
    sweep_tail = 2.2,
    max_animation_frames = 620L
  )
}

resolve_fortune_config <- function(
  complexity = c("simple", "standard", "complex"),
  n_sites = NULL,
  x_max = NULL,
  y_max = NULL,
  seed = NULL,
  n_frames = NULL,
  y_resolution = NULL,
  sweep_tail = NULL,
  max_animation_frames = NULL
) {
  cfg <- fortune_complexity_config(match.arg(complexity))
  if(!is.null(n_sites)) cfg$n_sites <- as.integer(n_sites)
  if(!is.null(x_max)) cfg$x_max <- as.integer(x_max)
  if(!is.null(y_max)) cfg$y_max <- as.integer(y_max)
  if(!is.null(seed)) cfg$seed <- as.integer(seed)
  if(!is.null(n_frames)) cfg$n_frames <- as.integer(n_frames)
  if(!is.null(y_resolution)) cfg$y_resolution <- as.integer(y_resolution)
  if(!is.null(sweep_tail)) cfg$sweep_tail <- as.numeric(sweep_tail)
  if(!is.null(max_animation_frames)) cfg$max_animation_frames <- as.integer(max_animation_frames)
  cfg
}

generate_fortune_sites <- function(n_sites = 18L, x_max = 230L, y_max = 130L, seed = 503L) {
  stopifnot(n_sites >= 4L, x_max >= 80L, y_max >= 60L)
  set.seed(as.integer(seed))

  cx <- x_max / 2
  cy <- y_max / 2
  theta <- pi / 8
  ctheta <- cos(theta)
  stheta <- sin(theta)

  .draw_batch <- function(k) {
    shell <- stats::runif(k) < 0.18
    su <- ifelse(shell, x_max * 0.30, x_max * 0.17)
    sv <- ifelse(shell, y_max * 0.30, y_max * 0.17)

    u <- stats::rnorm(k, mean = 0, sd = su)
    v <- stats::rnorm(k, mean = 0, sd = sv)

    x <- round(cx + (u * ctheta - v * stheta))
    y <- round(cy + (u * stheta + v * ctheta))

    keep <- x >= 6L & x <= (x_max - 6L) & y >= 6L & y <= (y_max - 6L)
    data.frame(x = as.integer(x[keep]), y = as.integer(y[keep]), stringsAsFactors = FALSE)
  }

  pts <- data.frame(x = integer(0), y = integer(0), stringsAsFactors = FALSE)
  while(nrow(pts) < n_sites) {
    need <- as.integer(n_sites - nrow(pts))
    b <- .draw_batch(max(24L, need * 5L))
    if(nrow(b) == 0L) next
    pts <- rbind(pts, b)
    k <- paste0(pts$x, ",", pts$y)
    pts <- pts[!duplicated(k), , drop = FALSE]
  }

  pts <- pts[seq_len(n_sites), , drop = FALSE]
  pts$id <- sprintf("S%02d", seq_len(nrow(pts)))
  pts <- pts[, c("id", "x", "y"), drop = FALSE]
  rownames(pts) <- NULL
  pts
}

parabola_x <- function(site_x, site_y, directrix_x, y_vals) {
  delta <- pmax(1e-4, directrix_x - site_x)
  0.5 * (directrix_x + site_x) - ((y_vals - site_y) ^ 2) / (2 * delta)
}

active_seq_to_df <- function(active_seq) {
  if(is.null(active_seq) || length(active_seq) == 0L) {
    return(data.frame(id = character(0), index = integer(0), x = numeric(0), y = numeric(0), stringsAsFactors = FALSE))
  }
  el <- as.list(active_seq)
  data.frame(
    id = vapply(el, function(e) as.character(e$id), character(1)),
    index = vapply(el, function(e) as.integer(e$index), integer(1)),
    x = vapply(el, function(e) as.numeric(e$x), numeric(1)),
    y = vapply(el, function(e) as.numeric(e$y), numeric(1)),
    stringsAsFactors = FALSE
  )
}

trail_seq_to_df <- function(trail_seq) {
  if(is.null(trail_seq) || length(trail_seq) == 0L) {
    return(data.frame(pair = character(0), step = integer(0), sweep_x = numeric(0), x = numeric(0), y = numeric(0), stringsAsFactors = FALSE))
  }
  el <- as.list(trail_seq)
  data.frame(
    pair = vapply(el, function(e) as.character(e$pair), character(1)),
    step = vapply(el, function(e) as.integer(e$step), integer(1)),
    sweep_x = vapply(el, function(e) as.numeric(e$sweep_x), numeric(1)),
    x = vapply(el, function(e) as.numeric(e$x), numeric(1)),
    y = vapply(el, function(e) as.numeric(e$y), numeric(1)),
    stringsAsFactors = FALSE
  )
}

build_beachline <- function(active_df, directrix_x, y_vals) {
  if(nrow(active_df) == 0L) {
    return(data.frame(y = numeric(0), x = numeric(0), site_id = character(0), site_index = integer(0), stringsAsFactors = FALSE))
  }

  x_cols <- lapply(
    seq_len(nrow(active_df)),
    function(i) parabola_x(active_df$x[[i]], active_df$y[[i]], directrix_x, y_vals)
  )
  x_mat <- do.call(cbind, x_cols)

  if(is.null(dim(x_mat))) {
    x_mat <- matrix(x_mat, ncol = 1L)
  }

  winner <- max.col(x_mat, ties.method = "first")
  ridx <- seq_along(y_vals)

  data.frame(
    y = as.numeric(y_vals),
    x = as.numeric(x_mat[cbind(ridx, winner)]),
    site_id = active_df$id[winner],
    site_index = as.integer(active_df$index[winner]),
    stringsAsFactors = FALSE
  )
}

extract_breakpoints <- function(beach_df) {
  if(nrow(beach_df) < 2L) {
    return(data.frame(x = numeric(0), y = numeric(0), left_id = character(0), right_id = character(0), pair = character(0), stringsAsFactors = FALSE))
  }

  change_at <- which(beach_df$site_id[-1L] != beach_df$site_id[-nrow(beach_df)])
  if(length(change_at) == 0L) {
    return(data.frame(x = numeric(0), y = numeric(0), left_id = character(0), right_id = character(0), pair = character(0), stringsAsFactors = FALSE))
  }

  left_id <- beach_df$site_id[change_at]
  right_id <- beach_df$site_id[change_at + 1L]
  pair <- ifelse(left_id < right_id, paste0(left_id, "|", right_id), paste0(right_id, "|", left_id))

  data.frame(
    x = (beach_df$x[change_at] + beach_df$x[change_at + 1L]) / 2,
    y = (beach_df$y[change_at] + beach_df$y[change_at + 1L]) / 2,
    left_id = left_id,
    right_id = right_id,
    pair = pair,
    stringsAsFactors = FALSE
  )
}

empty_beach_df <- function() {
  data.frame(
    y = numeric(0),
    x = numeric(0),
    site_id = character(0),
    site_index = integer(0),
    stringsAsFactors = FALSE
  )
}

empty_breakpoints_df <- function() {
  data.frame(
    x = numeric(0),
    y = numeric(0),
    left_id = character(0),
    right_id = character(0),
    pair = character(0),
    stringsAsFactors = FALSE
  )
}

rect_polygon <- function(xmin, xmax, ymin, ymax) {
  matrix(
    c(
      xmin, ymin,
      xmax, ymin,
      xmax, ymax,
      xmin, ymax
    ),
    ncol = 2,
    byrow = TRUE
  )
}

clip_polygon_halfplane <- function(poly, a, b, c, eps = 1e-9) {
  if(is.null(poly) || nrow(poly) == 0L) return(poly)
  inside <- function(p) (a * p[1] + b * p[2]) <= (c + eps)
  intersect_pt <- function(p1, p2) {
    v1 <- a * p1[1] + b * p1[2] - c
    v2 <- a * p2[1] + b * p2[2] - c
    denom <- (v1 - v2)
    if(abs(denom) < eps) return(p1)
    t <- v1 / denom
    p1 + t * (p2 - p1)
  }

  out <- matrix(numeric(0), ncol = 2)
  n <- nrow(poly)
  for(i in seq_len(n)) {
    s <- poly[i, ]
    e <- poly[if(i == n) 1L else i + 1L, ]
    s_in <- inside(s)
    e_in <- inside(e)
    if(s_in && e_in) {
      out <- rbind(out, e)
    } else if(s_in && !e_in) {
      out <- rbind(out, intersect_pt(s, e))
    } else if(!s_in && e_in) {
      out <- rbind(out, intersect_pt(s, e), e)
    }
  }
  if(nrow(out) == 0L) return(out)
  # Drop near-duplicate consecutive vertices.
  keep <- c(TRUE, sqrt(rowSums((out[-1L, , drop = FALSE] - out[-nrow(out), , drop = FALSE]) ^ 2)) > eps)
  out <- out[keep, , drop = FALSE]
  if(nrow(out) >= 2L) {
    if(sqrt(sum((out[1L, ] - out[nrow(out), ]) ^ 2)) <= eps) {
      out <- out[-nrow(out), , drop = FALSE]
    }
  }
  out
}

canonical_segment_key <- function(x1, y1, x2, y2, digits = 4L) {
  if((x2 < x1) || (x1 == x2 && y2 < y1)) {
    tx <- x1; ty <- y1
    x1 <- x2; y1 <- y2
    x2 <- tx; y2 <- ty
  }
  paste(
    round(x1, digits), round(y1, digits),
    round(x2, digits), round(y2, digits),
    sep = "|"
  )
}

compute_voronoi_segments <- function(sites, x_min, x_max, y_min, y_max) {
  n <- nrow(sites)
  if(n < 2L) {
    return(data.frame(seg_id = integer(0), x1 = numeric(0), y1 = numeric(0), x2 = numeric(0), y2 = numeric(0), stringsAsFactors = FALSE))
  }

  raw_segments <- vector("list", n * 8L)
  seg_i <- 0L

  for(i in seq_len(n)) {
    si <- c(as.numeric(sites$x[[i]]), as.numeric(sites$y[[i]]))
    poly <- rect_polygon(x_min, x_max, y_min, y_max)

    for(j in seq_len(n)) {
      if(j == i) next
      sj <- c(as.numeric(sites$x[[j]]), as.numeric(sites$y[[j]]))
      a <- 2 * (sj[1] - si[1])
      b <- 2 * (sj[2] - si[2])
      c <- (sj[1]^2 + sj[2]^2) - (si[1]^2 + si[2]^2)
      poly <- clip_polygon_halfplane(poly, a, b, c)
      if(nrow(poly) < 3L) break
    }

    if(nrow(poly) < 3L) next
    m <- nrow(poly)
    for(k in seq_len(m)) {
      p1 <- poly[k, ]
      p2 <- poly[if(k == m) 1L else k + 1L, ]
      if(sqrt(sum((p2 - p1)^2)) < 1e-7) next
      seg_i <- seg_i + 1L
      raw_segments[[seg_i]] <- list(x1 = p1[1], y1 = p1[2], x2 = p2[1], y2 = p2[2])
    }
  }

  raw_segments <- raw_segments[seq_len(seg_i)]
  if(length(raw_segments) == 0L) {
    return(data.frame(seg_id = integer(0), x1 = numeric(0), y1 = numeric(0), x2 = numeric(0), y2 = numeric(0), stringsAsFactors = FALSE))
  }

  seg_df <- data.frame(
    x1 = vapply(raw_segments, function(s) as.numeric(s$x1), numeric(1)),
    y1 = vapply(raw_segments, function(s) as.numeric(s$y1), numeric(1)),
    x2 = vapply(raw_segments, function(s) as.numeric(s$x2), numeric(1)),
    y2 = vapply(raw_segments, function(s) as.numeric(s$y2), numeric(1)),
    stringsAsFactors = FALSE
  )
  seg_df$key <- vapply(
    seq_len(nrow(seg_df)),
    function(i) canonical_segment_key(seg_df$x1[[i]], seg_df$y1[[i]], seg_df$x2[[i]], seg_df$y2[[i]]),
    character(1)
  )

  # Interior Voronoi edges appear twice (once per adjacent cell).
  key_tab <- table(seg_df$key)
  keep_keys <- names(key_tab)[key_tab >= 2L]
  seg_df <- seg_df[seg_df$key %in% keep_keys, , drop = FALSE]
  if(nrow(seg_df) == 0L) {
    return(data.frame(seg_id = integer(0), x1 = numeric(0), y1 = numeric(0), x2 = numeric(0), y2 = numeric(0), stringsAsFactors = FALSE))
  }

  uniq_idx <- !duplicated(seg_df$key)
  seg_df <- seg_df[uniq_idx, c("x1", "y1", "x2", "y2"), drop = FALSE]
  seg_df$seg_id <- seq_len(nrow(seg_df))
  seg_df <- seg_df[, c("seg_id", "x1", "y1", "x2", "y2"), drop = FALSE]
  rownames(seg_df) <- NULL
  seg_df
}

reveal_voronoi_segments <- function(seg_df, sweep_x, beach_df = NULL) {
  if(is.null(seg_df) || nrow(seg_df) == 0L) {
    return(data.frame(seg_id = integer(0), chunk = integer(0), group = character(0), x = numeric(0), y = numeric(0), stringsAsFactors = FALSE))
  }
  if(is.null(beach_df) || nrow(beach_df) < 2L) {
    return(data.frame(seg_id = integer(0), chunk = integer(0), group = character(0), x = numeric(0), y = numeric(0), stringsAsFactors = FALSE))
  }

  out <- vector("list", nrow(seg_df) * 2L)
  out_i <- 0L
  chunk_counter <- 0L

  for(i in seq_len(nrow(seg_df))) {
    x1 <- as.numeric(seg_df$x1[[i]])
    y1 <- as.numeric(seg_df$y1[[i]])
    x2 <- as.numeric(seg_df$x2[[i]])
    y2 <- as.numeric(seg_df$y2[[i]])
    sid <- as.integer(seg_df$seg_id[[i]])
    seg_len <- sqrt((x2 - x1)^2 + (y2 - y1)^2)
    n_sample <- max(20L, min(140L, as.integer(ceiling(seg_len * 2.2))))

    tvals <- seq(0, 1, length.out = n_sample)
    xs <- x1 + tvals * (x2 - x1)
    ys <- y1 + tvals * (y2 - y1)
    front_x <- stats::approx(
      x = beach_df$y,
      y = beach_df$x,
      xout = ys,
      rule = 2,
      ties = "ordered"
    )$y
    shown <- (xs <= (sweep_x + 1e-8)) & (xs <= (front_x + 1e-8))
    if(!any(shown)) next

    runs <- rle(shown)
    end_idx <- cumsum(runs$lengths)
    start_idx <- end_idx - runs$lengths + 1L
    for(j in which(runs$values)) {
      idx <- seq.int(start_idx[[j]], end_idx[[j]])
      if(length(idx) < 2L) next
      chunk_counter <- chunk_counter + 1L
      out_i <- out_i + 1L
      out[[out_i]] <- data.frame(
        seg_id = sid,
        chunk = chunk_counter,
        group = paste0(sid, ":", chunk_counter),
        x = xs[idx],
        y = ys[idx],
        stringsAsFactors = FALSE
      )
    }
  }

  if(out_i == 0L) {
    return(data.frame(seg_id = integer(0), chunk = integer(0), group = character(0), x = numeric(0), y = numeric(0), stringsAsFactors = FALSE))
  }
  do.call(rbind, out[seq_len(out_i)])
}

make_fortune_snapshot <- function(step, sweep_x, active, beach, breakpoints, trails, queue_size) {
  list(
    step = as.integer(step),
    sweep_x = as.numeric(sweep_x),
    active = active,
    beach = beach,
    breakpoints = breakpoints,
    trails = trails,
    queue_size = as.integer(queue_size)
  )
}

run_fortune_frontier_immutables <- function(
  sites,
  n_frames = 145L,
  y_resolution = 280L,
  sweep_tail = 2.2,
  track_snapshots = TRUE
) {
  load_immutables()

  if(!all(c("id", "x", "y") %in% names(sites))) {
    stop("`sites` must include columns: id, x, y")
  }

  key <- paste0(sites$x, ",", sites$y)
  pts <- sites[!duplicated(key), c("id", "x", "y"), drop = FALSE]
  pts <- pts[order(pts$x, pts$y), , drop = FALSE]
  rownames(pts) <- NULL

  # Site events are consumed in x-order by the queue.
  event_q <- priority_queue()
  for(i in seq_len(nrow(pts))) {
    site_i <- list(id = as.character(pts$id[[i]]), x = as.numeric(pts$x[[i]]), y = as.numeric(pts$y[[i]]), index = as.integer(i))
    event_q <- insert(event_q, value = site_i, priority = as.numeric(pts$x[[i]]))
  }

  active <- ordered_sequence()
  trails <- flexseq()
  snapshots <- if(isTRUE(track_snapshots)) flexseq() else NULL

  x_pad <- max(8, as.numeric(diff(range(pts$x))) * 0.15)
  y_pad <- max(8, as.numeric(diff(range(pts$y))) * 0.14)
  x_min <- min(pts$x) - x_pad
  x_max <- max(pts$x) + x_pad
  y_min <- min(pts$y) - y_pad
  y_max <- max(pts$y) + y_pad

  sweep_tail <- max(0, as.numeric(sweep_tail))
  sweep_end <- x_max + sweep_tail * (x_max - x_min)
  sweep_positions <- seq(x_min, sweep_end, length.out = as.integer(max(8L, n_frames)))
  y_vals <- seq(y_min, y_max, length.out = as.integer(max(60L, y_resolution)))
  voronoi_edges <- compute_voronoi_segments(pts, x_min = x_min, x_max = x_max, y_min = y_min, y_max = y_max)

  step <- 0L
  if(isTRUE(track_snapshots)) {
    snapshots <- push_back(
      snapshots,
      make_fortune_snapshot(
        step,
        sweep_x = sweep_positions[[1L]],
        active = active,
        beach = empty_beach_df(),
        breakpoints = empty_breakpoints_df(),
        trails = trails,
        queue_size = length(event_q)
      )
    )
  }

  for(sweep_x in sweep_positions) {
    # Process all site events now to the left of (or on) the directrix.
    repeat {
      if(length(event_q) == 0L) break
      popped <- pop_min(event_q)
      cand <- popped$value
      event_rest <- popped$remaining
      if(is.null(cand)) {
        event_q <- event_rest
        break
      }

      if(as.numeric(cand$x) <= (sweep_x + 1e-9)) {
        event_q <- event_rest
        site_key <- as.numeric(cand$y) * 1e6 + as.numeric(cand$x) * 1e3 + as.numeric(cand$index)
        active <- insert(active, value = cand, key = site_key)
      } else {
        # Not yet ready; restore and continue sweep.
        event_q <- insert(event_rest, value = cand, priority = as.numeric(cand$x))
        break
      }
    }

    active_df <- active_seq_to_df(active)
    beach_df <- build_beachline(active_df, directrix_x = sweep_x, y_vals = y_vals)
    breaks_df <- extract_breakpoints(beach_df)

    if(nrow(breaks_df) > 0L) {
      for(i in seq_len(nrow(breaks_df))) {
        trails <- push_back(
          trails,
          list(
            pair = as.character(breaks_df$pair[[i]]),
            step = as.integer(step),
            sweep_x = as.numeric(sweep_x),
            x = as.numeric(breaks_df$x[[i]]),
            y = as.numeric(breaks_df$y[[i]])
          )
        )
      }
    }

    step <- step + 1L
    if(isTRUE(track_snapshots)) {
      snapshots <- push_back(
        snapshots,
        make_fortune_snapshot(
          step = step,
          sweep_x = sweep_x,
          active = active,
          beach = beach_df,
          breakpoints = breaks_df,
          trails = trails,
          queue_size = length(event_q)
        )
      )
    }
  }

  final_trails <- trail_seq_to_df(trails)
  list(
    found = TRUE,
    steps = as.integer(step),
    sites = pts,
    active = active,
    snapshots = snapshots,
    trails = final_trails,
    voronoi_edges = voronoi_edges,
    x_min = x_min,
    x_max = x_max,
    y_min = y_min,
    y_max = y_max,
    sweep_end = sweep_end
  )
}

plot_fortune_frontier_snapshots <- function(
  result,
  animate = TRUE,
  outfile = NULL,
  fps = 10,
  max_animation_frames = 140L,
  frame_stride = NULL,
  hold_final_frames = 10L,
  loop = TRUE,
  width_px = 1760L,
  height_px = 768L,
  max_snapshot_step = 100L
) {
  if(is.null(result$snapshots)) {
    stop("No snapshots available. Re-run with `track_snapshots = TRUE`.")
  }
  if(!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Please install 'ggplot2' to visualize snapshots.")
  }

  shots <- as.list(result$snapshots)
  # After ~step 100 the sweep line is off-plot and snapshots add no visual
  # change; capping keeps the animation short.
  if(!is.null(max_snapshot_step)) {
    shots <- shots[seq_len(min(length(shots), as.integer(max_snapshot_step)))]
  }
  nshots <- length(shots)
  if(nshots == 0L) {
    stop("No snapshots to render.")
  }

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

  sites <- result$sites
  site_cols <- grDevices::hcl.colors(nrow(sites), palette = "Dynamic", alpha = 0.95)
  names(site_cols) <- sites$id

  .frame_plot <- function(s) {
    active_df <- active_seq_to_df(s$active)
    active_ids <- if(nrow(active_df) > 0L) active_df$id else character(0)

    site_plot <- sites
    site_plot$active <- site_plot$id %in% active_ids

    beach_df <- s$beach
    if(!all(c("x", "y", "site_id") %in% names(beach_df))) {
      beach_df <- empty_beach_df()
    }
    breaks_df <- s$breakpoints
    if(!all(c("x", "y") %in% names(breaks_df))) {
      breaks_df <- empty_breakpoints_df()
    }
    edge_df <- reveal_voronoi_segments(result$voronoi_edges, s$sweep_x, beach_df = beach_df)

    if(nrow(beach_df) > 0L) {
      beach_df$site_id <- factor(beach_df$site_id, levels = sites$id)
    }

    p <- ggplot2::ggplot() +
      ggplot2::geom_vline(
        xintercept = s$sweep_x,
        color = "#ED6A5A",
        linewidth = 1.05,
        alpha = 0.95,
        linetype = "22"
      ) +
      ggplot2::geom_path(
        data = edge_df,
        ggplot2::aes(x = x, y = y, group = group),
        color = "#3E6C7A",
        linewidth = 1.05,
        alpha = 0.70,
        lineend = "round"
      ) +
      ggplot2::geom_path(
        data = beach_df,
        ggplot2::aes(x = x, y = y, color = site_id),
        linewidth = 1.25,
        alpha = 0.97,
        lineend = "round"
      ) +
      ggplot2::geom_point(
        data = site_plot[!site_plot$active, , drop = FALSE],
        ggplot2::aes(x = x, y = y),
        shape = 21,
        fill = "#E7E0D6",
        color = "#6A6257",
        size = 3.8,
        stroke = 0.7
      ) +
      ggplot2::geom_point(
        data = site_plot[site_plot$active, , drop = FALSE],
        ggplot2::aes(x = x, y = y, fill = id),
        shape = 21,
        color = "#202020",
        size = 4.7,
        stroke = 0.85,
        inherit.aes = FALSE
      ) +
      ggplot2::geom_point(
        data = breaks_df,
        ggplot2::aes(x = x, y = y),
        shape = 21,
        fill = "#FFFFFF",
        color = "#111111",
        size = 4.5,
        stroke = 1.0
      ) +
      ggplot2::scale_fill_manual(values = site_cols, guide = "none") +
      ggplot2::scale_color_manual(values = site_cols, guide = "none", drop = FALSE) +
      ggplot2::coord_cartesian(
        xlim = c(result$x_min, result$x_max),
        ylim = c(result$y_min, result$y_max),
        expand = FALSE
      ) +
      ggplot2::labs(
        title = "Fortune-Style Sweep Frontier (Persistent State Playback)",
        subtitle = sprintf(
          "step=%d | active sites=%d | pending events=%d | shown edges=%d",
          s$step, length(active_ids), s$queue_size, length(unique(edge_df$seg_id))
        ),
        x = "x (sweep direction ->)",
        y = "y"
      ) +
      ggplot2::theme_minimal(base_size = 22) +
      ggplot2::theme(
        panel.grid.minor = ggplot2::element_blank(),
        panel.grid.major = ggplot2::element_line(color = "#E6E1D6", linewidth = 0.4)
      )

    p
  }

  if(isTRUE(animate)) {
    if(!requireNamespace("gifski", quietly = TRUE)) {
      stop("Animation requested but 'gifski' is not installed.")
    }

    render_idx <- c(frame_idx, rep(frame_idx[[length(frame_idx)]], as.integer(max(0L, hold_final_frames))))

    frame_dir <- tempfile("fortune-frontier-frames-")
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
      outfile <- tempfile("fortune-frontier-", fileext = ".gif")
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

run_fortune_frontier_demo <- function(
  complexity = c("simple", "standard", "complex"),
  n_sites = NULL,
  x_max = NULL,
  y_max = NULL,
  seed = NULL,
  n_frames = NULL,
  y_resolution = NULL,
  sweep_tail = NULL,
  visualize = TRUE,
  animate = TRUE,
  outfile = NULL,
  fps = 10,
  max_animation_frames = NULL,
  frame_stride = NULL,
  hold_final_frames = 10L,
  loop = TRUE,
  track_snapshots = TRUE,
  width_px = 1760L,
  height_px = 768L,
  max_snapshot_step = 100L
) {
  cfg <- resolve_fortune_config(
    complexity = match.arg(complexity),
    n_sites = n_sites,
    x_max = x_max,
    y_max = y_max,
    seed = seed,
    n_frames = n_frames,
    y_resolution = y_resolution,
    sweep_tail = sweep_tail,
    max_animation_frames = max_animation_frames
  )

  sites <- generate_fortune_sites(
    n_sites = cfg$n_sites,
    x_max = cfg$x_max,
    y_max = cfg$y_max,
    seed = cfg$seed
  )

  effective_track <- isTRUE(track_snapshots) || isTRUE(visualize)
  result <- run_fortune_frontier_immutables(
    sites = sites,
    n_frames = cfg$n_frames,
    y_resolution = cfg$y_resolution,
    sweep_tail = cfg$sweep_tail,
    track_snapshots = effective_track
  )

  viz <- NULL
  if(isTRUE(visualize)) {
    viz <- plot_fortune_frontier_snapshots(
      result,
      animate = animate,
      outfile = outfile,
      fps = fps,
      max_animation_frames = cfg$max_animation_frames,
      frame_stride = frame_stride,
      hold_final_frames = hold_final_frames,
      loop = loop,
      width_px = width_px,
      height_px = height_px,
      max_snapshot_step = max_snapshot_step
    )
  }

  list(
    config = cfg,
    sites = nrow(sites),
    steps = result$steps,
    trail_points = nrow(result$trails),
    voronoi_edges = nrow(result$voronoi_edges),
    visualization = viz,
    result = result
  )
}

# Minimal article-friendly helper.
run_fortune_frontier_paper_core <- function(complexity = c("simple", "standard", "complex")) {
  cfg <- resolve_fortune_config(complexity = match.arg(complexity))
  sites <- generate_fortune_sites(cfg$n_sites, cfg$x_max, cfg$y_max, cfg$seed)
  out <- run_fortune_frontier_immutables(
    sites = sites,
    n_frames = cfg$n_frames,
    y_resolution = cfg$y_resolution,
    sweep_tail = cfg$sweep_tail,
    track_snapshots = FALSE
  )
  list(
    n_sites = nrow(sites),
    steps = out$steps,
    trail_points = nrow(out$trails),
    voronoi_edges = nrow(out$voronoi_edges)
  )
}

if(sys.nframe() == 0L) {
  demo <- run_fortune_frontier_demo(complexity = "standard", 
                                    visualize = TRUE, 
                                    animate = TRUE,
                                    seed = 412)
  cat("Fortune frontier demo\n")
  cat("Complexity:", demo$config$complexity, "\n")
  cat("Sites:", demo$sites, "\n")
  cat("Steps:", demo$steps, "\n")
  cat("Trail points:", demo$trail_points, "\n")
}
