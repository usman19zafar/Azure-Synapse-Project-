Logical Data Warehouse (LDW) Setup in Synapse Serverless SQL

Professional Notes + Explanations + Clean Code (Native External Data Source Style)

This document prepares the Logical Data Warehouse (LDW) environment inside Azure Synapse Serverless SQL.

It includes:

Creating the LDW database

Applying UTF‑8 collation

Creating bronze/silver/gold schemas

Creating a native‑style external data source

Creating all required external file formats (CSV, TSV, Parquet, Delta)

```code

Logical Data Warehouse Setup (Synapse Serverless SQL)
│
├── 1. Database Initialization
│   │
│   ├── USE master
│   ├── CREATE DATABASE nyc_taxi_ldw
│   └── ALTER DATABASE nyc_taxi_ldw 
│         └── Set collation: Latin1_General_100_BIN2_UTF8
│
├── 2. Schema Architecture (Medallion Model)
│   │
│   ├── USE nyc_taxi_ldw
│   ├── CREATE SCHEMA bronze   (raw zone)
│   ├── CREATE SCHEMA silver   (cleansed zone)
│   └── CREATE SCHEMA gold     (curated zone)
│
├── 3. External Data Source (Native Style)
│   │
│   ├── Object: nyc_taxi_src
│   ├── Type: Native-style external data source
│   └── LOCATION:
│         https://synapsecoursedl.dfs.core.windows.net/nyc-taxi-data
│
├── 4. External File Formats
│   │
│   ├── CSV Formats
│   │   ├── csv_file_format        (Parser 2.0)
│   │   └── csv_file_format_pv1    (Parser 1.0)
│   │
│   ├── TSV Formats
│   │   ├── tsv_file_format        (Parser 2.0)
│   │   └── tsv_file_format_pv1    (Parser 1.0)
│   │
│   ├── Parquet Format
│   │   └── parquet_file_format
│   │
│   └── Delta Format
│       └── delta_file_format
│
└── 5. Environment Ready for Next Lecture
    │
    ├── Database created
    ├── UTF‑8 collation applied
    ├── Medallion schemas created
    ├── External data source connected
    ├── All file formats registered
    └── LDW fully prepared for external table creation
```

1. Creating the LDW Database

Purpose

A Logical Data Warehouse (LDW) is a virtual database used to organize schemas, external tables, and metadata for serverless SQL.
The database itself does not store data — it stores definitions.

Why UTF‑8 Collation?
Your CSV and Parquet files in ADLS are UTF‑8 encoded.
To avoid string comparison issues, the database must use:

Latin1_General_100_BIN2_UTF8

This ensures:

deterministic sorting

consistent behavior across file formats

correct handling of UTF‑8 characters

```sql
USE master
GO

CREATE DATABASE nyc_taxi_ldw
GO

ALTER DATABASE nyc_taxi_ldw COLLATE Latin1_General_100_BIN2_UTF8
GO
```
2. Creating Bronze, Silver, and Gold Schemas
Purpose
This follows the Medallion Architecture:

bronze → raw ingestion

silver → cleaned, standardized

gold → curated, analytics‑ready

Schemas help organize external tables logically.


```sql
USE nyc_taxi_ldw
GO

CREATE SCHEMA bronze
GO

CREATE SCHEMA silver
GO

CREATE SCHEMA gold
GO
```

3. Creating the External Data Source (Native Style)

Purpose

An external data source defines the root location of your data lake container.
This is the pointer Synapse uses to access files.

Native Style Explanation

In serverless SQL, you do not specify TYPE = HADOOP.
The engine automatically treats ADLS Gen2 as a file‑based source.

This is called native-style external data source creation.

LOCATION Explanation
The LOCATION must point to the container, not a folder or file.

```Code
location

https://786.dfs.core.windows.net/nyctaxidata
This gives access to all files under the container.
```

