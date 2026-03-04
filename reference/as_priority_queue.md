# Build a Priority Queue from `x` and `priorities`

Constructs a queue by pairing each element of `x` with the corresponding
value in `priorities`.

## Usage

``` r
as_priority_queue(x, priorities)
```

## Arguments

- x:

  Elements to enqueue.

- priorities:

  Priorities with the same length as `x`.

## Value

A `priority_queue`.

## Details

`x` is interpreted element-wise (via list coercion). Names on `x` are
preserved as queue element names.

All priorities must be non-missing and mutually comparable.

## Examples

``` r
x <- as_priority_queue(letters[1:4], priorities = c(3, 1, 2, 1))
x
#> Unnamed priority_queue with 4 elements.
#> Minimum priority: 1, Maximum priority: 3
#> 
#> Elements (by priority):
#> 
#> (priority 1)
#> [1] "b"
#> 
#> (priority 1)
#> [1] "d"
#> 
#> (priority 2)
#> [1] "c"
#> 
#> (priority 3)
#> [1] "a"
#> 
peek_min(x)
#> [1] "b"
peek_max(x)
#> [1] "a"

# Names are preserved
n <- as_priority_queue(setNames(as.list(1:3), c("a", "b", "c")), priorities = c(2, 1, 3))
n[["b"]]
#> [1] 2
```
