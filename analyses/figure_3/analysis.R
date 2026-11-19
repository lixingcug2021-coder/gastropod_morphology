# figure_3: portable entry point. Run from the repository root.
# Statistical calculations and decision rules are preserved from the supplied script.
# See README.md and docs/STATISTICAL_NOTES.md before interpreting outputs.
source("scripts/init.R", local = TRUE, encoding = "UTF-8")
analysis_id <- "figure_3"
analysis_dir <- file.path(repo_dir, "analyses", analysis_id)
output_dir <- file.path(repo_dir, "results", analysis_id)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
check_packages(c("readxl", "openxlsx", "PairedData", "car"))

############################################################
# Event分组统计分析
#
# 数据表头：
# Event
# Genus
# Background log10 V
# During log10 V
#
# 分析内容：
# 1. Pearson线性相关检验
# 2. Shapiro-Wilk正态性检验
# 3. Pitman-Morgan配对方差检验
# 4. 配对样本t检验
# 5. Levene方差齐性检验
# 6. 配对Wilcoxon符号秩检验
############################################################

############################
# 一、安装并加载R包
############################

library(readxl)
library(openxlsx)
library(PairedData)
library(car)

############################
# 二、设置文件路径
############################

input_file <- file.path(analysis_dir, "data.xlsx")

output_file <- file.path(output_dir, "results.xlsx")

############################
# 三、读取Excel文件
############################

if (!file.exists(input_file)) {
  stop(
    paste0(
      "Input file not found; check path:\n",
      input_file
    )
  )
}

raw_data <- read_excel(
  input_file,
  .name_repair = "minimal"
)

# 清理表头两侧的空格
names(raw_data) <- trimws(names(raw_data))

cat("Input columns:\n")
print(names(raw_data))

############################
# 四、检查数据表头
############################

required_columns <- c(
  "Event",
  "Genus",
  "Background log10 V",
  "During log10 V"
)

missing_columns <- setdiff(
  required_columns,
  names(raw_data)
)

if (length(missing_columns) > 0) {
  stop(
    paste0(
      "Missing Excel columns:\n",
      paste(missing_columns, collapse = "\n"),
      "\n\nCheck exact column names."
    )
  )
}

############################
# 五、数据整理
############################

clean_character <- function(x) {
  x <- trimws(as.character(x))
  x[x == ""] <- NA_character_
  return(x)
}

clean_numeric <- function(x) {

  if (is.numeric(x)) {
    return(as.numeric(x))
  }

  x <- trimws(as.character(x))
  x[x == ""] <- NA_character_

  result <- suppressWarnings(
    as.numeric(x)
  )

  return(result)
}

dat <- data.frame(
  Event = clean_character(raw_data[["Event"]]),
  Genus = clean_character(raw_data[["Genus"]]),
  Background_log10_V =
    clean_numeric(raw_data[["Background log10 V"]]),
  During_log10_V =
    clean_numeric(raw_data[["During log10 V"]]),
  stringsAsFactors = FALSE
)

# 删除Event为空的行
dat <- dat[
  !is.na(dat$Event),
  ,
  drop = FALSE
]

if (nrow(dat) == 0) {
  stop("No valid data found.")
}

############################
# 六、检查Event数量
############################

event_values <- unique(dat$Event)

cat("\nEvents present:\n")
print(event_values)

if (length(event_values) != 2) {
  warning(
    paste0(
      "Number of events: ",
      length(event_values),
      "; differs from the two events expected in the original script.",
      "\nContinuing with the events actually present."
    )
  )
}

############################
# 七、定义辅助函数
############################

