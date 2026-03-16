# Print a Priority Queue Summary

Prints a compact summary with priority range and a head/tail preview.

## Usage

``` r
# S3 method for class 'priority_queue'
print(x, max_elements = 4L, show_custom_monoids = FALSE, ...)
```

## Arguments

- x:

  A `priority_queue`.

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
q <- priority_queue(one = 1, two = 2, three = 3, priorities = c(20, 30, 10))
print(q, max_elements = 4)
#> Named priority_queue with 3 elements.
#> Minimum priority: 10, Maximum priority: 30
#> 
#> Elements (by priority):
#> 
#> $three (priority 10)
#> [1] 3
#> 
#> $one (priority 20)
#> [1] 1
#> 
#> $two (priority 30)
#> [1] 2
#> 
sum_item <- measure_monoid(`+`, 0, function(entry) as.numeric(entry$value))
q3 <- add_monoids(priority_queue(1, 2, priorities = c(2, 1)), list(sum_item = sum_item))
print(q3, max_elements = 0, show_custom_monoids = TRUE)
#> Unnamed priority_queue with 2 elements.
#> Minimum priority: 1, Maximum priority: 2
#> Custom monoids + measures:
#>   sum_item: 3

q2 <- priority_queue(1, 2, 3, priorities = c(2, 1, 3))
print(q2, max_elements = 3)
#> Unnamed priority_queue with 3 elements.
#> Minimum priority: 1, Maximum priority: 3
#> 
#> Elements (by priority):
#> 
#> (priority 1)
#> [1] 2
#> 
#> (priority 2)
#> [1] 1
#> 
#> (priority 3)
#> [1] 3
#> 

print(priority_queue())
#> Unnamed priority_queue with 0 elements.
```
