# Concatenate Two Structural Trees

Same-name monoids are assumed equivalent; left-tree definitions win.
Missing monoids are added to each side before concatenation.

## Usage

``` r
concat_trees(x, y)
```

## Arguments

- x:

  A `flexseq` (left side).

- y:

  A `flexseq` (right side).

## Value

Concatenated tree.

## Examples

``` r
if (FALSE) { # \dontrun{
left <- as_flexseq(letters[1:3])
right <- as_flexseq(letters[4:6])
t <- concat_trees(left, right)
as.list(t)
} # }
```
