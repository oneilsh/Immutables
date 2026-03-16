# Coerce Priority Queue to List

Returns queue entries as a plain list of records with fields `value` and
`priority`, in queue sequence order.

## Usage

``` r
# S3 method for class 'priority_queue'
as.list(x, ..., drop_meta = FALSE)
```

## Arguments

- x:

  A `priority_queue`.

- ...:

  Unused.

- drop_meta:

  Logical scalar. When `FALSE` (default), returns full queue entry
  records (`value` + `priority`). When `TRUE`, returns payload values
  only.

## Value

A plain list of queue entry records (`drop_meta = FALSE`) or payload
values (`drop_meta = TRUE`).

## Details

Each returned entry is a record with fields `value` and `priority`.
Entry names (when present) are preserved on the returned list.

## Examples

``` r
q <- priority_queue("a", "b", priorities = c(2, 1))
as.list(q)
#> [[1]]
#> [[1]]$value
#> [1] "a"
#> 
#> [[1]]$priority
#> [1] 2
#> 
#> 
#> [[2]]
#> [[2]]$value
#> [1] "b"
#> 
#> [[2]]$priority
#> [1] 1
#> 
#> 
as.list(q, drop_meta = TRUE)
#> [[1]]
#> [1] "a"
#> 
#> [[2]]
#> [1] "b"
#> 
```
