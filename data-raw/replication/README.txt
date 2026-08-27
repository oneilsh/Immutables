=============================================================================
Replication materials for:

  "Immutables: Fast and Functional Data Structures"
  Shawn T. O'Neil  <shawn@tislab.org>

=============================================================================

CONTENTS
-----------------------------------------------------------------------------
  README.txt                        This file.

  Immutables_<version>.tar.gz       Full package source, exactly as submitted
                                    to CRAN. Contains all R and C++ source,
                                    the benchmarking vignette, and the cached
                                    benchmark results used to typeset the
                                    manuscript figures.

  generate_publication_results.R    FULL replication script. Reproduces 
                                    benchmark figures and timings in the paper, 
                                    then typesets the manuscript.
                                    Runtime: several hours (seven problem sizes
                                    per collection up to ~10^6 elements,
                                    ten repetitions per operation, run serially 
                                    with a full garbage collection between every 
                                    measurement).

  replication-quick.R               FAST replication script for reviewers.
                                    Runs a reduced benchmark sweep (smallest
                                    three problem sizes per collection, a
                                    single repetition per operation) that
                                    reproduces a subset of benchmark results 
                                    in minutes on a regular
                                    laptop. It calls the same code (fast and full
                                    generation are controlled by an environment
                                    variable), serving as an execution-verification
                                    check for peer reviewers.


The package is also available from CRAN:
  https://CRAN.R-project.org/package=Immutables
and developed at:
  https://github.com/oneilsh/Immutables


REQUIREMENTS
-----------------------------------------------------------------------------
  - R (>= 4.1.0) with a C++ compiler toolchain (the package has compiled code).
  - The following R packages, all listed in the package's DESCRIPTION under
    Suggests, are needed to run the replication scripts:

      bench, ggplot2, dplyr, microbenchmark, rstackdeque, rmarkdown,
      rprojroot, IRanges, S4Vectors

    IRanges and S4Vectors are Bioconductor packages; install them with:
      install.packages("BiocManager"); BiocManager::install(c("IRanges", "S4Vectors"))

    Typesetting the manuscript (the full script's second step) additionally
    requires a LaTeX installation.


HOW TO RUN
-----------------------------------------------------------------------------
1. Unpack the package source:

      tar xzf Immutables_<version>.tar.gz
      cd Immutables

2. Install the package (from the unpacked source, or from CRAN):

      R CMD INSTALL .
   or, in R:
      install.packages("Immutables")

3a. QUICK reproduction (recommended first pass; minutes):

      Rscript data-raw/replication/replication-quick.R

    This renders the benchmarking vignette in fast mode and writes:
      inst/extdata/benchmarks-*-fast.rds   reduced timings
      paper/figures/benchmarks-*-fast.pdf  the quick-run figures

3b. FULL reproduction (exact published results; several hours):

      Rscript data-raw/replication/generate_publication_results.R

    This re-runs the complete benchmark sweep, overwrites the cached
    inst/extdata/benchmarks-*.rds, regenerates paper/figures/benchmarks-*.pdf,
    and typesets paper/manuscript.pdf against the fresh results.