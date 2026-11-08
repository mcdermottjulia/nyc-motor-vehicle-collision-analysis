# MySQL: Schema and Exploratory Analysis

This folder contains the relational database portion of the NYC collision project.

| File | Contents |
| --- | --- |
| `01_create_schema.sql` | Database and 29-column crash table definition |
| `02_exploratory_queries.sql` | Import checks, missing values, duplicate IDs, borough summaries, severity counts, date summaries, and injury statistics |

## Data and workflow

I worked with a **176,615-record** snapshot of the 2024–2025 NYC collision dataset. The schema contains the source fields for dates, location, injury and fatality counts, contributing factors, and vehicle types.

The SQL scripts define and query the database; they **do not contain the CSV import step**. For the AWS RDS exercise, I imported the local CSV using MySQL Shell and ran the queries through MySQL Workbench. The source CSV is excluded from this GitHub repository.

Some initial fields, including dates and coordinates, were stored as text. Date conversion is performed in the exploratory queries. A more strongly typed import workflow would improve downstream validation.

## Data validation

The original MySQL import produced three warnings on blank integer values. Subsequent inspection showed numeric zeros for three fatality fields that were blank in the source CSV. The original SQL severity totals therefore differ from the source-aware classifications now used in Python and R.

See [data validation notes](../docs/data_validation_notes.md) for the comparison and the current classification definitions.

[Return to project overview](../README.md)
