# Nearest Key to a Query

Returns the existing key closest to `query`. Generalizes
[`min_key()`](https://oneilsh.github.io/Immutables/reference/min_key.md)
and
[`max_key()`](https://oneilsh.github.io/Immutables/reference/max_key.md):
it resolves by order alone at the extremes and on an exact hit, and only
needs a distance metric when `query` falls strictly between two distinct
keys.

## Usage

``` r
nearest_key(x, query, ties = c("lower", "upper", "both"))
```

## Arguments

- x:

  An `ordered_sequence`.

- query:

  Query key.

- ties:

  How to resolve an equidistant tie between the two distinct
  neighbouring keys (the only case a tie can arise): `"lower"` (default)
  returns the lower key, `"upper"` the higher key, and `"both"` returns
  both as a length-2 vector.

## Value

The nearest key, or `NULL` when `x` is empty. A length-1 key except with
`ties = "both"` on an exact tie, which returns both equidistant keys.
Feed the result to
[`peek_key()`](https://oneilsh.github.io/Immutables/reference/peek_key.md)
/
[`pop_key()`](https://oneilsh.github.io/Immutables/reference/pop_key.md)
to read or remove the matching element.

## Details

Resolution:

- Exact match, or `query` below/above every key: decided by order alone,
  so it works for every key type (including `character`).

- `query` strictly between two distinct keys: returns the closer of the
  two by `abs(query - key)`, with an equidistant tie resolved by `ties`.
  This case needs a numeric difference, so it supports `numeric`,
  `Date`, and `POSIXct` keys; for `character` (and other
  non-subtractable orderable keys) it errors, because "closer" is
  undefined – use
  [`lower_bound()`](https://oneilsh.github.io/Immutables/reference/lower_bound.md)
  /
  [`peek_key()`](https://oneilsh.github.io/Immutables/reference/peek_key.md)
  for order-based lookup instead.

Duplicate keys are not disambiguated here: the return is a key value,
and
[`peek_key()`](https://oneilsh.github.io/Immutables/reference/peek_key.md)
/
[`pop_key()`](https://oneilsh.github.io/Immutables/reference/pop_key.md)
select the FIFO-first element for that key.

## See also

[`lower_bound()`](https://oneilsh.github.io/Immutables/reference/lower_bound.md),
[`peek_key()`](https://oneilsh.github.io/Immutables/reference/peek_key.md),
[`min_key()`](https://oneilsh.github.io/Immutables/reference/min_key.md),
[`max_key()`](https://oneilsh.github.io/Immutables/reference/max_key.md),
[`key_at()`](https://oneilsh.github.io/Immutables/reference/key_at.md)

## Examples

``` r
x <- ordered_sequence("a", "b", "c", "d", keys = c(1, 2, 4, 8))
nearest_key(x, 3)                 # 2 and 4 are equidistant -> lower key (2)
#> [1] 2
nearest_key(x, 3, ties = "upper") # 4
#> [1] 4
nearest_key(x, 3, ties = "both")  # c(2, 4)
#> [1] 2 4
nearest_key(x, 5)                 # 4
#> [1] 4
nearest_key(x, 100)               # 8 (above all)
#> [1] 8
nearest_key(ordered_sequence())   # NULL
#> NULL
```
