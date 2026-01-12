Boundary Document — Reading Delta Lake Tables with Serverless SQL

1. One Word
Delta

2. Two Words
Transaction Intelligence

3. Business Analogy
A Delta table is like a warehouse where the boxes (Parquet files) hold the data,
and the security office (_delta_log) records every movement —
every delivery, every update, every correction.

You don’t understand the warehouse unless you read both.

4. What Makes Delta Different?
Delta Lake is built on top of Parquet, but with one critical addition:

4.1 Parquet = Data Only
Stores rows and columns

Stores metadata (schema, statistics)

No versioning

No ACID guarantees

4.2 Delta = Parquet + Transaction Log
Inside your Delta folder:

```Code
trip_data_green_delta/
   _delta_log/
   year=2020/
      month=01/
         part-*.parquet
```
The _delta_log folder contains:

JSON transaction entries

Add/remove file actions

Schema evolution

Version history

This is what enables:

ACID transactions

Time travel

Schema enforcement

Reliable batch + streaming

Without _delta_log, a folder is NOT a Delta table.

5. Why You Must Query the ROOT Folder
Your Delta table lives at:

```Code
abfss://nyctaxidata@786.dfs.core.windows.net/raw/trip_data_green_delta/
```
This folder contains _delta_log, so Serverless SQL can identify it as a Delta table.

If you try to query:

```Code
trip_data_green_delta/year=2020
```
Serverless SQL looks for:

```Code
trip_data_green_delta/year=2020/_delta_log/
```
It doesn’t exist → error.

This is by design.

6. Reading Delta Tables in Serverless SQL
6.1 Basic Read (Correct)
```sql
USE nyc_taxi_discovery;
```
```sql
SELECT TOP 100 *
FROM OPENROWSET(
    BULK 'trip_data_green_delta/',
    DATA_SOURCE = 'nyc_taxi_data_raw',
    FORMAT = 'DELTA'
) AS trip_data;
```
What happens internally

Serverless SQL reads _delta_log

Determines the latest version

Identifies which Parquet files belong to that version

Reads only those files

Automatically exposes partition columns (year, month)

This is why Delta feels “smart” compared to CSV or raw Parquet.

7. What Happens When You Query a Subfolder (Expected Failure)

```sql
SELECT TOP 100 *
FROM OPENROWSET(
    BULK 'trip_data_green_delta/year=2020',
    DATA_SOURCE = 'nyc_taxi_data_raw',
    FORMAT = 'DELTA'
) AS trip_data;
```
Error Explanation

Serverless SQL tries to resolve:

```Code
trip_data_green_delta/year=2020/_delta_log/*.json
```
But _delta_log exists only at the root.

Therefore:

The engine cannot identify the table version

It cannot determine which Parquet files belong to the table

It throws: “Content of directory cannot be listed”

This is expected and correct behavior.

8. Schema Inference for Delta
```sql
EXEC sp_describe_first_result_set N'
SELECT TOP 100 *
FROM OPENROWSET(
    BULK ''trip_data_green_delta/'',
    DATA_SOURCE = ''nyc_taxi_data_raw'',
    FORMAT = ''DELTA''
) AS trip_data'
```
What you’ll see
Most numeric and datetime types inferred correctly

String fields default to VARCHAR(8000)

Partition columns (year, month) also default to VARCHAR(8000)

This is why manual schema definition is recommended.

9. Defining Your Own Schema (Best Practice)

```sql
SELECT TOP 100 *
FROM OPENROWSET(
    BULK 'trip_data_green_delta/',
    DATA_SOURCE = 'nyc_taxi_data_raw',
    FORMAT = 'DELTA'
)
WITH (
    VendorID INT,
    lpep_pickup_datetime datetime2(7),
    lpep_dropoff_datetime datetime2(7),
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
    congestion_surcharge FLOAT,
    year VARCHAR(4),
    month VARCHAR(2)
) AS trip_data;
```
Why this matters

Prevents VARCHAR(8000) bloat

Ensures correct data types

Improves performance

Reduces memory usage

Enables correct partition filtering

10. Column Pruning (Delta Requires Partition Columns)
If you try:

```sql
SELECT TOP 100 *
FROM OPENROWSET(
    BULK 'trip_data_green_delta/',
    DATA_SOURCE = 'nyc_taxi_data_raw',
    FORMAT = 'DELTA'
)
WITH (
    tip_amount FLOAT,
    trip_type INT
) AS trip_data;
```
You get an error.

Why?
Delta requires:

All selected columns

All partition columns

So you must include:

```sql
WITH (
    tip_amount FLOAT,
    trip_type INT,
    year VARCHAR(4),
    month VARCHAR(2)
)
```
Result
Data scanned drops from ~6 MB → ~1 MB

Faster execution

Lower cost

11. Partition Pruning Using WHERE (Delta’s Superpower)
Full table scan
```sql
SELECT COUNT(DISTINCT payment_type)
FROM OPENROWSET(
    BULK 'trip_data_green_delta/',
    DATA_SOURCE = 'nyc_taxi_data_raw',
    FORMAT = 'DELTA'
) AS trip_data;
```
Scans all partitions (~4 MB).

Targeting a specific partition

```sql
SELECT COUNT(DISTINCT payment_type)
FROM OPENROWSET(
    BULK 'trip_data_green_delta/',
    DATA_SOURCE = 'nyc_taxi_data_raw',
    FORMAT = 'DELTA'
) AS trip_data
WHERE year = '2020' AND month = '01';
```

Scans only the 2020/01 partition (~1 MB).

Why this works

Delta exposes partition columns as real columns.

Serverless SQL uses them to prune unnecessary folders.

This is far simpler than CSV or raw Parquet partitioning.

12. Time Travel (Not Supported in Serverless SQL Yet)

Delta Lake supports:

Versioned reads

Historical snapshots

Rollbacks

But Serverless SQL does not.

You can only read the current version.

If you update the Delta table:

Version 1 becomes history

Version 2 becomes current

Serverless SQL always reads version 2

Time travel is available in:

Databricks

Spark pools

But not yet in Serverless SQL.

13. Two‑Word Logic Summary

Delta root → Required

Transaction log → Identity

Partition columns → Exposed

Column pruning → Savings

Folder pruning → WHERE clause

Schema override → Control

Wildcard blocked → By design

Time travel → Unsupported
