#!/usr/bin/env Rscript
# -----------------------------------------------------------------------------
# JSS QUICK replication script for the Immutables paper.
#
# A reviewer-friendly counterpart to generate_publication_results.R. Instead of
# the full benchmark sweep (all sizes, 10 reps per operation, many hours), this
# runs a reduced sweep -- only the smallest three problem sizes per collection,
# a single repetition per operation -- so it finishes in well under an hour on a
# regular laptop.
#
# It reproduces the SHAPE of every benchmark figure in the manuscript (the same
# operations, implementations, and qualitative scaling behaviour), not the exact
# published timings. Outputs are written to separate *-fast files, so the
# canonical cached results shipped with the package are never overwritten:
#
#   inst/extdata/benchmarks-*-fast.rds  - reduced benchmark timings, one per batch
#   paper/figures/benchmarks-*-fast.pdf - the corresponding quick-run figures
#
# For the exact published numbers and figures, run the full script instead:
#   Rscript data-raw/replication/generate_publication_results.R
#
# Usage (from the unpacked package source directory):
#   Rscript /path/to/replication-quick.R
# The script locates the package root by walking up from the working directory,
# so run it from anywhere inside the unpacked source tree.
#
# Required packages (all listed in DESCRIPTION's Suggests):
#   Immutables, bench, ggplot2, dplyr, microbenchmark, rstackdeque, IRanges,
#   S4Vectors, rmarkdown, rprojroot
# -----------------------------------------------------------------------------

repo_root <- rprojroot::find_root(rprojroot::is_r_package)

Sys.setenv(IMMUTABLES_RUN_FAST = "true")

started_at <- Sys.time()

message("Rendering vignettes/benchmarks.Rmd in FAST mode (smallest 3 sizes, 1 rep)...")
rmarkdown::render(
  file.path(repo_root, "vignettes/benchmarks.Rmd"),
  knit_root_dir = repo_root,
  envir = new.env(),
  quiet = FALSE
)

elapsed <- difftime(Sys.time(), started_at, units = "mins")
message(sprintf("\nDone in %.1f minutes.", as.numeric(elapsed)))
message("Quick figures: ", file.path(repo_root, "paper", "figures"))
message("  (files ending in -fast.pdf; compare their shape against the paper's figures.)")
