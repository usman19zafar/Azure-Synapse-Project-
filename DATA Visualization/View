FINAL NOTES — Creating Views in Synapse Serverless (Bronze Layer)
1. Purpose of This Lesson
You created external tables for almost every file in the NYC Taxi dataset.
Two files could not be used to create external tables:

rate_code.json

payment_type.json

These are JSON‑adjacent files (newline‑delimited JSON fragments), which Serverless SQL cannot map to external tables.

However, Serverless SQL can read them using OPENROWSET + OPENJSON, and therefore you can expose them through views.

This lesson teaches you:

How to create views in the Bronze layer

How to use OPENROWSET to read JSON files

How to use CROSS APPLY OPENJSON to parse JSON

How to use DROP VIEW IF EXISTS

How to build a view on top of a multi‑folder CSV dataset

2. Why Views Matter in the Bronze Layer
Views allow you to:

Expose JSON data even when external tables are not supported

Hide complex OPENROWSET parameters

Standardize naming conventions

Provide a stable interface for downstream Silver/Gold layers

Add derived columns (like year/month extracted from file paths)

Apply filters or column selection

Views do not store data.
They simply replay the SELECT each time.

3. Naming Standards
The instructor recommends:

Schema: bronze

Prefix: vw_  
Example: bronze.vw_rate_code

This makes it obvious that the object is a view, not a table.

4. Important Synapse Rule
CREATE VIEW must be the first statement in a batch.

Therefore, you must separate statements using:

Code
GO
5. Final Code (Fully Embedded)
These are the exact, correct, production‑ready versions of all three views.

5.1 View: Rate Code (JSON)
sql
USE nyc_taxi_ldw
GO

-- Create view for rate code file
DROP VIEW IF EXISTS bronze.vw_rate_code
GO

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
     );
GO

SELECT * FROM bronze.vw_rate_code;
GO
5.2 View: Payment Type (JSON)
sql
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
     );
GO

SELECT * FROM bronze.vw_payment_type;
GO
5.3 View: Trip Data Green (CSV, Partitioned Folders)
This view demonstrates:

Reading partitioned folders using wildcards

Extracting folder names using filepath(n)

Exposing the raw Bronze data through a view

sql
-- Create view for trip_data_green
DROP VIEW IF EXISTS bronze.vw_trip_data_green_csv
GO

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
     ) AS result;
GO

SELECT TOP (100) *
FROM bronze.vw_trip_data_green_csv;
GO
