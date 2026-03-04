# Peek First Interval Containing a Point

Peek First Interval Containing a Point

## Usage

``` r
peek_point(x, point, bounds = NULL)
```

## Arguments

- x:

  An `interval_index`.

- point:

  Query point.

- bounds:

  Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.

## Value

The payload item from the first match, or `NULL` on no match.

## Details

Returns the first match in canonical interval order. Use
[`peek_all_point()`](https://oneilsh.github.io/immutables/reference/peek_all_point.md)
to retrieve all matches as an `interval_index` slice.

## Examples

``` r
ix <- interval_index("a", "b", "c", start = c(1, 2, 4), end = c(3, 2, 5))
peek_point(ix, 2)
#> [1] "a"

# Boundary override at an endpoint
edge <- interval_index("a", start = 1, end = 3, bounds = "[)")
peek_point(edge, 3)                # default "[)": no match at right endpoint
#> NULL
peek_point(edge, 3, bounds = "[]") # closed bounds: endpoint matches
#> [1] "a"
```
