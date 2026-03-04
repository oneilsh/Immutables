# Peek First Interval Within a Query Interval

Peek First Interval Within a Query Interval

## Usage

``` r
peek_within(x, start, end, bounds = NULL)
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

The payload item from the first match, or `NULL` on no match.

## Details

Returns the first match in canonical interval order. Use
[`peek_all_within()`](https://oneilsh.github.io/immutables/reference/peek_all_within.md)
to retrieve all matches as an `interval_index` slice.

## Examples

``` r
ix <- interval_index("a", "b", "c", start = c(1, 2, 4), end = c(6, 3, 5))
peek_within(ix, 1, 4)
#> [1] "b"
```
