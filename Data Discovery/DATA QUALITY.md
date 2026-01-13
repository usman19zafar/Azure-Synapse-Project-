Notes: Identifying Data Quality Issues Using Serverless SQL (Azure Synapse)

1. Introduction

In this lesson, we focus on data quality checks within raw trip data stored in Azure Data Lake.

The goal is to validate whether the total_amount column is reliable enough for:
```code
reporting

analytics

machine learning

downstream transformations

If the data quality is poor, we may need to:

contact the data supplier

apply transformations

exclude problematic records

or redesign the ingestion logic
```
This is a core part of data discovery.
_________________________________________________________________________________________________________________________________________________________________________________
2. Dataset and File Format

The trip data exists in three formats:

CSV

Parquet

Delta

For this lesson, we use the Parquet version because:

it loads faster

it preserves schema

it is optimized for analytics

We focus on:

```Code
trip_data_green_parquet/year=2020/month=01/
```

_________________________________________________________________________________________________________________________________________________________________________________
3. Step 1 — Inspect the Raw Data
We begin by previewing the top 100 rows to understand the structure and confirm the presence of total_amount.

```sql
USE nyc_taxi_discovery;

SELECT TOP 100 *
FROM OPENROWSET(
        BULK 'abfss://nyctaxidata@786.dfs.core.windows.net/raw/trip_data_green_parquet/year=2020/month=01/',
        FORMAT = 'PARQUET'
    ) AS result;
```
What we observe
The total_amount column appears valid in the preview.

But previewing 100 rows is not enough — we must analyze the full dataset.


_________________________________________________________________________________________________________________________________________________________________________________
4. Step 2 — Basic Data Quality Checks
We perform three foundational checks:

```code
1. Minimum value
2. Maximum value
3. Average value
4. Null count
5. Total record count
```

```sql
SELECT
    MIN(total_amount) AS min_total_amount,
    MAX(total_amount) AS max_total_amount,
    AVG(total_amount) AS avg_total_amount,
    COUNT(1) AS total_number_of_records,
    COUNT(total_amount) AS not_null_total_number_of_records
FROM OPENROWSET(
        BULK 'abfss://nyctaxidata@786.dfs.core.windows.net/raw/trip_data_green_parquet/year=2020/month=01/',
        FORMAT = 'PARQUET'
    ) AS result;

```
Interpretation of results
Min = -210 → suspicious

Max = 753 → reasonable for NYC

Avg = 18 → reasonable

Total records = 447,000

Not‑null records = 447,000 → no nulls in total_amount

Conclusion
The dataset contains negative total amounts, which indicates potential refunds or disputes.


_________________________________________________________________________________________________________________________________________________________________________________
5. Step 3 — Investigate Negative Values
We filter for negative totals to understand the cause.

```sql
SELECT *
FROM OPENROWSET(
        BULK 'abfss://nyctaxidata@786.dfs.core.windows.net/raw/trip_data_green_parquet/year=2020/month=01/',
        FORMAT = 'PARQUET'
    ) AS result
WHERE total_amount < 0;

```

Observations

Many rows have negative totals

Most of these rows have payment_type = 3 or 4

Other fields (trip type, flags, etc.) do not explain the issue

This suggests the negative values are tied to payment behavior, not trip behavior.


_________________________________________________________________________________________________________________________________________________________________________________
6. Step 4 — Understand Payment Types

We check the meaning of payment types using the lookup table.

Typical values:

```code
Payment Type	Meaning

1	Credit Card
2	Cash
3	No Charge
4	Dispute
5	Unknown
```
Interpretation

Type 3 (No Charge) → possibly promotional rides or waived fees

Type 4 (Dispute) → refunded or reversed charges

This explains the negative totals.


_________________________________________________________________________________________________________________________________________________________________________________
7. Step 5 — Validate the Theory Across the Full Dataset
We group by payment type to confirm the pattern.

```sql
SELECT
    payment_type,
    COUNT(1) AS number_of_records
FROM OPENROWSET(
        BULK 'abfss://nyctaxidata@786.dfs.core.windows.net/raw/trip_data_green_parquet/year=2020/month=01/',
        FORMAT = 'PARQUET'
    ) AS result
GROUP BY payment_type
ORDER BY payment_type;

```

Findings
Most negative totals belong to payment types 3 and 4

A few negative totals appear under type 2 (cash) → unexplained but very rare

~25% of all records have payment_type = NULL

This reveals a second data quality issue.

_________________________________________________________________________________________________________________________________________________________________________________
8. Data Quality Issues Identified

Issue 1 — Negative total amounts

Caused by refunds, disputes, or no‑charge rides

Must be handled depending on business requirements

Issue 2 — Null payment types

~25% of records missing payment type

This affects reporting, ML models, and aggregations

Issue 3 — Rare anomalies
A few negative totals under cash payments

Could be data entry errors

_________________________________________________________________________________________________________________________________________________________________________________
9. How to Handle These Issues

Option A — Reporting

Map null payment types to 5 = Unknown.

Option B — Machine Learning

Drop negative totals to avoid skewing predictions.

Option C — Data Engineering

Apply cleansing rules during ingestion:

Replace nulls

Flag anomalies

Separate refunds from normal trips

Option D — Business Validation

Contact data provider if:

negative totals are unexpected

null payment types violate schema

_________________________________________________________________________________________________________________________________________________________________________________
10. Summary

In this lesson, we learned how to:

Query Parquet files using Serverless SQL

Perform basic data quality checks

Detect negative values

Investigate root causes using lookup tables

Identify nulls and anomalies

Decide how to handle data issues based on business needs

This is a core part of data discovery, ensuring that downstream analytics and models are built on clean, trustworthy data.
