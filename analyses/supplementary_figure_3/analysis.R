# supplementary_figure_3: portable entry point. Run from the repository root.
# Statistical calculations and decision rules are preserved from the supplied script.
# See README.md and docs/STATISTICAL_NOTES.md before interpreting outputs.
source("scripts/init.R", local = TRUE, encoding = "UTF-8")
analysis_id <- "supplementary_figure_3"
analysis_dir <- file.path(repo_dir, "analyses", analysis_id)
output_dir <- file.path(repo_dir, "results", analysis_id)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
check_packages(c("readxl", "openxlsx", "PairedData"))

############################################################
# Event × Background facies 分组分析
#
# 输出：
# 1. Pearson相关分析
# 2. Shapiro-Wilk正态性检验
# 3. Pitman-Morgan配对方差检验
# 4. 配对样本t检验
############################################################

############################
# 1. 安装并加载R包
############################

library(readxl)
library(openxlsx)

############################
# 2. 设置文件路径
############################

input_file <- file.path(analysis_dir, "data.xlsx")

output_file <- file.path(output_dir, "results.xlsx")

if (!file.exists(input_file)) {
  stop("Input file not found; check path: ", input_file)
}

############################
# 3. 读取并检查表头
############################

raw <- read_excel(input_file, .name_repair = "minimal")
names(raw) <- trimws(names(raw))

required_columns <- c(
  "Event",
  "Background facies",
  "Genus",
  "Background_aspect_ratio",
  "During_aspect_ratio"
)

missing_columns <- setdiff(required_columns, names(raw))

if (length(missing_columns) > 0) {
  stop(
    "Missing Excel columns: ",
    paste(missing_columns, collapse = ", "),
    "\nCheck spelling and spaces in column names."
  )
}

############################
# 4. 整理数据
############################

clean_text <- function(x) {
  x <- trimws(as.character(x))
  x[x == ""] <- NA_character_
  x
}

to_numeric <- function(x) {
  if (is.numeric(x)) {
    return(as.numeric(x))
  }

  x <- trimws(as.character(x))
  x[x == ""] <- NA_character_
  suppressWarnings(as.numeric(x))
}

dat <- data.frame(
  Event = clean_text(raw[["Event"]]),
  Background_facies = clean_text(raw[["Background facies"]]),
  Genus = clean_text(raw[["Genus"]]),
  Background_aspect_ratio =
    to_numeric(raw[["Background_aspect_ratio"]]),
  During_aspect_ratio =
    to_numeric(raw[["During_aspect_ratio"]]),
  stringsAsFactors = FALSE
)

# 移除没有Event或facies标签的行
dat <- dat[
  !is.na(dat$Event) &
    !is.na(dat$Background_facies),
  ,
  drop = FALSE
]

if (nrow(dat) == 0) {
  stop("No analyzable rows.")
}

# 检查实际分组数量
group_keys <- unique(dat[, c("Event", "Background_facies")])

if (length(unique(dat$Event)) != 2 ||
    nrow(group_keys) != 4) {
  warning(
    "The input differs from the original expectation of two events and four Event x facies groups; ",
    "all observed groups will be analyzed."
  )
}

############################
# 5. 定义正态性检验函数
############################

safe_shapiro <- function(x) {
  x <- x[is.finite(x)]
  n <- length(x)

  if (n < 3) {
    return(list(
      n = n,
      W = NA_real_,
      p_value = NA_real_,
      conclusion = "Fewer than 3 observations; test unavailable."
    ))
  }

  if (n > 5000) {
    return(list(
      n = n,
      W = NA_real_,
      p_value = NA_real_,
      conclusion = "More than 5000 observations; test not performed."
    ))
  }

  if (length(unique(x)) < 2) {
    return(list(
      n = n,
      W = NA_real_,
      p_value = NA_real_,
      conclusion = "Zero variance; test unavailable."
    ))
  }

  test <- tryCatch(
    shapiro.test(x),
    error = function(e) NULL
  )

  if (is.null(test)) {
    return(list(
      n = n,
      W = NA_real_,
      p_value = NA_real_,
      conclusion = "Test failed."
    ))
  }

  list(
    n = n,
    W = unname(test$statistic),
    p_value = test$p.value,
    conclusion = if (test$p.value > 0.05) {
      "Normality not rejected"
    } else {
      "Normality rejected"
    }
  )
}

passed_normality <- function(result) {
  !is.na(result$p_value) && result$p_value > 0.05
}

############################
# 6. 定义结果表
############################

correlation_rows <- list()
normality_rows <- list()
pitman_rows <- list()
paired_t_rows <- list()

############################
# 7. 对每个Event × Background facies分析
############################

