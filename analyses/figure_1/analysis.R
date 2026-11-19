# figure_1: portable entry point. Run from the repository root.
# Statistical calculations and decision rules are preserved from the supplied script.
# See README.md and docs/STATISTICAL_NOTES.md before interpreting outputs.
source("scripts/init.R", local = TRUE, encoding = "UTF-8")
analysis_id <- "figure_1"
analysis_dir <- file.path(repo_dir, "analyses", analysis_id)
output_dir <- file.path(repo_dir, "results", analysis_id)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
check_packages(c("readxl", "dplyr", "tidyr", "openxlsx"))

# ============================================================
# PTAE / ETAE 配对 aspect_ratio 统计分析
# ============================================================

# 分析内容：
# 1. Background aspect_ratio 与 During aspect_ratio 的 Pearson 相关检验
# 2. 四组数据的 Shapiro-Wilk 正态性检验
# 3. 满足正态性时进行 Pitman-Morgan 配对方差检验
# 4. 满足正态性时进行配对样本 t 检验
# 5. 输出 Excel 和 CSV 结果
#
# 配对原则：
# 同一个 Event 内，同一个 Genus 的 Background 与 During 数据作为一对
# ============================================================

# ------------------------------------------------------------
# 0. 安装并加载必要的 R 包
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(tidyr)
  library(openxlsx)
})

# ------------------------------------------------------------
# 1. 设置文件路径和输出目录
# ------------------------------------------------------------

input_file <- file.path(analysis_dir, "data.xlsx")



output_excel <- file.path(
  output_dir,
  "results.xlsx"
)

if (!file.exists(input_file)) {
  stop(
    "Input file not found; check the path:\n",
    input_file
  )
}

if (!dir.exists(output_dir)) {
  dir.create(
    output_dir,
    recursive = TRUE
  )
}

# ------------------------------------------------------------
# 2. 读取 Excel 数据
# ------------------------------------------------------------

message("Reading Excel file:")
message(input_file)

raw_data <- read_excel(input_file)

message("Input rows: ", nrow(raw_data))
message("Input columns: ", paste(names(raw_data), collapse = " | "))

# ------------------------------------------------------------
# 3. 整理和检查列名
# ------------------------------------------------------------

# 去除列名两端的空格
names(raw_data) <- trimws(names(raw_data))

# 期望的数据列名
required_columns <- c(
  "Event",
  "Genus",
  "Background aspect_ratio",
  "During aspect_ratio"
)

missing_columns <- setdiff(
  required_columns,
  names(raw_data)
)

if (length(missing_columns) > 0) {
  stop(
    paste0(
      "Missing required columns:\n",
      paste(missing_columns, collapse = "\n"),
      "\n\nAvailable columns:\n",
      paste(names(raw_data), collapse = "\n")
    )
  )
}

# ------------------------------------------------------------
# 4. 数据预处理
# ------------------------------------------------------------

dat <- raw_data %>%
  transmute(
    Event = trimws(as.character(Event)),
    Genus = trimws(as.character(Genus)),
    Background_aspect_ratio = suppressWarnings(
      as.numeric(`Background aspect_ratio`)
    ),
    During_aspect_ratio = suppressWarnings(
      as.numeric(`During aspect_ratio`)
    )
  )

n_before_cleaning <- nrow(dat)

# 删除关键字段缺失或为空的数据
dat <- dat %>%
  filter(
    !is.na(Event),
    !is.na(Genus),
    Event != "",
    Genus != ""
  )

n_after_key_cleaning <- nrow(dat)

message(
  "Rows removed because Event or Genus is missing/empty: ",
  n_before_cleaning - n_after_key_cleaning
)

# 检查 Event
valid_events <- c("PTAE", "ETAE")

invalid_event_rows <- sum(
  !dat$Event %in% valid_events
)

