# Iterate over an iterator (re-exported from coro)

Re-exported
[`coro::loop()`](https://coro.r-lib.org/reference/collect.html). Enables
`for`-loop-style iteration over `immutables` structures without needing
to load `coro` separately.

## Usage

``` r
loop(loop)
```

## Arguments

- loop:

  A `for` loop expression.

## Value

`NULL`, invisibly. Called for side effects.

## See also

[`coro::loop()`](https://coro.r-lib.org/reference/collect.html) for full
documentation.

## Examples

``` r
s <- flexseq(1, 2, 3)
loop(for (x in s) print(x))
#> [1] 1
#> [1] 2
#> [1] 3
```
