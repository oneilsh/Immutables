# Algorithm Demos

This article presents six algorithm demos in a single walkthrough. Each
section focuses on the algorithmic idea, the specific immutable
data-structure roles, and a compact core logic view.

Runtime-heavy animation generation is intentionally excluded from
vignette build. The visuals shown here are pre-rendered GIF assets under
`vignettes/assets/algorithm-demos/`.

Maintainer note: re-render one demo asset

Use:

``` r
source("vignettes/helpers/render_algorithm_demo_assets.R")
render_algorithm_demo_assets(demos = "sweep_line")
```

CLI alternative:

``` sh
R -q -f vignettes/helpers/render_algorithm_demo_assets.R --args demo=sweep_line
```

## Sweep Line

### What This Illustrates

A one-dimensional sweep over interval start/end events. At each sweep
position, we ask: “which intervals are active right now?” This
demonstrates immutable state progression across ordered event keys.

### Data Structures and Their Roles

- `interval_index`: fast active-interval query at each x-position.
- `ordered_sequence`: persistent event stream keyed by x.
- `flexseq`: immutable snapshot history for playback.

### Core Logic (Minimal)

``` r
# Minimal wrapper from algorithm_demos_helpers.R
out <- run_sweep_line_minimal(seed = 42L, track_snapshots = TRUE)

# Persistent step updates:
# 1) pop events at current x from ordered_sequence
# 2) query active intervals from interval_index
# 3) append immutable snapshot to flexseq
```

### Visualization

![Sweep-line interval activity over persistent
snapshots.](assets/algorithm-demos/01-sweep-line.gif)

Sweep-line interval activity over persistent snapshots.

### Full Implementation

Show source/helper paths

- Demo source: `meta/scripts/demo_sweep_line_immutables.R`
- Asset renderer: `vignettes/helpers/render_algorithm_demo_assets.R`

## Segment Sweep

### What This Illustrates

A sweep over segment endpoint events with active-set intersection
discovery. This highlights immutable event processing and query state
over geometric input.

### Data Structures and Their Roles

- `interval_index`: active-segment candidate querying at current sweep
  x.
- `ordered_sequence`: endpoint event stream, processed in sorted order.
- `flexseq`: snapshot timeline of sweep states.

### Core Logic (Minimal)

``` r
# Minimal wrapper from algorithm_demos_helpers.R
stats <- run_segment_sweep_minimal(complexity = "standard")
stats

# Core behavior:
# - events are popped in x-order
# - active segments are queried via interval index
# - found intersections are accumulated persistently
```

### Visualization

![Segment sweep with active-set intersection
discovery.](assets/algorithm-demos/02-segment-sweep.gif)

Segment sweep with active-set intersection discovery.

### Full Implementation

Show source/helper paths

- Demo source: `meta/scripts/demo_segment_sweep_immutables.R`
- Asset renderer: `vignettes/helpers/render_algorithm_demo_assets.R`

## Convex Hull

### What This Illustrates

Monotone-chain convex hull construction with immutable lower/upper hull
stacks. The demo emphasizes turn tests and persistent stack evolution.

### Data Structures and Their Roles

- `ordered_sequence`: sorted point stream by `(x, y)`.
- `flexseq`: persistent lower/upper hull stacks and snapshot timeline.

### Core Logic (Minimal)

``` r
# Minimal wrapper from algorithm_demos_helpers.R
stats <- run_convex_hull_minimal(complexity = "standard")
stats

# Core behavior:
# - points consumed in sorted order
# - pop while orientation violates convexity
# - push next point, preserving prior versions immutably
```

### Visualization

![Monotone-chain hull construction with persistent
snapshots.](assets/algorithm-demos/03-convex-hull.gif)

Monotone-chain hull construction with persistent snapshots.

### Full Implementation

Show source/helper paths

- Demo source: `meta/scripts/demo_convex_hull_immutables.R`
- Asset renderer: `vignettes/helpers/render_algorithm_demo_assets.R`

## Fortune Frontier

### What This Illustrates

A Fortune-style sweep frontier (beach line) visualization that replays
immutable state over directrix progression. The focus is event-driven
frontier evolution.

### Data Structures and Their Roles

- `priority_queue`: site events consumed by sweep position.
- `ordered_sequence`: active frontier registry.
- `flexseq`: snapshots and breakpoint trails for playback.

### Core Logic (Minimal)

``` r
# Minimal wrapper from algorithm_demos_helpers.R
stats <- run_fortune_frontier_minimal(complexity = "standard")
stats

# Core behavior:
# - pop ready site events from priority queue
# - insert active sites into ordered frontier state
# - sample beach line and breakpoint trails into persistent snapshots
```

### Visualization

![Fortune-style frontier sweep and revealed Voronoi
structure.](assets/algorithm-demos/04-fortune-frontier.gif)

Fortune-style frontier sweep and revealed Voronoi structure.

### Full Implementation

Show source/helper paths

- Demo source: `meta/scripts/demo_fortune_frontier_immutables.R`
- Asset renderer: `vignettes/helpers/render_algorithm_demo_assets.R`

## A\* Organic History Large Fast

### What This Illustrates

A large maze A\* search with staged final-path reveal plus a
pressure-history summary. The replay first settles on the solved state,
then highlights the solved route in orange before revealing the final
purple path overlay, and ends on a full persistent pressure view.

### Data Structures and Their Roles

- `priority_queue`: open-set frontier ordered by `f = g + h`.
- `ordered_sequence`: closed/visited keys for deterministic membership
  updates.
- `flexseq`: full persistent snapshot timeline used for replay and
  history metrics.

### Core Logic (Minimal)

``` r
# Codified vignette preset (see algorithm_demos_helpers.R)
algorithm_demo_presets$astar_organic_history_large_fast

# Equivalent driver shape:
run_astar_from_preset(
  name = "astar_organic_history_large_fast",
  outfile = "vignettes/assets/algorithm-demos/05-astar-organic-history-large-fast.gif"
)
```

### Visualization

![A\* replay with staged final-route reveal, then persistent pressure
summary.](assets/algorithm-demos/05-astar-organic-history-large-fast.gif)

A\* replay with staged final-route reveal, then persistent pressure
summary.

### Full Implementation

Show source/helper paths

- Demo source: `meta/scripts/demo_astar_immutables.R`
- Preset registry: `vignettes/helpers/algorithm_demos_helpers.R`
- Asset renderer: `vignettes/helpers/render_algorithm_demo_assets.R`

## Wave Clear

### What This Illustrates

A queued “wave + clear-wave” process over a weighted obstacle field. The
demo shows how immutable timelines make event replay and summary metrics
straightforward.

### Data Structures and Their Roles

- `priority_queue`: add/clear events scheduled by time.
- `ordered_sequence`: active-cell set keyed by cell id.
- `flexseq`: immutable snapshot timeline for animation and playback.

### Core Logic (Minimal)

``` r
# Minimal wrapper from algorithm_demos_helpers.R
stats <- run_wave_clear_minimal(complexity = "standard")
stats

# Core behavior:
# - pop due events from priority queue
# - apply add/clear to active ordered state
# - append snapshot to persistent timeline
```

### Visualization

![Wave and clear-wave progression over persistent state
snapshots.](assets/algorithm-demos/06-wave-clear.gif)

Wave and clear-wave progression over persistent state snapshots.

### Full Implementation

Show source/helper paths

- Demo source: `meta/scripts/demo_wave_clear_immutables.R`
- Asset renderer: `vignettes/helpers/render_algorithm_demo_assets.R`
