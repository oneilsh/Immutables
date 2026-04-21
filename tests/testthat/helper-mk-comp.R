# Shared test utility: a minimal S3 class that supports `<`, `>`, `==` via
# `Ops` dispatch but has no `c()` method. Used to exercise the merge-sort
# fallback paths in .oms_order_entries / .ivx_order_entries, which fire only
# when `do.call(c, keys)` errors or returns a length-mismatched result.
#
# The methods must be registered via .S3method (not just assigned) so dispatch
# works when the package's internals — in a different namespace than this
# test env — call `<`/`>` on an mk_comp object.

mk_comp <- function(val) {
  structure(list(val = val), class = "mk_comp")
}

Ops.mk_comp <- function(e1, e2) {
  v1 <- if (inherits(e1, "mk_comp")) e1$val else e1
  v2 <- if (inherits(e2, "mk_comp")) e2$val else e2
  get(.Generic)(v1, v2)
}

is.na.mk_comp <- function(x) FALSE

.S3method("Ops", "mk_comp", Ops.mk_comp)
.S3method("is.na", "mk_comp", is.na.mk_comp)
