# Priority Queue Length

Priority Queue Length

## Usage

``` r
# S3 method for class 'priority_queue'
length(x)
```

## Arguments

- x:

  A `priority_queue`.

## Value

Integer length.

## Details

Uses cached size metadata and runs in O(1).

## Examples

``` r
q <- priority_queue("a", "b", priorities = c(2, 1))
length(q)
#> [1] 2

length(priority_queue())
#> [1] 0
```
