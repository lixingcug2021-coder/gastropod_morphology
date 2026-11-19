# Supplementary Figure 3 — background-facies analysis

## Files

- `data.xlsx`: byte-identical original workbook with a standardized filename; the first sheet is read.
- `data.csv`: CSV export for reuse.
- `analysis.R`: portable R script with translated result labels; original calculations and Chinese inline comments retained.

## Data and methods

27 rows: ETAE 11, PTAE 16. Six observed Event x Background facies groups are analyzed, preserving within-row pairing.

Pearson; marginal/difference Shapiro-Wilk; conditional Pitman-Morgan and paired t-tests. Holm adjustments are calculated separately for correlation, variance and mean tests.

Mean-difference direction: **During minus Background**. See [the data dictionary](../../docs/DATA_DICTIONARY.md) for exact input column names and unresolved variable definitions.

## Run

From the repository root, after installing dependencies:

```r
source("analyses/supplementary_figure_3/analysis.R", encoding = "UTF-8")
```

Outputs: `results/supplementary_figure_3/results.xlsx` and `sessionInfo.txt`. Workbook sheets: Pearson_correlation, Normality_Shapiro, Pitman_Morgan, Paired_t_test, Data_used.

`source("run_all.R", encoding = "UTF-8")` runs all four modules and also generates CSV copies of result worksheets.

## Author checks

PTAE / Araeonema is absent relative to Figure 1. The original script warns about six rather than four groups but analyzes all six. Two groups have n = 2.

See [STATISTICAL_NOTES.md](../../docs/STATISTICAL_NOTES.md) and [AUTHOR_CHECKLIST.md](../../docs/AUTHOR_CHECKLIST.md). Generated tables support the analysis associated with the named figure; these scripts do not reconstruct the finished figure layout.

