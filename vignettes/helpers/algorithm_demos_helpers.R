# Shared helpers for the Algorithm Demos vignette.
# These objects are documentation-only and are not package exports.

algorithm_demo_asset_files <- c(
  sweep_line = "01-sweep-line.gif",
  segment_sweep = "02-segment-sweep.gif",
  convex_hull = "03-convex-hull.gif",
  fortune_frontier = "04-fortune-frontier.gif",
  astar_organic_history_large_fast = "05-astar-organic-history-large-fast.gif",
  astar_trail = "06-astar-trail.gif"
)

algorithm_demo_asset <- function(name) {
  key <- match.arg(name, choices = names(algorithm_demo_asset_files))
  file.path("assets", "algorithm-demos", algorithm_demo_asset_files[[key]])
}

algorithm_demo_sources <- list(
  sweep_line = "vignettes/helpers/demos/demo_sweep_line_immutables.R",
  segment_sweep = "vignettes/helpers/demos/demo_segment_sweep_immutables.R",
  convex_hull = "vignettes/helpers/demos/demo_convex_hull_immutables.R",
  fortune_frontier = "vignettes/helpers/demos/demo_fortune_frontier_immutables.R",
  astar = "vignettes/helpers/demos/demo_astar_immutables.R",
  astar_trail = "vignettes/helpers/demos/demo_astar_trail_immutables.R",
  asset_renderer = "vignettes/helpers/render_algorithm_demo_assets.R"
)

algorithm_demo_presets <- list(
  astar_organic_history_large_fast = list(
    complexity = "complex",
    maze_seed = 53L,
    playback = "forward",
    history_metric = "pressure",
    history_hold_frames = 6L,
    max_animation_frames = 140L,
    fps = 12,
    animate = TRUE,
    visualize = TRUE,
    final_path_reveal = TRUE
  )
)

algorithm_demo_pause_frames <- function(fps, pause_seconds = 1.2) {
  max(0L, as.integer(round(as.numeric(fps) * as.numeric(pause_seconds))))
}

algorithm_demo_render_presets <- list(
  sweep_line = list(
    source = "sweep_line",
    asset_key = "sweep_line",
    runner = "run_sweep_line_demo",
    args = list(
      complexity = "standard",
      seed = 42L,
      visualize = TRUE,
      animate = TRUE,
      fps = 12,
      max_animation_frames = 90L,
      hold_final_frames = algorithm_demo_pause_frames(12),
      loop = TRUE,
      width_px = 800L,
      height_px = 420L
    )
  ),
  segment_sweep = list(
    source = "segment_sweep",
    asset_key = "segment_sweep",
    runner = "run_segment_sweep_demo",
    args = list(
      complexity = "standard",
      n_segments = 17L,
      seed = 43L,
      visualize = TRUE,
      animate = TRUE,
      fps = 10,
      max_animation_frames = 140L,
      hold_final_frames = algorithm_demo_pause_frames(10),
      loop = TRUE
    )
  ),
  convex_hull = list(
    source = "convex_hull",
    asset_key = "convex_hull",
    runner = "run_convex_hull_demo",
    args = list(
      complexity = "standard",
      n_points = 42L,
      visualize = TRUE,
      animate = TRUE,
      fps = 10,
      max_animation_frames = 170L,
      hold_final_frames = algorithm_demo_pause_frames(10),
      loop = TRUE
    )
  ),
  fortune_frontier = list(
    source = "fortune_frontier",
    asset_key = "fortune_frontier",
    runner = "run_fortune_frontier_demo",
    args = list(
      complexity = "standard",
      seed = 4121L,
      n_frames = 200L,
      visualize = TRUE,
      animate = TRUE,
      fps = 8,
      max_animation_frames = 240L,
      hold_final_frames = algorithm_demo_pause_frames(8),
      loop = TRUE
    )
  ),
  astar_organic_history_large_fast = list(
    source = "astar",
    asset_key = "astar_organic_history_large_fast",
    runner = "run_astar_demo",
    args = c(
      algorithm_demo_presets$astar_organic_history_large_fast,
      list(
        hold_final_frames = algorithm_demo_pause_frames(12),
        reveal_hold_frames = algorithm_demo_pause_frames(12),
        loop = TRUE
      )
    )
  ),
  astar_trail = list(
    source = "astar_trail",
    asset_key = "astar_trail",
    runner = "run_astar_trail_demo",
    args = list(
      complexity = "standard",
      lag_base = 3,
      lag_warp = 0.4,
      visualize = TRUE,
      animate = TRUE,
      fps = 12,
      max_animation_frames = 140L,
      hold_final_frames = algorithm_demo_pause_frames(12),
      reveal_hold_frames = algorithm_demo_pause_frames(12),
      loop = TRUE
    )
  )
)

run_sweep_line_minimal <- function(seed = 42L, track_snapshots = TRUE) {
  intervals <- generate_sweep_intervals(seed = seed)
  sweep_line_core_immutables(intervals, track_snapshots = track_snapshots)
}

run_segment_sweep_minimal <- function(complexity = "standard") {
  run_segment_sweep_paper_core(complexity = complexity)
}

run_convex_hull_minimal <- function(complexity = "standard") {
  run_convex_hull_paper_core(complexity = complexity)
}

run_fortune_frontier_minimal <- function(complexity = "standard") {
  run_fortune_frontier_paper_core(complexity = complexity)
}

run_astar_from_preset <- function(
  name = "astar_organic_history_large_fast",
  outfile = NULL
) {
  preset <- algorithm_demo_presets[[name]]
  if(is.null(preset)) {
    stop("Unknown algorithm demo preset: ", name)
  }
  args <- preset
  if(!is.null(outfile)) {
    args$outfile <- outfile
  }
  do.call(run_astar_demo, args)
}
