# Explicit, one-time dependency installation. Requires Internet access.
# This installs available CRAN versions, not a frozen historical environment.
# See docs/package_versions.csv for the environment used for validation.
packages <- c("readxl", "dplyr", "tidyr", "openxlsx", "purrr", "PairedData", "car")
missing <- packages[!vapply(packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))]
if (length(missing)) install.packages(missing, repos = "https://cloud.r-project.org")
if (!all(vapply(packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1)))) {
  stop("Some dependencies are still unavailable; review installation messages.")
}
message("All analysis dependencies are available.")
