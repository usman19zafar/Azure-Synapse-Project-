FINAL NOTES + FULL CODE (BLENDED, COMPLETE, WORKBOOK‑READY)

1, Purpose of the Exercise
We created external tables for four delimited datasets:

calendar → CSV

vendor → CSV

trip_type → TSV

trip_data_green_csv → CSV (partitioned folders)

The goal was to practice:

Creating external tables

Creating file formats (CSV + TSV)

Handling parser versions

Reading partitioned folders using wildcards

Understanding Serverless SQL limitations (no IF EXISTS, no OBJECT_ID)

2, Serverless SQL Rules (Critical)
❌ Not supported: OBJECT_ID()

DROP EXTERNAL TABLE IF EXISTS

ALTER EXTERNAL TABLE

Supported
Use TRY/CATCH for safe drops:

```sql
BEGIN TRY
    DROP EXTERNAL TABLE bronze.table_name;
END TRY
BEGIN CATCH
    PRINT 'Table not found — continuing.';
END CATCH;
```

3, FILE FORMATS (CSV + TSV)

CSV File Format (Parser Version 1.0)

```sql
IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name ='csv_file_format_pv1')
  CREATE EXTERNAL FILE FORMAT csv_file_format_pv1
  WITH (
      FORMAT_TYPE = DELIMITEDTEXT,
      FORMAT_OPTIONS (
          FIELD_TERMINATOR = ',',
          STRING_DELIMITER = '"',
          FIRST_ROW = 2,
          USE_TYPE_DEFAULT = FALSE,
          ENCODING = 'UTF8',
          PARSER_VERSION = '1.0'
      )
  );
```

CSV File Format (Parser Version 2.0)

```sql
IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name ='csv_file_format')
  CREATE EXTERNAL FILE FORMAT csv_file_format
  WITH (
      FORMAT_TYPE = DELIMITEDTEXT,
      FORMAT_OPTIONS (
          FIELD_TERMINATOR = ',',
          STRING_DELIMITER = '"',
          FIRST_ROW = 2,
          ENCODING = 'UTF8',
          PARSER_VERSION = '2.0'
      )
  );
```

TSV File Formats (Parser 1.0 + 2.0)

```sql
IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name ='tsv_file_format')
  CREATE EXTERNAL FILE FORMAT tsv_file_format
  WITH (
      FORMAT_TYPE = DELIMITEDTEXT,
      FORMAT_OPTIONS (
          FIELD_TERMINATOR = '\t',
          STRING_DELIMITER = '"',
          FIRST_ROW = 2,
          ENCODING = 'UTF8',
          PARSER_VERSION = '2.0'
      )
  );
```
```sql
IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name ='tsv_file_format_pv1')
  CREATE EXTERNAL FILE FORMAT tsv_file_format_pv1
  WITH (
      FORMAT_TYPE = DELIMITEDTEXT,
      FORMAT_OPTIONS (
          FIELD_TERMINATOR = '\t',
          STRING_DELIMITER = '"',
          FIRST_ROW = 2,
          ENCODING = 'UTF8',
          PARSER_VERSION = '1.0'
      )
  );
```

4, EXTERNAL TABLES (ALL FOUR, COMPLETE CODE)
A. CALENDAR (CSV)

```sql
BEGIN TRY
    DROP EXTERNAL TABLE bronze.calendar;
END TRY
BEGIN CATCH
    PRINT 'calendar table not found — continuing.';
END CATCH;
```

```sql
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

B. VENDOR (CSV)

```sql
BEGIN TRY
    DROP EXTERNAL TABLE bronze.vendor;
END TRY
BEGIN CATCH
    PRINT 'vendor table not found — continuing.';
END CATCH;
```
```sql
CREATE EXTERNAL TABLE bronze.vendor
(
    vendor_id   TINYINT,
    vendor_name VARCHAR(50)
)
WITH (
    LOCATION = 'raw/vendor.csv',
    DATA_SOURCE = nyc_taxi_src,
    FILE_FORMAT = csv_file_format_pv1,
    REJECT_VALUE = 10,
    REJECTED_ROW_LOCATION = 'rejections/vendor'
);
```

SELECT * FROM bronze.vendor;

C. TRIP_TYPE (TSV)
```sql
BEGIN TRY
    DROP EXTERNAL TABLE bronze.trip_type;
END TRY
BEGIN CATCH
    PRINT 'trip_type table not found — continuing.';
END CATCH;
```
```sql
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

D. TRIP_DATA_GREEN_CSV (CSV, PARTITIONED FOLDERS)
Important:
Use parser version 2.0 for performance.
Use wildcard /** to read all subfolders.

```sql
BEGIN TRY
    DROP EXTERNAL TABLE bronze.trip_data_green_csv;
END TRY
```
BEGIN CATCH
    PRINT 'trip_data_green_csv table not found — continuing.';
END CATCH;

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
SELECT TOP (100) * FROM bronze.trip_data_green_csv;
```

ARCHITECT SUMMARY (FINAL)

External Table Lifecycle

```Code
DROP (old metadata)
CREATE (new metadata)
SELECT (read files)
File Format Rules
Format	Use Case	Parser
CSV pv1	small files, reject logic	1.0
CSV pv2	large files	2.0
TSV pv1	tab-separated	1.0
TSV pv2	tab-separated	2.0
Wildcard Logic
* → match files
** → match files in all subfolders (required for partitioned data)
```
