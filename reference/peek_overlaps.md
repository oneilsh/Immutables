# Peek First Interval Overlapping a Query Interval

Peek First Interval Overlapping a Query Interval

## Usage

``` r
peek_overlaps(x, start, end, bounds = NULL)
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
[`peek_all_overlaps()`](https://oneilsh.github.io/immutables/reference/peek_all_overlaps.md)
to retrieve all matches as an `interval_index` slice.

## Examples

``` r
ix <- interval_index("a", "b", "c", start = c(1, 3, 5), end = c(2, 4, 6))
peek_overlaps(ix, 2, 3)
#> NULL

# Boundary override at touching endpoints
edge <- interval_index("a", start = 1, end = 3, bounds = "[)")
peek_overlaps(edge, 3, 4)                # default "[)": no endpoint overlap
#> NULL
peek_overlaps(edge, 3, 4, bounds = "[]") # closed bounds: endpoint overlaps
#> [1] "a"
```
