# Coerce Objects to `flexseq`

`as_flexseq()` is the canonical way to obtain a plain `flexseq` for full
sequence-style operations.

## Usage

``` r
as_flexseq(x, drop_meta = TRUE)
```

## Arguments

- x:

  Input object.

- drop_meta:

  Logical scalar controlling advanced-structure cast style. For
  `priority_queue`, `ordered_sequence`, and `interval_index`:

  - `TRUE` (default): return payload-only elements and drop custom
    monoids.

  - `FALSE`: return full stored entry records (for example `value` +
    metadata) and preserve cast-down custom monoids.

## Value

A plain `flexseq`.

## Details

For base vectors/lists, this builds a new `flexseq` preserving element
order and names.

For specialized immutable subclasses (`priority_queue`,
`ordered_sequence`, `interval_index`), this intentionally drops subclass
semantics and returns a plain `flexseq`.

This is an S3 generic. Notable method behavior:

- `as_flexseq.flexseq(x, drop_meta=...)` returns `x` unchanged.

- `as_flexseq.priority_queue(x, drop_meta=TRUE)` returns payload items;
  `drop_meta=FALSE` returns `list(value, priority)` entries.

- `as_flexseq.ordered_sequence(x, drop_meta=TRUE)` returns payload
  items; `drop_meta=FALSE` returns `list(value, key)` entries.

- `as_flexseq.interval_index(x, drop_meta=TRUE)` returns payload items;
  `drop_meta=FALSE` returns interval entry records.

For advanced types with `drop_meta = TRUE`, custom monoids are dropped
and the rebuilt `flexseq` keeps only structural monoids (`.size`,
`.named_count`).

## See also

[`flexseq()`](https://oneilsh.github.io/immutables/reference/flexseq.md),
[`priority_queue()`](https://oneilsh.github.io/immutables/reference/priority_queue.md),
[`ordered_sequence()`](https://oneilsh.github.io/immutables/reference/ordered_sequence.md),
[`interval_index()`](https://oneilsh.github.io/immutables/reference/interval_index.md)

## Examples

``` r
x <- as_flexseq(1:3)
x
#> Unnamed flexseq with 3 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] 1
#> 
#> [[2]]
#> [1] 2
#> 
#> [[3]]
#> [1] 3
#> 

q <- priority_queue("a", "b", priorities = c(2, 1))
as_flexseq(q)
#> Unnamed flexseq with 2 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "a"
#> 
#> [[2]]
#> [1] "b"
#> 
as_flexseq(q, drop_meta = FALSE)
#> Unnamed flexseq with 2 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> $value
#> [1] "a"
#> 
#> $priority
#> [1] 2
#> 
#> 
#> [[2]]
#> $value
#> [1] "b"
#> 
#> $priority
#> [1] 1
#> 
#> 

o <- ordered_sequence("a", "b", keys = c(2, 1))
as_flexseq(o)
#> Unnamed flexseq with 2 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "b"
#> 
#> [[2]]
#> [1] "a"
#> 
as_flexseq(o, drop_meta = FALSE)
#> Unnamed flexseq with 2 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> $value
#> [1] "b"
#> 
#> $key
#> [1] 1
#> 
#> 
#> [[2]]
#> $value
#> [1] "a"
#> 
#> $key
#> [1] 2
#> 
#> 
```
