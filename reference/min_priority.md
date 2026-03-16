# Minimum Priority Value

Returns the current minimum priority scalar in the queue.

## Usage

``` r
min_priority(x)
```

## Arguments

- x:

  A `priority_queue`.

## Value

Minimum priority value, or `NULL` when `x` is empty.

## Details

Uses cached `.pq_min` monoid state.

## Examples

``` r
q <- priority_queue("a", "b", priorities = c(2, 1))
min_priority(q)
#> [1] 1
min_priority(priority_queue())
#> NULL
```
