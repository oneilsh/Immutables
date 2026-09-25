#!/usr/bin/env Rscript
# -----------------------------------------------------------------------------
# Regenerates the benchmark results and figures for the Immutables paper.
# (For the linear replication script, see replication_code.R.)
#
# Reproduces every benchmark figure and timing reported in the manuscript,
# then typesets the manuscript itself against the freshly written results.
#
# Usage (from anywhere inside the repository; the script locates its root):
#   Rscript data-raw/replication/generate_benchmark_figs_slow.R
#
# Outputs (all under the package source tree):
#   inst/extdata/benchmarks-*.rds - raw benchmark timings, one file per batch
#                                   (sequence/pq/ordered/ivx), consumed by both
#                                   the benchmarks vignette and the paper
#   paper/figures/*.pdf           - publication-ready figures
#   paper/manuscript.pdf          - typeset manuscript referencing the above
#
# Runtime: a few hours on a modern laptop. The benchmark vignette uses an
# environment-variable gate so subsequent renders without IMMUTABLES_RUN_SLOW
# load the cached results instead of re-timing.
#
# Required packages (all listed in DESCRIPTION's Suggests):
#   bench, dplyr, ggplot2, igraph, IRanges, knitr, microbenchmark, pkgload,
#   rmarkdown, rprojroot, rticles, S4Vectors, scales
# Also requires a C++ compiler toolchain (the vignette compiles the package
# from this source tree) and a LaTeX installation.
# -----------------------------------------------------------------------------

repo_root <- rprojroot::find_root(rprojroot::is_r_package)

Sys.setenv(IMMUTABLES_RUN_SLOW = "true")

started_at <- Sys.time()

message("Step 1/2: rendering vignettes/benchmarks.Rmd (this is the slow step)...")
rmarkdown::render(
  file.path(repo_root, "vignettes/benchmarks.Rmd"),
  knit_root_dir = repo_root,
  envir = new.env(),
  quiet = FALSE
)

message("\nStep 2/2: rendering paper/manuscript.Rmd against the new cache...")
rmarkdown::render(
  file.path(repo_root, "paper/manuscript.Rmd"),
  knit_root_dir = repo_root,
  envir = new.env(),
  quiet = FALSE
)

elapsed <- difftime(Sys.time(), started_at, units = "mins")
message(sprintf("\nDone in %.1f minutes.", as.numeric(elapsed)))
message("Results:    ", file.path(repo_root, "inst/extdata/benchmarks-*.rds"))
message("Figures:    ", file.path(repo_root, "paper/figures/"))
message("Manuscript: ", file.path(repo_root, "paper/manuscript.pdf"))