# Shapiro-Wilk正态性检验
safe_shapiro_test <- function(x) {

  x <- x[is.finite(x)]
  n <- length(x)

  if (n < 3) {
    return(
      list(
        n = n,
        W = NA_real_,
        p_value = NA_real_,
        conclusion =
          "Fewer than 3 finite observations; Shapiro-Wilk test unavailable.",
        note = "At least 3 finite observations are required."
      )
    )
  }

  if (n > 5000) {
    return(
      list(
        n = n,
        W = NA_real_,
        p_value = NA_real_,
        conclusion =
          "More than 5000 observations; Shapiro-Wilk not performed.",
        note = "Shapiro-Wilk supports at most 5000 observations."
      )
    )
  }

  if (length(unique(x)) < 2) {
    return(
      list(
        n = n,
        W = NA_real_,
        p_value = NA_real_,
        conclusion =
          "All values identical; Shapiro-Wilk unavailable.",
        note = "Zero variance."
      )
    )
  }

  test_result <- tryCatch(
    shapiro.test(x),
    error = function(e) NULL
  )

  if (is.null(test_result)) {
    return(
      list(
        n = n,
        W = NA_real_,
        p_value = NA_real_,
        conclusion = "Shapiro-Wilk test failed.",
        note = ""
      )
    )
  }

  p_value <- test_result$p.value

  conclusion <- if (p_value > 0.05) {
    "Normality not rejected"
  } else {
    "Normality rejected"
  }

  return(
    list(
      n = n,
      W = unname(test_result$statistic),
      p_value = p_value,
      conclusion = conclusion,
      note = ""
    )
  )
}

# 判断Shapiro-Wilk检验是否通过
is_normal <- function(test_result) {

  !is.na(test_result$p_value) &&
    test_result$p_value > 0.05
}

# 对p值进行Holm校正
holm_adjust <- function(p_values) {

  result <- rep(NA_real_, length(p_values))
  valid <- !is.na(p_values)

  if (any(valid)) {
    result[valid] <- p.adjust(
      p_values[valid],
      method = "holm"
    )
  }

  return(result)
}

############################
# 八、建立结果列表
############################

correlation_list <- list()
normality_list <- list()
pitman_morgan_list <- list()
paired_t_list <- list()
levene_list <- list()
wilcoxon_list <- list()

############################
# 九、按Event进行分析
############################

