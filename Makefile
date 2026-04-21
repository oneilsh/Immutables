.PHONY: help document test check check-cran coverage coverage-report site paper build install clean

help:
	@echo "Available targets:"
	@echo "  document        - Rebuild man/ and NAMESPACE from roxygen comments"
	@echo "  test            - Run testthat tests"
	@echo "  check           - Run R CMD check --as-cran (matches CI)"
	@echo "  check-cran      - Stricter: remote URL/BioC checks + manual PDF"
	@echo "  coverage        - Print package coverage summary"
	@echo "  coverage-report - Open interactive HTML coverage report"
	@echo "  site            - Build pkgdown site into docs/"
	@echo "  paper           - Render paper/manuscript.Rmd to PDF"
	@echo "  build           - Build the source tarball"
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
	Rscript -e 'print(covr::package_coverage())'

coverage-report:
	@CACHE=$$(Rscript -e 'cat(tools::R_user_dir("immutables", "cache"))') && \
	 FILE="$$CACHE/coverage.html" && \
	 mkdir -p "$$CACHE" && \
	 Rscript -e "covr::report(covr::package_coverage(), file = '$$FILE', browse = FALSE)" && \
	 echo "Report: $$FILE" && \
	 (command -v open >/dev/null 2>&1 && open "$$FILE") || \
	 (command -v xdg-open >/dev/null 2>&1 && xdg-open "$$FILE") || true

site:
	Rscript -e 'pkgdown::build_site()'

paper:
	Rscript -e 'rmarkdown::render("paper/manuscript.Rmd")'

build:
	Rscript -e 'devtools::build()'

install:
	Rscript -e 'devtools::install()'

clean:
	rm -rf *.Rcheck ..Rcheck *.tar.gz paper/manuscript.pdf paper/manuscript.tex
