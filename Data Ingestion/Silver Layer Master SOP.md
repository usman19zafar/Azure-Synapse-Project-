SILVER LAYER MASTER SOP
One‑word anchor: Conversion  
Two‑word logic: CSV → Parquet

1. Purpose (Absolute Statement)
The Silver layer performs a format‑only transformation:

Reads CSV data from Bronze external tables

Converts it to Parquet

Writes Parquet files to the Silver folder structure

Creates Silver external tables pointing to those Parquet files

No business rules.
No filtering.
No enrichment.
Only format optimization.

2. Scope
This SOP applies to all Silver tables:

silver.taxi_zone

silver.trip_type

silver.vendor

silver.calendar

Each table is created using CTAS (CREATE EXTERNAL TABLE AS SELECT).

3. System Components
Component	Purpose
Bronze external tables	Read CSV files
Silver folders	Store Parquet output
Parquet file format	Defines output format
CTAS	Performs read → convert → write → register
External data source	Points to ADLS container
4. Silver Layer Micro‑SOP (Mechanical Truth)
Step 1 — Switch to the correct database
Code
USE nyc_taxi_ldw;
GO
Step 2 — Ensure the Silver schema exists
Code
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'silver')
    EXEC('CREATE SCHEMA silver');
GO
Step 3 — Drop the Silver table if it exists
Code
IF OBJECT_ID('silver.<table>') IS NOT NULL
    DROP EXTERNAL TABLE silver.<table>;
GO
Step 4 — Delete the Silver folder (mandatory)
CTAS cannot overwrite.
Folder must not exist.

Path pattern:

Code
silver/<table>/
Delete the entire folder.

Step 5 — Create the Silver external table using CTAS
Code
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
Step 6 — Validate
Code
SELECT COUNT(*) FROM silver.<table>;
SELECT TOP 10 * FROM silver.<table>;
Step 7 — Storage validation
Data Hub → Container → silver/<table>/

Expect:

Parquet files

_SUCCESS

_committed_* files

5. Silver Layer Folder Structure
Code
silver/
   taxi_zone/
   trip_type/
   vendor/
   calendar/
Each folder is created automatically by CTAS.

6. Silver Layer CTAS Templates (Clean, Reusable)
Template
Code
USE nyc_taxi_ldw;
GO

IF OBJECT_ID('silver.<table>') IS NOT NULL
    DROP EXTERNAL TABLE silver.<table>;
GO

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
Replace <table> with:

taxi_zone

trip_type

vendor

calendar

7. ASCII Table — Silver Layer Overview
Code
+------------------+---------------------------+-------------------------------------------+
| Silver Table     | Reads From (Bronze)       | Writes To (Storage Folder)                |
+------------------+---------------------------+-------------------------------------------+
| silver.taxi_zone | bronze.taxi_zone          | silver/taxi_zone                          |
| silver.trip_type | bronze.trip_type          | silver/trip_type                          |
| silver.vendor    | bronze.vendor             | silver/vendor                             |
| silver.calendar  | bronze.calendar           | silver/calendar                           |
+------------------+---------------------------+-------------------------------------------+
8. RCA Table — Why Silver CTAS Fails
Code
+--------------------------------------+-----------------------------------------+---------------------------+
| Issue                                | Root Cause                              | Fix                       |
+--------------------------------------+-----------------------------------------+---------------------------+
| "Location already exists"            | Folder silver/<table> exists            | Delete folder             |
| "External table exists"              | Metadata exists                          | DROP EXTERNAL TABLE       |
| "Schema does not exist"              | silver schema missing                    | CREATE SCHEMA silver      |
| "Cannot overwrite files"             | CTAS never overwrites                    | Pipeline cleanup required |
| "Batch error"                        | DDL cannot share batch                   | Use GO                    |
| "No files written"                   | Wrong LOCATION or file format            | Correct parameters        |
+--------------------------------------+-----------------------------------------+---------------------------+
9. Absolute Notes (Canonical Truths)
These are the rules that never change:

CTAS writes Parquet only

CTAS writes to one folder per table

CTAS never overwrites existing folders

Silver folder must be deleted before each run

Bronze → Silver is format‑only

Each Silver table must have its own CTAS block

External table DDL must be separated by GO

Pipelines handle cleanup in production

10. Silver Layer Master Script (All Tables in One File)
This is optional but allowed:

Code
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
One script, four CTAS operations.
