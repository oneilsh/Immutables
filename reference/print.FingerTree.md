# Print a compact summary of a finger tree

Print a compact summary of a finger tree

## Usage

``` r
# S3 method for class 'FingerTree'
print(x, max_elements = 4L, show_custom_monoids = FALSE, ...)

# S3 method for class 'Deep'
print(x, ...)

# S3 method for class 'Single'
print(x, ...)

# S3 method for class 'Empty'
print(x, ...)
```

## Arguments

- x:

  FingerTree.

- max_elements:

  Maximum number of elements shown in preview (`head + tail`). Default
  `4`.

- show_custom_monoids:

  Logical; show attached non-default monoids and their root cached
  measures. Default `FALSE`.

- ...:

  Passed through to [`print()`](https://rdrr.io/r/base/print.html) for
  preview elements.

## Value

`x`, invisibly.

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
sum_m <- measure_monoid(`+`, 0, function(el) as.numeric(el))
print(add_monoids(as_flexseq(1:3), list(sum = sum_m)), max_elements = 0, show_custom_monoids = TRUE)
#> Unnamed flexseq with 3 elements.
#> Custom monoids + measures:
#>   sum: 6

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
