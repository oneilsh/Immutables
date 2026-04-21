# Pop All Intervals Matching a Point

Pop All Intervals Matching a Point

## Usage

``` r
pop_all_point(
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
  (default; containment under `bounds`), `"start"`, `"end"`, or
  `"either"`. See
  [`peek_point()`](https://oneilsh.github.io/immutables/reference/peek_point.md)
  for details. The `"end"` mode is the standard primitive for retiring
  active intervals in a sweep-line.

## Value

A list with `elements` and `remaining`, both `interval_index` objects.

## Details

Use [`as.list()`](https://rdrr.io/r/base/list.html) to convert
`elements` to a standard R list.

## Examples

``` r
ix <- interval_index("a", "b", "c", start = c(1, 2, 4), end = c(3, 2, 5))
out <- pop_all_point(ix, 2)
as.list(out$elements)
#> [[1]]
#> [1] "a"
#> 

# Sweep-line retirement: remove everything ending at x = 3
retired <- pop_all_point(ix, 3, match_at = "end")
as.list(retired$elements)
#> [[1]]
#> [1] "a"
#> 
as.list(retired$remaining)
#> [[1]]
#> [1] "b"
#> 
#> [[2]]
#> [1] "c"
#> 
```
