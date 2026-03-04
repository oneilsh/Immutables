# Sequence Length

Sequence Length

## Usage

``` r
# S3 method for class 'flexseq'
length(x)
```

## Arguments

- x:

  A `flexseq`.

## Value

Number of elements in the sequence.

## Details

Uses cached size metadata and runs in O(1).

## Examples

``` r
x <- flexseq("a", "b")
length(x)
#> [1] 2

length(flexseq())
#> [1] 0
```
