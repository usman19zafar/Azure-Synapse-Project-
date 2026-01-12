File Metadata Functions in Synapse Serverless

Purpose: Extract file‑level metadata (file name, folder path, year, month) when reading partitioned data from ADLS using OPENROWSET.

1. Conceptual BLOC: Why Metadata Matters

Partitioned data is stored in folders such as:

```Code
trip_data_green_csv/
    year=2020/
        month=01/
            green_tripdata_2020-01.csv
```
When reading many files at once, you must know:

Which record came from which file

Which year/month partition it belongs to

How to filter partitions efficiently

How to reduce cost by scanning less data
___________________________________________________________________________________________________________________________________________________________
Serverless SQL provides two metadata functions:

filename() → returns only the file name

filepath(n) → returns folder segments based on wildcard position

These functions allow you to:

Identify partitions

Group by partitions

Filter partitions

Reduce data scanned

Improve performance and cost

___________________________________________________________________________________________________________________________________________________________
2. Procedural BLOC: Using filename()

2.1 Add file name to each record

```sql
SELECT
    TOP 100
    result.filename() AS file_name,
    result.*
FROM OPENROWSET(
        BULK 'trip_data_green_csv/year=*/month=*/*.csv',
        DATA_SOURCE = 'nyc_taxi_data_raw',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE
) AS result;
```

2.2 Count records per file

```sql
SELECT
    result.filename() AS file_name,
    COUNT(1) AS record_count
FROM OPENROWSET(
        BULK 'trip_data_green_csv/year=*/month=*/*.csv',
        DATA_SOURCE = 'nyc_taxi_data_raw',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE
) AS result
GROUP BY result.filename()
ORDER BY result.filename();
```

2.3 Filter by specific file names

```sql
SELECT
    result.filename() AS file_name,
    COUNT(1) AS record_count
FROM OPENROWSET(
        BULK 'trip_data_green_csv/year=*/month=*/*.csv',
        DATA_SOURCE = 'nyc_taxi_data_raw',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE
) AS result
WHERE result.filename() IN ('green_tripdata_2020-01.csv', 'green_tripdata_2021-01.csv')
GROUP BY result.filename()
ORDER BY result.filename();
```

___________________________________________________________________________________________________________________________________________________________
3. Structural BLOC: Using filepath(n)
filepath(n) returns the folder segment at wildcard position n.

Given:

```Code
trip_data_green_csv/year=*/month=*/*.csv
```

filepath(1) → year

filepath(2) → month

filepath(3) → file name

3.1 Extract year and month

```sql
SELECT
    result.filepath(1) AS year,
    result.filepath(2) AS month,
    COUNT(1) AS record_count
FROM OPENROWSET(
        BULK 'trip_data_green_csv/year=*/month=*/*.csv',
        DATA_SOURCE = 'nyc_taxi_data_raw',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE
) AS result
GROUP BY result.filename(), result.filepath(1), result.filepath(2)
ORDER BY result.filename(), result.filepath(1), result.filepath(2);
```

3.2 Filter by year/month using filepath()

```sql
SELECT
    result.filepath(1) AS year,
    result.filepath(2) AS month,
    COUNT(1) AS record_count
FROM OPENROWSET(
        BULK 'trip_data_green_csv/year=*/month=*/*.csv',
        DATA_SOURCE = 'nyc_taxi_data_raw',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE
) AS result
WHERE result.filepath(1) = '2020'
  AND result.filepath(2) IN ('06', '07', '08')
GROUP BY result.filename(), result.filepath(1), result.filepath(2)
ORDER BY result.filename(), result.filepath(1), result.filepath(2);
```

___________________________________________________________________________________________________________________________________________________________
4. Contextual BLOC: Why Partition Filtering Matters

4.1 Without filtering

Serverless scans all files

Example: 209 MB scanned

4.2 With partition filtering

Only June, July, August scanned

Example: 20 MB scanned

Benefits

Faster queries

Lower cost

Less data movement

Better scalability

Partition pruning is the core principle of big‑data engineering.

___________________________________________________________________________________________________________________________________________________________
5. Final Summary (No Information Lost)

filename() returns only the file name

filepath(n) returns folder segments

Both can be used in:

SELECT

GROUP BY

WHERE

Filtering partitions reduces:

Data scanned

Cost

Query time

Always filter partitions before reading data

___________________________________________________________________________________________________________________________________________________________

The Deep Explanation: File Metadata Functions in Serverless SQL

A journey through structure, meaning, and the limits of computation.

1. Why Metadata Exists: The Identity Problem in Big Data