if (invalid_event_rows > 0) {
  message(
    "Found ",
    invalid_event_rows,
    " rows with Event other than PTAE or ETAE; these will be excluded."
  )

  dat <- dat %>%
    filter(Event %in% valid_events)
}

# 检查每个 Event + Genus 是否唯一
# 如果同一个 Event + Genus 出现多行，则取平均值作为配对分析值
duplicate_pairs <- dat %>%
  count(Event, Genus, name = "n_rows") %>%
  filter(n_rows > 1)

if (nrow(duplicate_pairs) > 0) {
  message(
    "Note: found ",
    nrow(duplicate_pairs),
    " duplicated Event + Genus keys."
  )
  message("Duplicate rows will be averaged before paired analysis.")
}

# 对同一个 Event + Genus 的重复记录取平均值
dat_pair <- dat %>%
  group_by(Event, Genus) %>%
  summarise(
    Background_aspect_ratio = ifelse(
      all(is.na(Background_aspect_ratio)),
      NA_real_,
      mean(Background_aspect_ratio, na.rm = TRUE)
    ),
    During_aspect_ratio = ifelse(
      all(is.na(During_aspect_ratio)),
      NA_real_,
      mean(During_aspect_ratio, na.rm = TRUE)
    ),
    n_background = sum(!is.na(Background_aspect_ratio)),
    n_during = sum(!is.na(During_aspect_ratio)),
    .groups = "drop"
  ) %>%
  arrange(Event, Genus)

message("Number of Event + Genus pairs after processing: ", nrow(dat_pair))

# ------------------------------------------------------------
# 5. 定义辅助函数
# ------------------------------------------------------------

safe_mean <- function(x) {
  x <- x[is.finite(x)]

  if (length(x) == 0) {
    return(NA_real_)
  }

  mean(x)
}

safe_sd <- function(x) {
  x <- x[is.finite(x)]

  if (length(x) < 2) {
    return(NA_real_)
  }

  sd(x)
}

safe_variance <- function(x) {
  x <- x[is.finite(x)]

  if (length(x) < 2) {
    return(NA_real_)
  }

  var(x)
}

# ------------------------------------------------------------
# 6. Shapiro-Wilk 正态性检验函数
# ------------------------------------------------------------

run_shapiro_test <- function(x, event_name, time_name) {

  x <- x[is.finite(x)]

  n <- length(x)

  result <- data.frame(
    Event = event_name,
    Time = time_name,
    N = n,
    Mean = safe_mean(x),
    SD = safe_sd(x),
    Variance = safe_variance(x),
    W = NA_real_,
    p_value = NA_real_,
    Normality = NA_character_,
    Note = NA_character_,
    stringsAsFactors = FALSE
  )

  # shapiro.test 要求样本量至少为 3
  if (n < 3) {
    result$Normality <- "Not assessable"
    result$Note <- "Fewer than 3 finite observations; Shapiro-Wilk test unavailable."
    return(result)
  }

  # shapiro.test 最多接受 5000 个样本
  if (n > 5000) {
    result$Normality <- "Not assessable"
    result$Note <- "More than 5000 finite observations; Shapiro-Wilk test not performed."
    return(result)
  }

  if (length(unique(x)) < 3) {
    result$Normality <- "Not assessable"
    result$Note <- "Too few distinct values for the normality check implemented here."
    return(result)
  }

  test_result <- tryCatch(
    {
      shapiro.test(x)
    },
    error = function(e) {
      NULL
    }
  )

  if (is.null(test_result)) {
    result$Normality <- "Not assessable"
    result$Note <- "Shapiro-Wilk test failed."
    return(result)
  }

  result$W <- unname(test_result$statistic)
  result$p_value <- test_result$p.value

  if (test_result$p.value > 0.05) {
    result$Normality <- "Normality not rejected"
    result$Note <- "p > 0.05; normality not rejected."
  } else {
    result$Normality <- "Normality rejected"
    result$Note <- "p <= 0.05; normality rejected."
  }

  return(result)
}

