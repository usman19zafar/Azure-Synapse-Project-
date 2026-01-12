Detailed Notes: Reading Partitioned CSV Data Using OPENROWSET (Folders, Subfolders & Wildcards)

Modern big‑data systems rarely store all records in a single file.

Instead, data is partitioned—often by year, month, day, or even hour—to improve scalability, performance, and parallelism.

The NYC Taxi dataset follows this pattern:

```Code
trip_data_green_csv/
    year=2020/
        month=01/
            green_tripdata_2020-01.csv
        month=02/
            green_tripdata_2020-02.csv
        ...
    year=2021/
        month=01/
            green_tripdata_2021-01.csv
```

Your storage location:

```Code
abfss://nyctaxidata@786.dfs.core.windows.net/raw/trip_data_green_csv/
```

This lesson explains how to query:

A single file

All files in a folder

All files in subfolders

A list of specific files

Files using multiple wildcard patterns

1, Selecting Data from a Single CSV File

```sql

SELECT TOP 100 *
FROM OPENROWSET(
        BULK 'trip_data_green_csv/year=2020/month=01/green_tripdata_2020-01.csv',
        DATA_SOURCE = 'nyctaxidata',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE
     ) AS result;
```

What this does

Reads exactly one file

Applies CSV parsing

Uses the header row to name columns

2, Selecting Data from All Files in a Folder

```sql
SELECT TOP 100 *
FROM OPENROWSET(
        BULK 'trip_data_green_csv/year=2020/month=01/*.csv',
        DATA_SOURCE = 'nyctaxidata',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE
     ) AS result;
```
Use case

Folder contains multiple files for the same month

You want to read all of them

3, Selecting Data from Subfolders (Recursive Search)
This is where most people get stuck.

❌ Wrong
Using a single *:

```Code
trip_data_green_csv/year=2020/*
```

This only looks for files directly under the folder, not inside subfolders.

✅ Correct

Use double wildcard ** to recurse into subfolders:

```sql
SELECT TOP 100 *
FROM OPENROWSET(
        BULK 'trip_data_green_csv/year=2020/**',
        DATA_SOURCE = 'nyctaxidata',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE
     ) AS result;
```

What this does

Searches all subfolders under year=2020/

Reads all CSV files found anywhere inside

4, Selecting Data from More Than One File (Explicit List)

```sql
SELECT TOP 100 *
FROM OPENROWSET(
        BULK (
            'trip_data_green_csv/year=2020/month=01/*.csv',
            'trip_data_green_csv/year=2020/month=03/*.csv'
        ),
        DATA_SOURCE = 'nyctaxidata',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE
     ) AS result;
```

Use case
You want January + March only

You can list as many file paths as needed

5, Using Multiple Wildcards (Years + Months)

```sql
SELECT TOP 100 *
FROM OPENROWSET(
        BULK 'trip_data_green_csv/year=*/month=*/*.csv',
        DATA_SOURCE = 'nyctaxidata',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE
     ) AS result;
```

What this does
Reads all years

Reads all months

Reads all CSV files

Perfect for full‑dataset ingestion

6, Why Double Wildcards Matter
Pattern	Meaning	Searches Subfolders?
*	Match files in the current folder	❌ No
**	Match files in all nested folders	✅ Yes
Example:

```Code
year=2020/**
```
→ Reads all files in:

year=2020/month=01

year=2020/month=02

…

year=2020/month=12

7, Important Observation: No File Metadata Returned by Default
When you read from folders:

```sql
trip_data_green_csv/year=*/month=*/*.csv
```

You get the data, but not the file name.

Synapse can return metadata using:

filepath()

filename()

You’ll explore these in the next lesson.

Final Summary (No Information Skipped)

Big‑data systems store data in partitioned folders (year, month, day).

OPENROWSET can read:-

A single file

All files in a folder

All files in subfolders (using **)

A list of specific files

Files matching wildcard patterns

* matches files only

** matches files recursively

HEADER_ROW = TRUE ensures proper column names

PARSER_VERSION = '2.0' improves CSV parsing accuracy

This is the foundation for querying large partitioned datasets efficiently.
