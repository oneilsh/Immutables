# Validate full tree invariants (debug/test utility)

Performs expensive full-tree auditing of:

- structural attributes (`monoids`/`measures`) consistency

- global name-state invariants

## Usage

``` r
validate_tree(t)
```

## Arguments

- t:

  FingerTree.

## Value

`TRUE` invisibly; errors if invariant violations are found.

## Details

Intended for debugging and tests, not hot runtime paths.

## Examples

``` r
x <- as_flexseq(letters[1:10])
validate_tree(x)
```