for (i in seq_along(event_values)) {

  current_event <- event_values[i]

  event_data <- dat[
    dat$Event == current_event,
    ,
    drop = FALSE
  ]

  ##########################################################
  # A. 准备配对数据
  ##########################################################

  complete_pair <- is.finite(
    event_data$Background_log10_V
  ) &
    is.finite(event_data$During_log10_V)

  x <- event_data$Background_log10_V[complete_pair]
  y <- event_data$During_log10_V[complete_pair]

  difference <- y - x

  n_pairs <- length(x)

  ##########################################################
  # B. Pearson线性相关检验
  ##########################################################

  correlation_row <- data.frame(
    Event = current_event,
    n_pairs = n_pairs,
    correlation_coefficient_r = NA_real_,
    ci_low_95 = NA_real_,
    ci_high_95 = NA_real_,
    t_value = NA_real_,
    df = NA_real_,
    p_value = NA_real_,
    conclusion = "",
    note = "",
    stringsAsFactors = FALSE
  )

  if (n_pairs < 3) {

    correlation_row$conclusion <-
      "Fewer than 3 complete pairs; Pearson correlation unavailable."

  } else if (sd(x) == 0 || sd(y) == 0) {

    correlation_row$conclusion <-
      "Zero variance in at least one variable; correlation unavailable."

  } else {

    correlation_test <- tryCatch(
      cor.test(
        x = x,
        y = y,
        method = "pearson",
        conf.level = 0.95
      ),
      error = function(e) NULL
    )

    if (is.null(correlation_test)) {

      correlation_row$conclusion <-
        "Pearson correlation failed."

    } else {

      correlation_row$correlation_coefficient_r <-
        unname(correlation_test$estimate)

      correlation_row$ci_low_95 <-
        correlation_test$conf.int[1]

      correlation_row$ci_high_95 <-
        correlation_test$conf.int[2]

      correlation_row$t_value <-
        unname(correlation_test$statistic)

      correlation_row$df <-
        unname(correlation_test$parameter)

      correlation_row$p_value <-
        correlation_test$p.value

      correlation_row$conclusion <- if (
        correlation_test$p.value < 0.05
      ) {
        "Significant Background-During correlation (unadjusted p)"
      } else {
        "Background-During correlation not significant (unadjusted p)"
      }
    }
  }

  correlation_list[[i]] <- correlation_row

  ##########################################################
  # C. 四组数据的正态性检验
  ##########################################################

  background_normality <- safe_shapiro_test(
    event_data$Background_log10_V
  )

  during_normality <- safe_shapiro_test(
    event_data$During_log10_V
  )

  # 配对差值正态性，仅作为配对t检验的辅助诊断
  difference_normality <- safe_shapiro_test(
    difference
  )

  normality_list[[length(normality_list) + 1]] <-
    data.frame(
      Event = current_event,
      variable = "Background log10 V",
      n = background_normality$n,
      W = background_normality$W,
      p_value = background_normality$p_value,
      conclusion = background_normality$conclusion,
      note = background_normality$note,
      stringsAsFactors = FALSE
    )

  normality_list[[length(normality_list) + 1]] <-
    data.frame(
      Event = current_event,
      variable = "During log10 V",
      n = during_normality$n,
      W = during_normality$W,
      p_value = during_normality$p_value,
      conclusion = during_normality$conclusion,
      note = during_normality$note,
      stringsAsFactors = FALSE
    )

  normality_list[[length(normality_list) + 1]] <-
    data.frame(
      Event = current_event,
      variable = "Difference During - Background",
      n = difference_normality$n,
      W = difference_normality$W,
      p_value = difference_normality$p_value,
      conclusion = difference_normality$conclusion,
      note = "Normality of paired differences is reported as a diagnostic for the paired t-test.",
      stringsAsFactors = FALSE
    )

  ##########################################################
  # D. 判断两个变量是否都通过正态性检验
  ##########################################################

  both_groups_normal <-
    is_normal(background_normality) &&
    is_normal(during_normality)

  ##########################################################
  # E. 正态情况下：Pitman-Morgan配对方差检验
  ##########################################################

  pitman_row <- data.frame(
    Event = current_event,
    n_pairs = n_pairs,
    variance_background = NA_real_,
    variance_during = NA_real_,
    variance_ratio_background_over_during = NA_real_,
    statistic = NA_real_,
    df = NA_character_,
    p_value = NA_real_,
    conclusion = "",
    note = "",
    stringsAsFactors = FALSE
  )

  if (!both_groups_normal) {

    pitman_row$conclusion <-
      "Not performed: marginal normality checks did not both pass."

  } else if (n_pairs < 3) {

    pitman_row$conclusion <-
      "Not performed: fewer than 3 complete pairs."

  } else if (sd(x) == 0 || sd(y) == 0) {

    pitman_row$conclusion <-
      "Unavailable: zero variance in at least one variable."

  } else {

    pitman_test <- tryCatch(
      PairedData::Var.test(
        x = x,
        y = y,
        paired = TRUE,
        alternative = "two.sided",
        conf.level = 0.95
      ),
      error = function(e) NULL
    )

    if (is.null(pitman_test)) {

      pitman_row$conclusion <-
        "Pitman-Morgan test failed."

    } else {

      pitman_row$variance_background <- var(x)
      pitman_row$variance_during <- var(y)

      pitman_row$variance_ratio_background_over_during <-
        var(x) / var(y)

      pitman_row$statistic <-
        unname(pitman_test$statistic)

      if (!is.null(pitman_test$parameter)) {
        pitman_row$df <-
          paste(
            unname(pitman_test$parameter),
            collapse = ", "
          )
      }

      pitman_row$p_value <-
        pitman_test$p.value

      pitman_row$conclusion <- if (
        pitman_test$p.value < 0.05
      ) {
        "Significant paired variance difference (unadjusted p)"
      } else {
        "Paired variance difference not significant (unadjusted p)"
      }

      pitman_row$note <-
        "Null: Background and During population variances are equal."
    }
  }

  pitman_morgan_list[[i]] <- pitman_row

  ##########################################################
  # F. 正态情况下：配对样本t检验
  ##########################################################

  paired_t_row <- data.frame(
    Event = current_event,
    n_pairs = n_pairs,
    mean_background =
      if (n_pairs > 0) mean(x) else NA_real_,
    mean_during =
      if (n_pairs > 0) mean(y) else NA_real_,
    mean_difference_During_minus_Background =
      if (n_pairs > 0) mean(difference) else NA_real_,
    difference_normality_p =
      difference_normality$p_value,
    t_value = NA_real_,
    df = NA_real_,
    ci_low_95 = NA_real_,
    ci_high_95 = NA_real_,
    p_value = NA_real_,
    conclusion = "",
    note = "",
    stringsAsFactors = FALSE
  )

  if (!both_groups_normal) {

    paired_t_row$conclusion <-
      "Not performed: marginal normality checks did not both pass."

  } else if (n_pairs < 2) {

    paired_t_row$conclusion <-
      "Not performed: fewer than 2 complete pairs."

  } else {

    paired_t_test <- tryCatch(
      t.test(
        x = y,
        y = x,
        paired = TRUE,
        conf.level = 0.95
      ),
      error = function(e) NULL
    )

    if (is.null(paired_t_test)) {

      paired_t_row$conclusion <-
        "Paired t-test failed."

    } else {

      paired_t_row$t_value <-
        unname(paired_t_test$statistic)

      paired_t_row$df <-
        unname(paired_t_test$parameter)

      paired_t_row$ci_low_95 <-
        paired_t_test$conf.int[1]

      paired_t_row$ci_high_95 <-
        paired_t_test$conf.int[2]

      paired_t_row$p_value <-
        paired_t_test$p.value

      paired_t_row$conclusion <- if (
        paired_t_test$p.value < 0.05
      ) {
        "Significant Background-During mean difference (unadjusted p)"
      } else {
        "Background-During mean difference not significant (unadjusted p)"
      }

      if (
        !is.na(difference_normality$p_value) &&
        difference_normality$p_value <= 0.05
      ) {
        paired_t_row$note <-
          "Normality of paired differences rejected; interpret t-test cautiously."
      } else {
        paired_t_row$note <-
          "Mean difference: During log10 V minus Background log10 V."
      }
    }
  }

  paired_t_list[[i]] <- paired_t_row

  ##########################################################
  # G. 非正态情况下：Levene方差检验
  ##########################################################

  levene_row <- data.frame(
    Event = current_event,
    n_pairs = n_pairs,
    F_value = NA_real_,
    df1 = NA_real_,
    df2 = NA_real_,
    p_value = NA_real_,
    conclusion = "",
    note = "",
    stringsAsFactors = FALSE
  )

  if (both_groups_normal) {

    levene_row$conclusion <-
      "Not performed: both marginal normality checks passed; using Pitman-Morgan."

  } else if (n_pairs < 2) {

    levene_row$conclusion <-
      "Not performed: fewer than 2 complete pairs."

  } else {

    levene_data <- data.frame(
      value = c(x, y),
      condition = factor(
        c(
          rep("Background", length(x)),
          rep("During", length(y))
        )
      )
    )

    levene_test <- tryCatch(
      car::leveneTest(
        value ~ condition,
        data = levene_data,
        center = median
      ),
      error = function(e) NULL
    )

    if (is.null(levene_test)) {

      levene_row$conclusion <-
        "Levene test failed."

    } else {

      levene_row$F_value <-
        as.numeric(levene_test[1, "F value"])

      levene_row$df1 <-
        as.numeric(levene_test[1, "Df"])

      levene_row$df2 <-
        as.numeric(levene_test[2, "Df"])

      levene_row$p_value <-
        as.numeric(levene_test[1, "Pr(>F)"])

      levene_row$conclusion <- if (
        levene_row$p_value < 0.05
      ) {
        "Significant variance difference (unadjusted p)"
      } else {
        "Variance difference not significant (unadjusted p)"
      }

      levene_row$note <-
        "Median-centered Levene test; original implementation does not model pairing."
    }
  }

  levene_list[[i]] <- levene_row

  ##########################################################
  # H. 非正态情况下：配对Wilcoxon符号秩检验
  ##########################################################

  wilcoxon_row <- data.frame(
    Event = current_event,
    n_pairs = n_pairs,
    mean_background =
      if (n_pairs > 0) mean(x) else NA_real_,
    mean_during =
      if (n_pairs > 0) mean(y) else NA_real_,
    median_background =
      if (n_pairs > 0) median(x) else NA_real_,
    median_during =
      if (n_pairs > 0) median(y) else NA_real_,
    V_statistic = NA_real_,
    p_value = NA_real_,
    conclusion = "",
    note = "",
    stringsAsFactors = FALSE
  )

  if (both_groups_normal) {

    wilcoxon_row$conclusion <-
      "Not performed: both marginal normality checks passed; using paired t-test."

  } else if (n_pairs < 2) {

    wilcoxon_row$conclusion <-
      "Not performed: fewer than 2 complete pairs."

  } else if (all(difference == 0)) {

    wilcoxon_row$conclusion <-
      "All paired differences are zero; Wilcoxon not performed by original rule."

  } else {

    wilcoxon_test <- tryCatch(
      wilcox.test(
        x = y,
        y = x,
        paired = TRUE,
        alternative = "two.sided",
        exact = FALSE,
        conf.int = TRUE,
        conf.level = 0.95
      ),
      error = function(e) NULL
    )

    if (is.null(wilcoxon_test)) {

      wilcoxon_row$conclusion <-
        "Paired Wilcoxon test failed."

    } else {

      wilcoxon_row$V_statistic <-
        unname(wilcoxon_test$statistic)

      wilcoxon_row$p_value <-
        wilcoxon_test$p.value

      wilcoxon_row$conclusion <- if (
        wilcoxon_test$p.value < 0.05
      ) {
        "Significant paired location difference (unadjusted p)"
      } else {
        "Paired location difference not significant (unadjusted p)"
      }

      wilcoxon_row$note <-
        paste(
          "Wilcoxon is not a test of mean differences; ",
          "it assesses the location of paired differences."
        )
    }
  }

  wilcoxon_list[[i]] <- wilcoxon_row
}

