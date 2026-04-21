# Plot an Interval Index Tree

Plots the underlying tree structure used by an `interval_index`.

## Usage

``` r
# S3 method for class 'interval_index'
plot(x, ...)
```

## Arguments

- x:

  An `interval_index`.

- ...:

  Passed to the internal tree plotting routine.

## Details

Visualizes the internal finger-tree structure used for interval queries.

## Examples

``` r
ix <- interval_index("a", "b", "c", start = c(1, 3, 5), end = c(2, 4, 6))
if(requireNamespace("igraph", quietly = TRUE)) plot(ix)
```
