# Insert an Element

Inserts an element into a structure-specific position according to class
semantics.

## Usage

``` r
insert(x, ...)
```

## Arguments

- x:

  Object to insert into.

- ...:

  Method-specific arguments.

## Value

Updated object of the same class as `x`.

## Details

`insert()` is an S3 generic. Required arguments in `...` depend on `x`:

- `priority_queue`: `element`, `priority` (optional `name`)

- `ordered_sequence`: `element`, `key` (optional `name`)

- `interval_index`: `element`, `start`, `end` (optional `name`)

This operation is persistent: `x` is not modified.

## See also

[`priority_queue()`](https://oneilsh.github.io/immutables/reference/priority_queue.md),
[`ordered_sequence()`](https://oneilsh.github.io/immutables/reference/ordered_sequence.md),
[`interval_index()`](https://oneilsh.github.io/immutables/reference/interval_index.md),
[`insert_at()`](https://oneilsh.github.io/immutables/reference/insert_at.md)

## Examples

``` r
q <- priority_queue("a", "b", priorities = c(2, 1))
insert(q, "c", priority = 3)
#> Unnamed priority_queue with 3 elements.
#> Minimum priority: 1, Maximum priority: 3
#> 
#> Elements (by priority):
#> 
#> (priority 1)
#> [1] "b"
#> 
#> (priority 2)
#> [1] "a"
#> 
#> (priority 3)
#> [1] "c"
#> 

o <- ordered_sequence("a", "c", keys = c(1, 3))
insert(o, "b", key = 2)
#> Unnamed ordered_sequence with 3 elements.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key 1)
#> [1] "a"
#> 
#> [[2]] (key 2)
#> [1] "b"
#> 
#> [[3]] (key 3)
#> [1] "c"
#> 

iv <- interval_index("A", "B", starts = c(1, 5), ends = c(3, 8))
#> Error in .ivx_build_from_items(as.list(x), start = start, end = end, bounds = bounds,     monoids = monoids): `start` is required when elements are supplied.
insert(iv, "C", start = 2, end = 6)
#> Error: object 'iv' not found
```
