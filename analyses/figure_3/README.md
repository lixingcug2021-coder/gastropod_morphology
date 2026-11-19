# Figure 3 — paired shell-size analysis

## Files

- `data.xlsx`: byte-identical original workbook with a standardized filename; the first sheet is read.
- `data.csv`: CSV export for reuse.
- `analysis.R`: portable R script with translated result labels; original calculations and Chinese inline comments retained.

## Data and methods

28 rows: ETAE 11, PTAE 17. Each row contains paired log10 V values; analysis is grouped by Event.

Pearson; marginal/difference Shapiro-Wilk; conditional Pitman-Morgan and paired t-tests, or Levene and paired Wilcoxon. Holm adjustment is within each implemented test family.

Mean-difference direction: **During minus Background**. See [the data dictionary](../../docs/DATA_DICTIONARY.md) for exact input column names and unresolved variable definitions.

## Run

From the repository root, after installing dependencies:

```r
source("analyses/figure_3/analysis.R", encoding = "UTF-8")
```

Outputs: `results/figure_3/results.xlsx` and `sessionInfo.txt`. Workbook sheets: Pearson_correlation, Normality_Shapiro, Pitman_Morgan, Paired_t_test, Levene_test, Wilcoxon_paired, Data_used.

`source("run_all.R", encoding = "UTF-8")` runs all four modules and also generates CSV copies of result worksheets.

## Author checks

Define V, its original units and aggregation. The Levene implementation does not model paired dependence; review docs/STATISTICAL_NOTES.md.

See [STATISTICAL_NOTES.md](../../docs/STATISTICAL_NOTES.md) and [AUTHOR_CHECKLIST.md](../../docs/AUTHOR_CHECKLIST.md). Generated tables support the analysis associated with the named figure; these scripts do not reconstruct the finished figure layout.

