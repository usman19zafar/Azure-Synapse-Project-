Lecture: Creating Bronze External Tables + Handling Invalid Records (Reject Options)
Professional Notes + Explanations + Tree Diagram + Your Exact Code
1. Lecture Tree Diagram (Conceptual Flow)

```Code
Bronze Layer – External Table Creation & Reject Handling
│
├── 1. Understanding Invalid Records
│     ├── Why invalid rows occur
│     ├── Why queries fail without reject logic
│     └── Why reject handling is essential in LDW
│
├── 2. Reject Options (Serverless SQL)
│     ├── REJECT_VALUE (max allowed invalid rows)
│     ├── REJECTED_ROW_LOCATION (where rejected rows are written)
│     ├── Parser Version 1.0 requirement
│     └── Only works for delimited text (CSV/TSV)
│
├── 3. External Table Lifecycle
│     ├── Check if table exists
│     ├── Drop external table (metadata only)
│     └── Recreate with reject logic
│
├── 4. Bronze Tables Created
│     ├── taxi_zone (CSV + reject logic)
│     ├── calendar (CSV + reject logic)
│     ├── vendor (CSV + reject logic)
│     ├── trip_type (TSV + reject logic)
│     ├── trip_data_green_csv (CSV, no reject logic)
│     ├── trip_data_green_parquet (Parquet)
│     └── trip_data_green_delta (Delta)
│
└── 5. Validation
      ├── SELECT queries
      ├── Rejected rows written to ADLS
      └── JSON error files for debugging
```
__________________________________________________________________________________________________________________________________________________________________________________
2. Why Reject Handling Matters
Problem
External tables enforce strict data types.
If even one row contains:

a string where an INT is expected

a value longer than the defined VARCHAR

a malformed date

a corrupted row

…the entire query fails.

Why this is unacceptable in real projects
Because real-world data is messy.
You must be able to:

allow a controlled number of bad rows

continue processing

store invalid rows for investigation, 
Reject Options Solve These issues.

```code
Reject options allow:

Option	Meaning
REJECT_VALUE	Max invalid rows allowed before failure
REJECTED_ROW_LOCATION	Folder where rejected rows + JSON error logs are written
Parser Version Requirement
Reject logic only works with parser version 1.0, so CSV/TSV tables must use:
```

```Code
FILE_FORMAT = csv_file_format_pv1
FILE_FORMAT = tsv_file_format_pv1
```

__________________________________________________________________________________________________________________________________________________________________________________
3. Why We Drop External Tables Before Recreating Them

External tables store metadata only, not data.

Dropping them:

does NOT delete data in ADLS

simply removes the metadata definition

allows you to recreate the table with new settings (reject logic)

This is safe and standard practice.


__________________________________________________________________________________________________________________________________________________________________________________
4. Why LOCATION Paths Differ

```code
+---------------------------+----------------------------------------+-------------------------------+
| Table                     | LOCATION                               | Meaning                       |
+---------------------------+----------------------------------------+-------------------------------+
| taxi_zone                 | raw/taxi_zone.csv                      | Single CSV file               |
| calendar                  | raw/calendar.csv                       | Single CSV file               |
| vendor                    | raw/vendor.csv                         | Single CSV file               |
| trip_type                 | raw/trip_type.tsv                      | Single TSV file               |
| trip_data_green_csv       | raw/trip_data_green_csv/**             | Folder with many CSV files    |
| trip_data_green_parquet   | raw/trip_data_green_parquet/**         | Folder with many Parquet      |
|                           |                                        | files (recursive)             |
| trip_data_green_delta     | raw/trip_data_green_delta              | Delta Lake folder             |
+---------------------------+----------------------------------------+-------------------------------+
The /** wildcard tells Synapse to read all files recursively.
```

