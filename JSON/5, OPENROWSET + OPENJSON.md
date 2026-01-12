Notes: Reading Standard JSON Arrays Using OPENROWSET + OPENJSON 
This lesson focuses on how to read standard JSON files where multiple JSON objects are grouped inside a single JSON array.
This structure is different from line‑delimited JSON and requires a different ingestion approach.

1 Understanding the File Structure
The file:

```Code
abfss://nyctaxidata@786.dfs.core.windows.net/raw/rate_code.json
```
contains:

A single JSON array

Inside the array → multiple JSON objects

Each object contains:

rate_code_id

rate_code

Example Structure
```Code
[
  { "rate_code_id": 1, "rate_code": "Standard rate" },
  { "rate_code_id": 2, "rate_code": "JFK" },
  ...
]
```
Key Difference from Previous Lessons

Payment type JSON was line‑delimited → one JSON per line

Rate code JSON is a single multi‑line JSON array → not valid line‑by‑line

This means:

We must read the entire file as one JSON string, not one line per row.
______________________________________________________________________________________________________________________________________________________________
2, Why We Cannot Use ROWTERMINATOR = '\n'
If we use newline as the row terminator:

Synapse will try to read each line separately

But lines inside a JSON array are not valid JSON documents

Some lines start with commas

Some lines contain only brackets

Therefore:

We must override the row terminator so Synapse reads the entire file as one row.
______________________________________________________________________________________________________________________________________________________________
3, Correct Approach: Read the Entire File as One JSON Document
We override:

FIELDTERMINATOR = '0x0b'

FIELDQUOTE = '0x0b'

ROWTERMINATOR = '0x0b'

Vertical tab (0x0b) is chosen because it never appears in JSON.

This forces Synapse to:

Ignore commas

Ignore quotes

Ignore newlines

Read the entire file as one NVARCHAR(MAX) value
______________________________________________________________________________________________________________________________________________________________
4, Step 1 — Read the JSON File into a Single Column

```sql
USE nyc_taxi_discovery;

SELECT rate_code_id, rate_code
FROM OPENROWSET(
        BULK 'raw/rate_code.json',
        DATA_SOURCE = 'nyctaxidata',
        FORMAT = 'CSV',
        FIELDTERMINATOR = '0x0b',
        FIELDQUOTE = '0x0b',
        ROWTERMINATOR = '0x0b'
     )
WITH (jsonDoc NVARCHAR(MAX)) AS rate_code
CROSS APPLY OPENJSON(jsonDoc)
WITH (
        rate_code_id TINYINT,
        rate_code VARCHAR(20)
     );
```

What this does
Reads the entire file as one JSON string

Stores it in jsonDoc

OPENJSON parses the array

Returns one row per JSON object

Output
```Code
+--------------+-------------------+
| rate_code_id | rate_code         |
+--------------+-------------------+
| 1            | Standard rate     |
| 2            | JFK               |
| 3            | Newark            |
| 4            | Nassau/Westchester|
| 5            | Negotiated fare   |
| 6            | Group ride        |
+--------------+-------------------+
```
______________________________________________________________________________________________________________________________________________________________
5, Processing Multi‑Line JSON Files
The multi‑line version:

Code
abfss://nyctaxidata@786.dfs.core.windows.net/raw/rate_code_multi_line.json
uses the same logic:

```sql
SELECT rate_code_id, rate_code
FROM OPENROWSET(
        BULK 'raw/rate_code_multi_line.json',
        DATA_SOURCE = 'nyctaxidata',
        FORMAT = 'CSV',
        FIELDTERMINATOR = '0x0b',
        FIELDQUOTE = '0x0b',
        ROWTERMINATOR = '0x0b'
     )
WITH (jsonDoc NVARCHAR(MAX)) AS rate_code
CROSS APPLY OPENJSON(jsonDoc)
WITH (
        rate_code_id TINYINT,
        rate_code VARCHAR(20)
     );
```

Why this works
Multi‑line JSON arrays still need to be read as one JSON document

OPENJSON automatically handles multi‑line formatting

No need for JSON_VALUE

No need for manual indexing
______________________________________________________________________________________________________________________________________________________________
6, Why OPENJSON Is the Correct Tool

OPENJSON advantages

Parses JSON arrays into rows

Handles multi‑line JSON

Allows explicit data types

More efficient than JSON_VALUE

Cleaner and scalable
______________________________________________________________________________________________________________________________________________________________
JSON_VALUE limitations

Cannot parse arrays

Cannot explode multiple objects

Requires manual indexing

Not suitable for standard JSON arrays

Therefore:

For standard JSON arrays, always use OPENJSON, not JSON_VALUE.
______________________________________________________________________________________________________________________________________________________________
8 Key Takeaways from This Lesson
A. Override ROWTERMINATOR
Use ROWTERMINATOR = '0x0b' to force Synapse to read the entire file as one JSON string.

B. Use OPENJSON for arrays
OPENJSON automatically explodes the array into rows.

C. Define data types in the WITH clause
This ensures:

Performance

Cost efficiency

Schema stability

D. JSON_VALUE is not suitable for arrays
It cannot dynamically handle multiple elements.
______________________________________________________________________________________________________________________________________________________________
Final Summary:

The rate code file is a standard JSON array, not line‑delimited JSON.

You must read the entire file as one JSON document.

Override row terminator to vertical tab (0x0b).

Use OPENJSON to explode the array into rows.

Use the WITH clause to define:

rate_code_id as TINYINT

rate_code as VARCHAR(20)

JSON_VALUE is not appropriate for this structure.

OPENJSON is the correct and scalable solution.
