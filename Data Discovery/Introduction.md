Data Discovery with Serverless SQL (Azure Synapse)

Overview

Data Discovery is one of the most important early phases of any data engineering or analytics project. Azure Synapse Serverless SQL enables rapid exploration of raw files without provisioning infrastructure, without loading data into tables, and without complex setup.
```code
This makes it ideal for:

validating new data sources

profiling data quality

estimating storage and compute needs

identifying business‑critical fields

testing joins across multiple datasets

performing lightweight transformations

generating summary insights for stakeholders
```
This repository demonstrates how to use Serverless SQL to perform practical, real‑world data discovery tasks.

Why Serverless SQL for Data Discovery?
```code
1. Query files directly
Query CSV, Parquet, JSON, and other file formats in-place using OPENROWSET—no ingestion required.

2. Zero infrastructure management
No clusters, no pools, no provisioning. Synapse handles compute automatically.

3. Cost‑efficient
You only pay for the data scanned. Perfect for early exploration.

4. Fast iteration
Ideal for rapid prototyping, validation, and schema understanding.
```
___________________________________________________________________________________________________________________________________________________________________________________________________________
1, Record Counts & Volume Estimation
Understanding the size of the dataset helps determine:

whether to use Serverless SQL

whether a Dedicated SQL Pool is needed

whether Spark is required for heavy processing

Examples include:

total record count

record counts by day/week/month

growth projections

___________________________________________________________________________________________________________________________________________________________________________________________________________
2, Data Quality Checks
Duplicate Detection
Identify duplicate rows based on key columns.

Missing Values
Find nulls, blanks, or incomplete records.

Invalid or Unexpected Values
Detect values outside expected ranges or formats.

These checks help determine:

whether the data provider must fix issues

whether transformations are required

whether alternative data sources are needed

___________________________________________________________________________________________________________________________________________________________________________________________________________
3, Joinability Assessment
Most projects require combining multiple datasets.

We validate:

whether join keys exist

whether keys are unique

whether relationships are reliable

whether referential gaps exist

This ensures datasets can be integrated before deeper modeling begins.

___________________________________________________________________________________________________________________________________________________________________________________________________________
4, Business Value Validation

A dataset is only useful if it contains the fields required for:

KPIs

dashboards

reporting

machine learning

compliance

operational workflows

We check:

presence of required columns

data types

granularity

completeness

___________________________________________________________________________________________________________________________________________________________________________________________________________
5 Transformations & Aggregations

During discovery, we often test:

derived columns

date transformations

grouping and summarization

simple business rules

This helps confirm whether the data can support downstream use cases.

Example Serverless SQL Patterns

Query a file directly

```sql
SELECT *
FROM OPENROWSET(
    BULK 'https://storageaccount.dfs.core.windows.net/container/data/file.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    HEADER_ROW = TRUE
) AS rows;
Check for duplicates
sql
SELECT key_column, COUNT(*) AS cnt
FROM dataset
GROUP BY key_column
HAVING COUNT(*) > 1;
```

Find missing values

```sql
SELECT *
FROM dataset
WHERE columnA IS NULL OR columnA = '';
Validate join keys
sql
SELECT COUNT(*) AS matched
FROM tableA a
JOIN tableB b
    ON a.key = b.key;
```
Summary statistics

```sql
SELECT category, COUNT(*) AS total, AVG(amount) AS avg_amount
FROM dataset
GROUP BY category;
```
___________________________________________________________________________________________________________________________________________________________________________________________________________
```code
Repository Structure
Code
/data-discovery/
│
├── 01_record_counts.sql
├── 02_duplicates_check.sql
├── 03_missing_values.sql
├── 04_invalid_values.sql
├── 05_joinability_tests.sql
├── 06_summary_aggregations.sql
├── 07_transformations.sql
│
└── README.md   ← You are here
```
___________________________________________________________________________________________________________________________________________________________________________________________________________
Who This Is For

SQL developers

Data engineers learning Synapse

Analysts validating new datasets

Architects evaluating data sources

Anyone performing early‑stage data profiling

Experienced SQL users may skip the basics and jump directly into the discovery scripts.
___________________________________________________________________________________________________________________________________________________________________________________________________________
🏁 Conclusion

Serverless SQL is a powerful tool for rapid, cost‑efficient data discovery.

It allows you to:

explore raw files instantly

validate data quality

test joins

perform transformations

generate business insights

—all without provisioning infrastructure or loading data into tables.

This repository demonstrates the essential patterns needed to perform real‑world data discovery in Azure Synapse.
