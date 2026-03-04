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

Base R list of matched elements, in key order.

## Details

Range membership is controlled by `include_from` and `include_to`:

- `include_from = TRUE` uses `key >= from_key`; otherwise
  `key > from_key`.

- `include_to = TRUE` uses `key <= to_key`; otherwise `key < to_key`.

If no elements fall in the range, returns
[`list()`](https://rdrr.io/r/base/list.html).

## Examples

``` r
x <- ordered_sequence("a", "b", "c", "d", keys = c(1, 2, 2, 3))
elements_between(x, 2, 3)
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
#> list()
```
