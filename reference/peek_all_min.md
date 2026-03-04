# Peek All Minimum-Priority Elements

Returns the full minimum-priority tie run as a `priority_queue`.

## Usage

``` r
peek_all_min(x)
```

## Arguments

- x:

  A `priority_queue`.

## Value

A `priority_queue` containing all minimum-priority elements in stable
queue order. Returns an empty queue when `x` is empty.

## Details

The return is another
[`priority_queue()`](https://oneilsh.github.io/immutables/reference/priority_queue.md),
use [`as.list()`](https://rdrr.io/r/base/list.html) to convert the
result to a standard R list.

## Examples

``` r
x <- priority_queue("a", "b", "c", priorities = c(2, 1, 1))
peek_all_min(x)
#> Unnamed priority_queue with 2 elements.
#> Minimum priority: 1, Maximum priority: 1
#> 
#> Elements (by priority):
#> 
#> (priority 1)
#> [1] "b"
#> 
#> (priority 1)
#> [1] "c"
#> 
```
