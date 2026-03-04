# Peek at the Back Element

Returns the last element without modifying the sequence.

## Usage

``` r
peek_back(x)
```

## Arguments

- x:

  A `flexseq`.

## Value

Last element, or `NULL` when `x` is empty.

## Details

Returns the payload element without modifying `x`.

## Examples

``` r
x <- flexseq("a", "b", "c")
peek_back(x)
#> [1] "c"

peek_back(flexseq())
#> NULL
```
