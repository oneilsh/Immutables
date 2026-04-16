#!/usr/bin/env Rscript
# -----------------------------------------------------------------------------
# generate_publication_results.R
#
# Regenerates all published benchmarking results and figures for the immutables
# package and accompanying manuscript.
#
# Outputs:
#   inst/extdata/benchmarks.rds   - cached benchmark results loaded by the
#                                   vignette and the paper
#   paper/figures/*.pdf           - publication-ready figures
#
# Usage (from the repo root or any subdirectory):
#   Rscript data-raw/generate_publication_results.R
#
# Runtime: ~20 minutes on a modern laptop; longer on older hardware.
#
# Required packages (all already in DESCRIPTION's Suggests):
#   immutables, microbenchmark, ggplot2, rstackdeque, IRanges, S4Vectors,
#   scales, rmarkdown, rprojroot
# -----------------------------------------------------------------------------

repo_root <- rprojroot::find_root(rprojroot::is_r_package)

Sys.setenv(
  IMMUTABLES_RUN_SLOW     = "true",
  IMMUTABLES_SAVE_FIGURES = "true"
)

message("Rendering vignettes/benchmarks.Rmd (this is the slow step)...")
rmarkdown::render(
  file.path(repo_root, "vignettes/benchmarks.Rmd"),
  knit_root_dir = repo_root,
  envir = new.env(),
  quiet = FALSE
)

message("\nDone.")
message("Results: ", file.path(repo_root, "inst/extdata/benchmarks.rds"))
message("Figures: ", file.path(repo_root, "paper/figures/"))
