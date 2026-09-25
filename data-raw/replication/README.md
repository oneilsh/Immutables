# Replication materials

**Immutables: Fast, Functional Data Structures for R**  
Shawn T. O'Neil <shawn@tislab.org>

## Contents

- `README.md`: this file.
- `Immutables_<version>.tar.gz`: the full package source, exactly as submitted
  to CRAN.
- `replication_code.R`: a linear replication script. It runs every code example
  in the manuscript in order, under headers matching the manuscript's sections
  (Section 2.1, 2.2, ...), followed by the full benchmark suite of Section 4,
  with its figures drawn to the active graphics device.

The examples (Sections 2 and 3) run in seconds. The benchmarks take several
hours: seven problem sizes per collection and ten repetitions per operation,
run serially with a full garbage collection before every measurement. For a
faster, partial check, reduce `repeats` at the top of Section 4 and the
per-structure size vectors (`sequence_sizes`, `ord_sizes`, `pq_sizes`,
`ivx_sizes`).

The benchmark code in `replication_code.R` is the code of the package's
benchmarks vignette (`vignettes/benchmarks.Rmd`), with the vignette's caching
and figure-saving infrastructure removed.

## Requirements

- R (>= 4.1.0) with a C++ compiler toolchain, to install the package from
  source.
- The following R packages, all listed in the package's `DESCRIPTION` under
  Suggests: bench, dplyr, ggplot2, igraph, microbenchmark, scales, IRanges,
  and S4Vectors.

IRanges and S4Vectors are Bioconductor packages; install them with:

```r
install.packages("BiocManager")
BiocManager::install(c("IRanges", "S4Vectors"))
```

## How to run

1. Install the package from the included source tarball (or from CRAN with
   `install.packages("Immutables")`):

   ```sh
   R CMD INSTALL Immutables_<version>.tar.gz
   ```

2. Run the script, or step through it section by section in an R session:

   ```sh
   Rscript replication_code.R
   ```

## Regenerating the published figures

The manuscript's benchmark figures are produced by the package's benchmarks
vignette and cached in the package source. Regenerating them, and typesetting
the manuscript against the fresh results, requires the development repository,
since the CRAN source does not include the `paper/` and `data-raw/`
directories. It additionally requires knitr, pkgload, rmarkdown, rprojroot,
rticles, and a LaTeX installation.

```sh
git clone https://github.com/oneilsh/Immutables
cd Immutables
Rscript data-raw/replication/generate_benchmark_figs_slow.R
```

This takes several hours. It overwrites `inst/extdata/benchmarks-*.rds` and
`paper/figures/benchmarks-*.pdf`, and writes `paper/manuscript.pdf`.

## Links

- CRAN: <https://CRAN.R-project.org/package=Immutables>
- Source: <https://github.com/oneilsh/Immutables>
