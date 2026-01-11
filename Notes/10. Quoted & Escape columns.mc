SOP: Handling Delimiters Inside CSV Data Items (Updated With ABFSS Paths)
1. One word:
Delimiters

2. Two words:
Delimiter Control

3. Business analogy:
A CSV parser is like a warehouse receiving dock.
If a shipping label contains extra commas, the worker may think it’s multiple boxes instead of one.
You must either mark the box (escape) or wrap the box (quote) so the worker knows it’s a single item.

4. Theory: Why CSV Parsing Breaks
CSV parsers assume:

Comma = column separator

Header defines column count

Each row must match the header

When a data item contains a comma — e.g.,
Creative Mobile Technologies, LLC —
the parser misinterprets it as two columns, causing truncation or misalignment.

Two valid fixes:

Escape the delimiter

Quote the entire field

5. SOP: Correctly Parsing CSV Files With Embedded Delimiters
Step 1 — Connect to the correct database
sql
USE nyc_taxi_discovery;
Step 2 — Demonstrate the problem (unquoted CSV)
This file contains commas inside data but no escape and no quotes.

Corrected ABFSS path version

```sql
SELECT *
  FROM OPENROWSET(
      BULK 'raw/vendor_unquoted.csv',
      DATA_SOURCE = 'nyctaxidata',
      FORMAT = 'CSV',
      PARSER_VERSION = '2.0',
      HEADER_ROW = TRUE
  ) AS vendor;
```

Expected outcome:  
Vendor names containing commas are truncated.

Step 3 — Fix Option 1: Escape the delimiter
Theory
An escape character tells the parser:
“Anything after this slash is literal — not a delimiter.”


```sql
SELECT *
  FROM OPENROWSET(
      BULK 'raw/vendor_escaped.csv',
      DATA_SOURCE = 'nyctaxidata',
      FORMAT = 'CSV',
      PARSER_VERSION = '2.0',
      HEADER_ROW = TRUE,
      ESCAPECHAR = '\\'
  ) AS vendor;
```

Outcome:  
The parser keeps the comma inside the vendor name.

Step 4 — Fix Option 2: Quote the field
Theory
Quoting wraps the entire data item so the parser treats it as one column, regardless of internal commas.


```sql
SELECT *
  FROM OPENROWSET(
      BULK 'raw/vendor.csv',
      DATA_SOURCE = 'nyctaxidata',
      FORMAT = 'CSV',
      PARSER_VERSION = '2.0',
      HEADER_ROW = TRUE,
      FIELDQUOTE = '"'
  ) AS vendor;
```

Note:  
If the file already uses " " as quotes, you don’t need to specify FIELDQUOTE because it is the default.

6. Boundary‑Document Closure
This SOP defines the authoritative method for ingesting CSV files that contain embedded delimiters.
The two sanctioned protections — escape characters and field quotes — ensure structural integrity and prevent silent truncation.
All upstream providers must consistently apply one of these protections.
This document becomes the canonical reference for ingestion pipelines encountering delimiter‑inside‑data scenarios.
