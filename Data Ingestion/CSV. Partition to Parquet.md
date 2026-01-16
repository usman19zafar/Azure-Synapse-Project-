A9 — PARTITIONED PARQUET (WORKAROUND USING SERVERLESS SQL)
One‑word anchor: Partitioning  
Two‑word logic: Force → Folders

1. Purpose (Absolute Statement)
CTAS cannot write partitioned Parquet folders.
It always writes one output folder per CTAS statement.

To preserve partitioning (e.g., year=2020/month=01), we must:

Run one CTAS per partition

Write each partition to its own Silver folder

Use a stored procedure to automate the pattern

This is the only way to maintain partitioned Parquet using Serverless SQL.

2. Why CTAS Breaks Partitioning (Mechanical Truth)
CTAS has three hard limitations:

Writes to one folder only

Cannot create subfolders dynamically

Cannot partition output based on column values

So if your raw data is partitioned like:

Code
raw/trip_data_green_csv/year=2020/month=01/*.csv
raw/trip_data_green_csv/year=2020/month=02/*.csv
...
CTAS will flatten everything into:

Code
silver/trip_data_green/*.parquet
This destroys partition pruning and slows down queries.

3. The Workaround (Canonical Pattern)
To preserve partitions, you must:

Run CTAS once per partition
Each CTAS writes to:

Code
silver/trip_data_green/year=<YYYY>/month=<MM>/
Use a stored procedure
usp_silver_trip_data_green accepts:

@year

@month

and writes only that partition.

Execute the procedure for every partition
This is what your script is doing:

Code
EXEC silver.usp_silver_trip_data_green '2020', '01'
EXEC silver.usp_silver_trip_data_green '2020', '02'
...
EXEC silver.usp_silver_trip_data_green '2021', '06'
Each execution produces one Parquet folder.

4. Partitioned Parquet Folder Structure
Code
silver/
   trip_data_green/
      year=2020/
         month=01/
            part-0000.snappy.parquet
         month=02/
         month=03/
         ...
      year=2021/
         month=01/
         month=02/
         ...
This restores:

Partition pruning

Fast queries

Big‑data scalability

5. Stored Procedure Logic (Micro‑SOP)
Inside usp_silver_trip_data_green, the logic is:

Step 1 — Drop existing partition table
Code
DROP EXTERNAL TABLE IF EXISTS silver.trip_data_green_<YYYY>_<MM>
Step 2 — Delete Silver folder for that partition
Code
silver/trip_data_green/year=<YYYY>/month=<MM>/
Step 3 — CTAS for that partition
Code
CREATE EXTERNAL TABLE silver.trip_data_green_<YYYY>_<MM>
WITH
(
    LOCATION = 'silver/trip_data_green/year=<YYYY>/month=<MM>',
    FILE_FORMAT = parquet_file_format,
    DATA_SOURCE = nyc_taxi_src
)
AS
SELECT *
FROM bronze.trip_data_green_csv
WHERE year = <YYYY>
  AND month = <MM>;
Step 4 — Validate
Code
SELECT TOP 10 * FROM silver.trip_data_green_<YYYY>_<MM>;
6. Result Achievements (How Success Was Verified)
Code
+--------------------------------------+-----------------------------------------------------------+
| Result                               | How It Was Verified                                       |
+--------------------------------------+-----------------------------------------------------------+
| Partition-level Parquet created      | Folder year=YYYY/month=MM contains .parquet files         |
| CTAS executed per partition          | Each EXEC call produced one folder                        |
| Data preserved by year/month         | SELECT COUNT(*) matches raw partition counts              |
| Query performance improved           | Serverless prunes partitions automatically                |
+--------------------------------------+-----------------------------------------------------------+
7. RCA Notes (Why Partitioning Fails)
Code
+--------------------------------------+-----------------------------------------+---------------------------+
| Issue                                | Root Cause                              | Fix                       |
+--------------------------------------+-----------------------------------------+---------------------------+
| All data in one folder               | CTAS writes to one LOCATION only         | Use one CTAS per partition|
| No subfolders created                | CTAS cannot create dynamic partitions    | Stored procedure required |
| Slow queries                         | No partition pruning                     | Partitioned Parquet       |
| Wrong partition output               | Incorrect WHERE year/month filter        | Validate parameters       |
| Folder exists error                  | Partition folder not deleted             | Delete folder before CTAS |
+--------------------------------------+-----------------------------------------+---------------------------+
8. Absolute Notes (Canonical Truths)
These rules never change:

CTAS cannot write partitioned Parquet

CTAS writes to one folder only

Partitioning requires one CTAS per partition

Stored procedures automate the pattern

Partition pruning dramatically improves performance

Spark is the ideal tool for large‑scale partitioned writes

Serverless SQL partitioning is a workaround, not a native feature
