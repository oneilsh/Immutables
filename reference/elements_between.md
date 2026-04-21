# Return Elements in a Key Range

Return Elements in a Key Range

## Usage

``` r
elements_between(x, from_key, to_key, include_from = TRUE, include_to = TRUE)
```

## Arguments

- x:

  An `ordered_sequence`.

- from_key:

  Lower bound key.

- to_key:

  Upper bound key.

- include_from:

  Include lower bound when `TRUE`.

- include_to:

  Include upper bound when `TRUE`.

## Value

An `ordered_sequence` of matched elements, in key order. Use
[`as.list()`](https://rdrr.io/r/base/list.html) to convert to a plain
list.

## Details

Range membership is controlled by `include_from` and `include_to`:

- `include_from = TRUE` uses `key >= from_key`; otherwise
  `key > from_key`.

- `include_to = TRUE` uses `key <= to_key`; otherwise `key < to_key`.

If no elements fall in the range, returns an empty `ordered_sequence`.

## Examples

``` r
x <- ordered_sequence("a", "b", "c", "d", keys = c(1, 2, 2, 3))
elements_between(x, 2, 3)
#> Unnamed ordered_sequence with 3 elements.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key 2)
#> [1] "b"
#> 
#> [[2]] (key 2)
#> [1] "c"
#> 
#> [[3]] (key 3)
#> [1] "d"
#> 
as.list(elements_between(x, 2, 3))
#> [[1]]
#> [1] "b"
#> 
#> [[2]]
#> [1] "c"
#> 
#> [[3]]
#> [1] "d"
#> 
elements_between(x, 2, 2, include_to = FALSE)
#> Unnamed ordered_sequence with 0 elements.
```
