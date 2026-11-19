# Open the .Rproj file first, then source this file in a fresh R session.
source("scripts/init.R", local = TRUE, encoding = "UTF-8")
check_packages(c("readxl", "dplyr", "tidyr", "openxlsx", "purrr", "PairedData", "car"))
analysis_ids <- c("figure_1", "figure_3", "supplementary_figure_3", "supplementary_figure_7")
for (id in analysis_ids) {
  input <- file.path("analyses", id, "data.xlsx")
  if (!file.exists(input)) stop("Missing input: ", input)
}
for (id in analysis_ids) {
  message("\nRunning ", id)
  analysis_env <- new.env(parent = globalenv())
  source(file.path("analyses", id, "analysis.R"), local = analysis_env,
         keep.source = FALSE, encoding = "UTF-8")
}
source("scripts/export_csv.R", local = TRUE, encoding = "UTF-8")
message("Completed. Results are under results/<analysis_id>/.")
