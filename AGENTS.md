# AGENTS.md

## Purpose
Use this file as the durable startup context for work in this repository.
Treat tests and current source as the source of truth when docs conflict.

## Project Snapshot
- Package: `immutables` (R package using finger trees with optional C++ fast paths).
- Core structures:
  - `flexseq`: general persistent sequence.
  - `priority_queue`: queue-first API layered on `flexseq`.
  - `ordered_sequence`: key-ordered sequence API.
- Current API direction (important):
  - `push_front/push_back/pop_front/pop_back/peek_front/peek_back` are the preferred flexseq end-ops.
  - `priority_queue` intentionally blocks most sequence-style mutation/traversal; cast with `as_flexseq()` for those.
  - Ordered types block order-breaking writes and block `c()`.
  - Ordered merge is removed end-to-end for now (public API and internal merge primitive); do not assume `merge.ordered_sequence`.
  - `fapply` is the package's S3 generic for applying functions over immutable structures (not `lapply`, to avoid masking base).

## Recent Branch Trajectory (api-align)
Useful commit landmarks for intent:
- `b97a2b5` API alignment work begins (`apply` generic direction, shared method patterns).
- `3009b10` generalized reuse of flexseq infrastructure for subclasses.
- `0a5a601` ordered types split into `ordered_sequence` + `ordered_multiset` (now removed).
- `7b6fced` priority queue surface narrowed (queue-first UX).
- `ffcb101` removed fold/walk machinery from public surface.
- `c07b4e6` migrated user-facing sequence endpoints to push/pop/peek names.
- `b276f73` removed ordered merge methods for now.
- `e920165` minor pkgdown reference reorder.

Interpretation:
- The codebase is intentionally simplifying and narrowing APIs.
- If in doubt, follow current tests + `NAMESPACE` over historical docs/blog-style examples.

## First Files to Read
1. `NAMESPACE` (what is exported and dispatched right now).
2. `R/50-ordered_sequence-ops.R`
3. `R/40-priority_queue-constructors.R`
4. `R/40-priority_queue-queue-ops.R`
5. `tests/testthat/test-ordered-sequence.R`
6. `tests/testthat/test-priority-queue.R`
7. `tests/testthat/test-cpp-parity.R`
8. `tests/testthat/test-cpp-gc-safety.R`
9. `meta/bench_runner.R`

## Ground Rules
- Preserve persistence semantics (never mutate user-visible structures in place).
- Keep R reference behavior authoritative; C++/fast paths must match parity.
- Avoid introducing API aliases unless explicitly requested.
- Keep ordered semantics deterministic:
  - `lower_bound` is first `>= key`
  - `upper_bound` is first `> key`
  - duplicate-key operations are leftmost/FIFO within equal-key runs.
- For `priority_queue`, keep queue-oriented UX and strict name-based reads.
- This software is pre-release, there is no need for backward compatility

## Standard Commands
- Load package:
  - `R -q -e "devtools::load_all(quiet=TRUE)"`
- Full tests:
  - `R -q -e "devtools::test()"`
- Full tests (force pure-R backend reference path):
  - `R -q -e "old<-getOption('immutables.use_cpp'); options(immutables.use_cpp=FALSE); on.exit(options(immutables.use_cpp=old), add=TRUE); devtools::test()"`
- Targeted tests:
  - `R -q -e "devtools::test(test_file='test-ordered-sequence.R')"`
  - `R -q -e "devtools::test(test_file='test-priority-queue.R')"`
- C++ GC stress tests (gated):
  - `R -q -e "Sys.setenv(IMMUTABLES_GC_STRESS='1'); devtools::test(test_file='test-cpp-gc-safety.R')"`
- Regenerate docs/NAMESPACE:
  - `R -q -e "devtools::document(quiet=TRUE)"`

## Benchmarks
- Preferred entrypoint: repo skill `immutables-bench`
  - Skill file:
    - `.agents/skills/immutables-bench/SKILL.md`
  - Use the skill workflow first for consistency of runs/notes/comparisons.
