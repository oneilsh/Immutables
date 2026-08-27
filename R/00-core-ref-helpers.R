#SO

# identify internal structural nodes (vs user elements)
# Runtime: O(1). Plain S3-class lookup avoids lambda.r dispatcher overhead;
# called from many tree-traversal hot paths.
is_structural_node <- function(x) {
  cls <- class(x)
  any(cls %in% c("FingerTree", "Deep", "Digit", "Node", "Single", "Empty"))
}