Imagine a massive library where every book has been shredded into individual pages and scattered across thousands of shelves.

we  walk in and ask:

“Show me the first 100 pages.”

The librarian hands you 100 pages — but you have no idea:

Which book they came from

Which chapter they belonged to

Whether they were fiction or non‑fiction

Whether they were even from the same book

This is exactly what happens when you read partitioned data without metadata.

Data without metadata is content without identity.

Serverless SQL solves this identity crisis with two functions:

filename() → Who am I?

filepath(n) → Where did I come from?

These are not just functions.

They are identity extractors.
___________________________________________________________________________________________________________________________________________________________

2. filename(): The Surname of Every Record

Think of filename() as the surname of each row.

If each row is a person, then:

The columns are their attributes

The values are their behaviors

The file name is their family name

When you run:

```sql
result.filename() AS file_name
```
You’re essentially saying:

“Tell me which family this record belongs to.”

This matters because in big data:

January is a family

February is a family

2020 is a family

2021 is a family

And each file is a household inside that family.
___________________________________________________________________________________________________________________________________________________________

3. filepath(n): The Ancestry Tree of a Record

If filename() is the surname, then filepath(n) is the ancestry tree.

Example path:

```Code
trip_data_green_csv/year=2020/month=01/green_tripdata_2020-01.csv
filepath(1) → year
filepath(2) → month
filepath(3) → file name
```

This is like saying:

filepath(1) → “Which generation?”

filepath(2) → “Which branch of the family?”

filepath(3) → “Which individual?”

This is hierarchical identity.
___________________________________________________________________________________________________________________________________________________________

4. Why This Matters: Partition Pruning as Cognitive Efficiency

Humans don’t scan all memories when answering a question.

We don’t think:

“Let me recall every moment of my life to answer this.”

You prune:

Time

Context

Location

Relevance

This is cognitive partitioning.

Serverless SQL does the same thing.

When you filter using:

```sql
WHERE result.filepath(1) = '2020'
```
You’re telling the engine:

“Don’t search the entire library.

Go directly to the 2020 shelf.”

This is not just optimization.

It is computational cognition.
___________________________________________________________________________________________________________________________________________________________

5. The Cost Principle: Structure Saves Money

When you read all files:

You scanned 209 MB

When you filtered partitions:

You scanned 20 MB

This is a 10× reduction.

In Cognitive Engineering terms:

Structure reduces entropy.

Entropy reduction reduces cost.

Partition pruning is not a trick.

It is the mathematics of efficiency.
___________________________________________________________________________________________________________________________________________________________

6. The Boundary Reminder: Code Cannot Feel

You asked for depth, but also reminded:

“Each code is a reminder of boundary limits.”

Let’s honor that.

When you write:

```sql
result.filename()
```

The engine does not understand the file name.

It does not feel the year.

It does not interpret the month.

It simply extracts structured tokens from a structured path.

This is the essence of your Cognitive Engineering insight:

Computers operate inside structure.

Humans operate beyond it.

Metadata functions are powerful — but they are still structural tools, not cognitive ones.

They do not know meaning.

They only know position.
___________________________________________________________________________________________________________________________________________________________

7. The Grand Analogy: Metadata as the Postal System of Big Data

Think of your data lake as a global postal network.

Each file is a package

Each folder is a city

Each partition is a country

filename() is the package label

filepath(n) is the postal address

OPENROWSET is the mail carrier

If you don’t use metadata:

You dump all packages into one giant warehouse

You ask the worker to find “all packages from Canada”

The worker must open every box

This is expensive.

If you use metadata:

You read only the boxes labeled “Canada”

You skip the rest

You save time, energy, and cost

This is structured intelligence.
___________________________________________________________________________________________________________________________________________________________

8. The Final Layer: Why This Lesson Matters to You

Because this is exactly where your two worlds meet:

Azure Data Engineering → structure, partitions, metadata

Cognitive Engineering → meaning, identity, boundary limits

Metadata functions are the perfect metaphor for your entire philosophy:

Identity emerges from structure,

but meaning emerges from cognition.

Serverless SQL can extract identity.

Only you can extract meaning.

Never scan entire folders unless necessary

___________________________________________________________________________________________________________________________________________________________

PART 1 — The First Query (filename + TOP 100)
Purpose: Show the file name for each record.

```
sql
SELECT
    TOP 100 
    result.filename() AS file_name,
    result.*
FROM
    OPENROWSET(
        BULK 'trip_data_green_csv/year=*/month=*/*.csv',
        DATA_SOURCE = 'nyc_taxi_data_raw',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE
    ) AS [result]
```