- Primary benchmark harness: `meta/bench_runner.R`
  - Direct commands (fallback if not using skill):
  - Quick profile:
    - `R -q -e "source('meta/bench_runner.R'); run_quick(note='...', use_cpp=TRUE)"`
  - Full profile:
    - `R -q -e "source('meta/bench_runner.R'); run_full(note='...', use_cpp=TRUE)"`
  - Scenario catalog:
    - `R -q -e "source('meta/bench_runner.R'); list_scenarios(base='quick')"`
  - Custom mix-and-match:
    - `R -q -e "source('meta/bench_runner.R'); run_scenarios(c('as_flexseq_only','ordered_sequence_insert'), note='...', use_cpp=TRUE)"`
  - Compare recent runs:
    - `R -q -e "source('meta/bench_runner.R'); compare_last(n=2)"`
- Benchmark outputs are local-only and gitignored:
  - `meta/bench-results/*.csv`
  - `meta/bench-results/*.meta.json`
- Legacy script still exists for ad-hoc reference:
  - `meta/bench.R`

## Common Pitfalls
- README/pkgdown may lag behind current API changes; verify against tests and `NAMESPACE`.
- Ordered and PQ class restoration behavior matters after operations; tests should assert class stacks.
- GC torture is time consuming; use targeted files and env-gated paths.
- When changing C++ wrappers or behavior, update both parity and GC safety coverage.
- High-churn areas (re-check tests after edits):
  - `R/30-api-flexseq-indexing.R`
  - `R/40-priority_queue-indexing.R`
  - `R/40-priority_queue-queue-ops.R`
  - `R/50-ordered_sequence-indexing.R`
  - `R/50-ordered_sequence-ops.R`
  - `_pkgdown.yml` + generated man/NAMESPACE surface

## Change Checklist
For API or behavior changes:
1. Update relevant R implementation files.
2. Update/extend tests (unit + parity/GC where applicable).
3. Run targeted tests first, then `devtools::test()`.
4. Run `devtools::document(quiet=TRUE)` if roxygen-exposed behavior changed.
5. Update `_pkgdown.yml` reference entries when new/removed topics affect pkgdown.
6. Update this file and skills or benchmarks as needed.

## Updating AGENTS.md With Notes
You may add notes about the repo to the Notes section below in this file, located
at <project root>/AGENTS.md

You should also keep the information in this file accurate as the state of the
API or underlying implementations change.

## Documentation Organization Preferences
- **One pkgdown section per data structure** (flexseq, priority_queue, ordered_sequence) plus a Developer Tools section. Do not fragment into sub-sections like "Indexing" or "Shared Methods".
- **One man page per type per generic**: each type gets its own standalone roxygen block and man page for methods like `length`, `plot`, `as.list`, `fapply`, `insert`. Do not use `@rdname` to lump multiple types onto a shared page (e.g. no `@rdname length.flexseq` from `length.priority_queue`).
- **Group indexing methods per type**: all indexing operators (`[`, `[[`, `[<-`, `[[<-`, `$`, `$<-`) for a given type share one man page via `@rdname` (e.g. `sub-.flexseq`). This produces one row in the reference index per type rather than six.
- **Bare generics** (`fapply`, `insert`) go under Developer Tools in `_pkgdown.yml`.

## Notes
- Notes should be added as markdown list items.
- You may use sublists to organize notes
  - like this
  - and this
