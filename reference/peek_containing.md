# Peek First Interval Containing a Query Interval

Peek First Interval Containing a Query Interval

## Usage

``` r
peek_containing(x, start, end, bounds = NULL)
```

## Arguments

- x:

  An `interval_index`.

- start:

  Query interval start.

- end:

  Query interval end.

- bounds:

  Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.

## Value

The payload value from the first match, or `NULL` on no match.

## Details

Returns the first match in canonical interval order. Use
[`peek_all_containing()`](https://oneilsh.github.io/immutables/reference/peek_all_containing.md)
to retrieve all matches as an `interval_index` slice.

## Examples

``` r
ix <- interval_index("a", "b", "c", start = c(1, 2, 4), end = c(5, 3, 6))
peek_containing(ix, 2, 3)
#> [1] "a"
```
