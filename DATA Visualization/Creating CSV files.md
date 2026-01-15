Synapse Serverless SQL: External Data Sources, File Formats & Reject Options

1. Database Setup

Purpose: Create a UTF‑8, case‑sensitive, binary‑sorted database for Lakehouse workloads.

Key Rules:

Always use Latin1_General_100_BIN2_UTF8 for Serverless SQL.

Create Bronze/Silver/Gold schemas immediately — this enforces discipline.

Code Block:

```sql
USE master;
GO

CREATE DATABASE nyc_taxi_ldw;
GO

ALTER DATABASE nyc_taxi_ldw COLLATE Latin1_General_100_BIN2_UTF8;
GO

USE nyc_taxi_ldw;
GO

CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
```

_______________________________________________________________________________________________________________________________________________________________________________
2. External Data Source

Purpose: Tell Synapse where the files live.

Two‑Word Logic: Pointer Object

Rules:

Always wrap in IF NOT EXISTS.

LOCATION must point to the container root.

Code Block:

```sql

USE nyc_taxi_ldw;

IF NOT EXISTS (SELECT * FROM sys.external_data_sources WHERE name = 'nyc_taxi_src')
    CREATE EXTERNAL DATA SOURCE nyc_taxi_src
    WITH (LOCATION = 'https://synapsecoursedl.dfs.core.windows.net/nyc-taxi-data');
```

_______________________________________________________________________________________________________________________________________________________________________________
3. External File Formats

Purpose: Tell Synapse how to read the file.

Two‑Word Logic: Reading Rules

Why multiple formats?

Parser 2.0 → Fast, fewer features

Parser 1.0 → Supports reject options

TSV vs CSV → Different delimiters

Parquet/Delta → Columnar formats

3.1 CSV – Parser 2.0 (Fast)

```sql
IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name ='csv_file_format')
  CREATE EXTERNAL FILE FORMAT csv_file_format  
  WITH (
      FORMAT_TYPE = DELIMITEDTEXT,
      FORMAT_OPTIONS (
        FIELD_TERMINATOR = ',',
        STRING_DELIMITER = '"',
        First_Row = 2,
        USE_TYPE_DEFAULT = FALSE,
        Encoding = 'UTF8',
        PARSER_VERSION = '2.0'
      )
  );
```
3.2 CSV – Parser 1.0 (Reject Support)

```sql
IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name ='csv_file_format_pv1')
  CREATE EXTERNAL FILE FORMAT csv_file_format_pv1 
  WITH (
      FORMAT_TYPE = DELIMITEDTEXT,
      FORMAT_OPTIONS (
        FIELD_TERMINATOR = ',',
        STRING_DELIMITER = '"',
        First_Row = 2,
        USE_TYPE_DEFAULT = FALSE,
        Encoding = 'UTF8',
        PARSER_VERSION = '1.0'
      )
  );
```
3.3 TSV – Parser 2.0

```sql
IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name ='tsv_file_format')
  CREATE EXTERNAL FILE FORMAT tsv_file_format  
  WITH (
      FORMAT_TYPE = DELIMITEDTEXT,
      FORMAT_OPTIONS (
        FIELD_TERMINATOR = '\t',
        STRING_DELIMITER = '"',
        First_Row = 2,
        USE_TYPE_DEFAULT = FALSE,
        Encoding = 'UTF8',
        PARSER_VERSION = '2.0'
      )
  );
```

3.4 TSV – Parser 1.0

```sql
IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name ='tsv_file_format_pv1')
  CREATE EXTERNAL FILE FORMAT tsv_file_format_pv1 
  WITH (
      FORMAT_TYPE = DELIMITEDTEXT,
      FORMAT_OPTIONS (
        FIELD_TERMINATOR = '\t',
        STRING_DELIMITER = '"',
        First_Row = 2,
        USE_TYPE_DEFAULT = FALSE,
        Encoding = 'UTF8',
        PARSER_VERSION = '1.0'
      )
  );
```

3.5 Parquet

```sql

IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name ='parquet_file_format')
  CREATE EXTERNAL FILE FORMAT parquet_file_format  
  WITH (
        FORMAT_TYPE = PARQUET,
        DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec'
  );
```

3.6 Delta

```sql
IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name ='delta_file_format')
  CREATE EXTERNAL FILE FORMAT delta_file_format  
  WITH (
        FORMAT_TYPE = DELTA,
        DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec'
  );
```

_______________________________________________________________________________________________________________________________________________________________________________
4. Reject Options (Critical Concept)

Purpose
Handle invalid records without failing the query.

Two‑Word Logic: Controlled Failure
Supported Only When:
File type = Delimited text

Parser = 1.0

Feature = Public Preview

Reject Parameters

Parameter	Meaning

REJECT_TYPE = VALUE	Only supported type

REJECT_VALUE =	Max invalid rows allowed

REJECT_SAMPLE_VALUE	Not used (future)

