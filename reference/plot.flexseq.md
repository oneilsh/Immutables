# Plot a Sequence Tree

Plot a Sequence Tree

## Usage

``` r
# S3 method for class 'flexseq'
plot(x, ...)
```

## Arguments

- x:

  A `flexseq`.

- ...:

  Passed to the internal tree plotting routine.

## Details

Visualizes the internal finger-tree structure, not a value-level chart.

## Examples

``` r
x <- flexseq("a", "b", "c")
plot(x)
#> Error in plot_tree(x, ...): Package 'igraph' is required for plot_tree(). Install it with install.packages('igraph').
```
