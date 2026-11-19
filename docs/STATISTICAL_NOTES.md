# Statistical implementation and items for author review

This repository preserves the submitted scripts' analytical decisions. Packaging validation is not a statistical-method endorsement. No tests were replaced, no observations were added, and no multiple-testing rule was changed.

## Implemented analyses

| Module | Grouping | Implemented tests and decision rules | Multiple testing |
| --- | --- | --- | --- |
| Figure 1 | Event, with Event + Genus aggregation | Pearson correlation; Shapiro-Wilk on each marginal distribution; Pitman-Morgan via correlation of X+Y and X-Y; paired t-test only when both marginal normality checks pass | No p-value adjustment in original script |
| Figure 3 | Event | Pearson; marginal and difference Shapiro-Wilk; Pitman-Morgan and paired t-test when both marginal checks pass; otherwise median-centered Levene and paired Wilcoxon | Holm within each test family across available event p-values |
| Supplementary Figure 3 | Event x Background facies | Pearson; marginal and difference Shapiro-Wilk; Pitman-Morgan and paired t-test when both marginal checks pass | Holm within Pearson, Pitman-Morgan and paired t-test families, on nonmissing p-values |
| Supplementary Figure 7 | Event x Classification | Marginal and difference Shapiro-Wilk; both paired t-test and paired Wilcoxon, without normality gating | Holm across observed groups for each test family; normality p-values adjusted separately by variable |

Tests are two-sided. The original normality decision threshold is p > 0.05. Figure 1 uses p <= 0.05 for significance labels, whereas several other modules use p < 0.05. The supplied data do not create an exact 0.05 boundary case. Wilcoxon uses `exact = FALSE`, retaining R's default continuity correction.

Figure 1 mean differences are Background - During. Other mean changes are During - Background. Variance ratios are Background / During. These conventions must be consistent with figure captions and manuscript text.

## Normality rules need scientific review

For a paired t-test, the relevant normality condition concerns paired differences. Marginal normality of Background and During is not an equivalent condition. The original Figure 1, Figure 3 and Supplementary Figure 3 scripts gate paired t-tests on marginal checks; this was retained to avoid silently changing reported results.

Concrete examples in the supplied data:

- Figure 3 / ETAE: Background Shapiro-Wilk p is about 0.0173, but the paired-difference p is about 0.2684. The original rule therefore skips the paired t-test despite the difference normality check not rejecting normality.
- Supplementary Figure 3 / ETAE / Clastic: difference Shapiro-Wilk p is about 0.0274, but both marginal checks pass, so the original code executes the paired t-test and adds a cautionary note.

Passing a small-sample Shapiro-Wilk test does not establish normality. Pitman-Morgan also requires appropriate distributional assumptions for paired data; two separate marginal checks are not a verification of joint normality. The authors should review and justify the analysis plan before publication.

## Levene test and paired sampling

The Figure 3 Levene calculation stacks Background and During as two groups and supplies no genus/pair term. It therefore does not account for the paired dependence in this design. The result is retained as a reproduction of the supplied code and should not be described as a paired variance test. Review its suitability before using it to support a manuscript claim.

## Multiple comparisons and significance labels

The output `Conclusion`/`conclusion` strings are based on raw p-values. The English wording now says “unadjusted p” to make this explicit. Holm-adjusted p-values are separate columns where implemented. For example, Supplementary Figure 3 / PTAE / Carbonate has a Pitman-Morgan raw p of about 0.023739 and Holm-adjusted p of about 0.094956. Its original raw-p significance label must not be interpreted as significance after correction.

Figure 1 has no Holm correction. The other scripts have different adjustment scopes and do not form one joint correction across all four analyses. These original scopes must be described and scientifically justified. No unified correction was imposed during packaging.

## Small samples and identifiers

- Supplementary Figure 3 has two groups with n = 2; several tests are unavailable/skipped under the original rules. These NA results are retained.
- Supplementary Figure 7 / ETAE / Archaeobranchia has n = 1. Its Shapiro-Wilk and paired t-test results are unavailable. The original code nevertheless computes an approximate Wilcoxon p-value; it should not be treated as persuasive inferential evidence from one pair.
- Figure 1 has no duplicate keys in the supplied data. If duplicates are later introduced, `n_background`/`n_during` are evaluated after aggregation and do not measure the number of original observations.
- Supplementary Figure 7 lacks Genus identifiers; add a verified mapping before release if readers need genus-level traceability.

## References for software behavior

- R `t.test`: https://stat.ethz.ch/R-manual/R-devel/library/stats/html/t.test.html
- R `wilcox.test`: https://stat.ethz.ch/R-manual/R-devel/library/stats/html/wilcox.test.html
- R `p.adjust`: https://stat.ethz.ch/R-manual/R-devel/library/stats/html/p.adjust.html
- `car` documentation: https://cran.r-project.org/web/packages/car/refman/car.html

These references describe the procedures; they do not determine which analysis is scientifically appropriate for this manuscript.
