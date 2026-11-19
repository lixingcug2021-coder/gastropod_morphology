# supplementary_figure_7: portable entry point. Run from the repository root.
# Statistical calculations and decision rules are preserved from the supplied script.
# See README.md and docs/STATISTICAL_NOTES.md before interpreting outputs.
source("scripts/init.R", local = TRUE, encoding = "UTF-8")
analysis_id <- "supplementary_figure_7"
analysis_dir <- file.path(repo_dir, "analyses", analysis_id)
output_dir <- file.path(repo_dir, "results", analysis_id)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
check_packages(c("readxl", "dplyr", "purrr", "openxlsx"))

# 首次使用时安装所需软件包
library(readxl)
library(dplyr)
library(purrr)
library(openxlsx)

# 1. 输入文件与输出文件
input_file <- file.path(analysis_dir, "data.xlsx")

# 输出到相同文件夹，但使用新文件名，避免覆盖原始数据
output_file <- file.path(output_dir, "results.xlsx")

# 2. 读取数据
dat <- read_excel(input_file)

# 检查所需列是否存在
required_cols <- c(
  "Event",
  "Classification",
  "Background_aspect_ratio",
  "During_aspect_ratio"
)

missing_cols <- setdiff(required_cols, names(dat))

if (length(missing_cols) > 0) {
  stop(
    "Missing required columns: ",
    paste(missing_cols, collapse = ", ")
  )
}

# 转换为适合分析的类型，并只保留完整配对的数据
dat <- dat %>%
  mutate(
    Event = as.character(Event),
    Classification = as.character(Classification),
    Background_aspect_ratio = as.numeric(Background_aspect_ratio),
    During_aspect_ratio = as.numeric(During_aspect_ratio)
  ) %>%
  filter(
    !is.na(Event),
    !is.na(Classification),
    !is.na(Background_aspect_ratio),
    !is.na(During_aspect_ratio)
  ) %>%
  mutate(
    Difference = During_aspect_ratio - Background_aspect_ratio
  )

# Shapiro-Wilk 正态性检验函数
# Shapiro 检验要求样本数为 3 至 5000
shapiro_result <- function(x) {
  x <- x[is.finite(x)]
  n <- length(x)

  if (n < 3) {
    return(tibble(
      n = n,
      W = NA_real_,
      p_value = NA_real_,
      note = "Fewer than 3 observations; Shapiro-Wilk unavailable."
    ))
  }

  if (n > 5000) {
    return(tibble(
      n = n,
      W = NA_real_,
      p_value = NA_real_,
      note = "More than 5000 observations; Shapiro-Wilk unavailable."
    ))
  }

  # Shapiro-Wilk 检验无法处理完全相同的数值
  if (length(unique(x)) < 2) {
    return(tibble(
      n = n,
      W = NA_real_,
      p_value = NA_real_,
      note = "All values identical; Shapiro-Wilk unavailable."
    ))
  }

  test <- tryCatch(
    shapiro.test(x),
    error = function(e) NULL
  )

  if (is.null(test)) {
    return(tibble(
      n = n,
      W = NA_real_,
      p_value = NA_real_,
      note = "Test failed."
    ))
  }

  tibble(
    n = n,
    W = unname(test$statistic),
    p_value = test$p.value,
    note = ""
  )
}

# 3. 按 Event × Classification 检验正态性
# 分别检验 Background、During 和配对差值
normality_results <- dat %>%
  group_by(Event, Classification) %>%
  group_split() %>%
  map_dfr(function(g) {
    event_value <- g$Event[1]
    class_value <- g$Classification[1]

    bind_rows(
      shapiro_result(g$Background_aspect_ratio) %>%
        mutate(variable = "Background_aspect_ratio"),

      shapiro_result(g$During_aspect_ratio) %>%
        mutate(variable = "During_aspect_ratio"),

      shapiro_result(g$Difference) %>%
        mutate(variable = "Difference: During - Background")
    ) %>%
      mutate(
        Event = event_value,
        Classification = class_value,
        .before = 1
      )
  }) %>%
  group_by(variable) %>%
  mutate(
    p_adjusted_Holm = p.adjust(p_value, method = "holm")
  ) %>%
  ungroup()

