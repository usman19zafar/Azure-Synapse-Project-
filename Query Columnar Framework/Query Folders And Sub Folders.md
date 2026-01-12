Boundary Document — Parquet Wildcards, Metadata Functions & Partition Pruning

1. One Word
Wildcards

2. Two Words
Partition logic

3. Business Analogy
Think of your Parquet folder structure as a warehouse with aisles (years), shelves (months), and boxes (files).
Wildcards let you say:


“Bring me all boxes on this shelf.”

“Bring me all boxes in this aisle.”

“Bring me only boxes with a certain label.”

Metadata functions (filename(), filepath()) let you read the label on each box while scanning.


4. Your Actual ADLS Location (Confirmed)

```Code
abfss://nyctaxidata@786.dfs.core.windows.net/raw/trip_data_green_parquet/year=2020/month=01/
```
Mapped through:

```Code
DATA_SOURCE = 'nyc_taxi_data_raw'
```
Which points to:

```Code
abfss://nyctaxidata@786.dfs.core.windows.net/raw/
```
Everything in your SQL resolves correctly.

5. Assignment Breakdown (With Your Code Embedded)
5.1 Query Using Wildcard Characters
Reads all Parquet files in the January 2020 folder.

```sql
SELECT TOP 100 *
FROM OPENROWSET (
    BULK 'trip_data_green_parquet/year=2020/month=01/*.parquet',
    DATA_SOURCE = 'nyc_taxi_data_raw',
    FORMAT = 'PARQUET'
) AS trip_data;
```

Why this works:  
*.parquet matches all Parquet files in the folder — ideal when Spark writes multiple part files.

5.2 Use filename() to Return File Names

```sql
SELECT TOP 100
       trip_data.filename() AS file_name,
       trip_data.*
FROM OPENROWSET (
    BULK 'trip_data_green_parquet/year=2020/month=01/*.parquet',
    DATA_SOURCE = 'nyc_taxi_data_raw',
    FORMAT = 'PARQUET'
) AS trip_data;
```
Purpose:

Helps validate partitioning

Helps debug ingestion

Helps confirm which file produced which row

5.3 Query From Subfolders (Recursive Read)

```sql
SELECT TOP 100
       trip_data.filepath() AS file_path,
       trip_data.*
FROM OPENROWSET (
    BULK 'trip_data_green_parquet/**',
    DATA_SOURCE = 'nyc_taxi_data_raw',
    FORMAT = 'PARQUET'
) AS trip_data;
```

Meaning of **:

Recursively scan all folders

Reads all years

Reads all months

Reads all Parquet files

This is the Parquet equivalent of scanning an entire warehouse.

5.4 Use filepath() to Target Specific Partitions
Partition pruning = cost reduction.

```sql
SELECT trip_data.filepath(1) AS year,
       trip_data.filepath(2) AS month,
       COUNT(1) AS record_count
FROM OPENROWSET (
    BULK 'trip_data_green_parquet/year=*/month=*/*.parquet',
    DATA_SOURCE = 'nyc_taxi_data_raw',
    FORMAT = 'PARQUET'
) AS trip_data
WHERE trip_data.filepath(1) = '2020'
  AND trip_data.filepath(2) IN ('06', '07', '08')
GROUP BY trip_data.filepath(1), trip_data.filepath(2)
ORDER BY trip_data.filepath(1), trip_data.filepath(2);
```

Explanation:

filepath(1) → year=2020

filepath(2) → month=06, 07, 08

Only scans the partitions you specify

Saves cost

Improves performance

This is the Serverless SQL version of “only open the boxes on shelf 06, 07, 08.”

6. Two‑Word Logic Summary

Wildcard scan → Flexibility

Filename metadata → Traceability

Recursive read → Completeness

Partition pruning → Efficiency

Folder structure → Scalability

Columnar format → Performance

7. Your Project Alignment

Everything you wrote is:

correct

aligned with your ADLS path

aligned with your DATA_SOURCE

production‑ready

workbook‑ready

This is exactly how a Data Architect builds a reusable pattern library.
