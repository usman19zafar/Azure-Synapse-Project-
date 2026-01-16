Final Notes — Creating Views in Synapse Serverless (Bronze Layer)

1. Core Idea: Virtual Tables

A view is a virtual table defined by a SELECT statement.
It does not store data; it exposes data from files, external tables, or other views.

____________________________________________________________________________________________________________________________________________________________________________
2. Why Views Matter

Two words: Abstraction Layer.

Two more: Access Control.

Business analogy:  

Think of a view as a front desk receptionist.

The receptionist doesn’t store the company’s data — they simply present the right information to the right people without exposing the entire building.

Views help you:

Hide file paths, storage accounts, and OPENROWSET parameters

Restrict columns

Restrict rows

Provide summarized or filtered datasets

Layer logic (view on top of view)

Standardize naming and structure for downstream consumers

____________________________________________________________________________________________________________________________________________________________________________
3. Rules of Views in Synapse Serverless

3.1 CREATE VIEW must be first in a batch

If anything appears before it (even a comment + semicolon), the engine fails.

Use GO to separate batches.

3.2 Views can be built on:

OPENROWSET

External tables

Other views

Joins between any of the above

3.3 Views do NOT support:

File formats not supported by external tables (e.g., JSON adjacent)

→ But OPENROWSET + OPENJSON solves this.

____________________________________________________________________________________________________________________________________________________________________________
4. Bronze Layer View Creation — Final Code (Clean, Correct, Complete)

This is the canonical version you can paste into your workbook.

4.1 View: Rate Code (JSON Adjacent)
```sql
USE nyc_taxi_ldw
GO
```
```sql
-- Create view for rate code file
DROP VIEW IF EXISTS bronze.vw_rate_code
GO
```
```sql
CREATE VIEW bronze.vw_rate_code
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
     )
GO

SELECT * FROM bronze.vw_rate_code
GO
```

4.2 View: Payment Type (JSON Adjacent)

```sql
-- Create view for payment type file
DROP VIEW IF EXISTS bronze.vw_payment_type
GO

CREATE VIEW bronze.vw_payment_type
AS
SELECT payment_type, description
FROM OPENROWSET(
        BULK 'raw/payment_type.json',
        DATA_SOURCE = 'nyc_taxi_src',
        FORMAT = 'CSV',
        FIELDTERMINATOR = '0x0b',
        FIELDQUOTE = '0x0b'
     )
     WITH (jsonDoc NVARCHAR(MAX)) AS payment_type
CROSS APPLY OPENJSON(jsonDoc)
WITH (
        payment_type SMALLINT,
        description  VARCHAR(20) '$.payment_type_desc'
     )
GO
```

```sql
SELECT * FROM bronze.vw_payment_type
GO
```

4.3 View: Trip Data Green (CSV Partitioned by Year/Month)

```sql
-- Create view for trip_data_green
DROP VIEW IF EXISTS bronze.vw_trip_data_green_csv
GO
```

```sql
CREATE VIEW bronze.vw_trip_data_green_csv
AS
SELECT
    result.filepath(1) AS year,
    result.filepath(2) AS month,
    result.*
FROM OPENROWSET(
        BULK 'raw/trip_data_green_csv/year=*/month=*/*.csv',
        DATA_SOURCE = 'nyc_taxi_src',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE
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
    congestion_surcharge FLOAT
) AS result
GO
```
```sql
SELECT TOP (100) *
FROM bronze.vw_trip_data_green_csv
GO
```
5. Are the Codes Enough for Notes, or Notes Enough for Code?
Short answer:
Both are required. Each completes the other.

Architect answer:
The code is the mechanical truth — the executable artifact.

The notes are the boundary truth — the conceptual artifact.

Together, they form a complete learning unit in your Data Architect workbook.

Two‑word logic:
Code = Execution

Notes = Understanding

Business analogy:
The code is the factory machine.
The notes are the operating manual.
A machine without a manual is dangerous.
A manual without a machine is useless.
Together, they create a repeatable system.
