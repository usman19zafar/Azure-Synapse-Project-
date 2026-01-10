Lecture Title
Understanding Collation, UTF‑8 Warnings, and Schema Control in Synapse Serverless
1. Concept Anchor
One word: Integrity
Two words: Character safety

Analogy:  
Imagine receiving packages from around the world. If your warehouse workers assume every label is written in English, they’ll misread names, mis‑sort boxes, and corrupt information.
Collation is the rulebook that tells Synapse how to read characters, how to compare them, and how to preserve them.

If the rulebook is wrong, your data gets misinterpreted.
***************************************************************************************************************************************************************************
2. Why We Are Doing This
Synapse Serverless shows warnings when:

Your CSV contains UTF‑8 characters

Your database uses a non‑UTF‑8 collation

Synapse must implicitly convert characters to match the database collation

Implicit conversions are dangerous because they can:

Corrupt characters

Change sorting behavior

Break comparisons

Cause performance issues

Produce unexpected query results

So the goal of this lesson is to:

Understand what collation is

See why Synapse warns us

Inspect the current database collation

Fix the warnings using column‑level collation

Fix the warnings using database‑level collation

Understand when to use each method
***************************************************************************************************************************************************************************
3. What Is Collation? (Theory)
Collation defines:

Bit patterns used to represent characters

Sorting rules (A < B < C, etc.)

Comparison rules (case sensitivity, accent sensitivity)

Encoding rules (ASCII vs UTF‑8 vs UTF‑16)

In simple terms:

Collation tells Synapse how to read, store, compare, and sort text.

If your data contains UTF‑8 characters (e.g., accented names, emojis, multilingual text), but your database uses an ASCII collation, Synapse must convert the characters — and that triggers warnings.
***************************************************************************************************************************************************************************
4. Step 1 — Inspect the Inferred Schema (Why?)
Before fixing anything, we check what Synapse thinks the schema is.

```sql
EXEC sp_describe_first_result_set N'
SELECT
    *
FROM
    OPENROWSET(
        BULK ''abfss://nyctaxidata@786.dfs.core.windows.net/raw/taxi_zone.csv'',
        FORMAT = ''CSV'',
        PARSER_VERSION = ''2.0'',
        HEADER_ROW = TRUE,
        FIELDTERMINATOR = '','',
        ROWTERMINATOR = ''\n''
    ) 
    WITH (
        LocationID SMALLINT,
        Borough VARCHAR(15),
        Zone VARCHAR(50),
        service_zone VARCHAR(15)
    )AS [result]';
```

```SQL
Output:

Potential conversion error while reading VARCHAR column 'Borough' from UTF8 encoded text. Change database collation to a UTF8 collation or specify explicit column schema in WITH clause and assign UTF8 collation to VARCHAR columns.
Potential conversion error while reading VARCHAR column 'Zone' from UTF8 encoded text. Change database collation to a UTF8 collation or specify explicit column schema in WITH clause and assign UTF8 collation to VARCHAR columns.
Potential conversion error while reading VARCHAR column 'service_zone' from UTF8 encoded text. Change database collation to a UTF8 collation or specify explicit column schema in WITH clause and assign UTF8 collation to VARCHAR columns.
```

Why this step matters
It reveals the data types Synapse will use

It shows warnings about collation mismatches

It confirms whether Synapse is implicitly converting characters

Code explanation
sp_describe_first_result_set analyzes the query and returns the schema

The entire query is passed as a string literal

Single quotes inside must be escaped as ''

The result shows each column’s type, collation, and nullability

This is your diagnostic tool.
***************************************************************************************************************************************************************************
5. Step 2 — Check the Current Database Collation
```sql
SELECT name, collation_name FROM sys.databases;
```
```sql
output
SQL_Latin1_General_CP1_CI_AS — 
```

This means:

SQL_ → legacy SQL Server collation

Latin1_General → Western European rules

CP1 → Code Page 1252 (NOT UTF‑8)

CI → Case Insensitive

AS → Accent Sensitive

This is the default collation for many SQL Server environments.

Why this step matters
You need to know what collation your database is using

Synapse’s default databases (master, built‑in) use ASCII collations

ASCII cannot safely store UTF‑8 characters

This mismatch triggers warnings

Code explanation
sys.databases is a system catalog view

collation_name shows the active collation for each database

You will typically see something like:

```Code
SQL_Latin1_General_CP1_CI_AS
```
This is not UTF‑8.
***************************************************************************************************************************************************************************
6. Step 3 — Fix Warnings Using Column‑Level Collation
This is the surgical approach: apply UTF‑8 collation only to specific columns.

