Exploring Delimited Files Using OPENROWSET in Synapse Serverless SQL
Here we are introducing how to explore files stored in Azure Data Lake using Synapse Studio and the OPENROWSET function.
The goal is to understand how Serverless SQL reads delimited files (CSV, TSV, pipe‑delimited, etc.) and how to control the parser using optional parameters.

1, Navigating to the Data in Synapse Studio
Steps
Open Synapse Studio.

Go to the Data Hub.

Select Linked to view your connected storage accounts.

Expand your storage account → expand the container (e.g., nyctaxidata).

You will see all uploaded files (CSV, TSV, JSON, etc.).

Example file
taxi_zone.csv

Auto‑generated script
Right‑click → New SQL Script → Select Top 100 Rows  
Synapse generates a query using OPENROWSET to read the file directly from the lake.
_____________________________________________________________________________________________________________________________________________________________
2,  What OPENROWSET Does
OPENROWSET allows you to:

Read files directly from Azure Storage

Without loading them into a table

Without creating an external table

Treat the file as if it were a table in the FROM clause

Example

```sql
SELECT *
FROM OPENROWSET(
    BULK 'https://<storage>.dfs.core.windows.net/<container>/taxi_zone.csv',
    FORMAT = 'CSV'
) AS rows;
```
This returns the file contents as rows and columns.

_____________________________________________________________________________________________________________________________________________________________
3. Understanding the BULK Path Protocols
You can access files using different URL formats:

A. HTTPS protocol (default auto‑generated)
```Code
https://<storage>.dfs.core.windows.net/<container>/folder/file.csv
B. ABFSS protocol (recommended for ADLS Gen2)
```
```Code
abfss://<container>@<storage>.dfs.core.windows.net/folder/file.csv
C. WASBS protocol (for classic Blob Storage)
```
```Code
wasbs://<container>@<storage>.blob.core.windows.net/folder/file.csv
All three work — choose based on your environment.
```

_____________________________________________________________________________________________________________________________________________________________
4, FORMAT Parameter
Specifies the file type.

Supported formats:

'CSV'

'PARQUET'

'DELTA'

CSV requires more configuration because it has no schema metadata.

_____________________________________________________________________________________________________________________________________________________________
5, PARSER_VERSION (Critical for CSV)
Two parser versions exist:

Version 1.0
More features

Supports larger rows and columns

Slower

Version 2.0 (recommended)
Faster

Limited to:

Max column length: 8000 characters

Max row size: 8 MB

Use 1.0 only when:

Columns exceed 8000 characters

Rows exceed 8 MB

Otherwise, always use 2.0.

_____________________________________________________________________________________________________________________________________________________________
6, Fixing Header Recognition
By default, CSV headers are treated as data.

To fix this:

```sql
HEADER_ROW = TRUE
```
This tells the parser to treat the first row as column names.

_____________________________________________________________________________________________________________________________________________________________
7, Field Terminator (Delimiter)
CSV files may not always use commas.

Examples:

Tab → \t

Pipe → |

Semicolon → ;

Specify explicitly
```sql
FIELDTERMINATOR = ','
```
Comma is the default, so you only need to specify when using a different delimiter.

_____________________________________________________________________________________________________________________________________________________________
9, Row Terminator
Controls how rows end.

Default:

Windows: \r\n

Unix: \n

We can override:

```sql
ROWTERMINATOR = '\n'
```
Most of the time, defaults work fine.

10, Saving and Organizing Scripts
We created a script named:

```Code
1_explore_taxi_zone.sql
```
Then organized it into:

```Code
NYC_Taxi/
    Discovery/
```
Finally, we published the script to the Synapse repository.

This ensures:

Version control

Reproducibility

Clean project structure

_____________________________________________________________________________________________________________________________________________________________
Final Summary of section
explored files in Synapse Studio using the Data Hub.

used OPENROWSET to read files directly from the data lake.

learned the difference between HTTPS, ABFSS, and WASBS paths.

understood the FORMAT parameter and why CSV requires more configuration.

learned about PARSER_VERSION 1.0 vs 2.0.

fixed header recognition using HEADER_ROW = TRUE.

learned how to specify:

Field terminator

Row terminator

saved and organized your script into a safe place. for me it is this Repo! ;)
_____________________________________________________________________________________________________________________________________________________________

Section II: Why Explicit Data Types Matter in OPENROWSET (CSV Ingestion)
Up to this point, you’ve been reading CSV files using OPENROWSET without specifying any data types.
This is perfectly fine for initial exploration, but not ideal for repeated queries, performance, or cost efficiency.

This lesson explains:

How Synapse infers data types

Why inferred types are often too large

How to inspect inferred types

How to define explicit data types

Why explicit types improve performance and reduce cost
_____________________________________________________________________________________________________________________________________________________________

1, How Synapse Infers Data Types
When you run:

```sql
SELECT *
FROM OPENROWSET(...)
```
…without specifying data types, Synapse:

Reads the file

Inspects the values

Assigns default inferred types

Problem:
Synapse tends to be overly generous.

Example from the Taxi Zone file:

+--------------+-------------+----------------------+
|   Column     | Actual Size | Synapse Inferred Type|
+--------------+-------------+----------------------+
| LocationID   | 3 digits    | bigint               |
| Borough      | ~13 chars   | varchar(8000)        |
| Zone         | ~45 chars   | varchar(8000)        |
| ServiceZone  | ~11 chars   | varchar(8000)        |
+--------------+-------------+----------------------+

_____________________________________________________________________________________________________________________________________________________________
2, How to Inspect Inferred Data Types
Synapse provides a stored procedure:

```Code
sp_describe_first_result_set
```
This procedure analyzes a query and returns the data types Synapse would use.

Usage
You must pass the SELECT statement as a string, with quotes escaped.

Example:

```sql
EXEC sp_describe_first_result_set
    N'SELECT *
      FROM OPENROWSET(
          BULK ''raw/taxi_zone.csv'',
          DATA_SOURCE = ''nyctaxidata'',
          FORMAT = ''CSV'',
          PARSER_VERSION = ''2.0'',
          HEADER_ROW = TRUE
      ) AS rows';
```
This returns the inferred data types.
_____________________________________________________________________________________________________________________________________________________________

3, Why Inferred Types Are a Problem
There are two major issues:

A. Cost Impact (Serverless SQL charges per data processed)
Serverless SQL charges based on:

Data scanned

Data moved

Data returned

If Synapse assumes:

varchar(8000) instead of varchar(50)

bigint instead of smallint

…it allocates more memory and scans more data than necessary.

This increases cost.

B. Performance Impact
Larger data types mean:

More memory allocation

More data movement

Slower query execution

Explicit types = faster queries.
_____________________________________________________________________________________________________________________________________________________________
4, Finding the Actual Column Sizes
To determine the real sizes, run:

```sql
SELECT
    MAX(LEN(LocationID)) AS MaxLocationID,
    MAX(LEN(Borough)) AS MaxBorough,
    MAX(LEN(Zone)) AS MaxZone,
    MAX(LEN(ServiceZone)) AS MaxServiceZone
FROM OPENROWSET(
    BULK 'raw/taxi_zone.csv',
    DATA_SOURCE = 'nyctaxidata',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    HEADER_ROW = TRUE
) AS rows;
```
This gives the true maximum lengths.
_____________________________________________________________________________________________________________________________________________________________

5, Defining Explicit Data Types Using WITH Clause
Once you know the real sizes, you can define them:

```sql
SELECT *
FROM OPENROWSET(
    BULK 'raw/taxi_zone.csv',
    DATA_SOURCE = 'nyctaxidata',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    HEADER_ROW = TRUE
)
WITH (
    LocationID   smallint,
    Borough      varchar(15),
    Zone         varchar(50),
    ServiceZone  varchar(15)
) AS rows;
```
Important:
Column names are case‑sensitive because the database collation is case‑sensitive.

Example:

LocationID ≠ locationid

ServiceZone ≠ servicezone

If the case is wrong, the column returns NULL.
_____________________________________________________________________________________________________________________________________________________________

6, Verifying That Explicit Types Are Used
Run the stored procedure again:

```sql
EXEC sp_describe_first_result_set
    N'SELECT *
      FROM OPENROWSET(
          BULK ''raw/taxi_zone.csv'',
          DATA_SOURCE = ''nyctaxidata'',
          FORMAT = ''CSV'',
          PARSER_VERSION = ''2.0'',
          HEADER_ROW = TRUE
      )
      WITH (
          LocationID smallint,
          Borough varchar(15),
          Zone varchar(50),
          ServiceZone varchar(15)
      ) AS rows';
```
You will now see:

smallint

varchar(15)

varchar(50)

varchar(15)

Exactly as defined.
_____________________________________________________________________________________________________________________________________________________________

7, How This Improves Cost and Performance
A. Cost Reduction
Serverless SQL charges based on:

Data scanned

Data moved

Data returned

Smaller data types = less data processed = lower cost.

B. Performance Improvement
Explicit types:

Reduce memory allocation

Reduce I/O

Improve query speed

Improve parallelism

C. Predictable Schema
You avoid:

Random inferred types

Over‑allocation

Inconsistent schema across queries
_____________________________________________________________________________________________________________________________________________________________

Final Summary 
Synapse infers data types when none are provided.

Inferred types are often too large (varchar(8000), bigint).

Use sp_describe_first_result_set to inspect inferred types.

Use MAX(LEN()) to find actual column sizes.

Use the WITH clause to define explicit data types.

Case sensitivity matters for column names.

Explicit data types improve:

Cost efficiency

Performance

Schema consistency

Always define explicit types for production or repeated queries.


You published the script to the Synapse repo.

This summary captures every important detail from the lesson in a clean, structured, Data‑Architect‑ready format.