for (i in seq_len(nrow(group_keys))) {

  event_i <- group_keys$Event[i]
  facies_i <- group_keys$Background_facies[i]

  g <- dat[
    dat$Event == event_i &
      dat$Background_facies == facies_i,
    ,
    drop = FALSE
  ]

  # 各变量分别进行正态性检验
  normal_background <- safe_shapiro(
    g$Background_aspect_ratio
  )

  normal_during <- safe_shapiro(
    g$During_aspect_ratio
  )

  # 配对分析仅使用两列均为有限数值的完整配对
  pair_ok <- is.finite(g$Background_aspect_ratio) &
    is.finite(g$During_aspect_ratio)

  x <- g$Background_aspect_ratio[pair_ok]
  y <- g$During_aspect_ratio[pair_ok]
  difference <- y - x
  n_pairs <- length(x)

  # 额外检查配对差值的正态性，供配对t检验假设判断
  normal_difference <- safe_shapiro(difference)

  # 保存正态性检验结果
  normality_rows[[length(normality_rows) + 1]] <-
    data.frame(
      Event = event_i,
      Background_facies = facies_i,
      variable = "Background_aspect_ratio",
      n = normal_background$n,
      W = normal_background$W,
      p_value = normal_background$p_value,
      conclusion = normal_background$conclusion,
      stringsAsFactors = FALSE
    )

  normality_rows[[length(normality_rows) + 1]] <-
    data.frame(
      Event = event_i,
      Background_facies = facies_i,
      variable = "During_aspect_ratio",
      n = normal_during$n,
      W = normal_during$W,
      p_value = normal_during$p_value,
      conclusion = normal_during$conclusion,
      stringsAsFactors = FALSE
    )

  normality_rows[[length(normality_rows) + 1]] <-
    data.frame(
      Event = event_i,
      Background_facies = facies_i,
      variable = "Difference_During_minus_Background",
      n = normal_difference$n,
      W = normal_difference$W,
      p_value = normal_difference$p_value,
      conclusion = normal_difference$conclusion,
      stringsAsFactors = FALSE
    )

  ##########################
  # Pearson相关检验
  ##########################

  cor_row <- data.frame(
    Event = event_i,
    Background_facies = facies_i,
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
    cor_row$conclusion <-
      "Fewer than 3 complete pairs; Pearson correlation unavailable."

  } else if (sd(x) == 0 || sd(y) == 0) {
    cor_row$conclusion <-
      "Zero variance in at least one variable; correlation unavailable."

  } else {
    cor_test <- tryCatch(
      cor.test(x, y, method = "pearson", conf.level = 0.95),
      error = function(e) NULL
    )

    if (is.null(cor_test)) {
      cor_row$conclusion <- "Pearson correlation failed."
    } else {
      cor_row$correlation_coefficient_r <-
        unname(cor_test$estimate)

      if (!is.null(cor_test$conf.int) &&
          length(cor_test$conf.int) == 2) {
        cor_row$ci_low_95 <- cor_test$conf.int[1]
        cor_row$ci_high_95 <- cor_test$conf.int[2]
      }

      cor_row$t_value <- unname(cor_test$statistic)
      cor_row$df <- unname(cor_test$parameter)
      cor_row$p_value <- cor_test$p.value

      cor_row$conclusion <- if (cor_test$p.value < 0.05) {
        "Significant linear correlation (unadjusted p)"
      } else {
        "Linear correlation not significant (unadjusted p)"
      }
    }
  }

  correlation_rows[[i]] <- cor_row

  ##########################
  # 判断两列数据是否都通过正态性检验
  ##########################

  both_marginal_normal <-
    passed_normality(normal_background) &&
    passed_normality(normal_during)

  ##########################
  # Pitman-Morgan配对方差检验
  ##########################

  pm_row <- data.frame(
    Event = event_i,
    Background_facies = facies_i,
    n_pairs = n_pairs,
    variance_background = NA_real_,
    variance_during = NA_real_,
    variance_ratio_background_over_during = NA_real_,
    ratio_ci_low_95 = NA_real_,
    ratio_ci_high_95 = NA_real_,
    statistic_t = NA_real_,
    df = NA_real_,
    p_value = NA_real_,
    conclusion = "",
    note = "",
    stringsAsFactors = FALSE
  )

  if (!both_marginal_normal) {
    pm_row$conclusion <-
      "Not performed: marginal normality checks did not both pass."

  } else if (n_pairs < 3) {
    pm_row$conclusion <-
      "Not performed: fewer than 3 complete pairs."

  } else {
    pm_test <- tryCatch(
      PairedData::Var.test(
        x = x,
        y = y,
        paired = TRUE,
        alternative = "two.sided",
        conf.level = 0.95
      ),
      error = function(e) NULL
    )

    if (is.null(pm_test) || is.na(pm_test$p.value)) {
      pm_row$conclusion <- "Pitman-Morgan test failed."

    } else {
      pm_row$variance_background <- var(x)
      pm_row$variance_during <- var(y)
      pm_row$variance_ratio_background_over_during <-
        var(x) / var(y)

      if (!is.null(pm_test$conf.int) &&
          length(pm_test$conf.int) == 2) {
        pm_row$ratio_ci_low_95 <- pm_test$conf.int[1]
        pm_row$ratio_ci_high_95 <- pm_test$conf.int[2]
      }

      pm_row$statistic_t <- unname(pm_test$statistic)
      pm_row$df <- unname(pm_test$parameter)
      pm_row$p_value <- pm_test$p.value

      pm_row$conclusion <- if (pm_test$p.value < 0.05) {
        "Significant paired variance difference (unadjusted p)"
      } else {
        "Paired variance difference not significant (unadjusted p)"
      }

      pm_row$note <-
        "Null: Background and During population variances are equal."
    }
  }

  pitman_rows[[i]] <- pm_row

  ##########################
  # 配对样本t检验
  ##########################

  t_row <- data.frame(
    Event = event_i,
    Background_facies = facies_i,
    n_pairs = n_pairs,
    mean_background = if (length(x) > 0) mean(x) else NA_real_,
    mean_during = if (length(y) > 0) mean(y) else NA_real_,
    mean_difference_During_minus_Background =
      if (length(difference) > 0) mean(difference) else NA_real_,
    difference_normality_p = normal_difference$p_value,
    difference_normality_conclusion =
      normal_difference$conclusion,
    ci_low_95 = NA_real_,
    ci_high_95 = NA_real_,
    t_value = NA_real_,
    df = NA_real_,
    p_value = NA_real_,
    conclusion = "",
    note = "",
    stringsAsFactors = FALSE
  )

  if (!both_marginal_normal) {
    t_row$conclusion <-
      "Not performed: marginal normality checks did not both pass."

  } else if (n_pairs < 2) {
    t_row$conclusion <-
      "Not performed: fewer than 2 complete pairs."

  } else {
    t_test <- tryCatch(
      t.test(
        x = y,
        y = x,
        paired = TRUE,
        conf.level = 0.95
      ),
      error = function(e) NULL
    )

    if (is.null(t_test)) {
      t_row$conclusion <- "Paired t-test failed."

    } else {
      t_row$ci_low_95 <- t_test$conf.int[1]
      t_row$ci_high_95 <- t_test$conf.int[2]
      t_row$t_value <- unname(t_test$statistic)
      t_row$df <- unname(t_test$parameter)
      t_row$p_value <- t_test$p.value

      t_row$conclusion <- if (t_test$p.value < 0.05) {
        "Significant Background-During mean difference (unadjusted p)"
      } else {
        "Background-During mean difference not significant (unadjusted p)"
      }

      if (is.na(normal_difference$p_value)) {
        t_row$note <-
          "Performed using marginal normality rule; normality of differences not assessable."
      } else if (normal_difference$p_value <= 0.05) {
        t_row$note <-
          "Normality of paired differences rejected; interpret t-test cautiously."
      } else {
        t_row$note <-
          "Normality of paired differences not rejected."
      }
    }
  }

  paired_t_rows[[i]] <- t_row
}

