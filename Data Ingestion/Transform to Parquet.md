CREATE SILVER TABLE (taxi_zone)
One‑word anchor: Conversion  
Two‑word logic: CSV → Parquet
______________________________________________________________________________________________________________________________________________________________________
1. Purpose (Absolute Statement)
This script reads CSV data from the Bronze layer, converts it to Parquet, writes it to the Silver layer, and creates an external table pointing to the new Parquet files.
No business transformations occur — only file‑format transformation.

______________________________________________________________________________________________________________________________________________________________________
2. Full Task List 
Every task performed in this lesson is listed below.
This is the authoritative checklist.

A. Environment Preparation
Switch to correct database (nyc_taxi_ldw)

Ensure schema alignment (Bronze → Silver)

B. Table Safety
Check if silver.taxi_zone already exists

Drop the external table if it exists

Use GO to separate batches (required for external table operations)

C. Storage Preparation
```code
Understand that CE (CREATE EXTERNAL TABLE AS SELECT) writes files

Identify Silver layer folder path: silver/taxi_zone

Confirm that CE cannot overwrite existing files

Manually delete existing folder is an option.(for now)
```

D. External Table Creation
Define three mandatory parameters:

DATA_SOURCE → nyc_taxi_src

LOCATION → 'silver/taxi_zone'

FILE_FORMAT → parquet_file_format

Use CTAS (CREATE TABLE AS SELECT) to:

Read from bronze.taxi_zone

Write Parquet files to Silver

Create external table metadata

E. Validation
Confirm data written (Synapse messages show bytes written)

Verify folder creation in Data Hub

Verify Parquet files exist

Query silver.taxi_zone to confirm data matches Bronze

F. Production Considerations
CE cannot delete or overwrite files

Pipelines must handle folder cleanup

Each Silver table gets its own script (modular execution)

______________________________________________________________________________________________________________________________________________________________________
3. Micro‑SOP (Mechanical Truth)
This is the step‑by‑step operational sequence.

Step 1 — Switch Database
```sql
USE nyc_taxi_ldw;
```
Reason: All Bronze and Silver objects live here.

Step 2 — Drop Existing External Table

```sql
IF OBJECT_ID('silver.taxi_zone') IS NOT NULL
    DROP EXTERNAL TABLE silver.taxi_zone
GO
```
Mechanical Notes:

OBJECT_ID checks metadata

DROP EXTERNAL TABLE removes only metadata

GO is required because external table DDL cannot share a batch

This does not delete files — only the table definition

Step 3 — Create External Table Using CTAS

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
Mechanical Code Explanation (Syntax‑Level)

CREATE EXTERNAL TABLE silver.taxi_zone

Schema: silver

Table name: taxi_zone

WITH (...)

Parentheses required

Commas separate parameters

Order does not matter, but convention is:

DATA_SOURCE

LOCATION

FILE_FORMAT

DATA_SOURCE = nyc_taxi_src

Points to the container root

Already created in earlier lessons

LOCATION = 'silver/taxi_zone'

Folder is created automatically

CE writes Parquet files here

FILE_FORMAT = parquet_file_format

Must match previously created file format object

Controls output format

AS SELECT * FROM bronze.taxi_zone

Reads CSV via Bronze external table

Writes Parquet

Creates metadata for Silver table

______________________________________________________________________________________________________________________________________________________________________
4. Result Achievements (How Success Was Verified)
Each success condition is listed with the evidence.

Result	How It Was Verified

External table created	Synapse message: “Command completed successfully”
Data written to storage	Message shows “data written: X MB”
Silver folder created	Data Hub → Container → silver/taxi_zone
Parquet files generated	Visible under the folder
Table query works	SELECT * FROM silver.taxi_zone returns rows
Data matches Bronze	Row count and columns identical
5. RCA Notes (Why Errors Occur)
These are the mechanical truths behind failures.

Error	Root Cause	Fix

“External table already exists”	Metadata exists	Drop table
“External table location already exists”	Folder contains files	Delete folder
“Cannot overwrite files”	CE never overwrites	Use pipeline cleanup
“Batch error with semicolon”	External table DDL cannot share batch	Use GO
6. Absolute Notes (Final, Publish‑Ready)
CE (CTAS) writes files and creates metadata in one operation

CE cannot overwrite existing files

Silver layer requires clean folder before each run

External table creation requires three parameters

Bronze → Silver transformation is format‑only

Each Silver table gets its own script

Pipelines will automate folder cleanup in production
