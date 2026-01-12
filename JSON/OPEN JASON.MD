Notes: Using OPENJSON Instead of JSON_VALUE
This lesson explains why OPENJSON is superior to JSON_VALUE and how to use it to extract fields from JSON documents stored in a file.

The code:

```sql
SELECT payment_type, payment_type_desc_value
FROM OPENROWSET(
        BULK 'raw/payment_type_array.json',
        DATA_SOURCE = 'nyctaxidata',
        FORMAT = 'CSV',
        PARSER_VERSION = '1.0',
        FIELDTERMINATOR = '0x0b',
        FIELDQUOTE = '0x0b',
        ROWTERMINATOR = '0x0a'
     )
WITH (jsonDoc NVARCHAR(MAX)) AS payment_type
CROSS APPLY OPENJSON(jsonDoc)
WITH (
        payment_type SMALLINT,
        payment_type_desc NVARCHAR(MAX) AS JSON
     )
CROSS APPLY OPENJSON(payment_type_desc)
WITH (
        sub_type SMALLINT,
        payment_type_desc_value VARCHAR(20) '$.value'
     );
```
This is the correct pattern for extracting JSON fields using OPENJSON.

1, Why JSON_VALUE Has Limitations
JSON_VALUE() works, but it has several weaknesses:

A. You must CAST every field manually
Example:

```sql
CAST(JSON_VALUE(jsonDoc, '$.payment_type') AS SMALLINT)
```
This becomes messy for large schemas.

B. JSON_VALUE cannot explode arrays
It can only extract:

One scalar value

One specific array element (e.g., [0])

It cannot return multiple rows from an array.

C. JSON_VALUE is slower
For large datasets, OPENJSON is significantly more efficient.

2 Why OPENJSON Is Better
OPENJSON is a table‑valued function, meaning it returns rows and columns.

Advantages
More efficient than JSON_VALUE

Can explode arrays into multiple rows

Allows explicit data types (no CAST needed)

Lets you rename columns

Lets you extract multiple fields at once

Cleaner and more scalable

This makes it the preferred method for production pipelines.

What the Query Is Doing (Step‑by‑Step)
Step 1 — Read each JSON line as one field
sql
WITH (jsonDoc NVARCHAR(MAX))
This loads each JSON document into a single column.

Step 2 — CROSS APPLY OPENJSON(jsonDoc)
This passes each JSON document into OPENJSON.

OPENJSON reads the JSON and produces key/value pairs.

Step 3 — Use the WITH clause to define the schema

```sql
WITH (
    payment_type SMALLINT,
    description VARCHAR(20) '$.payment_type_desc'
)
```
This tells OPENJSON:

Extract payment_type

Extract payment_type_desc

Convert them to the specified SQL data types

Return them as columns

Step 4 — SELECT the final columns

```sql
SELECT payment_type, description
```
This produces a clean table.

What the Output Looks Like

```Code
+--------------+------------------+
| payment_type | description      |
+--------------+------------------+
| 1            | Credit card      |
| 2            | Cash             |
| 3            | No charge        |
| 4            | Dispute          |
| 5            | Unknown          |
| 6            | Voided trip      |
+--------------+------------------+
```

5, Why CROSS APPLY Is Needed
CROSS APPLY is simply a join between:

The rowset returned by OPENROWSET

The table returned by OPENJSON

It feeds each jsonDoc into OPENJSON.

Think of it as:

“For each row from OPENROWSET, apply OPENJSON to the jsonDoc column.”

No join condition is needed.

6, Key Takeaways
JSON_VALUE is fine for simple scalar extraction.

OPENJSON is the correct tool for:

Arrays

Nested objects

Multiple fields

Performance

Clean schema definition

The WITH clause inside OPENJSON lets you:

Define column names

Define data types

Map JSON paths

Rename fields

This is the preferred JSON ingestion pattern in Synapse Serverless SQL.
