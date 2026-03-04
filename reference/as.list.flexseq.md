# Coerce a Sequence to Base List

Returns elements in left-to-right sequence order.

## Usage

``` r
# S3 method for class 'flexseq'
as.list(x, ...)
```

## Arguments

- x:

  A `flexseq`.

- ...:

  Unused.

## Value

A base R list of sequence elements.

## Details

Returns payload elements in sequence order. If the sequence is fully
named, those names are preserved on the returned list.

## Examples

``` r
x <- flexseq("a", "b", "c")
as.list(x)
#> [[1]]
#> [1] "a"
#> 
#> [[2]]
#> [1] "b"
#> 
#> [[3]]
#> [1] "c"
#> 

n <- flexseq(a = 1, b = 2)
as.list(n)
#> $a
#> [1] 1
#> 
#> $b
#> [1] 2
#> 
```
