Detailed Notes: Exploring JSON Documents Containing Arrays (JSON_VALUE vs OPENJSON)

This lesson focuses on how to read and process JSON documents that contain arrays, using both:

JSON_VALUE()

OPENJSON()

We will see why JSON_VALUE quickly becomes insufficient, and why OPENJSON is the correct tool for array‑based JSON.

1, Understanding the File Structure
You created a modified version of the payment type file:

```Code
payment_type_array.json
```
Stored at:

```Code
abfss://nyctaxidata@786.dfs.core.windows.net/raw/payment_type_array.json
```

What changed?

payment_type remains a simple scalar.

payment_type_desc is now an array.

Each array element contains:

sub_type

value

Example

```Code
{
  "payment_type": 1,
  "payment_type_desc": [
      { "sub_type": 10, "value": "Credit card" }
  ]
}
```
For payment type 5, the array contains two elements, meaning two descriptions.

2, Step 1 — Reading the JSON File Using OPENROWSET
We use the CSV parser with overridden delimiters so each JSON line is read as a single field.

```sql
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

Why these settings?
FIELDTERMINATOR = '0x0b' → vertical tab (never appears in JSON)

FIELDQUOTE = '0x0b' → prevents breaking on quotes

ROWTERMINATOR = '0x0a' → newline = one JSON document

jsonDoc NVARCHAR(MAX) → entire JSON document stored in one column

This produces one row per JSON document, each stored in jsonDoc.

3 Step 2 — Using JSON_VALUE() on Arrays (Why It Fails)
Your first attempt:

```sql
SELECT 
    CAST(JSON_VALUE(jsonDoc, '$.payment_type') AS SMALLINT) payment_type,
    CAST(JSON_VALUE(jsonDoc, '$.payment_type_desc[0].value') AS VARCHAR(15)) payment_type_desc_0,
    CAST(JSON_VALUE(jsonDoc, '$.payment_type_desc[1].value') AS VARCHAR(15)) payment_type_desc_01
```

What happens?

JSON_VALUE works for:

payment_type

payment_type_desc[0].value

But it fails when:

The array has more than 2 elements

The array size is unknown

You need to return multiple rows instead of multiple columns

Limitations of JSON_VALUE

Cannot explode arrays

Cannot dynamically handle variable array sizes

Requires manual indexing ([0], [1], [2], …)

Requires CAST for every field

Not scalable

Not efficient

This is why JSON_VALUE is not suitable for JSON arrays.

4, Step 3 — Correct Approach: Using OPENJSON to Explode Arrays
OPENJSON is a table‑valued function that:

Reads JSON

Returns rows and columns

Explodes arrays automatically

Allows explicit data types

Handles nested structures

Step 3A — First OPENJSON: Extract scalar fields + array as JSON

```sql
CROSS APPLY OPENJSON(jsonDoc)
WITH (
    payment_type SMALLINT,
    payment_type_desc NVARCHAR(MAX) AS JSON
)
```
This produces:

payment_type	payment_type_desc (JSON array)
1	[{"sub_type":10,"value":"Credit card"}]
5	[{"sub_type":50,"value":"Unknown"},{"sub_type":51,"value":"Unavailable"}]

5, Step 4 — Second OPENJSON: Explode the Array
Now we explode the array:

```sql
CROSS APPLY OPENJSON(payment_type_desc)
WITH (
    sub_type SMALLINT,
    payment_type_desc_value VARCHAR(20) '$.value'
)
```

This produces one row per array element:

payment_type	payment_type_desc_value
1	Credit card
2	Cash
3	No charge
4	Dispute
5	Unknown
5	Unavailable
6	Voided trip
This is the correct and scalable output.

6, Final Combined Query (Correct Pattern)

```sql
SELECT  
       payment_type,
       payment_type_desc_value
FROM OPENROWSET(
        BULK 'raw/payment_type_array.json',
        DATA_SOURCE = 'nyctaxidata',
        FORMAT = 'CSV',
        PARSER_VERSION = '1.0',
        FIELDTERMINATOR = '0x0b',
        FIELDQUOTE = '0x0b',
        ROWTERMINATOR = '0x0a'
     )
WITH (jsonDoc NVARCHAR(MAX)) AS p
CROSS APPLY OPENJSON(jsonDoc)
WITH (
        payment_type SMALLINT,
        payment_type_desc NVARCHAR(MAX) AS JSON
     )
CROSS APPLY OPENJSON(payment_type_desc)
WITH (
        payment_type_desc_value VARCHAR(20) '$.value'
     );
```

7, Why OPENJSON Is the Correct Tool
OPENJSON advantages
Explodes arrays into multiple rows

Handles nested JSON

Allows explicit data types

More efficient than JSON_VALUE

Cleaner and more scalable

Works for unbounded arrays

Works for complex structures

JSON_VALUE disadvantages
Only extracts scalar values

Cannot explode arrays

Requires manual indexing

Not scalable

Requires CAST for every field

Summary:

The file contains arrays, so JSON_VALUE is insufficient.

JSON_VALUE can only extract specific array elements ([0], [1]).

Arrays may have unlimited elements → JSON_VALUE cannot scale.

OPENJSON is the correct tool because it:

Explodes arrays

Returns multiple rows

Allows explicit data types

Handles nested JSON

The correct pattern is:

Read JSON using OPENROWSET

Use OPENJSON to extract scalar fields

Use a second OPENJSON to explode arrays

This is the canonical method for handling JSON arrays in Synapse Serverless SQL.
