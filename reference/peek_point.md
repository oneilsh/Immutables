# Peek First Interval Matching a Point

Peek First Interval Matching a Point

## Usage

``` r
peek_point(
  x,
  point,
  bounds = NULL,
  match_at = c("interval", "start", "end", "either")
)
```

## Arguments

- x:

  An `interval_index`.

- point:

  Query point.

- bounds:

  Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
  Ignored when `match_at` is not `"interval"`.

- match_at:

  How the query point is matched against each entry. One of `"interval"`
  (default; entry interval contains `point`, under `bounds`), `"start"`
  (entry's start coordinate equals `point`), `"end"` (entry's end equals
  `point`), or `"either"` (start or end equals `point`). The three
  coordinate-equality modes are structural and ignore `bounds`.

## Value

The payload value from the first match, or `NULL` on no match.

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
edge <- interval_index("a", start = 1, end = 3, default_query_bounds = "[)")
peek_point(edge, 3)                # default "[)": no match at right endpoint
#> NULL
peek_point(edge, 3, bounds = "[]") # closed bounds: endpoint matches
#> [1] "a"

# Coordinate-equality modes (bounds irrelevant)
peek_point(ix, 2, match_at = "start")  # entry starting at 2
#> [1] "b"
peek_point(ix, 3, match_at = "end")    # entry ending at 3
#> [1] "a"
```
