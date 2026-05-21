#SO

##############################
## Node type definitions
##############################
#
# These constructors carry the same semantics as the Haskell-style spec used
# in the paper; the canonical signatures are preserved as comments above each
# function. The bodies are plain R (not lambda.r) so the hot tree-build path
# avoids per-call dispatcher overhead — the lambda.r reference layer is the
# canonical specification, but production code does not pay for its dispatch.

# generic node type — stores arbitrary child elements in a list
# Reference (Haskell-style, lambda.r):
#   Node(...) :: ... -> list
# Runtime: O(k), where k is the number of constructor arguments.
Node <- function(...) {
  structure(list(...), class = c("Node", "list"))
}

# Node2 / Node3 — internal nodes with 2 or 3 children
# Reference:
#   Node2(x, y)    :: . -> . -> list
#   Node3(x, y, z) :: . -> . -> . -> list
# Runtime: O(1).
Node2 <- function(x, y) {
  structure(list(x, y), class = c("Node2", "Node", "list"))
}

Node3 <- function(x, y, z) {
  structure(list(x, y, z), class = c("Node3", "Node", "list"))
}

# FingerTree — base type used for inheriting / generic construction
# Reference:
#   FingerTree()   :: FingerTree
#   FingerTree(...) :: ... -> list
# Runtime: O(k).
FingerTree <- function(...) {
  args <- list(...)
  if(length(args) == 0L) {
    return(Empty())
  }
  structure(args, class = c("FingerTree", "list"))
}

# empty tree
# Reference:
#   Empty() :: FingerTree
#   Empty() = FingerTree(NULL)
# Runtime: O(1).
Empty <- function() {
  structure(list(NULL), class = c("Empty", "FingerTree", "list"))
}

# single-element tree
# Reference:
#   Single(x) :: . -> FingerTree
#   Single(x) = FingerTree(x)
# Runtime: O(1).
Single <- function(x) {
  structure(list(x), class = c("Single", "FingerTree", "list"))
}

# digit (1..4 elements; prefix/suffix container in Deep)
# Reference:
#   Digit(...) :: ... -> list
# Runtime: O(k).
Digit <- function(...) {
  structure(list(...), class = c("Digit", "list"))
}

# Deep — main internal type with prefix / middle / suffix
# Reference:
#   Deep(prefix, middle, suffix) :: Digit -> FingerTree -> Digit -> FingerTree
# Runtime: O(1).
Deep <- function(prefix, middle, suffix) {
  structure(
    list(prefix = prefix, middle = middle, suffix = suffix),
    class = c("Deep", "FingerTree", "list")
  )
}
