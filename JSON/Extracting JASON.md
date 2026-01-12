Understanding the File Format
Line‑Delimited JSON Characteristics
Each line = one complete JSON document

Lines separated by newline (\n)

No outer array

No multi‑line formatting

Common in telemetry, logs, event streams

Example
```Code
{"payment_type":1,"payment_type_desc":"Credit Card"}
{"payment_type":2,"payment_type_desc":"Cash"}
```
This format is perfect for the two‑step ingestion approach.
___________________________________________________________________________________________________________________________________________________________
2, Why We Need the Two‑Step Process
Serverless SQL cannot directly parse JSON using OPENROWSET.
So we must:

Step 1 — Use CSV parser to read each JSON line as a single field
We must prevent the CSV parser from splitting JSON on commas or quotes.

JSON contains commas → default CSV parsing would break it.

JSON contains quotes → default FIELDQUOTE would break it.

Step 2 — Use JSON functions to extract properties
JSON_VALUE() for scalar values

OPENJSON() for arrays or nested objects

This pattern works for all JSON formats.
___________________________________________________________________________________________________________________________________________________________
3, Step 1 — Reading Each JSON Document as One Field
To prevent the CSV parser from splitting JSON:

We override:
FIELDTERMINATOR → use vertical tab (0x0B)

FIELDQUOTE → also vertical tab (0x0B)

ROWTERMINATOR → newline (0x0A)

Vertical tab is chosen because it never appears in JSON.

Updated Working Code (with ABFSS path)

```sql
USE nyc_taxi_discovery;

SELECT CAST(JSON_VALUE(jsonDoc, '$.payment_type') AS SMALLINT) AS payment_type,
       CAST(JSON_VALUE(jsonDoc, '$.payment_type_desc') AS VARCHAR(15)) AS payment_type_desc
FROM OPENROWSET(
        BULK 'raw/payment_type.json',
        DATA_SOURCE = 'nyctaxidata',
        FORMAT = 'CSV',
        PARSER_VERSION = '1.0',
        FIELDTERMINATOR = '0x0b',
        FIELDQUOTE = '0x0b',
        ROWTERMINATOR = '0x0a'
     )
WITH (jsonDoc NVARCHAR(MAX))
AS payment_type;
```
This produces six rows, each containing one full JSON document.
___________________________________________________________________________________________________________________________________________________________
4, Step 2 — Extracting JSON Properties Using JSON_VALUE()
Once each line is loaded into jsonDoc, we extract fields:

sql
CAST(JSON_VALUE(jsonDoc, '$.payment_type') AS SMALLINT)
CAST(JSON_VALUE(jsonDoc, '$.payment_type_desc') AS VARCHAR(15))
This produces a clean table:

payment_type	payment_type_desc
1	Credit Card
2	Cash
…	…
___________________________________________________________________________________________________________________________________________________________
5, Verifying Data Types Using sp_describe_first_result_set
This ensures Synapse uses the correct types:

```sql
EXEC sp_describe_first_result_set N'
 SELECT CAST(JSON_VALUE(jsonDoc, ''$.payment_type'') AS SMALLINT) AS payment_type,
        CAST(JSON_VALUE(jsonDoc, ''$.payment_type_desc'') AS VARCHAR(15)) AS payment_type_desc
 FROM OPENROWSET(
        BULK ''raw/payment_type.json'',
        DATA_SOURCE = ''nyctaxidata'',
        FORMAT = ''CSV'',
        PARSER_VERSION = ''1.0'',
        FIELDTERMINATOR = ''0x0b'',
        FIELDQUOTE = ''0x0b'',
        ROWTERMINATOR = ''0x0a''
     )
 WITH (jsonDoc NVARCHAR(MAX)) AS payment_type';
This confirms:

payment_type → SMALLINT

payment_type_desc → VARCHAR(15)
```
___________________________________________________________________________________________________________________________________________________________
6, Using OPENJSON() Instead of JSON_VALUE()
OPENJSON() is better when:

You want to extract multiple fields

You want to explode arrays

You want to handle nested objects

Example using OPENJSON()

```sql
SELECT payment_type, description
FROM OPENROWSET(
        BULK 'raw/payment_type.json',
        DATA_SOURCE = 'nyctaxidata',
        FORMAT = 'CSV',
        FIELDTERMINATOR = '0x0b',
        FIELDQUOTE = '0x0b'
     )
WITH (jsonDoc NVARCHAR(MAX)) AS payment_type
CROSS APPLY OPENJSON(jsonDoc)
WITH (
        payment_type SMALLINT,
        description VARCHAR(20) '$.payment_type_desc'
     );
```
___________________________________________________________________________________________________________________________________________________________
7, Reading JSON Arrays (payment_type_array.json)
Some JSON files contain arrays:

```Code
"payment_type_desc": [
    {"value":"Credit"},
    {"value":"Card"}
]
```
Extracting array elements using JSON_VALUE()

```sql
SELECT CAST(JSON_VALUE(jsonDoc, '$.payment_type') AS SMALLINT) AS payment_type,
       CAST(JSON_VALUE(jsonDoc, '$.payment_type_desc[0].value') AS VARCHAR(15)) AS payment_type_desc_0,
       CAST(JSON_VALUE(jsonDoc, '$.payment_type_desc[1].value') AS VARCHAR(15)) AS payment_type_desc_01
FROM OPENROWSET(
        BULK 'raw/payment_type_array.json',
        DATA_SOURCE = 'nyctaxidata',
        FORMAT = 'CSV',
        PARSER_VERSION = '1.0',
        FIELDTERMINATOR = '0x0b',
        FIELDQUOTE = '0x0b',
        ROWTERMINATOR = '0x0a'
     )
WITH (jsonDoc NVARCHAR(MAX)) AS payment_type;
```
___________________________________________________________________________________________________________________________________________________________
8, Exploding JSON Arrays Using OPENJSON()
This is the preferred method.

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
This produces one row per array element.
___________________________________________________________________________________________________________________________________________________________

Final Summary (No Information Skipped)
The file is line‑delimited JSON → one JSON document per line.

Use CSV parser with:

FIELDTERMINATOR = '0x0b'

FIELDQUOTE = '0x0b'

ROWTERMINATOR = '0x0a'

Read each JSON document into a single field (jsonDoc).

Use JSON_VALUE() for scalar extraction.

Use OPENJSON() for arrays and nested objects.

Always CAST extracted values to correct data types for:

performance

cost efficiency

schema stability

Use sp_describe_first_result_set to verify data types.

All code updated to use your real ABFSS path.
