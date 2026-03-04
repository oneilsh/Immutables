# Plot a finger tree with igraph

Plot a finger tree with igraph

## Usage

``` r
plot_tree(
  t1,
  vertex.size = 4,
  edge.width = 1,
  label_edges = FALSE,
  title = NULL,
  node_label = c("value", "type", "both", "none"),
  ...
)
```

## Arguments

- t1:

  FingerTree.

- vertex.size:

  Vertex size passed to `igraph::plot.igraph`.

- edge.width:

  Edge width passed to `igraph::plot.igraph`.

- label_edges:

  Whether to draw edge labels.

- title:

  Optional plot title.

- node_label:

  Node label mode: value, type, both, or none.

- ...:

  Additional arguments passed to `igraph::plot.igraph`.

## Examples

``` r
if (FALSE) { # \dontrun{
t <- as_flexseq(letters[1:8])
plot_tree(t, title = "Finger tree")

t2 <- as_flexseq(letters[1:12])
plot_tree(t2, node_label = "both", vertex.size = 8)
} # }
```
