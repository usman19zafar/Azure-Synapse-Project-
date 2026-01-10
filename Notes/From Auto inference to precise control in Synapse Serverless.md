One‑word anchor: Control
Two‑word logic: Type disciplineLecture title: From lazy inference to precise control in Synapse Serverless
One‑word anchor: Control
Two‑word logic: Type discipline

Analogy:  
Imagine a warehouse where, if you don’t tell workers how big the boxes are, they assume every box is the largest possible size. They reorganize the whole place to handle “maybe giant” boxes.
You get: wasted space, slower movement, higher cost.

Synapse Serverless does the same thing with data types when you don’t define them.
This lecture is about taking that control back.

Step 0 – The dataset and the goal
We’re working with a CSV in Azure Data Lake Storage Gen2, using the ABFSS protocol:

text
abfss://nyctaxidata@786.dfs.core.windows.net/raw/taxi_zone.csv
Goal of the lesson:

Let Synapse infer data types (lazy, exploratory mode).

Inspect what Synapse decided.

Check what the data actually needs.

Override Synapse and define explicit, right‑sized data types.

Understand why this matters for cost and performance.

Step 1 – Just read the file and explore
We start with the simplest form: “show me some rows.”

sql
SELECT
    TOP 100 *
FROM
    OPENROWSET(
        BULK 'abfss://nyctaxidata@786.dfs.core.windows.net/raw/taxi_zone.csv',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n'
    ) AS [result];
Theory of this step
At this stage, you’re in exploration mode. You don’t care yet about perfect types; you just want to see the data and understand the shape: columns, rough values, obvious junk.

Synapse Serverless is doing a lot behind the scenes:

It reads the file directly from storage.

It infers the column names from the header row.

It guesses the data types based on the first rows.

You haven’t taken control yet; you’re just letting Synapse be “smart.” This is fine for the first 30 minutes of a project. It’s terrible for the next 3 months if you stay here.

Code explanation, line by line
SELECT TOP 100 *  
Purpose: Limit the output to the first 100 rows.
Why: Faster feedback, less noise — good for exploration.

OPENROWSET(...)  
Purpose: Treat an external file as if it were a table, on the fly.

Inside OPENROWSET:

BULK 'abfss://nyctaxidata@786.dfs.core.windows.net/raw/taxi_zone.csv'  
BULK: “Read from this external file.”
ABFSS URI:

nyctaxidata → File system / container name

786 → Storage account name

/raw/taxi_zone.csv → Folder path + file name

FORMAT = 'CSV'  
Tells Synapse how to interpret the file: comma‑separated values.

PARSER_VERSION = '2.0'  
Uses the newer CSV parser, better handling of quotes, edge cases, etc.

HEADER_ROW = TRUE  
Tells Synapse: “First line is column names, not data.”

FIELDTERMINATOR = ','  
Each column is separated by a comma. This is default for CSV, but we’re being explicit.

ROWTERMINATOR = '\n'  
Each row ends with a newline (Unix style).

AS [result]  
Aliases the virtual table as result, so you can reference it if needed.

Step 2 – See what data types Synapse inferred
Now we ask: “What does Synapse think these columns are?”  
We use sp_describe_first_result_set to introspect the query.

sql
EXEC sp_describe_first_result_set N'
SELECT
    TOP 100 *
FROM
    OPENROWSET(
        BULK ''abfss://nyctaxidata@786.dfs.core.windows.net/raw/taxi_zone.csv'',
        FORMAT = ''CSV'',
        PARSER_VERSION = ''2.0'',
        HEADER_ROW = TRUE
    ) AS [result]';
Theory of this step
This is like asking Synapse:
“Show me the schema you inferred from that query — column names, data types, lengths, nullability, etc.”

In serverless SQL pools, this is crucial because:

You are not creating a permanent table.

The schema lives inside the query.

If you repeat this query across many files, you’re repeatedly paying for whatever types Synapse chooses.

Why the quotes look weird
The entire SELECT statement is passed as a string literal (because sp_describe_first_result_set expects a query text).

Inside that string, you need to escape single quotes by doubling them:

' becomes ''.

That’s why you see:

sql
BULK ''abfss://nyctaxidata@786.dfs.core.windows.net/raw/taxi_zone.csv''
FORMAT = ''CSV''
Synapse sees that whole N'... ' as one Unicode string containing the query.

What you typically see in the result
Synapse often infers:

LocationID → BIGINT

Borough, Zone, service_zone → VARCHAR(8000)

This is the warehouse assuming every box is XXL. It works, but it’s costly and sloppy.

Step 3 – Measure the real maximum lengths in the data
Now we move from “what Synapse guessed” to “what the data actually needs.”

