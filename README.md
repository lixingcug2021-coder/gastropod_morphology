# Gastropod morphology: paired analyses

Analysis code and supplied input datasets associated with Figure 1, Figure 3, Supplementary Figure 3 and Supplementary Figure 7 of a manuscript being prepared for submission to *Nature Communications*.

**Status:** the four analyses have been executed and checked against the supplied scripts. Author metadata, variable definitions and the items in [the author checklist](docs/AUTHOR_CHECKLIST.md) still require completion before a public submission release. This repository covers these four analyses only; it does not establish that the complete manuscript's data and code have been provided.

## Analysis map

| Manuscript item | Folder | Analysis | Input rows |
| --- | --- | --- | ---: |
| Figure 1 | `analyses/figure_1/` | Paired aspect-ratio values by Event | 28 |
| Figure 3 | `analyses/figure_3/` | Paired log10 V values by Event | 28 |
| Supplementary Figure 3 | `analyses/supplementary_figure_3/` | Paired aspect-ratio values by Event and background facies | 27 |
| Supplementary Figure 7 | `analyses/supplementary_figure_7/` | Paired aspect-ratio values by Event and Classification | 28 |

Each analysis folder contains `analysis.R`, the original input workbook renamed to `data.xlsx`, a CSV copy, and a short README. Excel bytes and all input column names were preserved. Scripts read the first Excel worksheet (`Sheet1`). CSV copies are supplied for inspection and reuse; the scripts read Excel.

The scripts reproduce statistical analyses and tables. They do **not** recreate the finished manuscript figure layouts. Figure 1 additionally generates a diagnostic Q-Q plot.

## Requirements and installation

- R; validated on R 4.5.1, Windows, 64-bit.
- RStudio is optional and convenient for opening `gastropod_morphology.Rproj`.
- Required packages: `readxl`, `dplyr`, `tidyr`, `openxlsx`, `purrr`, `PairedData`, `car`.
- No GPU, parallel processing or specialized hardware is needed. macOS/Linux were not tested.
- Exact installed package versions, including dependencies, are recorded in [package_versions.csv](docs/package_versions.csv). Several installed packages were built under R 4.5.3 and emitted build-version warnings on R 4.5.1; execution completed.

Open `gastropod_morphology.Rproj` in RStudio. In a fresh R session, install missing dependencies once:

```r
source("scripts/install_packages.R")
```

Installation requires Internet access and may take several minutes or longer. This helper installs available CRAN versions; it is not a version-locked restore operation. Installation time was not measured because the validation machine already had the dependencies.

## Run the supplied analyses

From the repository root, run:

```r
source("run_all.R", encoding = "UTF-8")
```

Or, in a terminal whose current directory is the repository root:

```sh
Rscript --vanilla run_all.R
```

Run a single analysis with, for example:

```r
source("analyses/figure_1/analysis.R", encoding = "UTF-8")
```

Results are written to `results/<analysis_id>/`. Rerunning replaces generated outputs in that folder, leaving the input datasets unchanged. `run_all.R` also refreshes the CSV copies. Each module records its R session in `sessionInfo.txt`.

The four analyses together took approximately 3.55 seconds in a validation rerun with dependencies installed. Runtime is hardware dependent. No Monte Carlo or random sampling is used, so no seed or iteration setting is required.

If a Windows session reports an invalid `C.UTF-8` locale or cannot read a path containing Chinese characters, restart R/RStudio with its normal Windows locale or unzip the repository to an ASCII-only path. The validation run used `English_United States.utf8`.

## Expected outputs and validation

Completed example outputs are included under `results/`:

- Four `results.xlsx` workbooks, comprising 21 worksheets in total.
- CSV copies of every result worksheet; Figure 1 also retains its original CSV outputs.
- `results/figure_1/aspect_ratio_qq.png`.
- Session records for each module.

All numeric/logical worksheet values, shapes and missing-value patterns matched the supplied-script baseline exactly; see [VALIDATION.md](docs/VALIDATION.md) and [numerical_equivalence.csv](docs/numerical_equivalence.csv). The baseline used the supplied scripts with only paths and dependency setup adjusted for execution.

This check confirms preservation of the supplied calculations. The manuscript and final figure values were not provided, so agreement with the published/submitted figures has not been verified.

## Data interpretation

Read [DATA_DICTIONARY.md](docs/DATA_DICTIONARY.md) for columns, group sizes, pairing and unresolved metadata. In particular, aspect-ratio-labelled values include negatives; their transformation has not been specified. Do not interpret them as untransformed height/width ratios without author confirmation.

Figure 1 reports mean differences as **Background minus During**. The other three analyses report them as **During minus Background**. Variance ratios are Background divided by During. These original conventions were retained.

The statistical decisions, normality gating, multiple-testing rules and small-sample behavior are described in [STATISTICAL_NOTES.md](docs/STATISTICAL_NOTES.md). Translated significance labels explicitly refer to unadjusted p-values; where present, `p_adjusted_Holm` must be interpreted separately.

## Reuse with other data

Retain the exact column names documented for the relevant module. Each row must contain the intended matched Background and During values. Figure 1 averages duplicate Event + Genus keys; the other modules do not perform that aggregation. New categories are not automatically supported by every module: Figure 1 retains only `PTAE` and `ETAE`. Review the filtering and small-sample rules before supplying another dataset.

## Data and code availability, citation and licensing

Before release, complete [AUTHOR_CHECKLIST.md](docs/AUTHOR_CHECKLIST.md), fill the separate [availability-statement templates](docs/AVAILABILITY_STATEMENTS.md), and replace the example citation fields in `docs/CITATION.cff.example`. Move the completed citation file to the repository root as `CITATION.cff`.

No reuse license has been assigned on the authors' behalf. License choices and rights to redistribute third-party data must be confirmed; see [LICENSE_OPTIONS.md](docs/LICENSE_OPTIONS.md). Do not describe this draft as open-source until the relevant license is supplied.

Use a public release archived in a DOI-minting repository for a stable publication citation. The GitHub repository URL, release DOI, article title, author list and contact details remain to be supplied by the authors.

## Documentation

- [CHANGELOG.md](CHANGELOG.md): packaging changes and preserved behavior.
- [INPUT_MANIFEST.json](docs/INPUT_MANIFEST.json): source filenames and SHA-256 checksums.
- [NATURE_COMMUNICATIONS.md](docs/NATURE_COMMUNICATIONS.md): submission-specific guidance and official policy links.

Original Chinese explanatory comments are retained in the R scripts for traceability. The README files, output labels and submission documentation are in English.