############################
# 8. 合并结果并进行Holm校正
############################

correlation_results <- do.call(rbind, correlation_rows)
normality_results <- do.call(rbind, normality_rows)
pitman_morgan_results <- do.call(rbind, pitman_rows)
paired_t_results <- do.call(rbind, paired_t_rows)

adjust_holm <- function(p) {
  result <- rep(NA_real_, length(p))
  valid <- !is.na(p)
  result[valid] <- p.adjust(p[valid], method = "holm")
  result
}

correlation_results$p_adjusted_Holm <-
  adjust_holm(correlation_results$p_value)

pitman_morgan_results$p_adjusted_Holm <-
  adjust_holm(pitman_morgan_results$p_value)

paired_t_results$p_adjusted_Holm <-
  adjust_holm(paired_t_results$p_value)

############################
# 9. 输出结果到Excel
############################

analysis_data <- data.frame(
  Event = dat$Event,
  `Background facies` = dat$Background_facies,
  Genus = dat$Genus,
  Background_aspect_ratio = dat$Background_aspect_ratio,
  During_aspect_ratio = dat$During_aspect_ratio,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

write.xlsx(
  list(
    Pearson_correlation = correlation_results,
    Normality_Shapiro = normality_results,
    Pitman_Morgan = pitman_morgan_results,
    Paired_t_test = paired_t_results,
    Data_used = analysis_data
  ),
  file = output_file,
  overwrite = TRUE
)

cat("Analysis completed. Results written to:\n", output_file, "\n")


writeLines(capture.output(sessionInfo()), file.path(output_dir, "sessionInfo.txt"))