sql
SELECT
    MAX(LEN(LocationID))     AS len_LocationID,
    MAX(LEN(Borough))        AS len_Borough,
    MAX(LEN(Zone))           AS len_Zone,
    MAX(LEN(service_zone))   AS len_service_zone
FROM
    OPENROWSET(
        BULK 'abfss://nyctaxidata@786.dfs.core.windows.net/raw/taxi_zone.csv',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n'
    ) AS [result];
Theory of this step
We’re now doing schema forensics:

LEN() tells us the length of each value.

MAX(LEN(...)) tells us the longest value encountered in the column.

This gives us evidence to design proper types:

No guessing.

No cargo‑culting.

No “VARCHAR(8000) just in case.”

Typical results might show:

LocationID max length → 3

Borough max length → 13

Zone max length → 45

service_zone max length → 11

So Synapse’s generous VARCHAR(8000) is absurd here.

Code explanation
MAX(LEN(LocationID)) AS len_LocationID  
Finds the longest number of characters in LocationID. Even if it’s numeric, it’s being read as text at this stage.

We do this for each column to understand true upper bounds.

The OPENROWSET block is the same as before: we re‑read the file, but this time, instead of SELECT *, we compute aggregates.

Step 4 – Take control with explicit data types using WITH
Now comes the architect move: you override Synapse’s guesses and specify your own schema.

sql
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
        LocationID   SMALLINT,
        Borough      VARCHAR(15),
        Zone         VARCHAR(50),
        service_zone VARCHAR(15)
    ) AS [result];
Theory of this step
The WITH (...) clause tells Synapse:

“Stop guessing. I’m giving you the schema.”

For each column, you now define:

Name

Data type

Size (for text types)

This has two major impacts:

Cost

Synapse serverless charges per data scanned.

Bigger types can mean more bytes processed internally.

Right‑sized types = less waste, lower bill.

Performance

Smaller types = less memory per row.

Faster scans, faster joins, better cache behavior.

Over massive datasets, this matters a lot.

You also gain semantic clarity: your schema reflects your understanding of the domain, not just what Synapse saw in a few rows.

Code explanation, line by line
The OPENROWSET arguments are the same as before; we still read from the same file.

The new part is:

sql
WITH (
    LocationID   SMALLINT,
    Borough      VARCHAR(15),
    Zone         VARCHAR(50),
    service_zone VARCHAR(15)
)
LocationID SMALLINT

SMALLINT is enough to store integer values from −32,768 to 32,767.

Our IDs are only 3 digits long, so this is safe and efficient.

Borough VARCHAR(15)

We observed max length 13.

We add a little buffer and set 15.

Zone VARCHAR(50)

Max was 45, so 50 gives breathing room.

service_zone VARCHAR(15)

Max was 11, so 15 is safe and still compact.

AS [result]

The final result set now honors your schema, not Synapse’s defaults.

Step 5 – Validate that Synapse is really using your types
We close the loop: introspect again, but now with the explicit schema included.

sql
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
        LocationID   SMALLINT,
        Borough      VARCHAR(15),
        Zone         VARCHAR(50),
        service_zone VARCHAR(15)
    ) AS [result]';
Theory of this step
This is schema verification:

You’re checking that Synapse has accepted and applied your explicit data types.

This step is crucial when you’re building repeatable workloads and shared queries for teams.

You are not just writing a query anymore. You are defining an interface contract for your data.

Code explanation
Again, the entire query is passed as a string literal to sp_describe_first_result_set.

Quotes are escaped ('') for any single quotes inside.

The result will show each column with:

Correct system_type_name (e.g., smallint, varchar(15)).

Nullability, order, etc.

Once you see the expected schema, you know:

“When anyone uses this query, Synapse will allocate memory and scan data using my schema, not its guess.”

Step 6 – Cost and performance: why this isn’t academic
Serverless SQL pools charge based on data processed.
When Synapse assumes:

BIGINT instead of SMALLINT

VARCHAR(8000) instead of VARCHAR(50)

… it’s effectively saying: “I’m going to treat every box like a giant one.”

Over a few MB, you don’t see much difference.
Over:

Billions of rows,

Daily refreshes,

Multi‑table joins,

… that “just let Synapse infer it” attitude becomes a real invoice and a real performance bottleneck.

You can also inspect messages in Synapse after execution to see:

Total size of data scanned

Total size of data returned

With explicit, tight data types, those numbers become healthier and more predictable.

Executive recap (for your workbook)
One word: Precision
Two words: Schema ownership

Story in one paragraph:  
You started by letting Synapse Serverless infer types, which is convenient, but lazy and costly in the long run. You then inspected what Synapse inferred, measured the true needs of your columns, and asserted your own schema using the WITH clause in OPENROWSET. Finally, you validated that Synapse is using your schema and reflected on the impact on cost, performance, and design discipline. You went from “Synapse guesses” to “you own the contract.”

