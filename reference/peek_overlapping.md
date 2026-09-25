# Peek First Interval Overlapping a Query Interval

Peek First Interval Overlapping a Query Interval

## Usage

``` r
peek_overlapping(x, start, end, bounds = NULL)
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
[`peek_all_overlapping()`](https://oneilsh.github.io/Immutables/reference/peek_all_overlapping.md)
to retrieve all matches as an `interval_index` slice.

## Examples

``` r
ix <- interval_index("a", "b", "c", start = c(1, 3, 5), end = c(2, 4, 6))
peek_overlapping(ix, 2, 3)
#> NULL

# Boundary override at touching endpoints
edge <- interval_index("a", start = 1, end = 3, default_query_bounds = "[)")
peek_overlapping(edge, 3, 4)                # default "[)": no endpoint overlap
#> NULL
peek_overlapping(edge, 3, 4, bounds = "[]") # closed bounds: endpoint overlaps
#> [1] "a"
```