############################
# 十、合并结果
############################

correlation_results <- do.call(
  rbind,
  correlation_list
)

normality_results <- do.call(
  rbind,
  normality_list
)

pitman_morgan_results <- do.call(
  rbind,
  pitman_morgan_list
)

paired_t_results <- do.call(
  rbind,
  paired_t_list
)

levene_results <- do.call(
  rbind,
  levene_list
)

wilcoxon_results <- do.call(
  rbind,
  wilcoxon_list
)

############################
# 十一、进行Holm多重比较校正
############################

correlation_results$p_adjusted_Holm <-
  holm_adjust(correlation_results$p_value)

pitman_morgan_results$p_adjusted_Holm <-
  holm_adjust(pitman_morgan_results$p_value)

paired_t_results$p_adjusted_Holm <-
  holm_adjust(paired_t_results$p_value)

levene_results$p_adjusted_Holm <-
  holm_adjust(levene_results$p_value)

wilcoxon_results$p_adjusted_Holm <-
  holm_adjust(wilcoxon_results$p_value)

############################
# 十二、整理实际使用的数据
############################

data_used <- data.frame(
  Event = dat$Event,
  Genus = dat$Genus,
  `Background log10 V` = dat$Background_log10_V,
  `During log10 V` = dat$During_log10_V,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

############################
# 十三、输出到Excel
############################

write.xlsx(
  x = list(
    Pearson_correlation = correlation_results,
    Normality_Shapiro = normality_results,
    Pitman_Morgan = pitman_morgan_results,
    Paired_t_test = paired_t_results,
    Levene_test = levene_results,
    Wilcoxon_paired = wilcoxon_results,
    Data_used = data_used
  ),
  file = output_file,
  overwrite = TRUE
)

############################
# 十四、输出完成信息
############################

cat("\nAnalysis completed.\n")
cat("Results written to:\n")
cat(output_file, "\n\n")

cat("Output sheets:\n")
cat("1. Pearson_correlation\n")
cat("2. Normality_Shapiro\n")
cat("3. Pitman_Morgan\n")
cat("4. Paired_t_test\n")
cat("5. Levene_test\n")
cat("6. Wilcoxon_paired\n")
cat("7. Data_used\n")


writeLines(capture.output(sessionInfo()), file.path(output_dir, "sessionInfo.txt"))
