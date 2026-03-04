# Peek Maximum-Priority Element

Returns the element at the maximum priority without modifying the queue.

## Usage

``` r
peek_max(x)
```

## Arguments

- x:

  A `priority_queue`.

## Value

Element at maximum priority, or `NULL` when `x` is empty.

## Details

Ties are stable: when multiple elements share maximum priority, this
returns the earliest element in queue order.

## Examples

``` r
x <- priority_queue("a", "b", "c", priorities = c(2, 3, 3))
peek_max(x)
#> [1] "b"
peek_max(priority_queue())
#> NULL
```
