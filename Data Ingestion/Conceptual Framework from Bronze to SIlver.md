BRONZE + SILVER MASTER SOP
One‑word anchor: Flow  
Two‑word logic: Ingest → Transform
________________________________________________________________________________________________________________________________________________
1. Scope (Absolute Statement)
This SOP defines the end‑to‑end mechanical process for:

Reading raw CSV files from the Bronze layer

Creating Bronze external tables

Converting CSV → Parquet

Writing Parquet files to the Silver layer

Creating Silver external tables

Ensuring rerun‑safe execution

This SOP is format‑only: no business transformations occur.

________________________________________________________________________________________________________________________________________________
2. System Components
Layer	Purpose	Format	Access Method
Bronze	Raw ingestion	CSV	External table or OPENROWSET
Silver	Clean, optimized storage	Parquet	External table


________________________________________________________________________________________________________________________________________________
3. Master Task List (Absolute, Exhaustive)
This is the authoritative checklist for the entire Bronze → Silver pipeline.

A. Bronze Layer Tasks
Create container folder structure (raw/…)

Create external data source (nyc_taxi_src)

Create CSV file format object

Create Bronze external table (schema = bronze)

Validate row count and schema

B. Silver Layer Tasks
Create Silver folder structure (silver/…)

Create Parquet file format object

Drop existing Silver external table (metadata only)

Delete Silver folder contents (files must be removed)

Create Silver external table using CTAS

Validate Parquet files

Validate Silver table row count

C. Rerun Safety Tasks
Ensure Bronze table exists

Ensure Silver table is dropped

Ensure Silver folder is empty

Ensure CTAS writes successfully

Ensure metadata matches storage

D. Production Pipeline Tasks
Automated folder cleanup

Automated CTAS execution

Automated validation queries

Logging and monitoring

________________________________________________________________________________________________________________________________________________
4. Bronze SOP (Mechanical Truth)
Step 1 — Switch Database
Code
USE nyc_taxi_ldw;
Step 2 — Create Bronze External Table
```sql
CREATE EXTERNAL TABLE bronze.taxi_zone
WITH
(
    DATA_SOURCE = nyc_taxi_src,
    LOCATION = 'raw/taxi_zone',
    FILE_FORMAT = csv_file_format
)
AS SELECT * FROM OPENROWSET(...)
```
Mechanical Notes:

Bronze reads CSV directly

Bronze table is a thin metadata layer

No transformations occur

5. Silver SOP (Mechanical Truth)
Step 1 — Drop Existing Silver Table

```sql
IF OBJECT_ID('silver.taxi_zone') IS NOT NULL
    DROP EXTERNAL TABLE silver.taxi_zone
GO
```
Step 2 — Ensure Silver Folder Is Empty
CE cannot overwrite

Folder must be manually or pipeline‑deleted

Step 3 — Create Silver External Table Using CTAS

```sql
CREATE EXTERNAL TABLE silver.taxi_zone
WITH
(
    DATA_SOURCE = nyc_taxi_src,
    LOCATION = 'silver/taxi_zone',
    FILE_FORMAT = parquet_file_format
)
AS
SELECT *
FROM bronze.taxi_zone;
```
Mechanical Notes:

CTAS performs read → convert → write → register

Parquet files are created automatically

Folder is created automatically

________________________________________________________________________________________________________________________________________________
6. Validation SOP
A. Storage Validation

Data Hub → container → silver/taxi_zone

Confirm .parquet files exist

Confirm file count > 0

B. Table Validation
```sql
SELECT COUNT(*) FROM silver.taxi_zone;
SELECT TOP 10 * FROM silver.taxi_zone;
```
C. Consistency Check
```sql
SELECT COUNT(*) FROM bronze.taxi_zone;
SELECT COUNT(*) FROM silver.taxi_zone;
```
Counts must match.

________________________________________________________________________________________________________________________________________________
7. RCA Table (Why Things Break)
Issue	Root Cause	Fix
```code
+---------------------------------------------------------------------------------+
|                              ROOT CAUSE ANALYSIS (RCA)                          |
+---------------------------+-------------------------------+---------------------+
| Issue                     | Root Cause                    | Fix                 |
+---------------------------+-------------------------------+---------------------+
| "Location already exists" | Silver folder contains files   | Delete folder      |
| "External table exists"   | Metadata exists                | Drop table         |
| "Batch error"             | DDL cannot share batch         | Use GO             |
| "No files written"        | Wrong LOCATION or file format  | Correct parameters |
| "Row mismatch"            | Bronze table incomplete        | Rebuild Bronze     |
+---------------------------+-------------------------------+---------------------+
```
“Location already exists”	Silver folder contains files	Delete folder
“External table exists”	Metadata exists	Drop table
“Batch error”	External table DDL cannot share batch	Use GO
“No files written”	Wrong LOCATION or file format	Correct parameters
“Row mismatch”	Bronze table incomplete	Rebuild Bronze
8. Absolute Notes (Canonical Truths)
Bronze = CSV → metadata

Silver = Parquet → optimized

CTAS = write + convert + register

CTAS never overwrites

Folder cleanup is mandatory

Silver tables must be modular (one script per table)

Pipelines handle deletion + execution in production

ASCII DIAGRAM — BRONZE → SILVER FLOW
```Code
                 ┌──────────────────────────────┐
                 │        RAW STORAGE           │
                 │      (CSV Files in Blob)     │
                 └──────────────┬───────────────┘
                                │
                                ▼
                     ┌────────────────────┐
                     │   BRONZE LAYER     │
                     │  External Table    │
                     │  (CSV Metadata)    │
                     └─────────┬──────────┘
                               │  SELECT *
                               │
                               ▼
                 ┌──────────────────────────────┐
                 │   CTAS (CREATE EXTERNAL)     │
                 │  Reads CSV → Writes Parquet  │
                 │  Creates Silver Metadata     │
                 └──────────────┬───────────────┘
                                │
                                ▼
                     ┌────────────────────┐
                     │   SILVER LAYER     │
                     │   Parquet Files    │
                     │ External Table     │
                     └────────────────────┘
```

