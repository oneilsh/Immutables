# Extra playground script for current fingertree API.
library(igraph)
library(magrittr)
library(pryr)
library(rstackdeque)

if(requireNamespace("devtools", quietly = TRUE)) {
  devtools::load_all()
} else {
  library(immutables)
}

set.seed(7)
size_monoids <- list(.size = size_measure_monoid())

left <- as_flexseq(as.list(letters[1:12]), monoids = size_monoids)
right <- as_flexseq(as.list(letters[16:26]), monoids = size_monoids)

# Shared monoid names warn during concat by design.
both <- suppressWarnings(c(left, right))
plot_structure(both, vertex.size = 9, title = "concat")

valued <- as_flexseq(letters, values = sample(1:26), monoids = size_monoids)
plot_structure(valued, vertex.size = 9, title = "valued")

char_concat <- measure_monoid(
  function(a, b) paste0(a, b),
  "",
  function(el) as.character(el)
)
print(fold_right(valued, char_concat))

value_min <- measure_monoid(
  min,
  Inf,
  function(el) as.numeric(attr(el, "value"))
)
value_sum <- measure_monoid(
  `+`,
  0,
  function(el) as.numeric(attr(el, "value"))
)
print(fold_left(valued, value_min))
print(fold_left(valued, value_sum))

# Split by size monoid name.
s <- split(both, function(v) v >= 7, ".size")
print(fold_left(s$left, size_measure_monoid()))
print(fold_left(s$right, size_measure_monoid()))

# Add a custom monoid to an existing tree.
numeric_tree <- as_flexseq(1:10, monoids = size_monoids)
sum_numeric <- measure_monoid(`+`, 0, as.numeric)
numeric_tree2 <- add_monoids(numeric_tree, list(sum = sum_numeric))
print(attr(numeric_tree2, "measures"))
