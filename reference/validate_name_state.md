# Validate name-state invariants only (debug/test utility)

Checks that trees are either fully unnamed or fully named with unique,
non-empty names.

## Usage

``` r
validate_name_state(t)
```

## Arguments

- t:

  FingerTree.

## Value

`TRUE` invisibly; errors if name invariants are violated.

## Details

Intended for debugging and tests, not hot runtime paths.

## Examples

``` r
x <- as_flexseq(setNames(as.list(letters[1:4]), letters[1:4]))
validate_name_state(x)
```