- Keep notes short and concrete (commit SHA + impact + risk).
- `local`: API ergonomics redesign landed across ordered/interval/priority/flexseq: removed public `which="first|all"` selectors in favor of explicit `peek_all_*`/`pop_all_*`, standardized scalar misses (`peek_*` returns `NULL`; scalar `pop_*` returns non-throwing miss object), and canonicalized ordered/interval vector `[` selectors to sorted unique positions (duplicates now error). Risk: intentional breaking changes for callers using old `which` signatures, bulk pop `$element`, or strict-increasing selector assumptions.
- `eb493fd`: ordered_sequence key APIs aligned around `key`/`from_key`/`to_key`, `extract_key` renamed to `pop_key`, and missing-key reads are non-throwing (`peek_key(..., if_missing=...)`, `pop_key()` null-returns on miss). Risk: callers relying on previous argument names/error behavior need updates.
- `eb493fd`: removed `delete_one`/`delete_all`; `peek_key()` and `pop_key()` now support `which = "first"|"all"` where `"all"` operates on full duplicate-key runs and returns an ordered slice. Risk: code using deleted functions or assuming `pop_key()` always pops one element must migrate.
- `eb493fd`: `pop_front()`/`pop_back()` now return `element` (not `value`) plus `rest`; tests/docs/vignette updated. Risk: callers using `$value` must switch to `$element`.
- `eb493fd`: removed `ordered_multiset` API/tests and dropped package-level set-op generics (`union`/`intersect`/`setdiff`) tied to that surface. Risk: any code importing those package methods must migrate to explicit sequence operations.
- `eb493fd`: hardened C++ monoid/measures field access under GC pressure in `src/ft_cpp.cpp` (name lookup fallback for monoid subfields; recursive fallback for `.size`/`.named_count` reads when measure names are missing). Risk: GC torture remains expensive; `pop_key(which='all')` is excluded from GC-stress assertions to keep the suite deterministic.
- `eb493fd`: `ensure_size_monoids()` now canonicalizes every monoid spec to named `list(f, i, measure)` and validates that `f`/`measure` are functions before use. Impact: C++ positional fallback remains safe even if monoid list names are absent; risk: malformed custom `MeasureMonoid` objects now fail earlier with clearer errors.
- `eb493fd`: benchmark harness no longer references removed `ordered_multiset`/set-op scenarios; quick/full profiles now target live APIs only. Risk: historical OMS benchmark comparisons are no longer directly reproducible from default profiles.
- `eb493fd`: quick/full benchmark profiles now include `ordered_sequence_insert` to keep ordered-keyed workload coverage after OMS removal; `pq_insert_pop` remains available as a custom-only scenario. Risk: historical quick/full trend lines have one scenario changed.
- `eb493fd`: full-profile benchmark sizes were reduced in high-cost R-backend scenarios (`flexseq_tree_from*`, split variants, index reads, `as_flexseq_only`) to keep single-scenario runs within ~30s when capped. Risk: full-profile values are less stress-heavy than earlier settings.
- `eb493fd`: fixed `insert.ordered_sequence()` R fallback boundary case (`use_cpp=FALSE`) by avoiding public `push_back()` guard when appending split-left fragments; `ordered_sequence_insert` benchmarks now execute on R backend. Risk: internal append helper path should continue to preserve ordered wrapping invariants (covered by ordered-sequence tests).
- `eb493fd`: benchmark coverage now includes additional non-flexseq structure scenarios (`ordered_sequence_bounds`, `pq_insert_pop`) and both are in quick/full profiles with R-safe parameter sizes. Risk: scenario names/default params changed; compare historical runs by scenario+params, not just run label.
- `eb493fd`: added deeper ordered-sequence and priority-queue benchmark scenarios (`ordered_sequence_range_queries`, `ordered_sequence_pop_cycle`, `pq_peek_min_max`, `pq_pop_min_drain`, `pq_mixed_ops`) to improve optimization signal across lookup vs mutation-heavy paths. Risk: broader quick/full profiles increase total run time; use `run_scenarios()` for focused profiling.
- `f300088`: interval_index query surface now uses `peek_point`/`peek_overlaps`/`peek_containing`/`peek_within` plus `pop_point`/relation `pop_*`; removed `find_*` interval query helpers from exports/docs/tests. Risk: callers using removed `find_*` APIs must migrate to `peek_*`/`pop_*`.
- `f300088`: ordered-subclass blocker errors now report concrete subclass names for inherited mutation endpoints (`c`, `push_front`, `push_back`, `insert_at`, `[<-`, `[[<-`, `$<-`) rather than hardcoded `ordered_sequence`. Risk: callers/tests matching exact prior error strings may need updates.
- `53437c6+local`: removed legacy internal ordered merge path (`.ft_cpp_oms_set_merge`) from R wrapper, C registration, C++ implementation, and parity/GC test references so "no ordered merge" remains true across all layers. Risk: any developer-only code invoking the removed internal symbol now errors and must wait for the planned clean reimplementation.
- `53437c6+local`: tightened test signal quality (`validate_*` now asserts invisible `TRUE`, redundant `test-seq-apply` monoid case folded into one stronger persistence assertion, and element tests now assert value-level identity for list/data.frame payloads). Risk: stricter tests may fail immediately when semantics intentionally change and require explicit test updates.
- `local`: pure-R core execution now routes through reference implementations for `tree_from` bulk build, `concat/app3`, and end-op append/prepend paths; legacy core fast-R files were removed and CI now includes a forced-R backend test workflow (`r-backend-reference`). Risk: fallback mode can be slower, but behavior is now easier to audit against tests/parity.
- `local`: interval_index now maintains additional reserved subtree monoids (`.ivx_max_end`, `.ivx_min_end`) and routes `peek_*`/`pop_*` relation operations through a shared pruning-aware query engine; `pop_* (which='all')` uses span partition + linear rebuild and benchmark coverage now includes `interval_index_overlaps_all_stress`. Risk: C++-enabled mixed-query scenarios may need follow-up tuning despite improved forced-R fallback times.
- `local`: `meta/bench_runner.R` now includes first-class custom-monoid scenarios for flexseq (`add_monoids_only*`, `locate_custom_cached*`, `split_tree_custom_cached*`, `split_custom_cached*`) so one-time attach cost and steady-state cached-query cost can be benchmarked without touching the stale auto-running `meta/bench.R`. Risk: quick/full suites are broader; compare by scenario and params, not just run label.
- `local`: `Rprof` on `add_monoids(as_flexseq(...), list(sum=...))` points to `add_monoids.flexseq -> rebind_tree_monoids -> set_measure_with_reuse` as the dominant path, with large self time in repeated lookup/dispatch helpers (`get0`, `get_lr`); the lightweight subtype measure wrapper is not the bottleneck. Risk: attach-cost optimizations likely need per-node recompute/lookup reductions rather than API-surface tweaks.
- C++ GC safety in `src/ft_cpp.cpp` — recurring "$ operator is invalid for atomic vectors" root cause and fix patterns:
  - **Root cause**: bare `SEXP` variables holding newly-allocated R objects (from R function calls or `make_*` helpers) are invisible to R's GC, which does not scan the C++ stack. Any subsequent R allocation (including Rcpp `Function::operator()` building its call via `Rf_lang3`) can trigger GC and collect these temporaries.
  - **Pattern 1 — unprotected R function results used as args to another R function call**: e.g. `SEXP m = measure(ch); f(acc.get(), m)`. The `f()` call allocates to build its LANGSXP before executing, collecting `m`. Fix: `Shield<SEXP> m(measure(ch)); f(acc.get(), (SEXP)m)`. Affected: `measures_from_children`, `measure_sequence`, `locate_digit_impl_cpp`, `split_digit_cpp`.
  - **Pattern 2 — multiple `make_*` results as direct arguments to `make_deep`**: e.g. `make_deep(make_digit(...), make_empty(...), make_digit(...), monoids)`. C++ argument eval order is implementation-defined; each `make_*` allocates heavily. Fix: Shield each result before passing. Affected: `tree_from_sorted_list_cpp`, `digit_to_tree_cpp`.
  - **Pattern 3 — unprotected `make_*` results in `List::push_back`**: `push_back` reallocates the list, which can collect the unprotected temporary. Fix: Shield before `push_back`. Affected: `measured_nodes_cpp`.
  - **Safe patterns (no fix needed)**: `d["prefix"]`, `sm["left"]`, `ms[monoid_name]` etc. return pointers into existing protected lists — elements are kept alive by parent objects through the attribute chain back to `.Call` arguments. `Shield<SEXP>` and `ReprotectSEXP` usage in `add_right_cpp`, `add_left_cpp`, `viewL_cpp`, `viewR_cpp` was already correct.
  - **Testing**: `IMMUTABLES_GC_STRESS=1` with `gctorture2(1)` reliably triggers these bugs. Always run GC torture after any C++ changes touching SEXP temporaries.
- `local`: added repo-local review workflow skill at `.agents/skills/immutables-review/SKILL.md` plus durable review artifacts under `.review/` (`curriculum.md`, `progress-ledger.md`, `issue-queue.md`). Default review rule: do not run tests without explicit user approval unless the user grants a temporary session override.
- `local`: review intent is user learning-first: each session should choose the best next topic, point to specific code anchors (file + line), and explain behavior/invariants in those exact sections.
- `local`: when a review is started/resumed ("review", "continue review"), default response mode must be guided walkthrough with anchor-based explanations; do not fall back to silent audit-style "no issues" summaries unless the user explicitly asks for findings-only mode.
