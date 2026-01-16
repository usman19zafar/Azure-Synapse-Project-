CREATE SILVER RATE_CODE (JSON → Parquet)

One‑word anchor: Extraction  
Two‑word logic: JSON → Parquet
_________________________________________________________________________________________________________________________________________________________________________
1. Purpose (Absolute Statement)
This script transforms the rate_code JSON file into Parquet format and creates the Silver external table:

Reads JSON using OPENROWSET + OPENJSON

Extracts fields into relational columns

Writes Parquet files to silver/rate_code

Registers silver.rate_code as an external table

This is a format + structure transformation (JSON → rows/columns → Parquet).

_________________________________________________________________________________________________________________________________________________________________________
2. Why This Table Is Different
Unlike earlier Silver tables:

There is no Bronze external table for JSON files

JSON is not delimited text → cannot be read by CSV external tables

Instead, we use:

OPENROWSET to read the raw JSON file

OPENJSON to shred the JSON into columns

(Another Option Bronze views), but OPENROWSET is used here

This is the correct pattern for semi‑structured ingestion.

_________________________________________________________________________________________________________________________________________________________________________
3. Micro‑SOP (Mechanical Truth)

Step 1 — Switch database

```Code
USE nyc_taxi_ldw;
GO
```
Step 2 — Drop Silver table if it exists

```Code
IF OBJECT_ID('silver.rate_code') IS NOT NULL
    DROP EXTERNAL TABLE silver.rate_code;
GO
```
Step 3 — Create Silver table using CTAS + JSON extraction

```sql
CREATE EXTERNAL TABLE silver.rate_code
WITH
(
    DATA_SOURCE = nyc_taxi_src,
    LOCATION = 'silver/rate_code',
    FILE_FORMAT = parquet_file_format
)
AS
SELECT rate_code_id, rate_code
FROM OPENROWSET(
        BULK 'raw/rate_code.json',
        DATA_SOURCE = 'nyc_taxi_src',
        FORMAT = 'CSV',
        FIELDTERMINATOR = '0x0b',
        FIELDQUOTE = '0x0b',
        ROWTERMINATOR = '0x0b'
     )
     WITH (jsonDoc NVARCHAR(MAX)) AS rate_code
CROSS APPLY OPENJSON(jsonDoc)
WITH (
        rate_code_id TINYINT,
        rate_code    VARCHAR(20)
     );
```
Mechanical Explanation
FORMAT='CSV' with 0x0b delimiters = trick to read entire JSON file as one string

jsonDoc = the full JSON document

OPENJSON(jsonDoc) = shreds JSON array into rows

WITH(...) = defines the schema

CTAS writes Parquet files to silver/rate_code

Step 4 — Validate

```sql

SELECT * FROM silver.rate_code;
```
_________________________________________________________________________________________________________________________________________________________________________
4. Result Achievements (How Success Was Verified)

```Code
+-------------------------------+-----------------------------------------------------------+
| Result                        | How It Was Verified                                       |
+-------------------------------+-----------------------------------------------------------+
| JSON successfully read        | OPENROWSET returned jsonDoc values                        |
| JSON shredded into rows       | OPENJSON returned rate_code_id + rate_code                |
| Parquet files written         | Data Hub → silver/rate_code shows .parquet files          |
| External table created        | SELECT * FROM silver.rate_code returns rows               |
| Data matches JSON source      | Values identical to raw JSON content                      |
+-------------------------------+-----------------------------------------------------------+
```
_________________________________________________________________________________________________________________________________________________________________________
5. RCA Notes (Why Errors Occur)

```Code
+--------------------------------------+-----------------------------------------+---------------------------+
| Issue                                | Root Cause                              | Fix                       |
+--------------------------------------+-----------------------------------------+---------------------------+
| "Location already exists"            | silver/rate_code folder exists          | Delete folder             |
| "External table exists"              | Metadata exists                         | DROP EXTERNAL TABLE       |
| "Cannot read JSON"                   | Wrong BULK path or data source          | Fix BULK path             |
| "OPENJSON returned NULL"             | Wrong JSON structure                    | Validate JSON format      |
| "Batch error"                        | Missing GO between DDL statements       | Add GO                    |
+--------------------------------------+-----------------------------------------+---------------------------+
```
_________________________________________________________________________________________________________________________________________________________________________
6. ASCII Table — JSON → Parquet Flow
```Code
+----------------------+------------------------------+------------------------------+
| Stage                | Action                       | Output                       |
+----------------------+------------------------------+------------------------------+
| Raw (JSON)           | OPENROWSET reads file        | jsonDoc (NVARCHAR(MAX))      |
| Shredding            | OPENJSON parses jsonDoc      | rate_code_id, rate_code      |
| CTAS                 | Writes Parquet to Silver     | silver/rate_code/*.parquet   |
| External Table       | Registers metadata           | silver.rate_code             |
+----------------------+------------------------------+------------------------------+
```
_________________________________________________________________________________________________________________________________________________________________________
7. Absolute Notes (Canonical Truths)
JSON files cannot be used directly with external tables

OPENROWSET + OPENJSON is the correct ingestion pattern

CTAS writes Parquet and registers metadata in one step

CTAS never overwrites → folder must be deleted before rerun

Views and OPENROWSET have identical performance (views are not materialized)

JSON → Parquet is both format and structure transformation
