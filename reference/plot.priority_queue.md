# Plot a Priority Queue Tree

Plot a Priority Queue Tree

## Usage

``` r
# S3 method for class 'priority_queue'
plot(x, ...)
```

## Arguments

- x:

  A `priority_queue`.

- ...:

  Passed to the internal tree plotting routine.

## Details

Visualizes the internal finger-tree structure backing the queue.

## Examples

``` r
q <- priority_queue("a", "b", "c", priorities = c(2, 1, 3))
plot(q)
#> Error in plot_tree(x, ...): Package 'igraph' is required for plot_tree(). Install it with install.packages('igraph').
```
