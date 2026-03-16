# Interval Indices

## What is an interval index?

`interval_index` stores elements with interval endpoints and supports
immutable relation queries.

``` r
ix <- interval_index(
  "A", "B", "C",
  start = c(1, 2, 4),
  end = c(3, 2, 5)
)
ix
#> Unnamed interval_index with 3 elements, default bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval [1, 3))
#> [1] "A"
#> 
#> [[2]] (interval [2, 2))
#> [1] "B"
#> 
#> [[3]] (interval [4, 5))
#> [1] "C"
```

`as_flexseq(ix)` returns payload-only values by default. Use
`as_flexseq(ix, drop_meta = FALSE)` to keep interval entry records.

## Point query

``` r
peek_point(ix, 2)
#> [1] "A"
as.list(peek_all_point(ix, 2))
#> [[1]]
#> [1] "A"
```

## Interval relations

``` r
peek_overlaps(ix, 2, 3)
#> [1] "A"
as.list(peek_all_overlaps(ix, 2, 3))
#> [[1]]
#> [1] "A"

peek_containing(ix, 2, 2)
#> [1] "A"
peek_within(ix, 1, 4)
#> [1] "A"
```

## Pop queries

``` r
p1 <- pop_point(ix, 2)
p1$value
#> [1] "A"
p1$start
#> [1] 1
p1$end
#> [1] 3
p1$remaining
#> Unnamed interval_index with 2 elements, default bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval [2, 2))
#> [1] "B"
#> 
#> [[2]] (interval [4, 5))
#> [1] "C"

p_all <- pop_all_overlaps(ix, 2, 3)
as.list(p_all$values)
#> list()
p_all$remaining
#> Unnamed interval_index with 2 elements, default bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval [2, 2))
#> [1] "B"
#> 
#> [[2]] (interval [4, 5))
#> [1] "C"
```

## Boundary modes

Use `bounds` to control endpoint inclusion (`"[)"`, `"[]"`, `"()"`,
`"(]"`).

``` r
edge <- interval_index("E", start = 1, end = 3, bounds = "[)")
peek_point(edge, 3)
#> NULL
peek_point(edge, 3, bounds = "[]")
#> [1] "E"
```

## Insert

``` r
ix2 <- insert(ix, "D", start = 2, end = 6)
ix2
#> Unnamed interval_index with 4 elements, default bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval [1, 3))
#> [1] "A"
#> 
#> [[2]] (interval [2, 2))
#> [1] "B"
#> 
#> [[3]] (interval [2, 6))
#> [1] "D"
#> 
#> [[4]] (interval [4, 5))
#> [1] "C"
```