Character‑by‑Character, Concept‑by‑Concept Explanation
SELECT
This is the instruction verb.
You’re telling the engine:

“Extract these columns from the virtual table I’m about to define.”

Without SELECT, nothing is returned.
This is the Conceptual BLOC: the “what.”

TOP 100
This is a safety valve.

It prevents:

scanning millions of rows

long execution times

unnecessary cost

overwhelming result sets

If you remove TOP 100:

Serverless will read all partitions

You pay for full scan

You wait longer

You risk timeouts

This is a Contextual BLOC: controlling scope.

result.filename() AS file_name,
This is the identity extractor.

result → alias for the virtual table
. → dot operator meaning “apply function to this table”
filename() → metadata function
AS file_name → rename the output column

This line answers:

“Which file did this row come from?”

If you remove this:

You lose partition identity

You cannot group by file

You cannot debug data issues

You cannot trace lineage

You cannot filter partitions

This is a Structural BLOC: identity.

result.*

The asterisk means:

“Return all columns from the file.”

If you remove it:

You only get the file name

You lose the actual data

The query becomes meaningless

This is the Procedural BLOC: the data itself.

FROM OPENROWSET(

This is the gateway.

OPENROWSET is how serverless SQL reads external files.

If you remove it:

There is no data source

The query has no table

The engine throws an error

This is the Structural BLOC: defining the table.

BULK 'trip_data_green_csv/year=*/month=*/*.csv',

This is the path pattern.

Let’s break it:

'trip_data_green_csv/ → folder

year=*/ → wildcard for year

month=*/ → wildcard for month

*.csv' → all CSV files

This pattern maps directly to your ADLS path:

```Code
abfss://nyctaxidata@786.dfs.core.windows.net/raw/trip_data_green_csv/
```
If you remove the wildcards:

You read only one file

You lose partitioning

You lose scalability

If you remove the folder structure:

You break the metadata functions

filepath(1) and filepath(2) return NULL

This is the Contextual BLOC: environment.

DATA_SOURCE = 'nyc_taxi_data_raw',

This is the logical pointer to your ADLS account.

It maps to:

```Code

abfss://nyctaxidata@786.dfs.core.windows.net/
```
If you remove it:

Serverless cannot find your storage

You get “external data source not found”

The query fails

This is the Structural BLOC: connection.

FORMAT = 'CSV',

This tells the engine:

“Interpret each file as CSV.”

If you remove it:

Serverless guesses the format

It guesses wrong

You get garbage data

Or the query fails

This is the Procedural BLOC: file interpretation.

PARSER_VERSION = '2.0',
This is the modern CSV parser.

If you remove it:

You fall back to legacy parser

You lose support for:

quoted fields

embedded commas
___________________________________________________________________________________________________________________________________________________________

UTF‑8

complex CSV structures

This is the Structural BLOC: parsing engine.

HEADER_ROW = TRUE

This tells the engine:

“The first row contains column names.”

If you remove it:

The first row becomes data

Column names become C1, C2, C3…

Your schema becomes meaningless

You break downstream logic

This is the Conceptual BLOC: meaning.

) AS [result]

This creates the alias.

If you remove it:

You cannot call result.filename()

You cannot call result.filepath()

You cannot reference columns

This is the Structural BLOC: naming.
___________________________________________________________________________________________________________________________________________________________

PART 2 — Counting Records Per File

```sql
SELECT
    result.filename() AS file_name,
    COUNT(1) AS record_count
...
GROUP BY result.filename()
ORDER BY result.filename();
```

Why this matters

Shows distribution of data

Detects missing files

Detects corrupted files

Detects uneven partitions

If you remove GROUP BY

You get “column not part of aggregate” error

If you remove ORDER BY

Output becomes chaotic

Debugging becomes harder
___________________________________________________________________________________________________________________________________________________________

PART 3 — Filtering by filename()

```sql
WHERE result.filename() IN (...)
```

Why this matters

Reads only specific files

Reduces cost

Reduces scan size

Speeds up queries

If you remove it

You scan the entire lake

You pay 10× more

You wait longer
___________________________________________________________________________________________________________________________________________________________

PART 4 — filepath(n)

This is the hierarchical metadata extractor.

```sql
result.filepath(1) AS year,
result.filepath(2) AS month
```
If you remove filepath()

You cannot extract year/month

You cannot group by partitions

You cannot filter partitions

You lose partition intelligence
___________________________________________________________________________________________________________________________________________________________

PART 5 — Filtering by filepath()

