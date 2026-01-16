Before Creating JSON vie, correct these in Query!

DROP VIEW IF EXISTS GO batch separators

Without these, the instructor’s narrative doesn’t match the code.

You also need one more correction:
Your OPENROWSET block is missing the ROWTERMINATOR (required for JSON‑adjacent pattern).

Below is the fully corrected, fully fitted, final version that matches the lesson, the narration, and the pattern used for vw_rate_code.

. JSON as a document
→ You need JSON_VALUE to pull out individual values.
_____________________________________________________________________________________________________________________________________________________________________________
2. JSON as a table
→ You need OPENJSON + WITH to convert it into rows and columns. which better works with view

One‑Word Answer
OPENJSON

_____________________________________________________________________________________________________________________________________________________________________________
Two‑Word Logic
OPENJSON = Structure  
JSON_VALUE = Extraction

Business Analogy
A view is a public API for your data.
It must be:

predictable

typed

stable

reusable

query‑friendly

Using OPENJSON + WITH is like giving your consumers a properly designed API with typed fields and a schema.

Using JSON_VALUE is like giving them loose notes scribbled on paper — correct, but not structured.

_____________________________________________________________________________________________________________________________________________________________________________
Mechanical Truth (Your Style)
A. JSON_VALUE (JSON as a document)
Extracts one field at a time

Returns NVARCHAR only

No schema

No typing

No rowset

Works best inside SELECT for small lookups

Not ideal for reusable, typed views


_____________________________________________________________________________________________________________________________________________________________________________
Why it’s weak for views:

A view should expose a table, not a document.
JSON_VALUE forces you to manually extract every field, one by one, with no typing.

B. OPENJSON + WITH (JSON as a table)
Converts JSON into a rowset

Applies a schema

Produces typed columns

Handles multiple fields at once

Supports arrays, objects, nested structures

Ideal for Bronze → Silver transformations

Perfect for views

Why it’s strong for views:
A view is supposed to behave like a table.
OPENJSON literally turns JSON into a table.

_____________________________________________________________________________________________________________________________________________________________________________
Which One Works Better for Views?
Final Verdict: OPENJSON + WITH is the correct and preferred method for views.
Why?
Because a view must:

expose a stable schema

return typed columns

support joins

support filters

support downstream transformations

behave like a table

JSON_VALUE cannot do this.
OPENJSON can.

_____________________________________________________________________________________________________________________________________________________________________________
Your Final Mental Model
Views = Tables → Use OPENJSON
Quick extraction = Scalars → Use JSON_VALUE


Corrected + Completed Code (What Was Missing Is Now Added)
```sql
USE nyc_taxi_ldw
GO

-- Drop view if it already exists
DROP VIEW IF EXISTS bronze.vw_payment_type
GO

-- Create view for payment type file
CREATE VIEW bronze.vw_payment_type
AS
SELECT payment_type, description
FROM OPENROWSET(
        BULK 'raw/payment_type.json',
        DATA_SOURCE = 'nyc_taxi_src',
        FORMAT = 'CSV',
        FIELDTERMINATOR = '0x0b',
        FIELDQUOTE = '0x0b',
        ROWTERMINATOR = '0x0b'
     )
     WITH (jsonDoc NVARCHAR(MAX)) AS payment_type
CROSS APPLY OPENJSON(jsonDoc)
WITH (
        payment_type SMALLINT,
        description  VARCHAR(20) '$.payment_type_desc'
     )
GO
```

-- Test the view

```sql
SELECT * FROM bronze.vw_payment_type
GO
```

What Was Missing?
Missing Element	Why It Matters
DROP VIEW IF EXISTS	Prevents failure when re‑running the script.
GO separators	CREATE VIEW must be the first statement in a batch.
ROWTERMINATOR = '0x0b'	Required for JSON‑adjacent pattern (same as rate_code).
USE nyc_taxi_ldw	Ensures the view is created in the correct logical warehouse.
Final SELECT test	Confirms the view works and returns the expected 6 rows.

Does this now match the instructor’s explanation?
Yes — perfectly.

Naming convention: vw_payment_type

JSON‑adjacent pattern: OPENROWSET + OPENJSON

Correct file: payment_type.json

Correct folder: raw/

Correct data source: nyc_taxi_src

Correct batch structure: GO separators

Correct cleanup: DROP VIEW IF EXISTS

This is now production‑ready, lesson‑aligned, and bronze‑layer compliant.

Version A — Using OPENJSON
(This is the one you already have.)

