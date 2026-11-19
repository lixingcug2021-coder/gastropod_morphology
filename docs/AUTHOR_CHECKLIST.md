# Author checks before public release and manuscript submission

## Metadata and measurement definitions

- [ ] Supply the final manuscript title, author list, author order, ORCIDs if used, and a contact address.
- [ ] Expand PTAE and ETAE and define the Background/During intervals and sampling framework.
- [ ] Define the aspect-ratio variable exactly. Values include negatives, so a raw positive height/width ratio cannot be assumed. Give the transformation formula/base, if any.
- [ ] Define V, the original units and the volume calculation. Confirm that the supplied log10 V values are already on the intended analysis scale.
- [ ] Explain how individual measurements were aggregated into each genus-level paired record (mean, median, etc.), including source sample sizes and provenance references.

## Dataset-specific checks

- [ ] Explain the absence of PTAE / Araeonema from Supplementary Figure 3 (27 rows versus 28 in Figure 1). No observation or facies assignment has been invented.
- [ ] Confirm the six Event x facies groups and how Carbonate, Clastic and Mixed were assigned. The original script expects four groups but analyzes all six.
- [ ] Supply a verified Genus/record-ID mapping for Supplementary Figure 7; its current workbook has no Genus column.
- [ ] Confirm taxonomic category spellings, rank and reference classification; categories have not been silently renamed.
- [ ] Map each analysis to the exact figure panel(s). The filenames identify figure numbers but not panel letters; the final figure layouts were not supplied.

## Statistical review

- [ ] Review paired-difference versus marginal normality gating and the use of Levene on paired observations; see STATISTICAL_NOTES.md.
- [ ] Decide and document the intended multiplicity correction. Figure 1 is unadjusted; other modules have family-specific Holm adjustments. Existing significance text is based on raw p-values.
- [ ] Decide how to describe groups with n = 1 or n = 2 and unavailable tests. In particular, do not interpret the single-pair approximate Wilcoxon result as strong evidence.
- [ ] Confirm the opposite mean-difference direction in Figure 1 versus the other modules.
- [ ] Compare regenerated tables with the manuscript, figure captions and reported sample sizes. Packaging validation compares the provided scripts, not an unseen manuscript.

## Release and journal submission

- [ ] Choose and apply an appropriate code license and data license, with authority to redistribute all included material.
- [ ] Complete `CITATION.cff` from the example, with genuine author and repository metadata. Do not upload example placeholder values as real metadata.
- [ ] Give reviewers access to the code and data at submission. A private GitHub URL alone does not grant access.
- [ ] Create a named GitHub release once the submission version is settled, archive that version in a DOI-minting repository, and record its exact version DOI.
- [ ] Complete separate Data availability and Code availability sections and cite archived records in the reference list where required.
- [ ] Confirm that the complete paper's minimum supporting dataset and all relevant custom code are available; this package covers only four supplied analyses.
- [ ] If a Source Data file is requested, ensure it covers all applicable main/supplementary figures, tables and panel mappings. The accompanying four-analysis Source Data ZIP is only the supplied subset.

No final manuscript, author-approved metadata, license choice, repository URL or DOI was provided when this package was prepared.
