# Pop All Minimum-Priority Elements

Removes the full minimum-priority tie run.

## Usage

``` r
pop_all_min(x)
```

## Arguments

- x:

  A `priority_queue`.

## Value

A list with fields:

- `elements`: `priority_queue` of removed minimum-priority elements.

- `remaining`: queue after removal.

## Details

The return `elements` is another
[`priority_queue()`](https://oneilsh.github.io/immutables/reference/priority_queue.md),
use [`as.list()`](https://rdrr.io/r/base/list.html) to convert the
result to a standard R list.

## Examples

``` r
x <- priority_queue("a", "b", "c", priorities = c(2, 1, 1))
out <- pop_all_min(x)
out$elements
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
