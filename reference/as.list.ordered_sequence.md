# Coerce Ordered Sequence to List

Coerce Ordered Sequence to List

## Usage

``` r
# S3 method for class 'ordered_sequence'
as.list(x, ...)
```

## Arguments

- x:

  An `ordered_sequence`.

- ...:

  Unused.

## Value

A plain list of elements in key order.

## Details

Returns payload elements only (keys are omitted) in canonical key order.
If entries are named, names are preserved on the returned list.

## Examples

``` r
x <- ordered_sequence("a", "b", "c", keys = c(2, 1, 3))
as.list(x)
#> [[1]]
#> [1] "b"
#> 
#> [[2]]
#> [1] "a"
#> 
#> [[3]]
#> [1] "c"
#> 
```
