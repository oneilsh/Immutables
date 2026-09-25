# Deprecated functions in Immutables

These functions still work but emit a deprecation warning and will be
removed in a future release. Use the replacements instead:

## Usage

``` r
peek_overlaps(x, start, end, bounds = NULL)

peek_all_overlaps(x, start, end, bounds = NULL, as_list = FALSE)

pop_overlaps(x, start, end, bounds = NULL)

pop_all_overlaps(x, start, end, bounds = NULL)
```

## Arguments

- x:

  An `interval_index`.

- start:

  Query interval start.

- end:

  Query interval end.

- bounds:

  Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.

- as_list:

  Passed to
  [`peek_all_overlapping()`](https://oneilsh.github.io/Immutables/reference/peek_all_overlapping.md).

## Value

The same value as the replacement function.

## Details

- `peek_overlaps()`: use
  [`peek_overlapping()`](https://oneilsh.github.io/Immutables/reference/peek_overlapping.md).

- `peek_all_overlaps()`: use
  [`peek_all_overlapping()`](https://oneilsh.github.io/Immutables/reference/peek_all_overlapping.md).

- `pop_overlaps()`: use
  [`pop_overlapping()`](https://oneilsh.github.io/Immutables/reference/pop_overlapping.md).

- `pop_all_overlaps()`: use
  [`pop_all_overlapping()`](https://oneilsh.github.io/Immutables/reference/pop_all_overlapping.md).

The `*_overlaps` names were renamed in version 1.2.0 so that the
single-match functions read as singular, matching
[`peek_containing()`](https://oneilsh.github.io/Immutables/reference/peek_containing.md)
and
[`peek_within()`](https://oneilsh.github.io/Immutables/reference/peek_within.md).
