1. External table creation — line by line

Let’s use this canonical version:

```sql
CREATE EXTERNAL TABLE bronze.taxi_zone
(
    LocationID     INT,
    Borough        VARCHAR(15),
    Zone           VARCHAR(50),
    service_zone   VARCHAR(50)
)
WITH
(
    LOCATION = 'raw/taxi_zone.csv',
    DATA_SOURCE = nyc_taxi_src,
    FILE_FORMAT = csv_file_format_pv1,
    REJECT_VALUE = 10,
    REJECTED_ROW_LOCATION = 'raw/rejections/taxi_zone/'
);
```
Line 1:

```sql
CREATE EXTERNAL TABLE bronze.taxi_zone
```
Meaning: Define a table whose data lives outside the database (in storage), but whose schema lives in SQL.

bronze.taxi_zone: Schema = bronze, table name = taxi_zone. This is your Bronze layer raw view.

Lines 2–5:

sql
(
    LocationID     INT,
    Borough        VARCHAR(15),
    Zone           VARCHAR(50),
    service_zone   VARCHAR(50)
)
Meaning: Column definitions.

LocationID INT → Must be an integer; any non‑integer in the file will be considered invalid.

Borough VARCHAR(15) → Max 15 characters; longer values cause truncation errors.

Zone, service_zone → Text columns with larger limits.

These definitions are the contract between the file and the table. Any mismatch here is what drives reject logic.

Line 6:

```sql
WITH
(
```
Meaning: Start of the external table options block.

Everything inside controls where and how the file is read.

Line 7:

```sql
    LOCATION = 'raw/taxi_zone.csv',
```
Meaning: Path to the file or folder relative to the external data source.

This does not include the account/container—those come from DATA_SOURCE.

Here, it points to a single file: raw/taxi_zone.csv.

Line 8:

```sql
    DATA_SOURCE = nyc_taxi_src,
```
Meaning: Use the previously defined external data source as the root.

If nyc_taxi_src points to:

https://synapsecoursedl.dfs.core.windows.net/nyc-taxi-data

Then the full path becomes:

https://synapsecoursedl.dfs.core.windows.net/nyc-taxi-data/raw/taxi_zone.csv

Line 9:

```sql
    FILE_FORMAT = csv_file_format_pv1,
```
Meaning: Use the CSV file format with parser version 1.0.

This tells Synapse:

Delimiter = ,

String delimiter = "

First row = 2 (skip header)

Encoding = UTF‑8

Parser version = 1.0 → enables reject options

Lines 10–11:

```sql
    REJECT_VALUE = 10,
    REJECTED_ROW_LOCATION = 'raw/rejections/taxi_zone/'
);
```
These are the reject logic options—explained in detail in the next section.

2. Reject logic — line by line
We’ll focus on these two lines:

```sql
REJECT_VALUE = 10,
REJECTED_ROW_LOCATION = 'raw/rejections/taxi_zone/'
REJECT_VALUE = 10
```
Meaning: Allow up to 10 invalid rows before failing the query.

Mechanics:

Synapse starts reading rows.

Each time a row violates the schema (e.g., truncation, type mismatch), it counts as a rejected row.

As long as rejected rows ≤ 10:

Query continues.

Rejected rows are written to the rejection location.

When the 11th invalid row is encountered:

Query fails.

All rejected rows up to that point are still written to the rejection files.

Edge case: If REJECT_VALUE = 0, the first invalid row causes failure, but that row is still written to the rejected rows file.

REJECTED_ROW_LOCATION = 'raw/rejections/taxi_zone/'

Meaning: Where to write the rejected rows and error details.

Relative path: This is relative to the same DATA_SOURCE as the table.

If DATA_SOURCE = nyc_taxi_src → https://synapsecoursedl.dfs.core.windows.net/nyc-taxi-data

Then full rejection path is:

https://synapsecoursedl.dfs.core.windows.net/nyc-taxi-data/raw/rejections/taxi_zone/

What gets created under this path:

A system folder: …/_rejectedrows/<date>/<statement_id>/

Inside:

rejectedrows.csv → the bad rows themselves.

error.json → detailed error info (column, row number, error type, file name).

3. Drop‑if‑exists logic — line by line
Canonical pattern:

```sql
IF OBJECT_ID('bronze.taxi_zone') IS NOT NULL
    DROP EXTERNAL TABLE bronze.taxi_zone;
GO
```
Line 1:

```sql
IF OBJECT_ID('bronze.taxi_zone') IS NOT NULL
```
Meaning: Check if an object with that name exists in the current database.

OBJECT_ID('bronze.taxi_zone'):

Returns the internal ID of the object if it exists.

Returns NULL if it doesn’t.

IS NOT NULL:

Condition is true only if the table already exists.

Line 2:

```sql
    DROP EXTERNAL TABLE bronze.taxi_zone;
```
Meaning: Drop the external table definition (metadata only).

Important: This does not delete the underlying file in storage.

Only the SQL object (the “view” over the file) is removed.

Why this pattern matters:

Serverless SQL does not support DROP TABLE IF EXISTS for external tables.

So you must:

Check existence with OBJECT_ID.

Conditionally drop.

This makes scripts idempotent:

Safe to run multiple times.

No “object already exists” errors.

4. LOCATION and abfss path resolution — line by line
You gave this full path:

abfss://nyctaxidata@786.dfs.core.windows.net/raw/taxi_zone.csv

Let’s break it down and map it to Synapse objects.

4.1. Understanding the abfss URI
abfss://nyctaxidata@786.dfs.core.windows.net/raw/taxi_zone.csv

abfss://

Protocol for secure ADLS Gen2 access (Azure Blob File System Secure).

nyctaxidata

Container name.

786.dfs.core.windows.net

Storage account FQDN (e.g., 786 is the account name).

/raw/taxi_zone.csv

Path inside the container:

Folder: raw

File: taxi_zone.csv

So the structure is:

Account: 786

Container: nyctaxidata

Folder: raw

File: taxi_zone.csv

4.2. How Synapse maps this
In Synapse Serverless SQL, you split this URI into:

External data source → account + container root

LOCATION in external table → path inside container

Example external data source:

```sql
CREATE EXTERNAL DATA SOURCE nyc_taxi_src
WITH
(
    LOCATION = 'abfss://nyctaxidata@786.dfs.core.windows.net'
);
```
This points to the container root.

No /raw here—just the container.

Then, in the external table:

```sql
WITH
(
    LOCATION = 'raw/taxi_zone.csv',
    DATA_SOURCE = nyc_taxi_src,
    FILE_FORMAT = csv_file_format_pv1
);
LOCATION = 'raw/taxi_zone.csv':
```
Relative path inside the container.

Full resolved path:

abfss://nyctaxidata@786.dfs.core.windows.net/raw/taxi_zone.csv

4.3. Key mental model
DATA_SOURCE = “Which lake?”

LOCATION = “Which folder/file in that lake?”

FILE_FORMAT = “How do I read it?”

REJECT options = “What do I do when it’s dirty?”
