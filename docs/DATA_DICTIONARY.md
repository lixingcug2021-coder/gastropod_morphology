# Data dictionary

All four original workbooks contain one sheet named `Sheet1`. No missing cells were found in their populated input tables. The three workbooks containing Genus have no duplicate Event + Genus keys. Rows are analytical paired records; they must not be interpreted as individual specimens or independent experimental replicates without a description of the underlying sampling and aggregation.

The exact definitions of the event abbreviations, time windows, measurements and original aggregation have not been provided in these eight files. They are author-completion items, not inferred from filenames.

## Figure 1

| Exact column name | Type | Interpretation |
| --- | --- | --- |
| `Event` | Text | Event label: ETAE or PTAE; full event definitions and time windows to be supplied |
| `Genus` | Text | Genus label; paired key together with Event |
| `Background aspect_ratio` | Numeric | Background-period aspect-ratio-labelled value, in the supplied analysis scale |
| `During aspect_ratio` | Numeric | Event-period aspect-ratio-labelled value, in the supplied analysis scale |

28 rows: ETAE 11 and PTAE 17. Background values range approximately from -0.488 to 0.619 (consult data for full precision). Negative values occur in both periods. Authors must specify whether these are log-transformed, centered, residualized or otherwise transformed, and provide the exact formula and the meaning of the original ratio. No transformation or back-transformation is applied by the supplied script.

Pairing is by Event + Genus. Duplicate keys would be averaged, but none occur in this input. The script's `n_background` and `n_during` are calculated after mean aggregation and therefore are not counts of original specimens or source observations.

## Figure 3

| Exact column name | Type | Interpretation |
| --- | --- | --- |
| `Event` | Text | Event label: ETAE or PTAE |
| `Genus` | Text | Genus label |
| `Background log10 V` | Numeric | Supplied base-10 logarithm of V for the background period |
| `During log10 V` | Numeric | Supplied base-10 logarithm of V for the event period |

28 rows: ETAE 11 and PTAE 17. The supplied script does not log-transform again. Authors must define V, its calculation and its original units, and describe the statistic represented by each genus value. Pairing is within each row, grouped by Event; the script does not join or aggregate by Genus.

## Supplementary Figure 3

| Exact column name | Type | Interpretation |
| --- | --- | --- |
| `Event` | Text | Event label |
| `Background facies` | Text | Background facies: Carbonate, Clastic or Mixed |
| `Genus` | Text | Genus label |
| `Background_aspect_ratio` | Numeric | Supplied background-period value; transformation to be specified |
| `During_aspect_ratio` | Numeric | Supplied event-period value; transformation to be specified |

27 rows. Within-row pairing is analyzed separately for each Event x Background facies group.

| Event | Carbonate | Clastic | Mixed | Total |
| --- | ---: | ---: | ---: | ---: |
| ETAE | 3 | 6 | 2 | 11 |
| PTAE | 9 | 2 | 5 | 16 |

There are six observed combinations. The supplied code expected four combinations and issues a warning, but processes all six. PTAE / Araeonema, present in Figure 1, is absent here. The reason for this omission and facies-assignment criteria require author confirmation; the record has not been added or assigned a facies.

## Supplementary Figure 7

| Exact column name | Type | Interpretation |
| --- | --- | --- |
| `Event` | Text | Event label |
| `Classification` | Text | Supplied taxonomic category; taxonomic rank and reference classification to be specified |
| `Background_aspect_ratio` | Numeric | Supplied background-period value; transformation to be specified |
| `During_aspect_ratio` | Numeric | Supplied event-period value; transformation to be specified |

28 rows, analyzed using the paired values in each row and grouped by Event x Classification.

| Event | Adenogonogastropoda | Amphigastropoda | Archaeobranchia | Vetigastropoda |
| --- | ---: | ---: | ---: | ---: |
| ETAE | 3 | 0 | 1 | 7 |
| PTAE | 6 | 4 | 0 | 7 |

Zero denotes an absent group, not a measured zero. Category spellings are preserved exactly as supplied. There is no Genus or persistent record identifier in this workbook; an author-verified mapping should be supplied for traceability. Row position defines the pairing within this workbook; it must not be used to join different workbooks.

## Missing values, exclusions and precision

The current inputs have no missing cells. The scripts nevertheless contain filtering for missing labels or paired values. Figure 1 accepts only PTAE/ETAE; Figure 3 accepts actual Event labels; Supplementary Figure 3 accepts actual Event/facies combinations; Supplementary Figure 7 drops missing Event, Classification or paired values.

Unavailable/skipped tests are represented by NA with an explanatory note, not by a p-value of zero. Figure 1 rounds exported numeric values to eight decimal places, as in the original script. Use the original Excel data for calculations; do not reconstruct input precision from result tables.