# ------------------------------------------------------------
# 7. 对四组数据进行正态性检验
# ------------------------------------------------------------

normality_results <- bind_rows(
  run_shapiro_test(
    dat_pair %>%
      filter(Event == "PTAE") %>%
      pull(Background_aspect_ratio),
    "PTAE",
    "Background"
  ),

  run_shapiro_test(
    dat_pair %>%
      filter(Event == "PTAE") %>%
      pull(During_aspect_ratio),
    "PTAE",
    "During"
  ),

  run_shapiro_test(
    dat_pair %>%
      filter(Event == "ETAE") %>%
      pull(Background_aspect_ratio),
    "ETAE",
    "Background"
  ),

  run_shapiro_test(
    dat_pair %>%
      filter(Event == "ETAE") %>%
      pull(During_aspect_ratio),
    "ETAE",
    "During"
  )
)

message("")
message("========================================")
message("Shapiro-Wilk normality results")
message("========================================")
print(normality_results)

# ------------------------------------------------------------
# 8. Pearson 线性相关检验函数
# ------------------------------------------------------------

run_correlation_test <- function(data, event_name) {

  event_data <- data %>%
    filter(Event == event_name) %>%
    filter(
      is.finite(Background_aspect_ratio),
      is.finite(During_aspect_ratio)
    )

  n_pair <- nrow(event_data)

  result <- data.frame(
    Event = event_name,
    N_paired_Genus = n_pair,
    Correlation_r = NA_real_,
    p_value = NA_real_,
    Confidence_Lower_95 = NA_real_,
    Confidence_Upper_95 = NA_real_,
    Method = "Pearson correlation",
    Conclusion = NA_character_,
    Note = NA_character_,
    stringsAsFactors = FALSE
  )

  if (n_pair < 3) {
    result$Conclusion <- "Not assessable"
    result$Note <- "Fewer than 3 complete genus pairs."
    return(result)
  }

  if (
    sd(event_data$Background_aspect_ratio) == 0 ||
    sd(event_data$During_aspect_ratio) == 0
  ) {
    result$Conclusion <- "Not assessable"
    result$Note <- "At least one variable has zero variance; Pearson correlation unavailable."
    return(result)
  }

  test_result <- tryCatch(
    {
      cor.test(
        event_data$Background_aspect_ratio,
        event_data$During_aspect_ratio,
        method = "pearson",
        alternative = "two.sided"
      )
    },
    error = function(e) {
      NULL
    }
  )

  if (is.null(test_result)) {
    result$Conclusion <- "Not assessable"
    result$Note <- "Pearson correlation test failed."
    return(result)
  }

  result$Correlation_r <- unname(test_result$estimate)
  result$p_value <- test_result$p.value
  result$Confidence_Lower_95 <- test_result$conf.int[1]
  result$Confidence_Upper_95 <- test_result$conf.int[2]

  if (test_result$p.value <= 0.05) {
    result$Conclusion <- "Significant linear correlation (unadjusted p)"
    result$Note <- "p <= 0.05"
  } else {
    result$Conclusion <- "Linear correlation not significant (unadjusted p)"
    result$Note <- "p > 0.05"
  }

  return(result)
}

# ------------------------------------------------------------
# 9. 分别计算 PTAE 和 ETAE 的 Pearson 相关
# ------------------------------------------------------------

correlation_results <- bind_rows(
  run_correlation_test(dat_pair, "PTAE"),
  run_correlation_test(dat_pair, "ETAE")
)

message("")
message("========================================")
message("Pearson correlation results")
message("========================================")
print(correlation_results)

# ------------------------------------------------------------
# 10. Pitman-Morgan 配对方差检验函数
# ------------------------------------------------------------