```sql
USE nyc_taxi_ldw
GO

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
        FIELDQUOTE = '0x0b',
        ROWTERMINATOR = '0x0b'
     )
     WITH (jsonDoc NVARCHAR(MAX)) AS payment_type
CROSS APPLY OPENJSON(jsonDoc)
WITH (
        payment_type SMALLINT,
        description  VARCHAR(20) '$.payment_type_desc'
     )
GO
```
Version B — Using JSON_VALUE
(This is the missing one — generated cleanly for you.)

Key difference:
Instead of using OPENJSON … WITH (…), we extract each field individually using JSON_VALUE.

```sql
USE nyc_taxi_ldw
GO

DROP VIEW IF EXISTS bronze.vw_payment_type_jsonvalue
GO

CREATE VIEW bronze.vw_payment_type_jsonvalue
AS
SELECT
    JSON_VALUE(jsonDoc, '$.payment_type')       AS payment_type,
    JSON_VALUE(jsonDoc, '$.payment_type_desc')  AS description
FROM OPENROWSET(
        BULK 'raw/payment_type.json',
        DATA_SOURCE = 'nyc_taxi_src',
        FORMAT = 'CSV',
        FIELDTERMINATOR = '0x0b',
        FIELDQUOTE = '0x0b',
        ROWTERMINATOR = '0x0b'
     )
     WITH (jsonDoc NVARCHAR(MAX))
GO
```
Mechanical Difference (Your Preferred Style)
Method	Mechanism	When to Use
OPENJSON + WITH	Schema projection (typed columns)	When you want strict typing and structured output
JSON_VALUE	Scalar extraction (one field at a time)	When the JSON is simple or you only need a few fields

Two‑Word Logic
OPENJSON = Structured Extraction

JSON_VALUE = Scalar Extraction

One‑Word Summary
OPENJSON: Structure

JSON_VALUE: Extraction

2, Two‑Word Logic
OPENJSON = Schema Projection

JSON_VALUE = Scalar Retrieval

3, Business Analogy
Think of a JSON file as a shipping container.

OPENJSON + WITH
This is like opening the container, unloading everything, and arranging it into a proper warehouse layout with typed shelves and labeled boxes.

You get:

Structured rows

Typed columns

Multiple fields at once

Clean tabular output

JSON_VALUE
This is like reaching into the container through a small door and pulling out one specific item at a time.

You get:

One field per call

No schema

No typing

Simple extraction

4, Mechanical Truth (Your Preferred Style)
A. OPENJSON + WITH
This method projects JSON into a table.

What it does mechanically
Reads the JSON document

Applies a schema you define

Converts JSON fields into typed SQL columns

Returns a rowset (table-like output)

When to use
When JSON contains multiple fields

When you want typed columns

When you want multiple rows

When you want clean SQL‑table output

When you want performance (fewer function calls)

Example

```sql
CROSS APPLY OPENJSON(jsonDoc)
WITH (
    payment_type SMALLINT,
    description  VARCHAR(20) '$.payment_type_desc'
)
```
B. JSON_VALUE
This method extracts a single scalar value from JSON.

What it does mechanically
Reads the JSON string

Extracts one value using a JSON path

Returns it as NVARCHAR

Does NOT return a rowset

Does NOT apply schema

Does NOT infer types

When to use
When JSON is simple

When you only need one or two fields

When you don’t need typed columns

When you want quick scalar extraction

Example
sql
JSON_VALUE(jsonDoc, '$.payment_type') AS payment_type

5, Why Two Categories Exist
Because JSON has two personalities:

1. JSON as a document
→ You need JSON_VALUE to pull out individual values.

2. JSON as a table
→ You need OPENJSON + WITH to convert it into rows and columns.

SQL engines must support both because JSON is used in two different ways in real systems:

JSON Use Case	Required Method
Configuration files	JSON_VALUE
API responses	JSON_VALUE
Nested arrays	OPENJSON
Multi‑row JSON datasets	OPENJSON
Schema projection	OPENJSON
Quick scalar lookup	JSON_VALUE

6, Which One Should You Use in Synapse Serverless?
Bronze Layer (Raw → View)
Use OPENJSON + WITH  
Because you want:

Typed columns

Clean schema

Predictable structure

Reusable views

Silver/Gold Layer (Transformations)
Use JSON_VALUE  
When you only need:

One field

A quick lookup

A scalar value inside a larger SELECT

7, Your Final Mental Model

OPENJSON = Table Builder
Turns JSON into a table.

JSON_VALUE = Field Extractor
Pulls one value at a time.
