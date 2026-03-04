# Count Elements in a Key Range

Count Elements in a Key Range

## Usage

``` r
count_between(x, from_key, to_key, include_from = TRUE, include_to = TRUE)
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

Integer count of matches.

## Details

Uses the same range semantics as
[`elements_between()`](https://oneilsh.github.io/immutables/reference/elements_between.md)
but returns only the count:

- `include_from = TRUE` uses `key >= from_key`; otherwise
  `key > from_key`.

- `include_to = TRUE` uses `key <= to_key`; otherwise `key < to_key`.

## Examples

``` r
x <- ordered_sequence("a", "b", "c", "d", keys = c(1, 2, 2, 3))
count_between(x, 2, 3)
#> [1] 3
count_between(x, 2, 2, include_to = FALSE)
#> [1] 0
```
