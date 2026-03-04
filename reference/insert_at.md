# Insert Elements at a Position

Inserts `values` before the current element at `index`.

## Usage

``` r
insert_at(x, index, values)
```

## Arguments

- x:

  A `flexseq`.

- index:

  One-based insertion position in `[1, length(x) + 1]`.

- values:

  Values to insert.

## Value

Updated sequence with inserted values.

## Details

`values` is interpreted as a collection of elements to splice in.

Common cases:

- Atomic vector (`c("x", "y")`): inserts one element per vector entry.

- List (`list("x", "y")`): inserts one element per list entry.

- `flexseq`: inserts all of its elements.

- Empty input ([`list()`](https://rdrr.io/r/base/list.html) or
  [`flexseq()`](https://oneilsh.github.io/immutables/reference/flexseq.md)):
  no change.

To insert one composite object (for example, a vector or a list) as a
single element, wrap it in `list(...)`.

This operation is persistent: `x` is not modified.

## Examples

``` r
x <- flexseq("a", "b", "c", "d")
insert_at(x, 3, c("x", "y"))
#> Unnamed flexseq with 6 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "a"
#> 
#> [[2]]
#> [1] "b"
#> 
#> ... (skipping 2 elements)
#> 
#> [[5]]
#> [1] "c"
#> 
#> [[6]]
#> [1] "d"
#> 
insert_at(x, 1, "start")
#> Unnamed flexseq with 5 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "start"
#> 
#> [[2]]
#> [1] "a"
#> 
#> ... (skipping 1 element)
#> 
#> [[4]]
#> [1] "c"
#> 
#> [[5]]
#> [1] "d"
#> 
insert_at(x, length(x) + 1, "end")
#> Unnamed flexseq with 5 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "a"
#> 
#> [[2]]
#> [1] "b"
#> 
#> ... (skipping 1 element)
#> 
#> [[4]]
#> [1] "d"
#> 
#> [[5]]
#> [1] "end"
#> 

# Insert one vector as a single element
insert_at(x, 3, list(c("u", "v")))
#> Unnamed flexseq with 5 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "a"
#> 
#> [[2]]
#> [1] "b"
#> 
#> ... (skipping 1 element)
#> 
#> [[4]]
#> [1] "c"
#> 
#> [[5]]
#> [1] "d"
#> 
```
