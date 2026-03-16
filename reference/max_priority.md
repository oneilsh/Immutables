# Maximum Priority Value

Returns the current maximum priority scalar in the queue.

## Usage

``` r
max_priority(x)
```

## Arguments

- x:

  A `priority_queue`.

## Value

Maximum priority value, or `NULL` when `x` is empty.

## Details

Uses cached `.pq_max` monoid state.

## Examples

``` r
q <- priority_queue("a", "b", priorities = c(2, 1))
max_priority(q)
#> [1] 2
max_priority(priority_queue())
#> NULL
```
