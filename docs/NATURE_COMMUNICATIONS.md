# Nature Communications: data and code submission notes

Policy checked: 19 November 2026. This is a practical mapping for the four supplied analyses, not a claim of editorial approval or complete manuscript compliance.

## Separate availability statements

The journal's policy guide requires a Data Availability statement describing access to the minimum supporting datasets, and a Code Availability statement when custom code or an algorithm is central to the conclusions. State actual access conditions, relevant software versions and licensing. Use the separate templates in AVAILABILITY_STATEMENTS.md after filling all fields.

Official policy: https://www.nature.com/ncomms/submit/policy

## Reviewer access and archival citation

The submission guidance requires previously unreported custom code central to the main claims to be available to editors and reviewers at submission. The reporting-standards guidance identifies DOI-minting repositories such as Zenodo or Code Ocean for archival code deposition and reference-list citation. GitHub is useful for version management; archive the exact submission/publication release for a stable citation. Code Ocean is an optional supported route, not a requirement to use that platform.

Official guidance:

- https://www.nature.com/ncomms/submit/how-to-submit
- https://www.nature.com/ncomms/editorial-policies/reporting-standards
- https://docs.github.com/en/repositories/archiving-a-github-repository/referencing-and-citing-content

## Source Data

The journal may request an Excel source-data file or a ZIP for relevant manuscripts. Its guidance calls for the numerical data behind graphs/charts and, where relevant, uncropped gels/blots, organized by figure/table. Separate files within a ZIP are permitted.

The accompanying `Source_Data_four_analyses.zip` retains each supplied workbook as a separate file labelled by its figure. It is a starting subset for these four analyses only. Authors must supply exact panel mapping, variable transformations/units, provenance, and any other required figure/table source data. The statistical result workbooks in `results/` are generated outputs; they should not be mistaken for the complete raw source measurements.

Official Source Data instructions: https://www.nature.com/ncomms/submit/how-to-submit

## Suggested upload sequence

1. Resolve the metadata and substantive analysis questions in AUTHOR_CHECKLIST.md.
2. Upload the contents of the `gastropod_morphology` folder to one GitHub repository. Keep the four analysis folders and their relative paths intact.
3. Add final citation and license files; confirm that README instructions work from a fresh download.
4. Provide reviewers an accessible copy or link when submitting. Follow the submission's chosen anonymity/access requirements.
5. When the release version is settled, connect the public GitHub repository to Zenodo before publishing a GitHub Release, or deposit the exact release through another suitable archive. Verify the issued DOI and archived file contents.
6. Insert the actual archive DOI, GitHub URL and license in the manuscript's separate statements and citations.

GitHub-Zenodo automated archiving requires a public repository. It does not provide reviewer access to a private repository automatically.
