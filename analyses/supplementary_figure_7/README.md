# Supplementary Figure 7 — taxonomic-category analysis

## Files

- `data.xlsx`: byte-identical original workbook with a standardized filename; the first sheet is read.
- `data.csv`: CSV export for reuse.
- `analysis.R`: portable R script with translated result labels; original calculations and Chinese inline comments retained.

## Data and methods

28 rows: ETAE 11, PTAE 17. Six observed Event x Classification groups; pairing is within rows.

Shapiro-Wilk for both periods and their difference; paired t-tests and approximate paired Wilcoxon tests. Holm adjustment is within each test family; normality adjustments are by variable.

Mean-difference direction: **During minus Background**. See [the data dictionary](../../docs/DATA_DICTIONARY.md) for exact input column names and unresolved variable definitions.

## Run

From the repository root, after installing dependencies:

```r
source("analyses/supplementary_figure_7/analysis.R", encoding = "UTF-8")
```

Outputs: `results/supplementary_figure_7/results.xlsx` and `sessionInfo.txt`. Workbook sheets: Normality_tests, Paired_t_tests, Wilcoxon_tests, Paired_data_used.

`source("run_all.R", encoding = "UTF-8")` runs all four modules and also generates CSV copies of result worksheets.

## Author checks

The input has no Genus column. Supply a verified record mapping. ETAE / Archaeobranchia has one pair; review the limitations of its approximate Wilcoxon result.

See [STATISTICAL_NOTES.md](../../docs/STATISTICAL_NOTES.md) and [AUTHOR_CHECKLIST.md](../../docs/AUTHOR_CHECKLIST.md). Generated tables support the analysis associated with the named figure; these scripts do not reconstruct the finished figure layout.

