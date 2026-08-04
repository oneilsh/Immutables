#!/usr/bin/env Rscript
# -----------------------------------------------------------------------------
# JSS replication script for the Immutables paper.
#
# Reproduces every benchmark figure and timing reported in the manuscript,
# then typesets the manuscript itself against the freshly written results.
#
# Usage (from any directory; the script locates the package root):
#   Rscript data-raw/generate_publication_results.R
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
#   Immutables, bench, ggplot2, rstackdeque, IRanges, S4Vectors,
#   rmarkdown, rprojroot
# -----------------------------------------------------------------------------

repo_root <- rprojroot::find_root(rprojroot::is_r_package)

Sys.setenv(
  IMMUTABLES_RUN_SLOW     = "true",
  IMMUTABLES_SAVE_FIGURES = "true"
)

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
message("Results:    ", file.path(repo_root, "inst/extdata/benchmarks.rds"))
message("Figures:    ", file.path(repo_root, "paper/figures/"))
message("Manuscript: ", file.path(repo_root, "paper/manuscript.pdf"))
