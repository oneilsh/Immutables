# Build graph data frames for a finger tree

Build graph data frames for a finger tree

## Usage

``` r
get_graph_df(t)
```

## Arguments

- t:

  FingerTree.

## Value

A list with three elements: `edge_df` (parent/child/label), `node_df`
(node/type/label), and `node_data` — a named list keyed by node id whose
values are lists with fields `type`, `label`, `measures` (cached monoid
values for structural nodes; `NULL` for element leaves), and `element`
(the raw leaf entry for element nodes; `NULL` for structural nodes).
