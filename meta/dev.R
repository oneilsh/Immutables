devtools::document()
unlink("docs", recursive=TRUE)
pkgdown::build_site(new_process = FALSE)    # builds site into docs/
pkgdown::preview_site()

