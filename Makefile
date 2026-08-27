.PHONY: help document test check check-cran coverage coverage-report coverage-dump snapshot-accept snapshot-review site paper build supplementary install clean

# Staging directory (transient) and output archive for the JSS supplementary bundle.
REPL_STAGE := Immutables-Supplementary
REPL_ZIP   := paper/Immutables-Supplementary.zip

# Passed to covr::package_coverage(code = ...) so local coverage runs the full test
# suite once with the default (C++) backend AND once with the pure-R backend,
# matching what test-coverage.yaml uploads to Codecov.
export COVR_DUAL_CODE := Sys.setenv(IMMUTABLES_USE_CPP = 'FALSE'); .out <- tempfile('immutables-r-backend'); dir.create(.out, recursive = TRUE); tools::testInstalledPackage('Immutables', outDir = .out, types = 'tests'); Sys.unsetenv('IMMUTABLES_USE_CPP')

# devtools::test() sets NOT_CRAN automatically, so snapshot tests (expect_snapshot)
# run locally. covrs subprocess runner (tools::testInstalledPackage) does NOT set
# it, and testthat auto-skips snapshots in CRAN-like envs. Export NOT_CRAN so
# coverage targets also exercise snapshot tests.
export NOT_CRAN := true

help:
	@echo "Available targets:"
	@echo "  document        - Rebuild man/ and NAMESPACE from roxygen comments"
	@echo "  test            - Run testthat tests"
	@echo "  check           - Run R CMD check --as-cran (matches CI)"
	@echo "  check-cran      - Stricter: remote URL/BioC checks + manual PDF"
	@echo "  coverage        - Print package coverage summary"
	@echo "  coverage-report - Open interactive HTML coverage report"
	@echo "  coverage-dump   - Write per-file + uncovered-line text dump to cache"
	@echo "  snapshot-accept - Accept all changed testthat snapshots (tests/testthat/_snaps/)"
	@echo "  snapshot-review - Interactively review changed snapshots (RStudio/console)"
	@echo "  site            - Build pkgdown site into docs/"
	@echo "  paper           - Render paper/manuscript.Rmd to PDF"
	@echo "  build           - Build the source tarball"
	@echo "  supplementary   - Assemble paper/Immutables-Supplementary.zip (tarball + scripts + README)"
	@echo "  install         - Install the package locally"
	@echo "  clean           - Remove check directory, tarballs, and paper artifacts"

document:
	Rscript -e 'devtools::document()'

test:
	Rscript -e 'devtools::test()'

check:
	Rscript -e 'devtools::check()'

check-cran:
	Rscript -e 'devtools::check(remote = TRUE, manual = TRUE)'

coverage:
	Rscript -e 'print(covr::package_coverage(code = Sys.getenv("COVR_DUAL_CODE")))'

coverage-report:
	@CACHE=$$(Rscript -e 'cat(tools::R_user_dir("Immutables", "cache"))') && \
	 FILE="$$CACHE/coverage.html" && \
	 mkdir -p "$$CACHE" && \
	 Rscript -e "covr::report(covr::package_coverage(code = Sys.getenv('COVR_DUAL_CODE')), file = '$$FILE', browse = FALSE)" && \
	 echo "Report: $$FILE" && \
	 (command -v open >/dev/null 2>&1 && open "$$FILE") || \
	 (command -v xdg-open >/dev/null 2>&1 && xdg-open "$$FILE") || true

coverage-dump:
	@CACHE=$$(Rscript -e 'cat(tools::R_user_dir("Immutables", "cache"))') && \
	 mkdir -p "$$CACHE" && \
	 FILE="$$CACHE/coverage-dump.txt" && \
	 Rscript -e 'options(width = 500); cov <- covr::package_coverage(code = Sys.getenv("COVR_DUAL_CODE")); con <- file(commandArgs(trailingOnly = TRUE)[1], "w"); sink(con, type = "output"); sink(con, type = "message"); cat("## Overall and per-file coverage\n\n"); print(cov); cat("\n\n## Uncovered lines (per file)\n\n"); zc <- covr::zero_coverage(cov); if (nrow(zc) == 0) { cat("(100% line coverage)\n") } else { wd <- normalizePath(getwd()); cat("Columns in zero_coverage: ", paste(names(zc), collapse = ", "), "\n\n", sep = ""); line_col <- if ("first_line" %in% names(zc)) "first_line" else if ("line" %in% names(zc)) "line" else names(zc)[sapply(zc, is.numeric)][1]; for (f in sort(unique(zc$$filename))) { lines <- sort(unique(zc[[line_col]][zc$$filename == f])); rel <- sub(paste0("^", wd, "/?"), "", f); cat(sprintf("%s: %s\n", rel, paste(lines, collapse = ","))) } }; sink(type = "message"); sink(); close(con)' "$$FILE" && \
	 echo "Dump: $$FILE"

snapshot-accept:
	Rscript -e 'testthat::snapshot_accept()'

snapshot-review:
	Rscript -e 'testthat::snapshot_review()'

site:
	Rscript -e 'pkgdown::build_site()'

paper:
	Rscript -e 'rmarkdown::render("paper/manuscript.Rmd")'

build:
	Rscript -e 'devtools::build()'

# Assemble the JStatSoft supplementary archive: a freshly built source tarball
# plus the full and quick replication scripts and the README.
# `R CMD build` writes the tarball into the current directory (unlike
# devtools::build, which writes to the parent).
supplementary:
	@VERSION=$$(Rscript -e 'cat(as.character(read.dcf("DESCRIPTION")[,"Version"]))') && \
	 TARBALL=Immutables_$$VERSION.tar.gz && \
	 rm -rf $(REPL_STAGE) $(REPL_ZIP) && \
	 R CMD build . && \
	 mkdir -p $(REPL_STAGE) && \
	 cp $$TARBALL $(REPL_STAGE)/ && \
	 cp data-raw/replication/generate_publication_results.R $(REPL_STAGE)/ && \
	 cp data-raw/replication/replication-quick.R $(REPL_STAGE)/ && \
	 sed "s/<version>/$$VERSION/g" data-raw/replication/README.txt > $(REPL_STAGE)/README.txt && \
	 zip -r $(REPL_ZIP) $(REPL_STAGE) && \
	 rm -rf $(REPL_STAGE) && \
	 echo "" && \
	 echo "Built $(REPL_ZIP) for package version $$VERSION."

install:
	Rscript -e 'devtools::install()'

clean:
	rm -rf *.Rcheck ..Rcheck *.tar.gz paper/manuscript.pdf paper/manuscript.tex \
	       $(REPL_STAGE) $(REPL_ZIP)