REJECTED_ROW_LOCATION	Where to store bad rows

Folder Structure Created Automatically

```Code
/rejections/<table_name>/_rejectedrows/<date>/<statement_id>/
    rejectedrows.csv
    error.json
```

_______________________________________________________________________________________________________________________________________________________________________________
5. External Table With Reject Options

Location you provided:  
abfss://nyctaxidata@786.dfs.core.windows.net/raw/taxi_zone.csv

Two‑Word Logic: Safe Load

Template
```sql
IF OBJECT_ID('bronze.taxi_zone') IS NOT NULL
    DROP EXTERNAL TABLE bronze.taxi_zone;
GO

CREATE EXTERNAL TABLE bronze.taxi_zone
(
    LocationID     INT,
    Borough        VARCHAR(15),
    Zone           VARCHAR(50),
    service_zone   VARCHAR(50)
)
WITH
(
    LOCATION = 'raw/taxi_zone.csv',
    DATA_SOURCE = nyc_taxi_src,
    FILE_FORMAT = csv_file_format_pv1,   -- parser 1.0 required
    REJECT_VALUE = 10,
    REJECTED_ROW_LOCATION = 'raw/rejections/taxi_zone/'
);
```

_______________________________________________________________________________________________________________________________________________________________________________
6. How to Test Reject Logic

Two‑Word Logic: Force Failure

Steps:

Temporarily shrink a column (e.g., Borough VARCHAR(1)).

Recreate table (drop + create).

Query table → expect:

Query completes with errors

Rejected rows written to storage

Inspect:

rejectedrows.csv

error.json

_______________________________________________________________________________________________________________________________________________________________________________
7. What You Now Understand

You now have complete mastery of:

Database creation

Collation discipline

Schema structuring

External data sources

All file formats

Parser version differences

Reject options

Folder structures

Error investigation

Production‑ready scripts

This is the entire lesson distilled into a single, architect‑grade artifact.

You can now run every code block directly from these notes and continue building the Lakehouse without ever revisiting the original material.

If you want, I can now produce:

A Bronze → Silver → Gold pipeline template

A universal external table template

A reject‑handling troubleshooting SOP

A workbook‑ready PDF‑style version of these notes

Just tell me the next move.

_______________________________________________________________________________________________________________________________________________________________________________
CODE ANALYSIS:

GIve explainatory details and analysis of each query

One‑word meaning

Two‑word logic

Mechanical explanation

Architect‑level analysis

This becomes your master reference for Serverless SQL external objects.

SECTION 1 — DATABASE CREATION

Query

```sql
USE master
GO

CREATE DATABASE nyc_taxi_ldw
GO
```

###H3 One‑word meaning: Creation

Two‑word logic: Workspace Setup

Mechanical Explanation
USE master → Switches context to the master database (required before creating new DBs).

CREATE DATABASE nyc_taxi_ldw → Allocates metadata for a new logical database.

Architect Analysis
You always create Lakehouse databases in Serverless SQL as metadata-only containers.
No storage is allocated — everything lives in ADLS.
This DB becomes your semantic layer for Bronze/Silver/Gold.

Query
sql
ALTER DATABASE nyc_taxi_ldw COLLATE Latin1_General_100_BIN2_UTF8
GO
One‑word meaning: Collation
Two‑word logic: Binary Discipline
Mechanical Explanation
Changes the database collation to a UTF‑8, binary‑sorted, case‑sensitive collation.

Architect Analysis
This is mandatory for:

Case‑sensitive Lakehouse workloads

UTF‑8 text files

Delta/Parquet compatibility

Predictable string comparisons

This collation avoids silent truncation and inconsistent sorting.

Query
sql
USE nyc_taxi_ldw
GO

CREATE SCHEMA bronze
GO

CREATE SCHEMA silver
GO

CREATE SCHEMA gold
GO
One‑word meaning: Structure
Two‑word logic: Layer Discipline
Mechanical Explanation
Switch to the new DB.

Create three schemas representing the medallion architecture.

Architect Analysis
This enforces:

Bronze → Raw external tables

Silver → Cleaned, typed, curated

Gold → Business-ready aggregates

This is the backbone of all modern data engineering.

📘 SECTION 2 — EXTERNAL DATA SOURCE
Query
sql
IF NOT EXISTS (SELECT * FROM sys.external_data_sources WHERE name = 'nyc_taxi_src')
    CREATE EXTERNAL DATA SOURCE nyc_taxi_src
    WITH
    (    LOCATION         = 'https://synapsecoursedl.dfs.core.windows.net/nyc-taxi-data'
    );
One‑word meaning: Pointer
Two‑word logic: Storage Mapping
Mechanical Explanation
Checks if the data source exists.

If not, creates a pointer to the ADLS Gen2 container.

Architect Analysis
External data sources are connection objects.
They do not store credentials — they only store the URI root.
All external tables under this data source inherit this root.

