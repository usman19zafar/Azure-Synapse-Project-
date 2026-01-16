BRONZE + SILVER UNIFIED SOP

One‑word anchor: Flow  

Two‑word logic: Ingest → Convert
_________________________________________________________________________________________________________________________________________________________________
1. Purpose (Absolute Statement)

This SOP defines the end‑to‑end mechanical process for:

Ingesting raw CSV files into the Bronze layer

Creating Bronze external tables

Converting CSV → Parquet using CTAS

Writing Parquet files into the Silver layer

Creating Silver external tables

This is a format‑only pipeline.

No business transformations occur.

_________________________________________________________________________________________________________________________________________________________________
2. Architecture Overview
Layer	Purpose	Format	Access Method
Bronze	Raw ingestion	CSV	External table
Silver	Optimized storage	Parquet	External table (CTAS output)

_________________________________________________________________________________________________________________________________________________________________
4. Unified Micro‑SOP (Bronze → Silver)
This is the mechanical sequence that never changes.

Step 1 — Switch to the correct database

```Code
USE nyc_taxi_ldw;
GO
```

Step 2 — Ensure schemas exist
```Code
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'bronze')
    EXEC('CREATE SCHEMA bronze');

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'silver')
    EXEC('CREATE SCHEMA silver');
GO
```

Step 3 — Create Bronze External Table (CSV)
Bronze reads raw CSV files directly.

```Code
CREATE EXTERNAL TABLE bronze.<table>
WITH
(
    DATA_SOURCE = nyc_taxi_src,
    LOCATION = 'raw/<table>',
    FILE_FORMAT = csv_file_format
)
AS
SELECT * FROM OPENROWSET(...)
```
Mechanical truth:  
Bronze = metadata layer over CSV.

Step 4 — Drop Silver table if it exists

```Code
IF OBJECT_ID('silver.<table>') IS NOT NULL
    DROP EXTERNAL TABLE silver.<table>;
GO
```

Step 5 — Delete Silver folder (mandatory)
CTAS cannot overwrite.
Folder must not exist.

Path:

```Code
silver/<table>/
```
Delete the entire folder.

Step 6 — Create Silver External Table (Parquet) using CTAS

```sql
CREATE EXTERNAL TABLE silver.<table>
WITH
(
    DATA_SOURCE = nyc_taxi_src,
    LOCATION = 'silver/<table>',
    FILE_FORMAT = parquet_file_format
)
AS
SELECT *
FROM bronze.<table>;
GO
```

Mechanical truth:  
CTAS = READ → CONVERT → WRITE → REGISTER.

Step 7 — Validate Silver table
```Code
SELECT COUNT(*) FROM silver.<table>;
SELECT TOP 10 * FROM silver.<table>;
```
Step 8 — Validate storage
Data Hub → Container → silver/<table>/

Expect:

Parquet files

_SUCCESS

_committed_* files

_________________________________________________________________________________________________________________________________________________________________
4. Bronze + Silver Folder Structure
```Code
raw/
   taxi_zone/
   trip_type/
   vendor/
   calendar/

silver/
   taxi_zone/
   trip_type/
   vendor/
   calendar/
```
_________________________________________________________________________________________________________________________________________________________________
5. Unified ASCII Table — Bronze → Silver Mapping

```Code
+------------------+---------------------------+-------------------------------------------+
| Silver Table     | Reads From (Bronze)       | Writes To (Storage Folder)                |
+------------------+---------------------------+-------------------------------------------+
| silver.taxi_zone | bronze.taxi_zone          | silver/taxi_zone                          |
| silver.trip_type | bronze.trip_type          | silver/trip_type                          |
| silver.vendor    | bronze.vendor             | silver/vendor                             |
| silver.calendar  | bronze.calendar           | silver/calendar                           |
+------------------+---------------------------+-------------------------------------------+
```
_________________________________________________________________________________________________________________________________________________________________
6. Unified RCA Table — Why Bronze/Silver Fail

```Code
+--------------------------------------+-----------------------------------------+---------------------------+
| Issue                                | Root Cause                              | Fix                       |
+--------------------------------------+-----------------------------------------+---------------------------+
| "Schema does not exist"              | bronze/silver schema missing             | CREATE SCHEMA             |
| "External table exists"              | Metadata exists                          | DROP EXTERNAL TABLE       |
| "Location already exists"            | Silver folder contains files             | Delete folder             |
| "Cannot overwrite files"             | CTAS never overwrites                    | Pipeline cleanup required |
| "Batch error"                        | DDL cannot share batch                   | Use GO                    |
| "No files written"                   | Wrong LOCATION or file format            | Correct parameters        |
| "Row mismatch"                       | Bronze table incomplete                  | Rebuild Bronze            |
+--------------------------------------+-----------------------------------------+---------------------------+
```
_________________________________________________________________________________________________________________________________________________________________
7. Absolute Notes (Canonical Truths)
These rules never change:

Bronze = CSV ingestion

Silver = Parquet optimization

CTAS writes to one folder per table

CTAS never overwrites existing folders

Silver folder must be deleted before each run

External table DDL must be separated by GO

Bronze → Silver is format‑only

Pipelines automate folder cleanup in production

Each Silver table must have its own CTAS block

_________________________________________________________________________________________________________________________________________________________________
8. Unified Master Script (All Tables in One File)
This is allowed and recommended:

```Code
-- taxi_zone
CTAS...
GO

-- trip_type
CTAS...
GO

-- vendor
CTAS...
GO

-- calendar
CTAS...
GO
```
One script, four CTAS operations.
