# Coerce Priority Queue to List

Returns queue entries as a plain list of records with fields `item` and
`priority`, in queue sequence order.

## Usage

``` r
# S3 method for class 'priority_queue'
as.list(x, ...)
```

## Arguments

- x:

  A `priority_queue`.

- ...:

  Unused.

## Value

A plain list of queue entry records.

## Details

Each returned element is a record with fields `item` and `priority`.
Entry names (when present) are preserved on the returned list.

## Examples

``` r
q <- priority_queue("a", "b", priorities = c(2, 1))
as.list(q)
#> [[1]]
#> [[1]]$item
#> [1] "a"
#> 
#> [[1]]$priority
#> [1] 2
#> 
#> 
#> [[2]]
#> [[2]]$item
#> [1] "b"
#> 
#> [[2]]$priority
#> [1] 1
#> 
#> 
```
