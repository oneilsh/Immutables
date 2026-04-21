# Interval Indices

## Interval index basics

`interval_index` is a persistent structure that associates elements with
interval endpoints and supports fast interval-relation queries.
Intervals are stored sorted by start endpoint, with stable
first-in-first-out (FIFO) ordering for ties.

All operations are persistent, and return modified copies. Peeking
returns the stored element (which may be any type), popping returns a
list with `$value` containing the stored element, `$start` and `$end`
the interval endpoints, and `$remaining` the rest of the index without
that element.

``` r
ix <- interval_index(
  "A", "B", "C",
  start = c(1, 2, 4),
  end = c(3, 4, 5)
)
ix
#> Unnamed interval_index with 3 elements, default query bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval 1 - 3)
#> [1] "A"
#> 
#> [[2]] (interval 2 - 4)
#> [1] "B"
#> 
#> [[3]] (interval 4 - 5)
#> [1] "C"
```

The
[`as_interval_index()`](https://oneilsh.github.io/immutables/reference/as_interval_index.md)
variant builds an index from a vector or list of elements paired with
start/end vectors, useful when endpoints are already in separate
vectors.

``` r
ix2 <- as_interval_index(c("phase1", "phase2", "phase3"), start = c(1, 3, 2), end = c(4, 5, 6))
ix2
#> Unnamed interval_index with 3 elements, default query bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval 1 - 4)
#> [1] "phase1"
#> 
#> [[2]] (interval 2 - 6)
#> [1] "phase3"
#> 
#> [[3]] (interval 3 - 5)
#> [1] "phase2"
```

`as_flexseq(ix)` returns a payload-only `flexseq`; interval bounds and
any custom monoids are dropped (see `as.list` to convert and preserve
interval metadata).

## Point and interval queries

[`peek_point()`](https://oneilsh.github.io/immutables/reference/peek_point.md)
returns the *first* (in FIFO order) element whose interval contains a
query point;
[`peek_all_point()`](https://oneilsh.github.io/immutables/reference/peek_all_point.md)
returns all matches as an `interval_index` slice.

``` r
peek_point(ix, point = 2)
#> [1] "A"
peek_all_point(ix, point = 2)
#> Unnamed interval_index with 2 elements, default query bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval 1 - 3)
#> [1] "A"
#> 
#> [[2]] (interval 2 - 4)
#> [1] "B"
```

[`pop_point()`](https://oneilsh.github.io/immutables/reference/pop_point.md)
removes and returns the first match as
`$value`/`$start`/`$end`/`$remaining`. Its “all” counterpart
[`pop_all_point()`](https://oneilsh.github.io/immutables/reference/pop_all_point.md)
returns `$elements` (an interval_index of removed matches) and
`$remaining`.

``` r
res <- pop_point(ix, 2)
res$value
#> [1] "A"
res$start
#> [1] 1
res$end
#> [1] 3
res$remaining
#> Unnamed interval_index with 2 elements, default query bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval 2 - 4)
#> [1] "B"
#> 
#> [[2]] (interval 4 - 5)
#> [1] "C"
```

By default the four `*_point()` functions test interval containment. The
`match_at` parameter lets them match instead on coordinate equality at
the entry’s start, end, or either endpoint. This is useful for
sweep-line patterns where you need to identify intervals arriving or
retiring at a specific event point. `bounds` is ignored for these modes
(coordinate equality is structural).

``` r
# Entries whose start coordinate equals 2
peek_all_point(ix, point = 2, match_at = "start")
#> Unnamed interval_index with 1 element, default query bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval 2 - 4)
#> [1] "B"

# Entries whose end coordinate equals 3 — the sweep-line retirement query
peek_all_point(ix, point = 3, match_at = "end")
#> Unnamed interval_index with 1 element, default query bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval 1 - 3)
#> [1] "A"

# Either endpoint equals 3
peek_all_point(ix, point = 3, match_at = "either")
#> Unnamed interval_index with 1 element, default query bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval 1 - 3)
#> [1] "A"
```

Interval-vs-interval queries select overlaps of different kinds. First
we’ll build a new index to query:

``` r
ix3 <- interval_index(
  "narrow", "wide", "right", "inner",
  start = c(2, 1, 4, 3),
  end   = c(3, 6, 5, 4)
)
ix3
#> Unnamed interval_index with 4 elements, default query bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval 1 - 6)
#> [1] "wide"
#> 
#> [[2]] (interval 2 - 3)
#> [1] "narrow"
#> 
#> [[3]] (interval 3 - 4)
#> [1] "inner"
#> 
#> [[4]] (interval 4 - 5)
#> [1] "right"
```

[`peek_overlaps()`](https://oneilsh.github.io/immutables/reference/peek_overlaps.md)
returns any interval that shares at least one point with the query
range.
[`peek_containing()`](https://oneilsh.github.io/immutables/reference/peek_containing.md)
returns intervals that fully contain the query range.
[`peek_within()`](https://oneilsh.github.io/immutables/reference/peek_within.md)
returns intervals fully contained by the query range.

``` r
# overlaps [2, 5]: any shared point
peek_all_overlaps(ix3, start = 2, end = 5)
#> Unnamed interval_index with 4 elements, default query bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval 1 - 6)
#> [1] "wide"
#> 
#> [[2]] (interval 2 - 3)
#> [1] "narrow"
#> 
#> [[3]] (interval 3 - 4)
#> [1] "inner"
#> 
#> [[4]] (interval 4 - 5)
#> [1] "right"

# containing [3, 4]: index interval must enclose query
peek_all_containing(ix3, start = 3, end = 4)
#> Unnamed interval_index with 2 elements, default query bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval 1 - 6)
#> [1] "wide"
#> 
#> [[2]] (interval 3 - 4)
#> [1] "inner"

# within [1, 5]: index interval must fit inside query
peek_all_within(ix3, start = 1, end = 5)
#> Unnamed interval_index with 3 elements, default query bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval 2 - 3)
#> [1] "narrow"
#> 
#> [[2]] (interval 3 - 4)
#> [1] "inner"
#> 
#> [[3]] (interval 4 - 5)
#> [1] "right"
```

All relation queries have symmetric `pop_*` and `pop_all_*` variants
following the same return contract as
[`pop_point()`](https://oneilsh.github.io/immutables/reference/pop_point.md)
and
[`pop_all_point()`](https://oneilsh.github.io/immutables/reference/pop_all_point.md).

## Boundary modes

Endpoint inclusion is controlled by two related parameters. The
constructors take `default_query_bounds` — one of `"[)"` (default,
left-closed right-open), `"[]"` (closed), `"()"` (open), or `"(]"`
(left-open right-closed) — which sets the convention used when queries
on this index don’t specify their own. Query functions (`peek_*` /
`pop_*`) then accept a `bounds` override for the duration of a single
call.

``` r
edge <- interval_index("E", start = 1, end = 3, default_query_bounds = "[)")

# right endpoint excluded by default
peek_point(edge, 3)
#> NULL

# override to closed bounds for this query
peek_point(edge, 3, bounds = "[]")
#> [1] "E"
```

Note that bounds affect what counts as a valid interval: under `"[)"`,
an interval with `start == end` like \[2, 2) is empty and will never
match any query. Use `"[]"` if you need point intervals where
`start == end`.

``` r
# [2, 2) contains nothing under half-open bounds
pt_open <- interval_index("X", start = 2, end = 2, default_query_bounds = "[)")
peek_point(pt_open, point = 2)
#> NULL

# [2, 2] contains exactly the point 2
pt_closed <- interval_index("X", start = 2, end = 2, default_query_bounds = "[]")
peek_point(pt_closed, point = 2)
#> [1] "X"
```

## Insertion and endpoint extrema

[`insert()`](https://oneilsh.github.io/immutables/reference/insert.md)
adds an element preserving interval start order.

``` r
ix4 <- insert(ix, "D", start = 2, end = 6)
ix4
#> Unnamed interval_index with 4 elements, default query bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval 1 - 3)
#> [1] "A"
#> 
#> [[2]] (interval 2 - 4)
#> [1] "B"
#> 
#> [[3]] (interval 2 - 6)
#> [1] "D"
#> 
#> [[4]] (interval 4 - 5)
#> [1] "C"
```

[`min_endpoint()`](https://oneilsh.github.io/immutables/reference/min_endpoint.md)
and
[`max_endpoint()`](https://oneilsh.github.io/immutables/reference/max_endpoint.md)
return the current smallest start and largest end endpoints (not the
stored elements).

``` r
min_endpoint(ix)
#> [1] 1
max_endpoint(ix)
#> [1] 5
min_endpoint(interval_index())
#> NULL
```

## Empty indices

Query and endpoint helpers are non-throwing on empty indices, and
[`length()`](https://rdrr.io/r/base/length.html) allows for empty
checking.

``` r
empty_ix <- interval_index()
length(empty_ix)
#> [1] 0
peek_point(empty_ix, point = 1)
#> NULL
pop_overlaps(empty_ix, start = 1, end = 5)
#> $value
#> NULL
#> 
#> $start
#> NULL
#> 
#> $end
#> NULL
#> 
#> $remaining
#> Unnamed interval_index with 0 elements, default query bounds [start, end).
```

## Named interval indices

Interval indices can carry names, set either at construction or through
[`as_interval_index()`](https://oneilsh.github.io/immutables/reference/as_interval_index.md)
on a named list. Names support read-only indexing via `[`, `[[`, and
`$`; all replacement forms (`[<-`, `[[<-`, `$<-`) error, because
index-based assignment may break the ordering invariant. Named and
unnamed elements cannot be mixed within one index.

``` r
ix_named <- as_interval_index(
  setNames(list("alice", "bob", "carol"), c("a", "b", "c")),
  start = c(1, 3, 2),
  end = c(4, 5, 6)
)
ix_named
#> Named interval_index with 3 elements, default query bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> $a (interval 1 - 4)
#> [1] "alice"
#> 
#> $c (interval 2 - 6)
#> [1] "carol"
#> 
#> $b (interval 3 - 5)
#> [1] "bob"

ix_named[["b"]]
#> [1] "bob"
ix_named[c("a", "c")]
#> Named interval_index with 2 elements, default query bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> $a (interval 1 - 4)
#> [1] "alice"
#> 
#> $c (interval 2 - 6)
#> [1] "carol"
ix_named[1]
#> Named interval_index with 1 element, default query bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> $a (interval 1 - 4)
#> [1] "alice"

try(ix_named$a <- "!!")
#> Error in `$<-.interval_index`(`*tmp*`, a, value = "!!") : 
#>   `$<-` is not supported for interval_index.
```

## Transforming, iterating, merging

[`fapply()`](https://oneilsh.github.io/immutables/reference/fapply.md)
maps a function over elements while preserving intervals and order. The
function receives `(value, start, end)`, or `(value, start, end, name)`
if it accepts a fourth argument. Endpoints and names are passed in
read-only, and the return value replaces the stored element (similar to
[`lapply()`](https://rdrr.io/r/base/lapply.html) for named R lists).

``` r
fapply(ix, function(value, start, end) paste0(value, "[", start, ",", end, "]"))
#> Unnamed interval_index with 3 elements, default query bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval 1 - 3)
#> [1] "A[1,3]"
#> 
#> [[2]] (interval 2 - 4)
#> [1] "B[2,4]"
#> 
#> [[3]] (interval 4 - 5)
#> [1] "C[4,5]"
```

[`loop()`](https://oneilsh.github.io/immutables/reference/loop.md)
(re-exported from the **coro** package) walks the index in interval
start-position order, yielding bare values. Interval endpoints are
dropped from each yield; use
[`fapply()`](https://oneilsh.github.io/immutables/reference/fapply.md)
if your callback needs `(value, start, end)`.

``` r
loop(for (v in ix) print(v))
#> [1] "A"
#> [1] "B"
#> [1] "C"
```

Plain `for (v in ix)` (without
[`loop()`](https://oneilsh.github.io/immutables/reference/loop.md)) does
*not* dispatch to the iteration protocol, it walks the underlying
structure and yields internal nodes rather than elements. Always wrap
with [`loop()`](https://oneilsh.github.io/immutables/reference/loop.md).

`merge(x, y)` combines two interval indices into a new one in
start-position order, preserving left-biased FIFO on tied starts. The
general case runs in O(m + n); disjoint start ranges collapse to
O(log(min(m, n))) via concat. The reserved `.ivx_min_end` /
`.ivx_max_end` monoids recompute automatically, so interval-relation
queries work immediately on the result.

``` r
a <- as_interval_index(c("A1", "A2"), start = c(1, 5), end = c(4, 8))
b <- as_interval_index(c("B1", "B2"), start = c(3, 7), end = c(6, 10))
m <- merge(a, b)
peek_all_point(m, 3)
#> Unnamed interval_index with 2 elements, default query bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval 1 - 4)
#> [1] "A1"
#> 
#> [[2]] (interval 3 - 6)
#> [1] "B1"
```

Both indices must share the same endpoint type, the same `bounds`
convention, and the same monoid set; mismatches error. Both inputs are
left unmodified.
