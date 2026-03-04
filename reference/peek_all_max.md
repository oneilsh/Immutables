# Peek All Maximum-Priority Elements

Returns the full maximum-priority tie run as a `priority_queue`.

## Usage

``` r
peek_all_max(x)
```

## Arguments

- x:

  A `priority_queue`.

## Value

A `priority_queue` containing all maximum-priority elements in stable
queue order. Returns an empty queue when `x` is empty.

## Details

The return is another
[`priority_queue()`](https://oneilsh.github.io/immutables/reference/priority_queue.md),
use [`as.list()`](https://rdrr.io/r/base/list.html) to convert the
result to a standard R list.

## Examples

``` r
x <- priority_queue("a", "b", "c", priorities = c(2, 3, 3))
peek_all_max(x)
#> Unnamed priority_queue with 2 elements.
#> Minimum priority: 3, Maximum priority: 3
#> 
#> Elements (by priority):
#> 
#> (priority 3)
#> [1] "b"
#> 
#> (priority 3)
#> [1] "c"
#> 
```
