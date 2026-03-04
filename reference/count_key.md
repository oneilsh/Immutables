# Count Elements Matching One Key

Count Elements Matching One Key

## Usage

``` r
count_key(x, key)
```

## Arguments

- x:

  An `ordered_sequence`.

- key:

  Query key.

## Value

Integer count of matches.

## Details

Counts multiplicity for a single key. Returns `0L` when the key is not
present.

## Examples

``` r
x <- ordered_sequence("a", "b", "c", keys = c(1, 2, 2))
count_key(x, 2)
#> [1] 2
count_key(x, 10)
#> [1] 0
```
