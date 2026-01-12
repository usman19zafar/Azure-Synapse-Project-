Detailed Notes: Processing Multi‑Line (Classic) JSON Files Using OPENROWSET + OPENJSON

This lesson explains how to process classic multi‑line JSON files in Synapse Serverless SQL.

These files contain one JSON array that spans multiple lines, with each element representing a JSON object.

The file you are working with:

```Code
abfss://nyctaxidata@786.dfs.core.windows.net/raw/rate_code_multi_line.json
```
contains the same data as the single‑line rate_code.json file, but formatted across multiple lines for readability.

1, Understanding the File Structure

Standard JSON Array (Single‑Line Version)

```Code
[{"rate_code_id":1,"rate_code":"Standard rate"}, ...]
Multi‑Line JSON Version
Code
[
  {
    "rate_code_id": 1,
    "rate_code": "Standard rate"
  },
  {
    "rate_code_id": 2,
    "rate_code": "JFK"
  },
  ...
]
```

Key Characteristics
Both files contain one JSON array.

Each element in the array is a JSON object.

Multi‑line formatting is purely cosmetic — the structure is identical.

Important Difference

Line‑delimited JSON → one JSON document per line

Multi‑line JSON → one JSON array spanning multiple lines

Because of this:

You cannot read multi‑line JSON using newline (\n) as the row terminator.

You must read the entire file as one JSON string.

2, Why We Override ROWTERMINATOR

If you use the default newline terminator:

Synapse will try to read each line separately.

But lines like {, }, and , are not valid JSON documents.

The parser will break the JSON structure.

To avoid this:

We override ROWTERMINATOR to a character that never appears in JSON:

```Code
ROWTERMINATOR = '0x0b'   -- vertical tab
```
This forces Synapse to:

Ignore newlines

Read the entire file as one row

Store the entire JSON array in jsonDoc

3, Step 1 — Read the Entire File as One JSON Document
```sql
SELECT rate_code_id, rate_code
FROM OPENROWSET(
        BULK 'raw/rate_code_multi_line.json',
        DATA_SOURCE = 'nyctaxidata',
        FORMAT = 'CSV',
        FIELDTERMINATOR = '0x0b',
        FIELDQUOTE     = '0x0b',
        ROWTERMINATOR  = '0x0b'
     )
WITH (jsonDoc NVARCHAR(MAX)) AS rate_code;
```
What this does
Reads the entire file as a single NVARCHAR(MAX) string

Stores it in a column named jsonDoc

Prepares it for JSON parsing

4, Step 2 — Use OPENJSON to Parse the JSON Array
```sql
CROSS APPLY OPENJSON(jsonDoc)
WITH (
        rate_code_id TINYINT,
        rate_code    VARCHAR(20)
     );

```
What OPENJSON does
Detects that jsonDoc contains a JSON array

Automatically explodes the array

Returns one row per JSON object

Maps JSON properties to SQL columns

Applies the data types you specify

5, Final Combined Query
```sql
SELECT rate_code_id, rate_code
FROM OPENROWSET(
        BULK 'raw/rate_code_multi_line.json',
        DATA_SOURCE = 'nyctaxidata',
        FORMAT = 'CSV',
        FIELDTERMINATOR = '0x0b',
        FIELDQUOTE     = '0x0b',
        ROWTERMINATOR  = '0x0b'
     )
WITH (jsonDoc NVARCHAR(MAX)) AS rate_code
CROSS APPLY OPENJSON(jsonDoc)
WITH (
        rate_code_id TINYINT,
        rate_code    VARCHAR(20)
     );
```
6, Output
Code
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
Exactly the same result as the single‑line JSON file.

7, Key Takeaways
A. Multi‑line JSON is still one JSON document
Formatting does not change the structure.

B. Override ROWTERMINATOR
Use 0x0b so Synapse reads the entire file as one string.

C. Use OPENJSON to explode the array
OPENJSON automatically:

Parses the array

Returns one row per element

Applies your data types

D. JSON_VALUE is not suitable
It cannot parse arrays or multi‑line JSON structures.


Final Summary

Multi‑line JSON files are processed the same way as standard JSON arrays.

Override row terminator to vertical tab so the entire file is read as one JSON string.

Use OPENJSON to convert the JSON array into rows and columns.

Use the WITH clause to define data types and column names.

This pattern works for any classic JSON array, regardless of formatting.