Mechanical Note
The /** wildcard instructs Synapse Serverless SQL to read all files recursively, including subfolders.

No wildcard is needed for Delta Lake folders because Synapse automatically reads the transaction log and underlying Parquet files.
__________________________________________________________________________________________________________________________________________________________________________________
5. Why Different File Formats Are Used
```code
+-------------------------+-----------------------------------------------+
| File Format             | Why Used                                      |
+-------------------------+-----------------------------------------------+
| csv_file_format_pv1     | Required for reject logic                     |
| tsv_file_format_pv1     | Required for reject logic on TSV              |
| csv_file_format         | Faster parser for large CSV datasets          |
| parquet_file_format     | Columnar, compressed, optimized               |
| delta_file_format       | ACID, versioned, Lakehouse-ready              |
+-------------------------+-----------------------------------------------+
```
__________________________________________________________________________________________________________________________________________________________________________________
6. Full Code With Explanations Before Each Block

6.1 taxi_zone External Table (CSV + Reject Logic)

Why this table exists
This is the first Bronze table.

It demonstrates:

reject handling

CSV ingestion

metadata recreation pattern

Why REJECT_VALUE = 10

Allows up to 10 bad rows before failing.

Why REJECTED_ROW_LOCATION

Stores rejected rows + JSON error logs for debugging.

Code
```sql
USE nyc_taxi_ldw;
```

```sql
-- Create taxi_zone table
IF EXISTS (SELECT * FROM sys.external_tables WHERE name = 'taxi_zone' AND schema_id = SCHEMA_ID('bronze'))
    DROP EXTERNAL TABLE bronze.taxi_zone;
```
OR
```sql
-- Drop if exists (Serverless-compatible)
IF EXISTS (
    SELECT * 
    FROM sys.external_tables 
    WHERE name = 'taxi_zone' 
      AND schema_id = SCHEMA_ID('bronze')
)
    DROP EXTERNAL TABLE bronze.taxi_zone;
```
```sql
IF OBJECT_ID('bronze.taxi_zone') IS NOT NULL
    DROP EXTERNAL TABLE bronze.taxi_zone;

CREATE EXTERNAL TABLE bronze.taxi_zone
    (   location_id SMALLINT ,
        borough VARCHAR(15) ,
        zone VARCHAR(50) ,
        service_zone VARCHAR(15) )  
    WITH (
            LOCATION = 'raw/taxi_zone.csv',  
            DATA_SOURCE = nyc_taxi_src,  
            FILE_FORMAT = csv_file_format_pv1,
            REJECT_VALUE = 10,
            REJECTED_ROW_LOCATION = 'rejections/taxi_zone'
    );

SELECT s.name AS schema_name, t.name AS table_name
FROM sys.external_tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
ORDER BY s.name, t.name;
```

The Mechanical Truth
Serverless SQL external tables do NOT appear in the Synapse Studio “Tables” pane.  
They only appear in:

The database → External Tables folder

Or via a query against sys.external_tables

If you’re looking under Tables (the regular tables folder), you will never see them.

How to Confirm the Table Exists
Run this:

Code
SELECT * 
FROM sys.external_tables
WHERE name = 'taxi_zone';
If it returns a row → the table exists.

You can also check the schema:

```Code
SELECT s.name AS schema_name, t.name AS table_name
FROM sys.external_tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
ORDER BY s.name, t.name;
```
You should see:
```code
bronze   taxi_zone
```
Where It Appears in Synapse Studio
In the left pane:

```Code
nyc_taxi_ldw
 └── External Tables
       └── bronze.taxi_zone
```

NOT under:

```Code
nyc_taxi_ldw
 └── Tables
```
That folder is only for physical tables in Dedicated SQL Pools.

Serverless SQL has no physical storage, so everything is external.

Quick Test Query
To prove the table works:

```Code
SELECT TOP 10 *
FROM bronze.taxi_zone;
If this returns rows → everything is correct.
```

```sql
SELECT * FROM bronze.taxi_zone;
```

6.2 calendar External Table (CSV + Reject Logic)
Why this table exists
A reusable date dimension for analytics.

Why reject logic
Calendar files sometimes contain malformed dates or stray characters.


-- Create calendar table

```sql

IF OBJECT_ID('bronze.calendar') IS NOT NULL
    DROP EXTERNAL TABLE bronze.calendar;

CREATE EXTERNAL TABLE bronze.calendar
    (
        date_key        INT,
        date            DATE,
        year            SMALLINT,
        month           TINYINT,
        day             TINYINT,
        day_name        VARCHAR(10),
        day_of_year     SMALLINT,
        week_of_month   TINYINT,
        week_of_year    TINYINT,
        month_name      VARCHAR(10),
        year_month      INT,
        year_week       INT
    )  
    WITH (
        LOCATION = 'raw/calendar.csv',  
        DATA_SOURCE = nyc_taxi_src,  
        FILE_FORMAT = csv_file_format_pv1,
        REJECT_VALUE = 10,
        REJECTED_ROW_LOCATION = 'rejections/calendar'
    );
```

```sql
SELECT * FROM bronze.calendar;
```

6.3 vendor External Table (CSV + Reject Logic)
Why this table exists
Maps vendor IDs to vendor names.

Why reject logic
Vendor files often contain stray characters or corrupted rows.

Code
```sql
-- Create vendor table
IF OBJECT_ID('bronze.vendor') IS NOT NULL
    DROP EXTERNAL TABLE bronze.vendor;

CREATE EXTERNAL TABLE bronze.vendor
    (
        vendor_id       TINYINT,
        vendor_name     VARCHAR(50)
    )  
    WITH (
        LOCATION = 'raw/vendor.csv',  
        DATA_SOURCE = nyc_taxi_src,  
        FILE_FORMAT = csv_file_format_pv1,
        REJECT_VALUE = 10,
        REJECTED_ROW_LOCATION = 'rejections/vendor'
    );
```

```sql
SELECT * FROM bronze.vendor;
```

6.4 trip_type External Table (TSV + Reject Logic)

Why this table exists
Maps trip type codes to descriptions.

Why TSV format
The source file is tab‑separated.

Why reject logic
TSV files often contain inconsistent delimiters.

Code
```sql
-- Create trip_type table
IF OBJECT_ID('bronze.trip_type') IS NOT NULL
    DROP EXTERNAL TABLE bronze.trip_type;

CREATE EXTERNAL TABLE bronze.trip_type
    (
        trip_type       TINYINT,
        trip_type_desc  VARCHAR(50)
    )  
    WITH (
        LOCATION = 'raw/trip_type.tsv',  
        DATA_SOURCE = nyc_taxi_src,  
        FILE_FORMAT = tsv_file_format_pv1,
        REJECT_VALUE = 10,
        REJECTED_ROW_LOCATION = 'rejections/trip_type'
    );
```

```sql

SELECT * FROM bronze.trip_type;
```

6.5 trip_data_green_csv (CSV Folder, No Reject Logic)
Why no reject logic?
This dataset is large and uses parser version 2.0, which is faster but does not support reject logic.

Why LOCATION = 'raw/trip_data_green_csv/'**

Reads all CSV files recursively.

Code
```sql
-- Create trip_data_green_csv table
IF OBJECT_ID('bronze.trip_data_green_csv') IS NOT NULL
    DROP EXTERNAL TABLE bronze.trip_data_green_csv;
```

```sql
CREATE EXTERNAL TABLE bronze.trip_data_green_csv
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
        LOCATION = 'raw/trip_data_green_csv/**',
        DATA_SOURCE = nyc_taxi_src,   
        FILE_FORMAT = csv_file_format
    );
```

```sql
SELECT TOP(100) * FROM bronze.trip_data_green_csv;
```

6.6 trip_data_green_parquet (Parquet Folder)
Why Parquet?

Columnar, compressed, optimized for analytics.

Code
```sql
-- Create trip_data_green_parquet table
IF OBJECT_ID('bronze.trip_data_green_parquet') IS NOT NULL
    DROP EXTERNAL TABLE bronze.trip_data_green_parquet;
```
```sql
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
SELECT TOP(100) * FROM bronze.trip_data_green_parquet;

6.7 trip_data_green_delta (Delta Lake Folder)
Why Delta?
Delta Lake supports:

ACID transactions

versioning

schema evolution

Code

```sql
-- Create trip_data_green_delta table
IF OBJECT_ID('bronze.trip_data_green_delta') IS NOT NULL
    DROP EXTERNAL TABLE bronze.trip_data_green_delta;
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

SELECT TOP(100) * FROM bronze.trip_data_green_delta;
```
__________________________________________________________________________________________________________________________________________________________________________________
7. Final Notes (For GitHub)
Why reject logic is critical
It prevents entire pipelines from failing due to a few bad rows.

Why parser version 1.0 is required
Reject logic is only implemented in parser v1.0.

Why external tables are safe to drop
They store metadata only — data remains in ADLS.

Why LOCATION paths differ
Some tables read single files, others read entire folders.

Why this lecture matters
This is the foundation of the Bronze Layer in a modern Lakehouse architecture.