Analogy:  
Imagine a warehouse where, if you don’t tell workers how big the boxes are, they assume every box is the largest possible size. They reorganize the whole place to handle “maybe giant” boxes.
You get: wasted space, slower movement, higher cost.

Synapse Serverless does the same thing with data types when you don’t define them.
This lecture is about taking that control back.

Step 0 – The dataset and the goal
We’re working with a CSV in Azure Data Lake Storage Gen2, using the ABFSS protocol:

text
abfss://nyctaxidata@786.dfs.core.windows.net/raw/taxi_zone.csv
Goal of the lesson:

Let Synapse infer data types (lazy, exploratory mode).

Inspect what Synapse decided.

Check what the data actually needs.

Override Synapse and define explicit, right‑sized data types.

Understand why this matters for cost and performance.

Step 1 – Just read the file and explore
We start with the simplest form: “show me some rows.”

sql
SELECT
    TOP 100 *
FROM
    OPENROWSET(
        BULK 'abfss://nyctaxidata@786.dfs.core.windows.net/raw/taxi_zone.csv',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n'
    ) AS [result];
Theory of this step
At this stage, you’re in exploration mode. You don’t care yet about perfect types; you just want to see the data and understand the shape: columns, rough values, obvious junk.

Synapse Serverless is doing a lot behind the scenes:

It reads the file directly from storage.

It infers the column names from the header row.

It guesses the data types based on the first rows.

You haven’t taken control yet; you’re just letting Synapse be “smart.” This is fine for the first 30 minutes of a project. It’s terrible for the next 3 months if you stay here.

Code explanation, line by line
SELECT TOP 100 *  
Purpose: Limit the output to the first 100 rows.
Why: Faster feedback, less noise — good for exploration.

OPENROWSET(...)  
Purpose: Treat an external file as if it were a table, on the fly.

Inside OPENROWSET:

BULK 'abfss://nyctaxidata@786.dfs.core.windows.net/raw/taxi_zone.csv'  
BULK: “Read from this external file.”
ABFSS URI:

nyctaxidata → File system / container name

786 → Storage account name

/raw/taxi_zone.csv → Folder path + file name

FORMAT = 'CSV'  
Tells Synapse how to interpret the file: comma‑separated values.

PARSER_VERSION = '2.0'  
Uses the newer CSV parser, better handling of quotes, edge cases, etc.

HEADER_ROW = TRUE  
Tells Synapse: “First line is column names, not data.”

FIELDTERMINATOR = ','  
Each column is separated by a comma. This is default for CSV, but we’re being explicit.

ROWTERMINATOR = '\n'  
Each row ends with a newline (Unix style).

AS [result]  
Aliases the virtual table as result, so you can reference it if needed.

Step 2 – See what data types Synapse inferred
Now we ask: “What does Synapse think these columns are?”  
We use sp_describe_first_result_set to introspect the query.

sql
EXEC sp_describe_first_result_set N'
SELECT
    TOP 100 *
FROM
    OPENROWSET(
        BULK ''abfss://nyctaxidata@786.dfs.core.windows.net/raw/taxi_zone.csv'',
        FORMAT = ''CSV'',
        PARSER_VERSION = ''2.0'',
        HEADER_ROW = TRUE
    ) AS [result]';
Theory of this step
This is like asking Synapse:
“Show me the schema you inferred from that query — column names, data types, lengths, nullability, etc.”

In serverless SQL pools, this is crucial because:

You are not creating a permanent table.

The schema lives inside the query.

If you repeat this query across many files, you’re repeatedly paying for whatever types Synapse chooses.

Why the quotes look weird
The entire SELECT statement is passed as a string literal (because sp_describe_first_result_set expects a query text).

Inside that string, you need to escape single quotes by doubling them:

' becomes ''.

That’s why you see:

sql
BULK ''abfss://nyctaxidata@786.dfs.core.windows.net/raw/taxi_zone.csv''
FORMAT = ''CSV''
Synapse sees that whole N'... ' as one Unicode string containing the query.

What you typically see in the result
Synapse often infers:

LocationID → BIGINT

Borough, Zone, service_zone → VARCHAR(8000)

This is the warehouse assuming every box is XXL. It works, but it’s costly and sloppy.

Step 3 – Measure the real maximum lengths in the data
Now we move from “what Synapse guessed” to “what the data actually needs.”

sql
SELECT
    MAX(LEN(LocationID))     AS len_LocationID,
    MAX(LEN(Borough))        AS len_Borough,
    MAX(LEN(Zone))           AS len_Zone,
    MAX(LEN(service_zone))   AS len_service_zone
