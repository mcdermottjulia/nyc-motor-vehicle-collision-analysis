# Data Quality and Validation

This document summarizes checks performed on a locally saved 2024–2025 extract of the NYC Open Data *Motor Vehicle Collisions – Crashes* dataset. The source contains **176,615 records** across **29 original columns**.

## Source-data checks

| Check | Result |
| --- | ---: |
| Missing `BOROUGH` values | 43,029 |
| Missing `NUMBER OF PERSONS KILLED` values | 3 |
| Missing `NUMBER OF PERSONS INJURED` values | 0 |
| Mean persons injured per collision | 0.586031764 |
| Population standard deviation of persons injured | 0.853046054 |
| Sample standard deviation of persons injured | 0.853048469 |

## Crash Impact classification

The *Crash Impact* variable distinguishes three ordered outcomes: **No Injury**, **Injury**, and **Fatality**. A separate **Unknown** category captures records that cannot be confidently placed into one of those outcomes.

- **Fatality:** at least one person killed, regardless of the injury count.
- **Injury:** zero people killed and at least one person injured.
- **No Injury:** zero people killed and zero people injured.
- **Unknown:** a required count is missing and the available data do not establish one of the above classifications.

| Classification | Records |
| --- | ---: |
| No Injury | 99,060 |
| Injury | 77,087 |
| Fatality | 465 |
| Unknown | 3 |
| **Total** | **176,615** |

## Cross-platform comparison

The initial Python analysis used `fillna(0)` for missing fatality counts, classifying three records as **Injury**. The original R code left those same records unclassified. After examining the source values, I aligned the Python and R rules and retained **Unknown** for those three cases.

I also inspected the corresponding records in MySQL and MongoDB. Both databases contained **numeric zero** values in the fatality field, while the CSV values were missing. MySQL had reported three conversion warnings during an earlier import, consistent with this difference in stored values. The precise import handling in MongoDB was not independently established.

The revised Python and R results agree on the source-aware classification. The existing database copies still contain the original imported values and therefore produce different severity counts.

## Interpretation limits

- Missing borough information limits geographic comparisons. Borough counts are not adjusted for population or road traffic.
- The source includes **3,380 records at exactly 00:00**. This concentration warrants checking whether some timestamps were rounded or entered as defaults; the raw times alone cannot establish that.
- The original R report contained an injury-count standard deviation of **0.830**. Recalculation from the source CSV gave **0.853048469** using the sample standard deviation.

The next stage of the research includes further contributing-factor analysis and statistical comparisons using the validated source-data definitions.

[Return to project overview](../README.md)
