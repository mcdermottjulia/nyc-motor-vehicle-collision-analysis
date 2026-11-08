-- NYC Motor Vehicle Collision Analysis | MySQL exploration
-- Run only AFTER the source data has been imported into nyc_crashes.crashes.
-- Descriptive exploration only; final research analyses are still in progress.

USE nyc_crashes;

-- A. INGEST VERIFICATION: counts, sample records, duplicates
SELECT COUNT(*) AS total_crashes FROM crashes;
SELECT * FROM crashes LIMIT 5;

SELECT collision_id, COUNT(*) AS occurrences
FROM crashes
GROUP BY collision_id
HAVING COUNT(*) > 1;

-- B. DATA QUALITY: missing geographic and contributing-factor fields
-- Treat both SQL NULL and empty strings as missing.
SELECT
    COUNT(*) AS total_records,
    SUM(CASE WHEN borough IS NULL OR borough = '' THEN 1 ELSE 0 END)
        AS missing_borough,
    SUM(CASE WHEN zip_code IS NULL OR zip_code = '' THEN 1 ELSE 0 END)
        AS missing_zip_codes,
    SUM(CASE WHEN latitude IS NULL OR latitude = '' THEN 1 ELSE 0 END)
        AS missing_latitude,
    SUM(CASE WHEN longitude IS NULL OR longitude = '' THEN 1 ELSE 0 END)
        AS missing_longitude,
    SUM(CASE WHEN contributing_factor_vehicle_1 IS NULL
                   OR contributing_factor_vehicle_1 = ''
             THEN 1 ELSE 0 END) AS missing_primary_factor
FROM crashes;

-- C. NOMINAL: BOROUGH
-- Percentages use ALL records, including missing-borough records.
SELECT borough, COUNT(*) AS crash_count,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM crashes), 2)
           AS percentage_of_all_crashes
FROM crashes
GROUP BY borough
ORDER BY crash_count DESC;

-- D. ORDINAL: DERIVED CRASH IMPACT
-- Severity results reflect values stored in the initial SQL import.
-- Three source records with missing fatality counts were stored as zeros;
-- the source-aware validation is documented in docs/data_validation_notes.md.
SELECT
    CASE
        WHEN persons_killed > 0 THEN 'Fatality'
        WHEN persons_injured > 0 THEN 'Injury'
        WHEN persons_injured = 0 AND persons_killed = 0 THEN 'No Injury'
        ELSE 'Unknown'
    END AS crash_impact,
    COUNT(*) AS crash_count
FROM crashes
GROUP BY crash_impact
ORDER BY
    CASE crash_impact
        WHEN 'No Injury' THEN 1
        WHEN 'Injury' THEN 2
        WHEN 'Fatality' THEN 3
        ELSE 4
    END;

-- E. INTERVAL: CRASH DATE
-- Text dates reflect the original import schema. Convert in query.
SELECT
    MIN(STR_TO_DATE(crash_date, '%m/%d/%Y')) AS earliest_crash,
    MAX(STR_TO_DATE(crash_date, '%m/%d/%Y')) AS latest_crash,
    DATEDIFF(
        MAX(STR_TO_DATE(crash_date, '%m/%d/%Y')),
        MIN(STR_TO_DATE(crash_date, '%m/%d/%Y'))
    ) AS date_range_days
FROM crashes;

-- F. RATIO: NUMBER OF PERSONS INJURED
-- STDDEV() in MySQL returns POPULATION standard deviation.
SELECT
    COUNT(persons_injured) AS non_null_count,
    MIN(persons_injured) AS minimum,
    MAX(persons_injured) AS maximum,
    ROUND(AVG(persons_injured), 3) AS mean,
    ROUND(STDDEV(persons_injured), 3) AS population_std_dev
FROM crashes;