run_pitman_morgan_test <- function(data, event_name, normality_table) {

  event_data <- data %>%
    filter(Event == event_name) %>%
    filter(
      is.finite(Background_aspect_ratio),
      is.finite(During_aspect_ratio)
    )

  x <- event_data$Background_aspect_ratio
  y <- event_data$During_aspect_ratio

  n_pair <- length(x)

  # 获取该 Event 的正态性检验结果
  normal_background <- normality_table %>%
    filter(
      Event == event_name,
      Time == "Background"
    )

  normal_during <- normality_table %>%
    filter(
      Event == event_name,
      Time == "During"
    )

  both_normal <- nrow(normal_background) == 1 &&
    nrow(normal_during) == 1 &&
    normal_background$Normality == "Normality not rejected" &&
    normal_during$Normality == "Normality not rejected"

  result <- data.frame(
    Event = event_name,
    N_paired_Genus = n_pair,
    Background_variance = safe_variance(x),
    During_variance = safe_variance(y),
    Variance_ratio_Background_During = NA_real_,
    Pitman_Morgan_r = NA_real_,
    p_value = NA_real_,
    Conclusion = NA_character_,
    Note = NA_character_,
    stringsAsFactors = FALSE
  )

  if (!both_normal) {
    result$Conclusion <- "Not performed"
    result$Note <- "Normality was not accepted for both Background and During under the original decision rule."
    return(result)
  }

  if (n_pair < 3) {
    result$Conclusion <- "Not performed"
    result$Note <- "Fewer than 3 complete genus pairs."
    return(result)
  }

  if (
    sd(x) == 0 ||
    sd(y) == 0
  ) {
    result$Conclusion <- "Not performed"
    result$Note <- "At least one variable has zero variance."
    return(result)
  }

  # Pitman-Morgan 检验：
  # 在配对数据中，检验：
  # H0: Var(Background) = Var(During)
  #
  # 若两组方差相等，则：
  # cor(X + Y, X - Y) = 0
  sum_xy <- x + y
  diff_xy <- x - y

  pm_test <- tryCatch(
    {
      cor.test(
        sum_xy,
        diff_xy,
        method = "pearson",
        alternative = "two.sided"
      )
    },
    error = function(e) {
      NULL
    }
  )

  if (is.null(pm_test)) {
    result$Conclusion <- "Not assessable"
    result$Note <- "Pitman-Morgan test failed."
    return(result)
  }

  result$Variance_ratio_Background_During <-
    var(x) / var(y)

  result$Pitman_Morgan_r <-
    unname(pm_test$estimate)

  result$p_value <- pm_test$p.value

  if (pm_test$p.value > 0.05) {
    result$Conclusion <- "Variance difference not significant (unadjusted p)"
    result$Note <- "p > 0.05; equal-variance null not rejected."
  } else {
    result$Conclusion <- "Significant variance difference (unadjusted p)"
    result$Note <- "p <= 0.05; equal-variance null rejected."
  }

  return(result)
}

# ------------------------------------------------------------
# 11. 配对样本 t 检验函数
# ------------------------------------------------------------

