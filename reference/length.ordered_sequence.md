# Ordered Sequence Length

Ordered Sequence Length

## Usage

``` r
# S3 method for class 'ordered_sequence'
length(x)
```

## Arguments

- x:

  An `ordered_sequence`.

## Value

Integer length.

## Details

Uses cached size metadata and runs in O(1).

## Examples

``` r
x <- ordered_sequence("a", "b", keys = c(2, 1))
length(x)
#> [1] 2

length(ordered_sequence())
#> [1] 0
```
