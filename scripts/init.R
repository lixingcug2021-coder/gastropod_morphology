# Shared initialization; all entry points are run from the repository root.
repo_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repo_dir, "gastropod_morphology.Rproj"))) {
  stop("Open gastropod_morphology.Rproj, or set the working directory to the repository root.")
}
check_packages <- function(packages) {
  available <- vapply(packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))
  if (any(!available)) {
    stop("Missing R packages: ", paste(packages[!available], collapse = ", "),
         ". Run source('scripts/install_packages.R') once, then retry.")
  }
}
