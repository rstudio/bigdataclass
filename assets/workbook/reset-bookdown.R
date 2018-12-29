files <- c(
  "derby.log",
  "parsedmodel.csv",
  "_bookdown_files",
  "_main.Rmd",
  "logs"
)
unlink(files, recursive = TRUE, force = TRUE)
rm(list=ls())
bookdown:::serve_book()