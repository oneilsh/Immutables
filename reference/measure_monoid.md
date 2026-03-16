# Construct a Measure Monoid Specification

Defines how element-level values are measured and combined as
accumulated tree metadata.

## Usage

``` r
measure_monoid(f, i, measure)
```

## Arguments

- f:

  Associative binary function over measure values.

- i:

  Identity value for `f`.

- measure:

  Function mapping one element to its measure value.

## Value

An object of class `measure_monoid`.

## Details

A measure monoid has three parts:

- `measure(entry)`: maps each stored leaf entry to a measure value.

- `f(left, right)`: combines two measure values.

- `i`: identity value for `f`.

Requirements:

- `f` should be associative.

- `i` should satisfy `f(i, x) == x` and `f(x, i) == x`.

- `measure()` outputs must be compatible with `f` and `i`.

Developer APIs are leaf-entry oriented:

- `flexseq`: entry is the stored user element.

- `ordered_sequence`: entry is `list(value, key)`.

- `priority_queue`: entry is `list(value, priority)`.

- `interval_index`: entry is `list(value, start, end)`.

`measure_monoid()` only constructs the specification; it becomes active
after being attached to a structure via
[`add_monoids()`](https://oneilsh.github.io/immutables/reference/add_monoids.md).

## Examples

``` r
sum_m <- measure_monoid(`+`, 0, as.numeric)
x <- as_flexseq(1:5)
x2 <- add_monoids(x, list(sum = sum_m))
attr(x2, "measures")$sum
#> [1] 15
split_around_by_predicate(x2, function(v) v >= 6, "sum")
#> $left
#> Unnamed flexseq with 2 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] 1
#> 
#> [[2]]
#> [1] 2
#> 
#> 
#> $value
#> [1] 3
#> 
#> $right
#> Unnamed flexseq with 2 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] 4
#> 
#> [[2]]
#> [1] 5
#> 
#> 

# Count elements
count_m <- measure_monoid(`+`, 0L, function(el) 1L)
x3 <- add_monoids(x, list(count = count_m))
attr(x3, "measures")$count
#> [1] 5

# Character-width accumulation
width_m <- measure_monoid(`+`, 0L, function(el) nchar(as.character(el)))
s <- as_flexseq(c("aa", "b", "cccc"))
s2 <- add_monoids(s, list(width = width_m))
attr(s2, "measures")$width
#> [1] 7
```
