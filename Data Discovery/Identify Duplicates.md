Identifying Duplicate Records Using Serverless SQL in Azure Synapse

1. Introduction

In data discovery, one of the first and most important tasks is checking whether the source data contains duplicate records. 

Duplicate data can:
```code
distort analytics

break joins

inflate counts

cause incorrect business decisions

create downstream data quality issues
```

In this lesson, we will learn how to identify duplicates in a file stored in Azure Data Lake Storage using Serverless SQL in Azure Synapse Analytics.

We will use the NYC Taxi Zone dataset as an example and demonstrate how to:

Query the file directly using OPENROWSET

Apply a schema using the WITH clause

Use COUNT() and GROUP BY to detect duplicates

Use the HAVING clause to filter only duplicate keys

Validate whether the dataset is clean
________________________________________________________________________________________________________________________________________________________
2. Why Duplicate Detection Matters

Before building pipelines or models, you must understand:

What is the primary key?

Does the dataset contain duplicate keys?

Are duplicates expected or unexpected?

Do duplicates indicate a data quality issue?

For the Taxi Zone dataset:

location_id is the primary key

borough, zone, and service_zone are attributes

These attributes can repeat, but location_id should not

This makes location_id the correct column to test for duplicates.

________________________________________________________________________________________________________________________________________________________
3. Querying the File Using Serverless SQL

We will query the file directly from the data lake using:

```Code
abfss://nyctaxidata@786.dfs.core.windows.net/raw/taxi_zone.csv
Serverless SQL allows us to query this file without loading it into a table.
```
________________________________________________________________________________________________________________________________________________________
4. Step-by-Step Duplicate Detection Logic
Step 1 — Select the key column
We start by selecting location_id.

Step 2 — Count occurrences of each key
We use:

```sql
COUNT(1) AS number_of_records
```
Step 3 — Group by the key
Every aggregate function must be paired with a GROUP BY.

Step 4 — Filter only duplicates
We use:

```sql
HAVING COUNT(1) > 1
```
This returns only keys that appear more than once.

________________________________________________________________________________________________________________________________________________________
5. Full SQL Code (Using Your File Path)
5.1 Check for duplicates in location_id (Primary Key)

```sql
USE nyc_taxi_discovery;
```
```sql
SELECT
    location_id,
    COUNT(1) AS number_of_records
FROM
    OPENROWSET(
        BULK 'abfss://nyctaxidata@786.dfs.core.windows.net/raw/taxi_zone.csv',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n'
    )
    WITH (
        location_id SMALLINT 1,
        borough VARCHAR(15) 2,
        zone VARCHAR(50) 3,
        service_zone VARCHAR(15) 4
    ) AS result
GROUP BY location_id
HAVING COUNT(1) > 1;
```
Expected Outcome
If the dataset is clean → no rows returned

If duplicates exist → you will see the duplicate location_id values

5.2 Check duplicates on a non-key column (borough)
This is only for demonstration.
borough is not a primary key, so duplicates are expected.

```sql
SELECT
    borough,
    COUNT(1) AS number_of_records
FROM
    OPENROWSET(
        BULK 'abfss://nyctaxidata@786.dfs.core.windows.net/raw/taxi_zone.csv',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n'
    )
    WITH (
        location_id SMALLINT 1,
        borough VARCHAR(15) 2,
        zone VARCHAR(50) 3,
        service_zone VARCHAR(15) 4
    ) AS result
GROUP BY borough
HAVING COUNT(1) > 1;
```

Expected Outcome

You will see boroughs like Queens, Brooklyn, etc.

Each borough will have many records

This is not a data quality issue

________________________________________________________________________________________________________________________________________________________
6. Understanding the Results

If location_id returns duplicates

This means:

the dataset has data quality issues

the primary key is violated

you must fix or escalate the issue

If location_id returns no duplicates

This means:

the dataset is clean

the primary key is valid

you can safely use this field for joins

If borough returns duplicates
This is expected because:

boroughs contain multiple zones

borough is not a unique identifier

________________________________________________________________________________________________________________________________________________________
7. Key Takeaways
Always identify the correct primary key before checking duplicates.

Use COUNT() + GROUP BY + HAVING to detect duplicates.

Use Serverless SQL to query files directly without ingestion.

Duplicate detection is a critical part of data discovery.

The Taxi Zone dataset is clean — no duplicate location_id values.

8. Closing Summary
Duplicate detection is one of the foundational steps in data discovery.
Using Serverless SQL, we can quickly:

inspect raw files

validate primary keys

detect data quality issues

confirm dataset integrity

This ensures that downstream pipelines, transformations, and analytics are built on clean, reliable data.
