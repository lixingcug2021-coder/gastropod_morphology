# Packaging change log

## Prepared submission package — 2026-11-19

- Converted the four supplied code text files to UTF-8 `.R` entry points.
- Placed each code/data pair under an explicit manuscript-figure folder.
- Preserved all four Excel input files byte-for-byte; retained original sheet and column names.
- Replaced personal absolute input/output paths with paths relative to the repository root.
- Separated package installation into an explicit setup script; normal runs only check dependencies.
- Added `run_all.R`, an RStudio project, CSV exports, package-version records and session records.
- Translated output messages and result labels into English, including string comparisons used by the original normality branches. Original Chinese inline comments remain.
- Clarified that existing significance labels use raw p-values and that the Levene implementation does not model pairing. These wording changes do not alter numerical calculations.
- Renamed Figure 1 output files to `results.xlsx` and `aspect_ratio_qq.png`.
- Included generated results and verified numerical equivalence for all 21 result worksheets.
- Added data dictionaries, pairing/group summaries, provenance, submission-statement templates and author checks.

Preserved: data values, original calculation formulas, aggregation/filtering, test-selection branches, confidence levels, difference directions, p-value adjustment scopes, and Figure 1's eight-decimal output rounding. No new scientific analysis or figure-layout reconstruction was introduced.
