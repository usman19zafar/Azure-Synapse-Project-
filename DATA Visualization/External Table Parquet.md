FINAL NOTES — External Tables for PARQUET Files (Synapse Serverless)
One‑Word: Parquet
Two‑Words: Columnar Efficiency

Business Analogy:
CSV is like reading every page of a book line‑by‑line.
Parquet is like jumping directly to the chapter you need.

What This Lesson Teaches
A. Parquet is columnar
Serverless reads only the columns you query

Faster, cheaper, more efficient than CSV/TSV
_______________________________________________________________________________________________________________________________________________________________________________
B. Parquet is compressed
NY taxi Parquet files use Snappy compression

You must declare this in the file format

_______________________________________________________________________________________________________________________________________________________________________________
C. Parquet is partitioned

Data stored in:
year=YYYY/month=MM/*.parquet

You must use:
LOCATION = 'raw/trip_data_green_parquet/**'  
to read all subfolders

_______________________________________________________________________________________________________________________________________________________________________________
D. Parquet file formats are simple
No delimiters, no string quotes, no parser versions.
Just:

```Code
FORMAT_TYPE = PARQUET
COMPRESSION = 'snappy'
```
_______________________________________________________________________________________________________________________________________________________________________________
E. External tables still follow the same lifecycle

```Code
DROP (old metadata)
CREATE (new metadata)
SELECT (read files)
```

Correct Serverless SQL Rules (Critical)
❌ Not supported
OBJECT_ID()

DROP EXTERNAL TABLE IF EXISTS

ALTER EXTERNAL TABLE

✅ Supported
Use TRY/CATCH for safe drops.

4, FILE FORMAT — Parquet (Snappy)

```sql
IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name = 'parquet_file_format')
    CREATE EXTERNAL FILE FORMAT parquet_file_format
    WITH (
        FORMAT_TYPE = PARQUET,
        DATA_COMPRESSION = 'snappy'
    );
```

5, EXTERNAL TABLE — trip_data_green_parquet
Correct Serverless Version (no OBJECT_ID)
```sql
BEGIN TRY
    DROP EXTERNAL TABLE bronze.trip_data_green_parquet;
END TRY
BEGIN CATCH
    PRINT 'trip_data_green_parquet not found — continuing.';
END CATCH;
```
```SQL
CREATE EXTERNAL TABLE bronze.trip_data_green_parquet
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
    LOCATION = 'raw/trip_data_green_parquet/**',
    DATA_SOURCE = nyc_taxi_src,
    FILE_FORMAT = parquet_file_format
);
```

SELECT TOP (100) * FROM bronze.trip_data_green_parquet;
6️⃣ Key Takeaways (Workbook‑Ready)
Parquet Advantages
Columnar → faster queries

Compressed → cheaper storage

Self‑describing → no schema in file format

Efficient for large datasets

Partition Handling
Use /** to read all year/month folders

Serverless does not automatically prune partitions

Partition pruning is covered in a later lesson

File Format Simplicity
Format	Needs Delimiter?	Needs Parser Version?	Needs Compression?
CSV	Yes	Yes	No
TSV	Yes	Yes	No
Parquet	No	No	Yes (Snappy)
External Table Lifecycle
Code
DROP → CREATE → SELECT
Serverless SQL Limitations
No OBJECT_ID()

No DROP IF EXISTS

No ALTER EXTERNAL TABLE

7️⃣ What You Achieved
You now know how to:

Create Parquet file formats

Declare Snappy compression

Read partitioned Parquet folders

Build external tables for columnar data

Validate with SELECT queries

Follow the correct Serverless SQL patterns

This is the foundation for the next lessons on Delta Lake, partition pruning, and performance tuning.
