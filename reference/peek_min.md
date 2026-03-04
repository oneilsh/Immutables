# Peek Minimum-Priority Element

Returns the element at the minimum priority without modifying the queue.

## Usage

``` r
peek_min(x)
```

## Arguments

- x:

  A `priority_queue`.

## Value

Element at minimum priority, or `NULL` when `x` is empty.

## Details

Ties are stable: when multiple elements share minimum priority, this
returns the earliest element in queue order.

## Examples

``` r
x <- priority_queue("a", "b", "c", priorities = c(2, 1, 1))
peek_min(x)
#> [1] "b"
peek_min(priority_queue())
#> NULL
```
