# Construct a Priority Queue

Creates a `priority_queue` from elements in `...` and matching
`priorities`.

## Usage

``` r
priority_queue(..., priorities)
```

## Arguments

- ...:

  Elements to enqueue.

- priorities:

  Priorities with the same length as `...`.

## Value

A `priority_queue`.

## Details

Empty construction is supported: `priority_queue()` returns an empty
queue.

If elements are named, names are preserved for name-based reads.

Queue operations are exposed through
[`insert()`](https://oneilsh.github.io/immutables/reference/insert.md),
`peek_*()`, `pop_*()`, and
[`fapply()`](https://oneilsh.github.io/immutables/reference/fapply.md).

## Examples

``` r
x <- priority_queue("a", "b", "c", priorities = c(2, 1, 2))
x
#> Unnamed priority_queue with 3 elements.
#> Minimum priority: 1, Maximum priority: 2
#> 
#> Elements (by priority):
#> 
#> (priority 1)
#> [1] "b"
#> 
#> (priority 2)
#> [1] "a"
#> 
#> (priority 2)
#> [1] "c"
#> 
peek_min(x)
#> [1] "b"

empty_q <- priority_queue()
peek_min(empty_q)
#> NULL
```
