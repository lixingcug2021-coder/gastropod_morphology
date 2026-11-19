# Optional interoperable CSV copies. Original Excel input files are never rewritten.
source("scripts/init.R", local = TRUE, encoding = "UTF-8")
check_packages("readxl")
ids <- c("figure_1", "figure_3", "supplementary_figure_3", "supplementary_figure_7")
for (id in ids) {
  input <- file.path("analyses", id, "data.xlsx")
  sheets <- readxl::excel_sheets(input)
  for (s in seq_along(sheets)) {
    d <- readxl::read_excel(input, sheet = sheets[s], .name_repair = "minimal")
    target <- if (length(sheets) == 1) "data.csv" else paste0("data_sheet_", s, ".csv")
    write.csv(d, file.path("analyses", id, target), row.names = FALSE, na = "", fileEncoding = "UTF-8")
  }
  result <- file.path("results", id, "results.xlsx")
  if (file.exists(result)) {
    for (sheet in readxl::excel_sheets(result)) {
      d <- readxl::read_excel(result, sheet = sheet, .name_repair = "minimal")
      # Use a separate prefix so original Figure 1 CSV outputs are retained.
      write.csv(d, file.path("results", id, paste0("sheet_", sheet, ".csv")),
                row.names = FALSE, na = "", fileEncoding = "UTF-8")
    }
  }
}