```sql
USE nyc_taxi_ldw;

IF NOT EXISTS (SELECT * FROM sys.external_data_sources WHERE name = 'nyc_taxi_src')
    CREATE EXTERNAL DATA SOURCE nyc_taxi_src
    WITH
    (    LOCATION         = 'https://786.dfs.core.windows.net/nyctaxidata'
    );
```

4. Creating External File Formats
Purpose
External file formats tell Synapse how to interpret:

CSV

TSV

Parquet

Delta

These formats are required before creating external tables.

General Notes
PARSER_VERSION = '2.0' is faster and more accurate

First_Row = 2 skips the header row

USE_TYPE_DEFAULT = FALSE prevents unwanted default values

UTF‑8 encoding matches your data lake files

4.1 CSV File Format (Parser 2.0)
Explanation
Used for modern CSV ingestion with improved parsing performance.

Code
```sql
--IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name ='csv_file_format')
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
```
4.2 CSV File Format (Parser 1.0)
Explanation
Older parser for compatibility with legacy CSV structures.

Code
```sql
--IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name ='csv_file_format_pv1')
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
```
4.3 TSV File Format (Parser 2.0)
Explanation
Used for tab‑separated files (\t).

Code
```sql
--IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name ='tsv_file_format')
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
```

4.4 TSV File Format (Parser 1.0)
Explanation
Legacy parser for older TSV structures.

Code
```sql
--IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name ='tsv_file_format_pv1')
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
```
4.5 Parquet File Format
Explanation
Parquet is columnar, compressed, and optimized for analytics.

Code
```sql
--IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name ='parquet_file_format')
  CREATE EXTERNAL FILE FORMAT parquet_file_format  
  WITH (  
        FORMAT_TYPE = PARQUET,  
        DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec'  
       ); 
```
4.6 Delta File Format
Explanation
Delta Lake format supports ACID transactions and versioning.

Code
```sql
--IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name ='delta_file_format')
  CREATE EXTERNAL FILE FORMAT delta_file_format  
  WITH (  
        FORMAT_TYPE = DELTA,  
        DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec'  
       ); 
```
Final Section: Why HADOOP Is Used in Other Tutorials
Even though you used native‑style external data source creation, many tutorials use:

```Code
TYPE = HADOOP
Reason 1 — Dedicated SQL Pools Require It
Dedicated SQL Pools must specify TYPE = HADOOP when accessing ADLS.

Reason 2 — Legacy Compatibility
Older Synapse and SQL DW engines required explicit Hadoop protocol declarations.

Reason 3 — Explicit Protocol Declaration
TYPE = HADOOP tells the engine:
```
“This is a file‑based storage system, not a relational database.”

Reason 4 — Serverless SQL Automatically Assumes HADOOP
In serverless SQL:

ADLS Gen2 is always treated as a Hadoop‑compatible filesystem

Therefore, we do not need to specify the type
_________________________________________________________________________________________________________________________________________________________________________________
QUESTION: the data base created as a result of this lesson, is stored or will be gone as session is finished?

What is stored permanently?

Stored permanently:

Database name

Schemas (bronze, silver, gold)

External data sources

External file formats

External tables (metadata only)

Views

Not stored:

Actual data (because serverless SQL never stores data)

Query results (unless you export them)

Your data always stays in ADLS Gen2, not in the database.

3, Why does it persist?
Because the Workspace SQL endpoint is a logical server, not a temporary session.

It behaves like:

Azure SQL Database (persistent metadata)

SQL Server (persistent metadata)

Even though compute is serverless, metadata is not serverless — it is stored in the workspace.

4,  What disappears after the session?
Nothing you created disappears.

The only things that are temporary are:

Query execution context

OPENROWSET results

Temporary result sets

But your database, schemas, external data source, and file formats remain.
```code
5,  Why some people think it disappears

Because:

Serverless SQL has no physical storage

External tables don’t store data

Everything feels “virtual”

But the metadata layer is persistent.
```
Final clarity
Your LDW database is permanent
Your schemas are permanent
Your external data source is permanent
Your file formats are permanent
Your external tables (when you create them) will be permanent
Nothing disappears unless you drop it.

This is why your code works without it.
