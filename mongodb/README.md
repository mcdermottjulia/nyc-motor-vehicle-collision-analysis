# MongoDB: Aggregation Analysis

This folder contains MongoDB queries used to explore the NYC collision dataset in a document database.

## Data and queries

I imported the 2024–2025 collision CSV into the `nyc_crashes` database and `crashes` collection using MongoDB Compass. The original CSV field names were retained, including names with spaces such as `NUMBER OF PERSONS INJURED`.

The [`aggregation_pipelines.js`](aggregation_pipelines.js) script collects the exploratory queries for:

- A sample Brooklyn collision record
- Collision counts by borough
- Derived Crash Impact categories
- Minimum and maximum crash dates
- Descriptive statistics for the number of people injured

The queries use MongoDB aggregation stages such as `$group`, `$sort`, `$addFields`, and `$dateFromString`. They can be examined in MongoDB Compass or run in `mongosh` against an imported database.

## Data validation

A comparison with the original CSV found three missing fatality values that were represented as numeric zeros in the imported MongoDB collection. The initial database-based severity counts therefore differ slightly from the source-aware Python and R results. The database import has been retained as originally performed.

See [data validation notes](../docs/data_validation_notes.md) for details.

[Return to project overview](../README.md)
