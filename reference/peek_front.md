# Peek at the Front Element

Returns the first element without modifying the sequence.

## Usage

``` r
peek_front(x)
```

## Arguments

- x:

  A `flexseq`.

## Value

First element, or `NULL` when `x` is empty.

## Details

Returns the payload element without modifying `x`.

## Examples

``` r
x <- flexseq("a", "b", "c")
peek_front(x)
#> [1] "a"

peek_front(flexseq())
#> NULL
```
