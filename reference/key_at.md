# Key at a Position

Returns the key of the element at a one-based position, without removing
it. This is the positional companion to
[`peek_at()`](https://oneilsh.github.io/Immutables/reference/peek_at.md)
(which returns the value at a position) and the general form of
[`min_key()`](https://oneilsh.github.io/Immutables/reference/min_key.md)
(`key_at(x, 1)`) and
[`max_key()`](https://oneilsh.github.io/Immutables/reference/max_key.md)
(`key_at(x, length(x))`).

## Usage

``` r
key_at(x, index)
```

## Arguments

- x:

  An `ordered_sequence`.

- index:

  One-based position to read.

## Value

The key at `index`, or `NULL` when `index` is out of bounds.

## Details

Positive integer indices beyond `length(x)` return `NULL`. Invalid
indices (`NA`, non-integer, `<= 0`, or length not equal to 1) error.
Pair with
[`peek_at()`](https://oneilsh.github.io/Immutables/reference/peek_at.md)
to read the value at the same position, or use
[`pop_at()`](https://oneilsh.github.io/Immutables/reference/pop_at.md)
when you also want the remaining sequence.

## See also

[`peek_at()`](https://oneilsh.github.io/Immutables/reference/peek_at.md),
[`min_key()`](https://oneilsh.github.io/Immutables/reference/min_key.md),
[`max_key()`](https://oneilsh.github.io/Immutables/reference/max_key.md),
[`nearest_key()`](https://oneilsh.github.io/Immutables/reference/nearest_key.md),
[`lower_bound()`](https://oneilsh.github.io/Immutables/reference/lower_bound.md),
[`pop_at()`](https://oneilsh.github.io/Immutables/reference/pop_at.md)

## Examples

``` r
x <- ordered_sequence("a", "b", "c", keys = c(10, 20, 30))
key_at(x, 2)
#> [1] 20
key_at(x, 10)
#> NULL
```
