# Pop All Maximum-Priority Elements

Removes the full maximum-priority tie run.

## Usage

``` r
pop_all_max(x)
```

## Arguments

- x:

  A `priority_queue`.

## Value

A list with fields:

- `elements`: `priority_queue` of removed maximum-priority elements.

- `remaining`: queue after removal.

## Details

The return `elements` is another
[`priority_queue()`](https://oneilsh.github.io/immutables/reference/priority_queue.md),
use [`as.list()`](https://rdrr.io/r/base/list.html) to convert the
result to a standard R list.

## Examples

``` r
x <- priority_queue("a", "b", "c", priorities = c(2, 3, 3))
out <- pop_all_max(x)
out$elements
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
out$remaining
#> Unnamed priority_queue with 1 element.
#> Minimum priority: 2, Maximum priority: 2
#> 
#> Elements (by priority):
#> 
#> (priority 2)
#> [1] "a"
#> 
```
