# Build a Structural Tree from a Vector or List

Build a Structural Tree from a Vector or List

## Usage

``` r
tree_from(x, monoids = NULL)
```

## Arguments

- x:

  Elements to insert.

- monoids:

  Optional named list of `measure_monoid` objects.

## Value

A finger tree with cached measures for all monoids. If `x` has names,
they are used for name-based indexing and must be complete (no
missing/empty names) and unique.
