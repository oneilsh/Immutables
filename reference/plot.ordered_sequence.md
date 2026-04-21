# Plot an Ordered Sequence Tree

Plots the underlying tree structure used by an `ordered_sequence`.

## Usage

``` r
# S3 method for class 'ordered_sequence'
plot(x, ...)
```

## Arguments

- x:

  An `ordered_sequence`.

- ...:

  Passed to the internal tree plotting routine.

## Details

Visualizes the internal finger-tree structure used to store ordered
entries.

## Examples

``` r
x <- ordered_sequence("a", "b", "c", keys = c(2, 1, 3))
if(requireNamespace("igraph", quietly = TRUE)) plot(x)
```
