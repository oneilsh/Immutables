# Lets CI force a specific backend for reference / coverage runs via env var
# (options set in the parent process don't propagate through subprocess test
# runners like tools::testInstalledPackage, but env vars do).
if (nzchar(Sys.getenv("IMMUTABLES_USE_CPP"))) {
  options(immutables.use_cpp = as.logical(Sys.getenv("IMMUTABLES_USE_CPP")))
}
