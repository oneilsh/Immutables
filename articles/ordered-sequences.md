# Ordered Sequences

## What is an ordered sequence?

`ordered_sequence` stores elements sorted by key, with stable FIFO
behavior for duplicate keys.

``` r
xs <- ordered_sequence("a1", "b1", "b2", "c1", keys = c(1, 2, 2, 3))
xs
#> Unnamed ordered_sequence with 4 elements.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key 1)
#> [1] "a1"
#> 
#> [[2]] (key 2)
#> [1] "b1"
#> 
#> [[3]] (key 2)
#> [1] "b2"
#> 
#> [[4]] (key 3)
#> [1] "c1"
```

`as_flexseq(xs)` returns a payload-only `flexseq` by default. Use
`as_flexseq(xs, drop_meta = FALSE)` to keep entry records (`value`,
`key`).

## Key-based lookup

``` r
peek_key(xs, 2)
#> [1] "b1"
as.list(peek_all_key(xs, 2))
#> [[1]]
#> [1] "b1"
#> 
#> [[2]]
#> [1] "b2"
count_key(xs, 2)
#> [1] 2
```

## Key boundaries

[`lower_bound()`](https://oneilsh.github.io/immutables/reference/lower_bound.md)
gives first `>= key`, and
[`upper_bound()`](https://oneilsh.github.io/immutables/reference/upper_bound.md)
gives first `> key`.

``` r
lower_bound(xs, 2)
#> $found
#> [1] TRUE
#> 
#> $index
#> [1] 2
#> 
#> $value
#> [1] "b1"
#> 
#> $key
#> [1] 2
upper_bound(xs, 2)
#> $found
#> [1] TRUE
#> 
#> $index
#> [1] 4
#> 
#> $value
#> [1] "c1"
#> 
#> $key
#> [1] 3
```

## Key range queries

``` r
elements_between(xs, 2, 3)
#> [[1]]
#> [1] "b1"
#> 
#> [[2]]
#> [1] "b2"
#> 
#> [[3]]
#> [1] "c1"
count_between(xs, 2, 3)
#> [1] 3
count_between(xs, 2, 3, include_to = FALSE)
#> [1] 2
```

## Pop by key

``` r
one <- pop_key(xs, 2)
one$value
#> [1] "b1"
one$key
#> [1] 2
one$remaining
#> Unnamed ordered_sequence with 3 elements.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key 1)
#> [1] "a1"
#> 
#> [[2]] (key 2)
#> [1] "b2"
#> 
#> [[3]] (key 3)
#> [1] "c1"

all_two <- pop_all_key(xs, 2)
as.list(all_two$values)
#> list()
all_two$remaining
#> Unnamed ordered_sequence with 2 elements.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key 1)
#> [1] "a1"
#> 
#> [[2]] (key 3)
#> [1] "c1"
```

## Insert

``` r
xs2 <- insert(xs, "a2", key = 1)
xs2
#> Unnamed ordered_sequence with 5 elements.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key 1)
#> [1] "a1"
#> 
#> [[2]] (key 1)
#> [1] "a2"
#> 
#> ... (skipping 1 element)
#> 
#> [[4]] (key 2)
#> [1] "b2"
#> 
#> [[5]] (key 3)
#> [1] "c1"
```
