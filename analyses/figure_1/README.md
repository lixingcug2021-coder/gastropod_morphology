# Figure 1 — paired shell aspect-ratio analysis

## Files

- `data.xlsx`: byte-identical original workbook with a standardized filename; the first sheet is read.
- `data.csv`: CSV export for reuse.
- `analysis.R`: portable R script with translated result labels; original calculations and Chinese inline comments retained.

## Data and methods

28 rows: ETAE 11, PTAE 17. Pairing is by Event + Genus; duplicate keys would be averaged.

Pearson correlation; marginal Shapiro-Wilk tests; conditional Pitman-Morgan and paired t-tests. No multiple-testing adjustment.

Mean-difference direction: **Background minus During**. See [the data dictionary](../../docs/DATA_DICTIONARY.md) for exact input column names and unresolved variable definitions.

## Run

From the repository root, after installing dependencies:

```r
source("analyses/figure_1/analysis.R", encoding = "UTF-8")
```

Outputs: `results/figure_1/results.xlsx` and `sessionInfo.txt`. Workbook sheets: Normality, Pearson_Correlation, Pitman_Morgan, Paired_t_test, Paired_Data.

`source("run_all.R", encoding = "UTF-8")` runs all four modules and also generates CSV copies of result worksheets.

## Author checks

A diagnostic Q-Q image, aspect_ratio_qq.png, is also generated. Input values include negatives; their transformation must be specified by the authors.

See [STATISTICAL_NOTES.md](../../docs/STATISTICAL_NOTES.md) and [AUTHOR_CHECKLIST.md](../../docs/AUTHOR_CHECKLIST.md). Generated tables support the analysis associated with the named figure; these scripts do not reconstruct the finished figure layout.

