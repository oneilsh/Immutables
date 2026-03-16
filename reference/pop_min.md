# Pop Minimum-Priority Element

Removes one minimum-priority element and returns it with the remaining
queue.

## Usage

``` r
pop_min(x)
```

## Arguments

- x:

  A `priority_queue`.

## Value

A list with fields:

- `value`: removed element, or `NULL` when `x` is empty.

- `priority`: removed priority, or `NULL` when `x` is empty.

- `remaining`: queue after removal.

## Details

Ties are stable: when multiple elements share minimum priority, the
earliest element in queue order is removed.

## Examples

``` r
x <- priority_queue("a", "b", "c", priorities = c(2, 1, 1))
out <- pop_min(x)
out$value
#> [1] "b"
out$priority
#> [1] 1
out$remaining
#> Unnamed priority_queue with 2 elements.
#> Minimum priority: 1, Maximum priority: 2
#> 
#> Elements (by priority):
#> 
#> (priority 1)
#> [1] "c"
#> 
#> (priority 2)
#> [1] "a"
#> 
pop_min(priority_queue())
#> $value
#> NULL
#> 
#> $priority
#> NULL
#> 
#> $remaining
#> Unnamed priority_queue with 0 elements.
#> 
```
