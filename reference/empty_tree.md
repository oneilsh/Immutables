# Create an Empty Structural Tree

Create an Empty Structural Tree

## Usage

``` r
empty_tree(monoids = NULL)
```

## Arguments

- monoids:

  Optional named list of `measure_monoid` objects.

## Value

An empty finger tree with structural `monoids` and `measures` attrs.

## Examples

``` r
if (FALSE) { # \dontrun{
t <- empty_tree()
t

count_m <- measure_monoid(`+`, 0, function(el) 1)
t2 <- empty_tree(monoids = list(count = count_m))
attr(t2, "measures")
} # }
```