run_paired_t_test <- function(data, event_name, normality_table) {

  event_data <- data %>%
    filter(Event == event_name) %>%
    filter(
      is.finite(Background_aspect_ratio),
      is.finite(During_aspect_ratio)
    )

  x <- event_data$Background_aspect_ratio
  y <- event_data$During_aspect_ratio

  n_pair <- length(x)

  # 获取正态性结果
  normal_background <- normality_table %>%
    filter(
      Event == event_name,
      Time == "Background"
    )

  normal_during <- normality_table %>%
    filter(
      Event == event_name,
      Time == "During"
    )

  both_normal <- nrow(normal_background) == 1 &&
    nrow(normal_during) == 1 &&
    normal_background$Normality == "Normality not rejected" &&
    normal_during$Normality == "Normality not rejected"

  result <- data.frame(
    Event = event_name,
    N_paired_Genus = n_pair,
    Background_mean = safe_mean(x),
    During_mean = safe_mean(y),
    Mean_difference_Background_minus_During = NA_real_,
    t_value = NA_real_,
    df = NA_real_,
    p_value = NA_real_,
    Confidence_Lower_95 = NA_real_,
    Confidence_Upper_95 = NA_real_,
    Conclusion = NA_character_,
    Note = NA_character_,
    stringsAsFactors = FALSE
  )

  if (!both_normal) {
    result$Conclusion <- "Not performed"
    result$Note <- "Normality was not accepted for both Background and During under the original decision rule."
    return(result)
  }

  if (n_pair < 2) {
    result$Conclusion <- "Not performed"
    result$Note <- "Fewer than 2 complete genus pairs."
    return(result)
  }

  t_test <- tryCatch(
    {
      t.test(
        x,
        y,
        paired = TRUE,
        alternative = "two.sided"
      )
    },
    error = function(e) {
      NULL
    }
  )

  if (is.null(t_test)) {
    result$Conclusion <- "Not assessable"
    result$Note <- "Paired t-test failed."
    return(result)
  }

  result$Mean_difference_Background_minus_During <-
    mean(x - y)

  result$t_value <-
    unname(t_test$statistic)

  result$df <-
    unname(t_test$parameter)

  result$p_value <-
    t_test$p.value

  result$Confidence_Lower_95 <-
    t_test$conf.int[1]

  result$Confidence_Upper_95 <-
    t_test$conf.int[2]

  if (t_test$p.value <= 0.05) {
    result$Conclusion <- "Significant mean difference (unadjusted p)"
    result$Note <- "p <= 0.05; zero mean-difference null rejected."
  } else {
    result$Conclusion <- "Mean difference not significant (unadjusted p)"
    result$Note <- "p > 0.05; zero mean-difference null not rejected."
  }

  return(result)
}

# ------------------------------------------------------------
# 12. 分别进行 Pitman-Morgan 检验和配对样本 t 检验
# ------------------------------------------------------------

pitman_morgan_results <- bind_rows(
  run_pitman_morgan_test(
    dat_pair,
    "PTAE",
    normality_results
  ),

  run_pitman_morgan_test(
    dat_pair,
    "ETAE",
    normality_results
  )
)

paired_t_results <- bind_rows(
  run_paired_t_test(
    dat_pair,
    "PTAE",
    normality_results
  ),

  run_paired_t_test(
    dat_pair,
    "ETAE",
    normality_results
  )
)

message("")
message("========================================")
message("Pitman-Morgan results")
message("========================================")
print(pitman_morgan_results)

message("")
message("========================================")
message("Paired t-test results")
message("========================================")
print(paired_t_results)

# ------------------------------------------------------------
# 13. 生成 Q-Q 图
# ------------------------------------------------------------

qq_plot_file <- file.path(
  output_dir,
  "aspect_ratio_qq.png"
)

png(
  filename = qq_plot_file,
  width = 1800,
  height = 1200,
  res = 180
)

par(
  mfrow = c(2, 2),
  mar = c(4, 4, 3, 1)
)

plot_qq <- function(x, main_title) {
  x <- x[is.finite(x)]

  if (length(x) >= 2) {
    qqnorm(
      x,
      main = main_title,
      pch = 19,
      col = "#2C7FB8"
    )
    qqline(
      x,
      col = "red",
      lwd = 2
    )
  } else {
    plot.new()
    title(main = main_title)
    text(
      0.5,
      0.5,
      "Insufficient valid data",
      cex = 1.2
    )
  }
}

plot_qq(
  dat_pair %>%
    filter(Event == "PTAE") %>%
    pull(Background_aspect_ratio),
  "PTAE - Background"
)

plot_qq(
  dat_pair %>%
    filter(Event == "PTAE") %>%
    pull(During_aspect_ratio),
  "PTAE - During"
)

plot_qq(
  dat_pair %>%
    filter(Event == "ETAE") %>%
    pull(Background_aspect_ratio),
  "ETAE - Background"
)