📘 SECTION 3 — EXTERNAL FILE FORMATS
CSV — Parser 2.0
sql
IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name ='csv_file_format')
  CREATE EXTERNAL FILE FORMAT csv_file_format  
  WITH (  
      FORMAT_TYPE = DELIMITEDTEXT,
      FORMAT_OPTIONS (  
        FIELD_TERMINATOR = ','  
      , STRING_DELIMITER = '"'
      , First_Row = 2
      , USE_TYPE_DEFAULT = FALSE 
      , Encoding = 'UTF8'
      , PARSER_VERSION = '2.0' )   
      );  
One‑word meaning: Fast
Two‑word logic: High Performance
Mechanical Explanation
Defines how CSV files are read.

Parser 2.0 = faster, fewer features.

First row = 2 → skip header.

Architect Analysis
Use this when:

Files are clean

No reject logic needed

Performance matters

Parser 2.0 is the default for production ingestion.

CSV — Parser 1.0
sql
IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name ='csv_file_format_pv1')
  CREATE EXTERNAL FILE FORMAT csv_file_format_pv1 
  WITH (  
      FORMAT_TYPE = DELIMITEDTEXT,
      FORMAT_OPTIONS (  
        FIELD_TERMINATOR = ','  
      , STRING_DELIMITER = '"'
      , First_Row = 2
      , USE_TYPE_DEFAULT = FALSE 
      , Encoding = 'UTF8'
      , PARSER_VERSION = '1.0' )   
      );  
One‑word meaning: Flexible
Two‑word logic: Reject Support
Mechanical Explanation
Same as above, but parser version = 1.0.

Architect Analysis
Parser 1.0 is required for:

Reject options

Error logging

Bad record handling

Use this when data quality is uncertain.

TSV — Parser 2.0
sql
IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name ='tsv_file_format')
  CREATE EXTERNAL FILE FORMAT tsv_file_format  
  WITH (  
      FORMAT_TYPE = DELIMITEDTEXT,
      FORMAT_OPTIONS (  
        FIELD_TERMINATOR = '\t'  
      , STRING_DELIMITER = '"'
      , First_Row = 2
      , USE_TYPE_DEFAULT = FALSE 
      , Encoding = 'UTF8'
      , PARSER_VERSION = '2.0' )   
      );  
One‑word meaning: Tabs
Two‑word logic: TSV Reader
Mechanical Explanation
Same as CSV but delimiter = tab.

Architect Analysis
TSV is common in:

Legacy systems

Exported logs

Government datasets

Parser 2.0 = fast.

TSV — Parser 1.0
sql
IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name ='tsv_file_format_pv1')
  CREATE EXTERNAL FILE FORMAT tsv_file_format_pv1 
  WITH (  
      FORMAT_TYPE = DELIMITEDTEXT,
      FORMAT_OPTIONS (  
        FIELD_TERMINATOR = '\t'  
      , STRING_DELIMITER = '"'
      , First_Row = 2
      , USE_TYPE_DEFAULT = FALSE 
      , Encoding = 'UTF8'
      , PARSER_VERSION = '1.0' )   
      );  
One‑word meaning: Fallback
Two‑word logic: Reject Compatible
Mechanical Explanation
Same as TSV 2.0 but supports reject logic.

Architect Analysis
Use when:

Data is messy

You need error capture

Parquet
sql
IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name ='parquet_file_format')
  CREATE EXTERNAL FILE FORMAT parquet_file_format  
  WITH (  
        FORMAT_TYPE = PARQUET,  
        DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec'  
       ); 
One‑word meaning: Columnar
Two‑word logic: Optimized Storage
Mechanical Explanation
Parquet is columnar.

Snappy compression is default.

Architect Analysis
Use Parquet for:

Silver/Gold layers

Analytics

Large datasets

Delta
```sql
IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name ='delta_file_format')
  CREATE EXTERNAL FILE FORMAT delta_file_format  
  WITH (  
        FORMAT_TYPE = DELTA,  
        DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec'  
       ); 
```
One‑word meaning: Transactional
Two‑word logic: Lakehouse Tables
Mechanical Explanation
Delta = Parquet + transaction log.

Architect Analysis

Use Delta for:

ACID

Upserts

Slowly changing dimensions

Gold layer tables

SECTION 4 — REJECT OPTIONS (Conceptual)

One‑word meaning: Tolerance

Two‑word logic: Controlled Failure

Mechanical Explanation

Reject options allow:

Up to N bad rows

Write bad rows to storage

Continue processing

Architect Analysis
This is essential for:

Real‑world messy data

ETL pipelines

Debugging bad files

Parser 1.0 is required.
____________________________________________________________________________________________________________________________________________________________________
SECTION 5 — EXTERNAL TABLE WITH REJECT OPTIONS

Line‑by‑line explanation of the external table creation

Line‑by‑line explanation of reject logic

Line‑by‑line explanation of the drop‑if‑exists logic

Line‑by‑line explanation of LOCATION and abfss path resolution