# 配对 t 检验函数
paired_t_result <- function(g) {
  n <- nrow(g)

  if (n < 2) {
    return(tibble(
      n = n,
      mean_background = mean(g$Background_aspect_ratio),
      mean_during = mean(g$During_aspect_ratio),
      mean_change = mean(g$Difference),
      ci_low = NA_real_,
      ci_high = NA_real_,
      t_value = NA_real_,
      df = NA_real_,
      p_value = NA_real_,
      note = "Fewer than 2 pairs; paired t-test unavailable."
    ))
  }

  test <- tryCatch(
    t.test(
      g$During_aspect_ratio,
      g$Background_aspect_ratio,
      paired = TRUE
    ),
    error = function(e) NULL
  )

  if (is.null(test)) {
    return(tibble(
      n = n,
      mean_background = mean(g$Background_aspect_ratio),
      mean_during = mean(g$During_aspect_ratio),
      mean_change = mean(g$Difference),
      ci_low = NA_real_,
      ci_high = NA_real_,
      t_value = NA_real_,
      df = NA_real_,
      p_value = NA_real_,
      note = "Test failed."
    ))
  }

  tibble(
    n = n,
    mean_background = mean(g$Background_aspect_ratio),
    mean_during = mean(g$During_aspect_ratio),
    mean_change = mean(g$Difference),
    ci_low = unname(test$conf.int[1]),
    ci_high = unname(test$conf.int[2]),
    t_value = unname(test$statistic),
    df = unname(test$parameter),
    p_value = test$p.value,
    note = ""
  )
}

# Wilcoxon 配对符号秩检验函数
paired_wilcox_result <- function(g) {
  n <- nrow(g)

  if (n < 1) {
    return(tibble(
      n = n,
      median_change = NA_real_,
      p_value = NA_real_,
      note = "No valid paired data."
    ))
  }

  if (all(g$Difference == 0)) {
    return(tibble(
      n = n,
      median_change = 0,
      p_value = 1,
      note = "All paired differences are zero."
    ))
  }

  test <- tryCatch(
    wilcox.test(
      g$During_aspect_ratio,
      g$Background_aspect_ratio,
      paired = TRUE,
      exact = FALSE
    ),
    error = function(e) NULL
  )

  if (is.null(test)) {
    return(tibble(
      n = n,
      median_change = median(g$Difference),
      p_value = NA_real_,
      note = "Test failed."
    ))
  }

  tibble(
    n = n,
    median_change = median(g$Difference),
    p_value = test$p.value,
    note = ""
  )
}

# 4. 每个 Event × Classification 进行配对 t 检验
t_test_results <- dat %>%
  group_by(Event, Classification) %>%
  group_split() %>%
  map_dfr(function(g) {
    bind_cols(
      tibble(
        Event = g$Event[1],
        Classification = g$Classification[1]
      ),
      paired_t_result(g)
    )
  }) %>%
  mutate(
    p_adjusted_Holm = p.adjust(p_value, method = "holm")
  )

# 5. 每个 Event × Classification 进行 Wilcoxon 符号秩检验
wilcox_results <- dat %>%
  group_by(Event, Classification) %>%
  group_split() %>%
  map_dfr(function(g) {
    bind_cols(
      tibble(
        Event = g$Event[1],
        Classification = g$Classification[1]
      ),
      paired_wilcox_result(g)
    )
  }) %>%
  mutate(
    p_adjusted_Holm = p.adjust(p_value, method = "holm")
  )

# 6. 输出到同一文件夹中的新 Excel 文件
write.xlsx(
  list(
    Normality_tests = normality_results,
    Paired_t_tests = t_test_results,
    Wilcoxon_tests = wilcox_results,
    Paired_data_used = dat
  ),
  file = output_file,
  overwrite = TRUE
)

cat("Analysis completed. Results written to:\n", output_file)


writeLines(capture.output(sessionInfo()), file.path(output_dir, "sessionInfo.txt"))