```sql
WHERE result.filepath(1) = '2020'
  AND result.filepath(2) IN ('06','07','08')
```
Why this matters
Reads only June–August 2020

Reduces scan from 209 MB → 20 MB

Saves cost

Improves performance

If you remove it
You read all years

You read all months

You pay for everything
___________________________________________________________________________________________________________________________________________________________

PART 6 — The ADLS Path (abfss://…)

Your storage location:

```Code

abfss://nyctaxidata@786.dfs.core.windows.net/raw/trip_data_green_csv/
```
This is the root of your data universe.

If this is wrong:

Nothing loads

OPENROWSET fails

Metadata functions break

Wildcards return nothing

This is the Contextual BLOC: environment anchor.
___________________________________________________________________________________________________________________________________________________________

FINAL SUMMARY — What Problems These Queries Solve

1. Identity Problem
Solved by: filename()

2. Partition Awareness Problem
Solved by: filepath(n)

3. Cost Explosion Problem
Solved by: filtering partitions

4. Performance Problem
Solved by: pruning data early

5. Debugging Problem
Solved by: grouping by file

6. Lineage Problem
Solved by: metadata extraction

7. Cognitive Boundary Problem
Solved by: acknowledging structure limits
___________________________________________________________________________________________________________________________________________________________


Metadata Layer — Identity Extraction

Business Analogy: Employee ID badges

Purpose: Know who each record is and where it came from.

Example 1 — Extract file name

```sql
SELECT
    result.filename() AS file_name,
    result.*
FROM OPENROWSET(
        BULK 'trip_data_green_csv/year=*/month=*/*.csv',
        DATA_SOURCE = 'nyc_taxi_data_raw',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE
) AS result;
```

Why this matters (business analogy)
Like printing the employee’s last name on their badge.
Without it, you don’t know which department they belong to.

Example 2 — Extract year and month using filepath()

```sql
SELECT
    result.filepath(1) AS year,
    result.filepath(2) AS month,
    COUNT(*) AS record_count
FROM OPENROWSET(
        BULK 'trip_data_green_csv/year=*/month=*/*.csv',
        DATA_SOURCE = 'nyc_taxi_data_raw',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE
) AS result
GROUP BY result.filepath(1), result.filepath(2);
```

Why this matters
Like knowing the employee’s department (year) and floor (month).

___________________________________________________________________________________________________________________________________________________________

2, External Tables Layer — Materialization
Business Analogy: Turning sticky notes into official company documents.

Example 1 — CTAS (Create Table As Select)

```sql
CREATE TABLE dbo.GreenTrips_2020
AS
SELECT *
FROM OPENROWSET(
        BULK 'trip_data_green_csv/year=2020/month=*/*.csv',
        DATA_SOURCE = 'nyc_taxi_data_raw',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE
) AS result;
```

Why this matters
You’re turning temporary notes into an official internal document.

Example 2 — CETAS (Create External Table As Select)

```sql
CREATE EXTERNAL TABLE ext.GreenTrips_Parquet
WITH (
    LOCATION = 'silver/green_trips/',
    DATA_SOURCE = nyc_taxi_data_raw,
    FILE_FORMAT = ParquetFormat
)
AS
SELECT *
FROM OPENROWSET(
        BULK 'trip_data_green_csv/year=*/month=*/*.csv',
        DATA_SOURCE = 'nyc_taxi_data_raw',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE
) AS result;
```

Why this matters

This is like publishing the document into the company library.
___________________________________________________________________________________________________________________________________________________________

3, Parquet & Delta Layer — Performance
Business Analogy: Shipping goods in containers instead of cardboard boxes.

Example 1 — Reading Parquet
```sql
SELECT *
FROM OPENROWSET(
        BULK 'silver/green_trips/*.parquet',
        DATA_SOURCE = 'nyc_taxi_data_raw',
        FORMAT = 'PARQUET'
) AS result;
```

Why this matters

Parquet is compressed, columnar, and fast — like shipping containers.

Example 2 — Writing Parquet via CETAS

```sql
CREATE EXTERNAL TABLE ext.GreenTrips_Parquet
WITH (
    LOCATION = 'silver/green_trips/',
    DATA_SOURCE = nyc_taxi_data_raw,
    FILE_FORMAT = ParquetFormat
)
AS
SELECT *
FROM dbo.GreenTrips_2020;
```

Why this matters
You’re converting fragile cardboard boxes (CSV) into durable containers (Parquet).
___________________________________________________________________________________________________________________________________________________________

4, Optimization Layer — Efficiency
Business Analogy: A smart warehouse that opens only the boxes you need.

Example 1 — Partition pruning

```sql
SELECT *
FROM OPENROWSET(
        BULK 'trip_data_green_csv/year=2021/month=07/*.csv',
        DATA_SOURCE = 'nyc_taxi_data_raw',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE
) AS result;
```

Why this matters
You’re telling the warehouse:
“Only open the July 2021 boxes.”

Example 2 — Predicate pushdown

```sql
SELECT *
FROM OPENROWSET(
        BULK 'trip_data_green_csv/year=*/month=*/*.csv',
        DATA_SOURCE = 'nyc_taxi_data_raw',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE
) AS result
WHERE result.filepath(1) = '2021'
  AND result.filepath(2) = '07';
```
Why this matters
The warehouse opens only the aisle and shelf you need.
___________________________________________________________________________________________________________________________________________________________

5, Architecture Layer — Governance
Business Analogy: Organizing a company’s filing cabinet.

Example — Raw → Bronze → Silver → Gold
Raw (CSV)

```sql
SELECT *
FROM OPENROWSET(
        BULK 'raw/trip_data_green_csv/year=*/month=*/*.csv',
        DATA_SOURCE = 'nyc_taxi_data_raw',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE
) AS raw;
```

Bronze (cleaned CSV)

```sql
CREATE EXTERNAL TABLE bronze.GreenTrips
WITH (
    LOCATION = 'bronze/green_trips/',
    DATA_SOURCE = nyc_taxi_data_raw,
    FILE_FORMAT = CsvFormat
)
AS
SELECT *
FROM raw.GreenTrips;
```
Silver (Parquet)

```sql
CREATE EXTERNAL TABLE silver.GreenTrips
WITH (
    LOCATION = 'silver/green_trips/',
    DATA_SOURCE = nyc_taxi_data_raw,
    FILE_FORMAT = ParquetFormat
)
AS
SELECT *
FROM bronze.GreenTrips;
```

Gold (Aggregated)

```sql
CREATE EXTERNAL TABLE gold.GreenTrips_Monthly
WITH (
    LOCATION = 'gold/green_trips_monthly/',
    DATA_SOURCE = nyc_taxi_data_raw,
    FILE_FORMAT = ParquetFormat
)
AS
SELECT
    year,
    month,
    COUNT(*) AS trip_count
FROM silver.GreenTrips
GROUP BY year, month;
```
Why this matters

You’re organizing documents into:

Raw inbox

Cleaned drafts

Approved documents

Published reports
___________________________________________________________________________________________________________________________________________________________

6, Debugging Layer — Problem Solving

Business Analogy: A mechanic diagnosing a car engine.

Example 1 — Header row mismatch

```sql
SELECT *
FROM OPENROWSET(
        BULK 'trip_data_green_csv/year=*/month=*/*.csv',
        DATA_SOURCE = 'nyc_taxi_data_raw',
        FORMAT = 'CSV',
        HEADER_ROW = FALSE
) AS result;
Why this matters
If the engine makes a strange noise, you check the basics first.
```

Example 2 — Parser version fix

```sql
SELECT *
FROM OPENROWSET(
        BULK 'trip_data_green_csv/year=*/month=*/*.csv',
        DATA_SOURCE = 'nyc_taxi_data_raw',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0'
) AS result;
```

Why this matters
Old parser = old engine.
New parser = smoother performance.

Example 3 — Wildcard resolution failure

```sql
SELECT *
FROM OPENROWSET(
        BULK 'trip_data_green_csv/year=2020/month=13/*.csv',
        DATA_SOURCE = 'nyc_taxi_data_raw',
        FORMAT = 'CSV'
) AS result;
```
___________________________________________________________________________________________________________________________________________________________

Why this matters
Month 13 doesn’t exist — the mechanic says:
“You’re looking in the wrong place.”

Final Summary — All 6 Layers with SQL

```code
┌──────────────────┬───────────────────────────┬───────────────────────────┐
│      Layer       │        SQL Purpose        │      Business Analogy     │
├──────────────────┼───────────────────────────┼───────────────────────────┤
│ Metadata         │ filename(), filepath()    │ Employee ID badges        │
│ External Tables  │ CTAS, CETAS               │ Official documents        │
│ Parquet/Delta    │ Columnar formats          │ Shipping containers       │
│ Optimization     │ Partition pruning         │ Smart warehouse           │
│ Architecture     │ Raw → Gold                │ Filing cabinet            │
│ Debugging        │ RCA (Root Cause Analysis) │ Mechanic                  │
└──────────────────┴───────────────────────────┴───────────────────────────┘
```
