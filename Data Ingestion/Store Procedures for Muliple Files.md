Partitioned Silver Transformation — Master Notes

1. Problem Definition
CTAS (CREATE EXTERNAL TABLE AS SELECT):

Reads all CSV partitions from Bronze

Converts them to Parquet

BUT writes all Parquet files into one folder

AND creates one external table pointing to that single folder

This destroys:

Partition structure

Partition pruning

Query performance

CTAS has no native support for writing partitioned Parquet folders.
__________________________________________________________________________________________________________________________________________________________
2. What We Actually Need
A solution that:

Reads each raw partition (year/month)

Writes each partition to its own Parquet folder

Drops the temporary external table created by CTAS

Creates one unified view over the entire Silver folder

Allows partition pruning using WHERE year = … AND month = …

This gives us:

Partitioned Parquet

Efficient reads

A single logical object to query

__________________________________________________________________________________________________________________________________________________________
3. Why CTAS Alone Cannot Do This
CTAS limitations:

Writes to one folder only

Cannot create subfolders dynamically

Cannot partition output based on column values

Always creates an external table (metadata)

Therefore:

One CTAS = One folder = One external table

To preserve partitioning, we need multiple CTAS executions, one per partition.

__________________________________________________________________________________________________________________________________________________________
4. The Workaround (Serverless SQL Pattern)
4.1 Use one CTAS per partition
Example:

Code
CTAS for 2020/01 → silver/trip_data_green/year=2020/month=01/
CTAS for 2020/02 → silver/trip_data_green/year=2020/month=02/
...
4.2 Automate using a stored procedure
Stored procedure accepts:

@year

@month

It performs:

CTAS for that partition

Drops the external table created by CTAS

Leaves the Parquet files intact

4.3 Execute the stored procedure in a loop
In the course, you hardcode:

```Code
EXEC silver.usp_silver_trip_data_green '2020', '01'
EXEC silver.usp_silver_trip_data_green '2020', '02'
```
In production, Synapse Pipelines will loop dynamically.

4.4 Create a unified view
The view:

Points to the root Silver folder

Includes year and month as columns

Enables partition pruning

__________________________________________________________________________________________________________________________________________________________
5. End‑State Architecture
```Code
silver/
   trip_data_green/
      year=2020/
         month=01/
         month=02/
         ...
      year=2021/
         month=01/
         ...
```
And one view:

```Code
silver.vw_trip_data_green
```
This view reads all partitions and allows:

```Code
SELECT *
FROM silver.vw_trip_data_green
WHERE year = 2020 AND month = 05;
```
Serverless SQL prunes all other folders.

__________________________________________________________________________________________________________________________________________________________
6. Steps Required (SOP)
Step 1 — Create the stored procedure
Accepts @year, @month

Builds dynamic CTAS

Writes to partition folder

Drops the temporary external table

Step 2 — Execute the stored procedure for each partition
Hardcoded in the course

Dynamic in production (via Pipelines)

Step 3 — Create a unified view
Points to the entire Silver folder

Includes partition columns

Enables pruning

__________________________________________________________________________________________________________________________________________________________
7. Why This Works
Because:

CTAS writes Parquet files correctly

Stored procedure isolates each partition

Dropping the external table removes metadata clutter

View provides a single logical access point

Folder structure enables pruning

Serverless SQL automatically skips irrelevant folders

This is the only viable Serverless SQL solution without Spark.

__________________________________________________________________________________________________________________________________________________________
8. When to Prefer Spark
Spark is the ideal tool when:

You want native partitioned writes

You want Delta Lake

You want schema evolution

You want automatic folder creation

You want large‑scale transformations

Serverless SQL partitioning is a workaround, not a native feature.

__________________________________________________________________________________________________________________________________________________________
9. Summary (Workbook‑Ready)
```Code
+------------------------------+----------------------------------------------+
| Problem                      | CTAS collapses all partitions into one folder|
+------------------------------+----------------------------------------------+
| Requirement                  | Partitioned Parquet + partition pruning      |
+------------------------------+----------------------------------------------+
| Solution                     | One CTAS per partition via stored procedure  |
+------------------------------+----------------------------------------------+
| Extra step                   | Drop temp external tables                    |
+------------------------------+----------------------------------------------+
| Final object                 | One unified view over all partitions         |
+------------------------------+----------------------------------------------+
| Ideal tool                   | Spark (native partitioning)                  |
+------------------------------+----------------------------------------------+
```
