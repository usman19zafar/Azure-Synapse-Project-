FINAL NOTES — External Tables for DELTA Files (Synapse Serverless)
1, One‑Word: Delta
2, Two‑Words: Transaction Log
Business Analogy:
Parquet is a warehouse of boxes.
Delta is the same warehouse with a ledger that tells you which boxes are valid, updated, or deleted.

2,B) What Makes Delta Different?
A. Delta = Parquet + Delta Log
Delta files are literally Parquet files with:

Snappy compression

A _delta_log folder that tracks:

which Parquet files are active

which are removed

which are updated

schema changes

transaction history

B. Synapse Serverless reads Delta using the log
This is the key difference:

Parquet external table
You must specify:

```Code
LOCATION = 'folder/**'
```
because Synapse must scan subfolders manually.

Delta external table
You specify:

```Code
LOCATION = 'folder'
```
because Synapse reads _delta_log and automatically discovers all Parquet files.

C. Compression
Delta files are Parquet files → use:

Code
DATA_COMPRESSION = 'snappy'
D. No wildcard needed
Delta log handles the folder traversal.

3, Serverless SQL Rules (Critical)
❌ Not supported
OBJECT_ID()

DROP EXTERNAL TABLE IF EXISTS

ALTER EXTERNAL TABLE

✅ Supported
Use TRY/CATCH for safe drops.

4 FILE FORMAT — Delta (Snappy)
```sql
IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name = 'delta_file_format')
    CREATE EXTERNAL FILE FORMAT delta_file_format
    WITH (
        FORMAT_TYPE = DELTA,
        DATA_COMPRESSION = 'snappy'
    );
```
5 EXTERNAL TABLE — trip_data_green_delta (Correct Serverless Version)
Your pasted code uses OBJECT_ID, which does not work in Serverless.
Below is the corrected, production‑ready version.

```sql
BEGIN TRY
    DROP EXTERNAL TABLE bronze.trip_data_green_delta;
END TRY
BEGIN CATCH
    PRINT 'trip_data_green_delta not found — continuing.';
END CATCH;
```

```sql
CREATE EXTERNAL TABLE bronze.trip_data_green_delta
(
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
    congestion_surcharge FLOAT
)
WITH (
    LOCATION = 'raw/trip_data_green_delta',
    DATA_SOURCE = nyc_taxi_src,
    FILE_FORMAT = delta_file_format
);
```
```sql
SELECT TOP (100) * FROM bronze.trip_data_green_delta;
```
6, Key Takeaways (Workbook‑Ready)
Delta vs Parquet
Feature	Parquet	Delta
File type	Parquet	Parquet
Compression	Snappy	Snappy
Transaction log	❌ No	✅ Yes (_delta_log)
Wildcards needed	Yes (/**)	No
ACID semantics	❌ No	⚠️ Partial in Serverless (read‑only)
Partition discovery	Manual	Automatic via log
Delta External Table Rules
Use FORMAT_TYPE = DELTA

Use DATA_COMPRESSION = 'snappy'

Point to folder only, not subfolders

Synapse reads _delta_log to find valid Parquet files

External Table Lifecycle
Code
DROP → CREATE → SELECT

7, What You Achieved
You now understand:

How Delta builds on Parquet

How Synapse uses the Delta log

Why wildcards are not needed

How to create Delta file formats

How to create Delta external tables

How to query Delta data efficiently

This completes the full progression:

CSV → TSV → Parquet → Delta

You now have the complete mental model of how Serverless SQL interacts with every major file type in a modern data lake.
