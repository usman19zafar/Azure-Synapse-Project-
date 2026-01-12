Boundary Document — Exploring Parquet Files with Serverless SQL

1. Concept Summary
One word: Parquet
Two words: Column storage
Business analogy:  
A Parquet file is like a warehouse where items are stored by attribute, not by row. If you only need “blue shirts,” you don’t walk every aisle — you go straight to the “color = blue” shelf.

2. Folder Structure (Your Actual Project Path)

Your ADLS Gen2 path:

```Code
abfss://nyctaxidata@786.dfs.core.windows.net/raw/trip_data_green_parquet/year=2020/month=01/

```
Inside this folder:

```Code
year=2020/
   month=01/
      part-00000-*.parquet
      _committed_*
      _started_*
      _SUCCESS
```
Notes:

_started, _committed, _SUCCESS are Spark job markers → ignored by OPENROWSET.

Parquet files contain data + metadata (schema, column types, statistics).

3. Theory — Why Parquet Behaves Differently
3.1 Automatic Schema Inference
Parquet stores:

column names

data types

min/max statistics

encoding details

Serverless SQL’s OPENROWSET … FORMAT='PARQUET' reads this metadata automatically.

Result:

No need for FIELDTERMINATOR, ROWTERMINATOR, or manual parsing.

More accurate data types than CSV (e.g., INT instead of BIGINT, DATETIME2 instead of VARCHAR).
```
3.2 Column Pruning = Cost Reduction

Because Parquet is columnar:

Selecting fewer columns → scanning fewer bytes

Scanning fewer bytes → lower cost + faster execution

Example from your lesson:

Selecting all columns scanned ~6 MB

Selecting only trip_type and tip_amount scanned ~1 MB
```

4. SQL Patterns Used in This Lesson

4.1 Basic Parquet Read (Auto‑Generated)

```sql
USE nyc_taxi_discovery;

SELECT TOP 100 *
FROM OPENROWSET(
        BULK 'trip_data_green_parquet/year=2020/month=01/',
        FORMAT = 'PARQUET',
        DATA_SOURCE = 'nyc_taxi_data_raw'
    ) AS [result];
Key point:  
```
Reading the folder, not the individual file → supports multiple Parquet parts.

4.2 Inspecting Inferred Schema
```sql
EXEC sp_describe_first_result_set N'
SELECT TOP 100 *
FROM OPENROWSET(
        BULK ''trip_data_green_parquet/year=2020/month=01/'',
        FORMAT = ''PARQUET'',
        DATA_SOURCE = ''nyc_taxi_data_raw''
    ) AS [result]';
Outcome:
```
Most types inferred correctly

But string fields default to VARCHAR(8000)

Example: store_and_fwd_flag should be CHAR(1)

4.3 Defining Your Own Schema (Recommended for Production)
```sql
SELECT TOP 100 *
FROM OPENROWSET(
        BULK 'trip_data_green_parquet/year=2020/month=01/',
        FORMAT = 'PARQUET',
        DATA_SOURCE = 'nyc_taxi_data_raw'
    )
WITH (
      VendorID INT,
      lpep_pickup_datetime DATETIME2(7),
      lpep_dropoff_datetime DATETIME2(7),
      store_and_fwd_flag CHAR(1),
      RatecodeID INT,
      PULocationID INT,
      DOLocationID INT,
      passenger_count INT,
      trip_distance FLOAT,
      fare_amount FLOAT,
      extra FLOAT,
      mta_tax FLOAT,
      tip_amount FLOAT,
      tolls_amount FLOAT,
      ehail_fee INT,
      improvement_surcharge FLOAT,
      total_amount FLOAT,
      payment_type INT,
      trip_type INT,
      congestion_surcharge FLOAT
) AS [result];
```
Why define schema manually?

Ensures correct types

Prevents VARCHAR(8000) inflation

Improves query performance

Reduces memory footprint

4.4 Column Pruning Example (Cost Optimization)
```sql
SELECT TOP 100 *
FROM OPENROWSET(
        BULK 'trip_data_green_parquet/year=2020/month=01/',
        FORMAT = 'PARQUET',
        DATA_SOURCE = 'nyc_taxi_data_raw'
    )
WITH (
        tip_amount FLOAT,
        trip_type INT
) AS [result];
```
Effect:

Scans only the required Parquet columns

Reduces scanned data from ~6 MB → ~1 MB

5. File Location Embedded in Code (As You Requested)
All SQL examples reference your actual ADLS path:

```Code
abfss://nyctaxidata@786.dfs.core.windows.net/raw/trip_data_green_parquet/year=2020/month=01/
```
And the corresponding OPENROWSET folder reference:

Code
```BULK 'trip_data_green_parquet/year=2020/month=01/'
DATA_SOURCE = 'nyc_taxi_data_raw'
```
This keeps your workbook consistent and production‑aligned.

6. Two‑Word Logic Summary

Column storage → Parquet

Automatic inference → Metadata

Better types → Accuracy

Column pruning → Savings

Folder reading → Scalability

Manual schema → Control

Marker files → Ignored

Serverless SQL → Pay‑per‑scan
