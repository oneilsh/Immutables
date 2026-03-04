# Print a flexseq

Print a flexseq

## Usage

``` r
# S3 method for class 'flexseq'
print(x, max_elements = 4L, show_internal_monoids = FALSE, ...)
```

## Arguments

- x:

  A `flexseq`.

- max_elements:

  Maximum number of elements shown in preview (`head + tail`).

- show_internal_monoids:

  Logical; include internal monoids in the "Custom monoids" line.

- ...:

  Passed through to per-element
  [`print()`](https://rdrr.io/r/base/print.html).

## Examples

``` r
x <- as_flexseq(setNames(as.list(1:6), letters[1:6]))
print(x, max_elements = 4)
#> Named flexseq with 6 elements.
#> 
#> Elements:
#> 
#> $a
#> [1] 1
#> 
#> $b
#> [1] 2
#> 
#> ... (skipping 2 elements)
#> 
#> $e
#> [1] 5
#> 
#> $f
#> [1] 6
#> 

y <- as_flexseq(as.list(1:6))
print(y, max_elements = 3)
#> Unnamed flexseq with 6 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] 1
#> 
#> [[2]]
#> [1] 2
#> 
#> ... (skipping 3 elements)
#> 
#> [[6]]
#> [1] 6
#> 
```