plot_qq(
  dat_pair %>%
    filter(Event == "ETAE") %>%
    pull(During_aspect_ratio),
  "ETAE - During"
)

par(mfrow = c(1, 1))

dev.off()

# ------------------------------------------------------------
# 14. 输出 Excel 文件
# ------------------------------------------------------------

message("")
message("Writing Excel results...")

# 统一数值结果的小数位可以根据需要修改
round_numeric_columns <- function(data, digits = 8) {
  data %>%
    mutate(
      across(
        where(is.numeric),
        ~ round(.x, digits)
      )
    )
}

normality_output <- round_numeric_columns(
  normality_results
)

correlation_output <- round_numeric_columns(
  correlation_results
)

pitman_morgan_output <- round_numeric_columns(
  pitman_morgan_results
)

paired_t_output <- round_numeric_columns(
  paired_t_results
)

dat_pair_output <- round_numeric_columns(
  dat_pair
)

# 创建 Excel 工作簿
wb <- createWorkbook()

# 表头样式
header_style <- createStyle(
  textDecoration = "bold",
  fgFill = "#D9EAF7",
  border = "Bottom",
  halign = "center",
  valign = "center"
)

# 添加工作表的辅助函数
add_result_sheet <- function(
    wb,
    sheet_name,
    data
) {
  addWorksheet(wb, sheet_name)

  writeData(
    wb,
    sheet = sheet_name,
    x = data,
    headerStyle = header_style,
    withFilter = TRUE
  )

  if (ncol(data) > 0) {
    setColWidths(
      wb,
      sheet = sheet_name,
      cols = seq_len(ncol(data)),
      widths = "auto"
    )
  }

  freezePane(
    wb,
    sheet = sheet_name,
    firstRow = TRUE
  )
}

# 添加各个结果表
add_result_sheet(
  wb,
  "Normality",
  normality_output
)

add_result_sheet(
  wb,
  "Pearson_Correlation",
  correlation_output
)

add_result_sheet(
  wb,
  "Pitman_Morgan",
  pitman_morgan_output
)

add_result_sheet(
  wb,
  "Paired_t_test",
  paired_t_output
)

add_result_sheet(
  wb,
  "Paired_Data",
  dat_pair_output
)

saveWorkbook(
  wb,
  file = output_excel,
  overwrite = TRUE
)

# ------------------------------------------------------------
# 15. 同时输出 CSV 文件
# ------------------------------------------------------------

write.csv(
  normality_output,
  file = file.path(output_dir, "Normality.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

write.csv(
  correlation_output,
  file = file.path(output_dir, "Pearson_Correlation.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

write.csv(
  pitman_morgan_output,
  file = file.path(output_dir, "Pitman_Morgan.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

write.csv(
  paired_t_output,
  file = file.path(output_dir, "Paired_t_test.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

write.csv(
  dat_pair_output,
  file = file.path(output_dir, "Paired_Data.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

# ------------------------------------------------------------
# 16. 输出运行摘要
# ------------------------------------------------------------

message("")
message("====================================================")
message("Analysis completed")
message("====================================================")
message("Input file:")
message(input_file)
message("")
message("Output Excel file:")
message(output_excel)
message("")
message("Output directory:")
message(output_dir)
message("")
message("Q-Q plot:")
message(qq_plot_file)
message("")
message("Processed Event + Genus pairs: ", nrow(dat_pair))
message(
  "PTAE complete pairs: ",
  sum(
    dat_pair$Event == "PTAE" &
      !is.na(dat_pair$Background_aspect_ratio) &
      !is.na(dat_pair$During_aspect_ratio)
  )
)
message(
  "ETAE complete pairs: ",
  sum(
    dat_pair$Event == "ETAE" &
      !is.na(dat_pair$Background_aspect_ratio) &
      !is.na(dat_pair$During_aspect_ratio)
  )
)
message("====================================================")


writeLines(capture.output(sessionInfo()), file.path(output_dir, "sessionInfo.txt"))
