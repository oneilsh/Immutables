# Pop Maximum-Priority Element

Removes one maximum-priority element and returns it with the remaining
queue.

## Usage

``` r
pop_max(x)
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

Ties are stable: when multiple elements share maximum priority, the
earliest element in queue order is removed.

## Examples

``` r
x <- priority_queue("a", "b", "c", priorities = c(2, 3, 3))
out <- pop_max(x)
out$value
#> [1] "b"
out$priority
#> [1] 3
out$remaining
#> Unnamed priority_queue with 2 elements.
#> Minimum priority: 2, Maximum priority: 3
#> 
#> Elements (by priority):
#> 
#> (priority 2)
#> [1] "a"
#> 
#> (priority 3)
#> [1] "c"
#> 
pop_max(priority_queue())
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
