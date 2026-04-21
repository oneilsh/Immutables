library(testthat)
library(Immutables)

# testthat/waldo uses temporary language switching for stable output.
# If LC_ALL is pinned, this emits noisy warnings on every expectation.
Sys.unsetenv("LC_ALL")

test_check("Immutables")