FROM
    OPENROWSET(
        BULK 'abfss://nyctaxidata@786.dfs.core.windows.net/raw/taxi_zone.csv',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n'
    ) AS [result];
Theory of this step
We’re now doing schema forensics:

LEN() tells us the length of each value.

MAX(LEN(...)) tells us the longest value encountered in the column.

This gives us evidence to design proper types:

No guessing.

No cargo‑culting.

No “VARCHAR(8000) just in case.”

Typical results might show:

LocationID max length → 3

Borough max length → 13

Zone max length → 45

service_zone max length → 11

So Synapse’s generous VARCHAR(8000) is absurd here.

Code explanation
MAX(LEN(LocationID)) AS len_LocationID  
Finds the longest number of characters in LocationID. Even if it’s numeric, it’s being read as text at this stage.

We do this for each column to understand true upper bounds.

The OPENROWSET block is the same as before: we re‑read the file, but this time, instead of SELECT *, we compute aggregates.

Step 4 – Take control with explicit data types using WITH
Now comes the architect move: you override Synapse’s guesses and specify your own schema.

sql
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
        LocationID   SMALLINT,
        Borough      VARCHAR(15),
        Zone         VARCHAR(50),
        service_zone VARCHAR(15)
    ) AS [result];
Theory of this step
The WITH (...) clause tells Synapse:

“Stop guessing. I’m giving you the schema.”

For each column, you now define:

Name

Data type

Size (for text types)

This has two major impacts:

Cost

Synapse serverless charges per data scanned.

Bigger types can mean more bytes processed internally.

Right‑sized types = less waste, lower bill.

Performance

Smaller types = less memory per row.

Faster scans, faster joins, better cache behavior.

Over massive datasets, this matters a lot.

You also gain semantic clarity: your schema reflects your understanding of the domain, not just what Synapse saw in a few rows.

Code explanation, line by line
The OPENROWSET arguments are the same as before; we still read from the same file.

The new part is:

sql
WITH (
    LocationID   SMALLINT,
    Borough      VARCHAR(15),
    Zone         VARCHAR(50),
    service_zone VARCHAR(15)
)
LocationID SMALLINT

SMALLINT is enough to store integer values from −32,768 to 32,767.

Our IDs are only 3 digits long, so this is safe and efficient.

Borough VARCHAR(15)

We observed max length 13.

We add a little buffer and set 15.

Zone VARCHAR(50)

Max was 45, so 50 gives breathing room.

service_zone VARCHAR(15)

Max was 11, so 15 is safe and still compact.

AS [result]

The final result set now honors your schema, not Synapse’s defaults.

Step 5 – Validate that Synapse is really using your types
We close the loop: introspect again, but now with the explicit schema included.

sql
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
        LocationID   SMALLINT,
        Borough      VARCHAR(15),
        Zone         VARCHAR(50),
        service_zone VARCHAR(15)
    ) AS [result]';
Theory of this step
This is schema verification:

You’re checking that Synapse has accepted and applied your explicit data types.

This step is crucial when you’re building repeatable workloads and shared queries for teams.

You are not just writing a query anymore. You are defining an interface contract for your data.

Code explanation
Again, the entire query is passed as a string literal to sp_describe_first_result_set.

Quotes are escaped ('') for any single quotes inside.

The result will show each column with:

Correct system_type_name (e.g., smallint, varchar(15)).

Nullability, order, etc.

Once you see the expected schema, you know:

“When anyone uses this query, Synapse will allocate memory and scan data using my schema, not its guess.”

Step 6 – Cost and performance: why this isn’t academic
Serverless SQL pools charge based on data processed.
When Synapse assumes:

BIGINT instead of SMALLINT

VARCHAR(8000) instead of VARCHAR(50)

… it’s effectively saying: “I’m going to treat every box like a giant one.”

Over a few MB, you don’t see much difference.
Over:

Billions of rows,

Daily refreshes,

Multi‑table joins,

… that “just let Synapse infer it” attitude becomes a real invoice and a real performance bottleneck.

You can also inspect messages in Synapse after execution to see:

Total size of data scanned

Total size of data returned

With explicit, tight data types, those numbers become healthier and more predictable.

Executive recap (for your workbook)
One word: Precision
Two words: Schema ownership

Story in one paragraph:  
You started by letting Synapse Serverless infer types, which is convenient, but lazy and costly in the long run. You then inspected what Synapse inferred, measured the true needs of your columns, and asserted your own schema using the WITH clause in OPENROWSET. Finally, you validated that Synapse is using your schema and reflected on the impact on cost, performance, and design discipline. You went from “Synapse guesses” to “you own the contract.”