```sql
SELECT
    *
FROM
    OPENROWSET(
        BULK 'abfss://nyctaxidata@786.dfs.core.windows.net/raw/taxi_zone.csv',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n'
    ) 
    WITH (
        LocationID SMALLINT,
        Borough VARCHAR(15) COLLATE Latin1_General_100_CI_AI_SC_UTF8,
        Zone VARCHAR(50) COLLATE Latin1_General_100_CI_AI_SC_UTF8,
        service_zone VARCHAR(15) COLLATE Latin1_General_100_CI_AI_SC_UTF8
    )AS [result];
```

Why this works
You override the database collation

You force Synapse to treat these columns as UTF‑8

No more implicit conversions

No more warnings

UTF‑8 characters remain intact

Code explanation
COLLATE Latin1_General_100_CI_AI_SC_UTF8

Latin1_General_100 → modern collation family

CI → Case Insensitive

AI → Accent Insensitive

SC → Supplementary Characters (emoji support)

UTF8 → UTF‑8 encoding

This is the recommended UTF‑8 collation for Synapse.

```code
OUTPUT
Started executing query at Line 111
Statement ID: {7FC07F98-D1FE-46D2-8E9C-F04696A1C0BE} | Query hash: 0x698D22D98345091A | Distributed request ID: {0F002EF4-3037-4012-9937-66F1F3E3F71A}. Total size of data scanned is 1 megabytes, total size of data moved is 1 megabytes, total size of data written is 0 megabytes.
(265 records affected)
```

How Synapse Achieved This (Internal Mechanics)
Here’s what actually happened behind the scenes:

Step 1 — Your query hit the control node
Synapse parsed your SQL and created a distributed execution plan.

Step 2 — The engine contacted ADLS Gen2
It opened the file:

```Code
abfss://nyctaxidata@786.dfs.core.windows.net/raw/taxi_zone.csv
```

Step 3 — Data was scanned
Synapse read the file in parallel across distributed workers.

Step 4 — Data was moved
Workers exchanged partitions to align the data for your SELECT.

Step 5 — Data was returned
265 rows were streamed back to your client.

Step 6 — Telemetry was logged
Synapse reported:

Data scanned

Data moved

Data written

Query identifiers

This is what you saw in the output.

Executive Summary

Synapse scanned 1 MB (minimum billing unit).

It moved 1 MB across distributed compute nodes.

It wrote 0 MB because you didn’t save anything.

It returned 265 rows from your CSV.

The IDs (Statement ID, Query Hash, Distributed Request ID) are tracking and diagnostic identifiers.

This output is Synapse telling you:

“Our query ran successfully, here’s how much it cost, and here’s how I processed it.”
***************************************************************************************************************************************************************************

7. Step 4 — Fix Warnings Using Database‑Level Collation
This is the architectural approach: set UTF‑8 collation for the entire database.

Create a new database
```sql
CREATE DATABASE nyc_taxi_discovery;
```

Switch to it

```sql
USE nyc_taxi_discovery;
```
Apply UTF‑8 collation

```sql
ALTER DATABASE nyc_taxi_discovery COLLATE Latin1_General_100_CI_AI_SC_UTF8;
```

```code
Out put: All Messages will be gone, it will be like a clean slate!
```

Why this approach is better for real projects
Every query inherits UTF‑8 behavior

No need to specify collation per column

No warnings anywhere

Consistent behavior across all tables and queries

Future‑proof for multilingual data

Important note
You cannot alter the master database.
Synapse manages it.
You can only alter databases you create.
***************************************************************************************************************************************************************************
8. Step 5 — Test the Query Again (No Collation Needed Now)

```sql
SELECT
    *
FROM
    OPENROWSET(
        BULK 'abfss://nyctaxidata@786.dfs.core.windows.net/raw/taxi_zone.csv',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n'
    ) 
    WITH (
        LocationID SMALLINT,
        Borough VARCHAR(15),
        Zone VARCHAR(50),
        service_zone VARCHAR(15)
    )AS [result];
```

Why this works now
The database collation is UTF‑8

Synapse no longer needs to convert characters

No warnings

No need for per‑column collation
***************************************************************************************************************************************************************************
9. When to Use Which Method
Use column‑level collation when:
You cannot change the database collation

You are working in shared environments

You only need UTF‑8 for specific columns

Use database‑level collation when:
You own the database

Most of your data is UTF‑8

You want consistent behavior

You want to eliminate warnings permanently
***************************************************************************************************************************************************************************
10. Executive Summary
Synapse warns you because your data is UTF‑8 but your database is ASCII.

Collation defines how characters are stored, compared, and sorted.

You can fix warnings by applying UTF‑8 collation at:

Column level (local fix)

Database level (global fix)

UTF‑8 collation prevents data corruption and ensures correct behavior.

Database‑level UTF‑8 is the modern best practice.
