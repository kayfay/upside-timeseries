# R/utils.R
# Utility functions for package management and error handling

#' Ensure required packages are installed and loaded
#' @param packages Character vector of package names
ensure_packages <- function(packages) {
  for (pkg in packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      message(sprintf("Installing missing package: %s", pkg))
      try(install.packages(pkg, repos = "https://cloud.r-project.org"), silent = TRUE)
    }
    suppressPackageStartupMessages(library(pkg, character.only = TRUE))
  }
}

#' Safe execution wrapper with default return and optional error message
#' @param expr Expression to evaluate
#' @param default Default value to return on error
#' @param msg Optional error message to display
safe <- function(expr, default = NULL, msg = NULL) {
  tryCatch(expr, error = function(e) {
    if (!is.null(msg)) message(msg)
    message("Error: ", conditionMessage(e))
    default
  })
}
