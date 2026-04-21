# Print an Ordered Sequence Summary

Prints a compact summary and head/tail preview in key order.

## Usage

``` r
# S3 method for class 'ordered_sequence'
print(x, max_elements = 4L, show_custom_monoids = FALSE, ...)
```

## Arguments

- x:

  An `ordered_sequence`.

- max_elements:

  Maximum number of elements shown in the preview.

- show_custom_monoids:

  Logical; show attached non-default monoids and their root cached
  measures.

- ...:

  Passed through to per-element
  [`print()`](https://rdrr.io/r/base/print.html).

## Value

Invisibly returns `x`.

## Examples

``` r
xs <- ordered_sequence(one = "a", two = "b", three = "c", keys = c(20, 30, 10))
print(xs, max_elements = 4)
#> Named ordered_sequence with 3 elements.
#> 
#> Elements (by key order):
#> 
#> $three (key 10)
#> [1] "c"
#> 
#> $one (key 20)
#> [1] "a"
#> 
#> $two (key 30)
#> [1] "b"
#> 
sum_key <- measure_monoid(`+`, 0, function(entry) as.numeric(entry$key))
ys2 <- add_monoids(ordered_sequence("a", "b", keys = c(2, 1)), list(sum_key = sum_key))
print(ys2, max_elements = 0, show_custom_monoids = TRUE)
#> Unnamed ordered_sequence with 2 elements.
#> Custom monoids + measures:
#>   sum_key: 3 (aggregate)

ys <- ordered_sequence("x", "y", "z", keys = c(2, 1, 3))
print(ys, max_elements = 3)
#> Unnamed ordered_sequence with 3 elements.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key 1)
#> [1] "y"
#> 
#> [[2]] (key 2)
#> [1] "x"
#> 
#> [[3]] (key 3)
#> [1] "z"
#> 

print(ordered_sequence())
#> Unnamed ordered_sequence with 0 elements.
```
