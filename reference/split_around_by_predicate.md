# Split Around First Predicate Match

Splits at the first point where a `predicate` function becomes `TRUE`
while scanning the sequence.

## Usage

``` r
split_around_by_predicate(t, predicate, monoid_name, accumulator = NULL)
```

## Arguments

- t:

  A `flexseq` (or subclass).

- predicate:

  Function applied to accumulated monoid values.

- monoid_name:

  Name of the monoid used for scanning.

- accumulator:

  Optional starting accumulator value.

## Value

A list with fields:

- `left`: elements before the split point.

- `value`: the matched element at the split point.

- `right`: elements after the split point.

## Details

This function generally requires the sequence be annotated with a
[`measure_monoid()`](https://oneilsh.github.io/immutables/reference/measure_monoid.md);
see the examples and
[`measure_monoid()`](https://oneilsh.github.io/immutables/reference/measure_monoid.md)
for more information.

`value` is the matched leaf entry for the input structure:

- `flexseq`: stored user element.

- `ordered_sequence`: `list(value, key)`.

- `priority_queue`: `list(value, priority)`.

- `interval_index`: `list(value, start, end)`.

`left` and `right` preserve subclass when the input is a subclass of
`flexseq`.

## Examples

``` r
x <- flexseq("a", "b", "c", "d")

# Each element e has measure 1; the accumulated measure for
# a set of elements is computed by the associative function `+`
# along with the identity value 0.
size_monoid <- measure_monoid(`+`, 0L, function(e) 1L)
x2 <- add_monoids(x, list(size = size_monoid))

# the first time the measure stored in the size monoid
# accumulates to greater than or equal to 3 is the 3rd
# element in sequence.
split_around_by_predicate(x2, function(v) v >= 3L, "size")
#> $left
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
#> 
#> $value
#> [1] "c"
#> 
#> $right
#> Unnamed flexseq with 1 element.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "d"
#> 
#> 

# Split at the first element
split_around_by_predicate(x2, function(v) v >= 1L, "size")
#> $left
#> Unnamed flexseq with 0 elements.
#> 
#> $value
#> [1] "a"
#> 
#> $right
#> Unnamed flexseq with 3 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "b"
#> 
#> [[2]]
#> [1] "c"
#> 
#> [[3]]
#> [1] "d"
#> 
#> 

# Split at the last element
split_around_by_predicate(x2, function(v) v >= 4L, "size")
#> $left
#> Unnamed flexseq with 3 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "a"
#> 
#> [[2]]
#> [1] "b"
#> 
#> [[3]]
#> [1] "c"
#> 
#> 
#> $value
#> [1] "d"
#> 
#> $right
#> Unnamed flexseq with 0 elements.
#> 
```
