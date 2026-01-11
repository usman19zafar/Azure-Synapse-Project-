MASTER INGESTION SOP (CSV, Escaped CSV, Quoted CSV, TSV)
1. One word:
Ingestion

2. Two words:
Parser Control

3. Business analogy:
Imagine a warehouse receiving dock.
Every shipment arrives with labels, but each supplier uses a different style:

Some use commas

Some use tabs

Some put commas inside the label

Some wrap labels in quotes

Some escape special characters

If the receiving worker doesn’t know the rules, shipments get misread, mis‑sorted, or rejected.

Your job as the Data Architect is to teach the receiving dock (SQL parser) how to read each shipment correctly.

4. Theory: Why ingestion fails
Serverless SQL has strict assumptions:

Default delimiter = comma (,)

Default field terminator = comma (,)

Default quote = double quote (")

No auto‑detection of delimiters

No tolerance for unexpected characters

Real‑world files violate these assumptions:

CSV with commas inside data

CSV with escape characters

CSV with quotes

TSV with tabs

Files with BOM

Files in subfolders

Files with inconsistent encoding

If you don’t explicitly tell SQL how to parse the file, you get:

Truncation

Misaligned columns

“Unexpected token” errors

Silent corruption

The Master Ingestion SOP solves this by explicitly controlling the parser.

5. SOP: Master Rules for Ingesting Text Files
Step 1 — Always specify the correct BULK path
Your files live here:

```Code
abfss://nyctaxidata@786.dfs.core.windows.net/raw/
```
So every BULK path must include /raw/:

```Code
BULK 'raw/<filename>'
```
Step 2 — Always use the correct DATA_SOURCE
Your configured external data source is:

```Code
nyctaxidata
```
This must be used consistently.

Step 3 — Choose the correct ingestion strategy based on file type
A. Unquoted CSV (contains commas inside data)
Problem: parser splits data incorrectly

Fix: none — this file is intentionally broken

Purpose: demonstration of failure mode

B. Escaped CSV
Fix: specify ESCAPECHAR = '\\'

C. Quoted CSV
Fix: specify FIELDQUOTE = '"' (optional because it’s default)

D. TSV (tab‑separated)
Fix: specify FIELDTERMINATOR = '0x09'  
(ASCII TAB — more reliable than \t)

Step 4 — Use PARSER_VERSION = '2.0'
This ensures modern, stable parsing behavior.

Step 5 — Always include HEADER_ROW = TRUE
This ensures the first row is treated as column names.

6. Master Ingestion Code Set (All Four Files)
Unquoted CSV (demonstrates failure)
```sql
SELECT *
  FROM OPENROWSET(
      BULK 'raw/vendor_unquoted.csv',
      DATA_SOURCE = 'nyctaxidata',
      FORMAT = 'CSV',
      PARSER_VERSION = '2.0',
      HEADER_ROW = TRUE
  ) AS vendor_unquoted;
```

Escaped CSV (correct handling of embedded commas)

```sql
SELECT *
  FROM OPENROWSET(
      BULK 'raw/vendor_escaped.csv',
      DATA_SOURCE = 'nyctaxidata',
      FORMAT = 'CSV',
      PARSER_VERSION = '2.0',
      HEADER_ROW = TRUE,
      ESCAPECHAR = '\\'
  ) AS vendor_escaped;
```
Quoted CSV (correct handling of embedded commas)

```sql
SELECT *
  FROM OPENROWSET(
      BULK 'raw/vendor.csv',
      DATA_SOURCE = 'nyctaxidata',
      FORMAT = 'CSV',
      PARSER_VERSION = '2.0',
      HEADER_ROW = TRUE,
      FIELDQUOTE = '"'
  ) AS vendor_quoted;
```
TSV (tab‑separated values)
The correct, production‑safe version:

```sql
SELECT *
  FROM OPENROWSET(
      BULK 'raw/trip_type.tsv',
      DATA_SOURCE = 'nyctaxidata',
      FORMAT = 'CSV',
      PARSER_VERSION = '2.0',
      HEADER_ROW = TRUE,
      FIELDTERMINATOR = '0x09'
  ) AS trip_type;
```

7. What this Master SOP achieves
1. Eliminates ingestion errors
No more:

Unexpected token

Truncation

Misaligned columns

2. Makes ingestion predictable
Every file type has a defined parsing rule.

3. Prevents silent corruption
The parser no longer guesses — you control it.

4. Creates a reusable ingestion pattern
This SOP becomes the template for all future ingestion pipelines.

5. Establishes Data Architect discipline
You are defining the boundary between raw data and structured ingestion.

8. Boundary‑Document Closure
This Master Ingestion SOP formalizes the authoritative method for parsing all text‑based source files in the NYC Taxi Discovery environment.
By explicitly defining delimiters, escape rules, quoting rules, and file paths, this SOP ensures ingestion reliability, schema integrity, and repeatable pipeline behavior.
This document stands as the canonical reference for all future ingestion work, preventing ambiguity and enforcing parser discipline across the entire data estate.
