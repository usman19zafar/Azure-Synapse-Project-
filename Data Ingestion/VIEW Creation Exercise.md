Final Notes: Creating a Partition-Pruned View on Silver Layer

Objective
Expose partitioned Parquet data from the Silver zone as a SQL view that supports partition pruning by extracting year and month from the file path.

This enables:

Efficient querying

Performance optimization

Logical separation of storage and compute

Reusability across downstream layers (Gold, reporting, ML)

📁 Folder Structure
The Silver zone contains partitioned Parquet files:

```Code
silver/trip_data_green/
  └── year=YYYY/
        └── month=MM/
              └── *.parquet
```
Each folder contains 1–3 Parquet files depending on Synapse Serverless parallelism.

Why Use a View Instead of an External Table?
Feature	External Table	View with OPENROWSET
Partition Pruning	❌ Not supported	✅ Supported via filepath()
Schema Flexibility	Medium	High
Performance	Medium	High
Metadata Overhead	High	None
Reusability	Medium	High

SQL Script

```sql
USE nyc_taxi_ldw;
GO

-- Drop existing view if present
DROP VIEW IF EXISTS silver.vw_trip_data_green;
GO

-- Create partition-pruned view
CREATE VIEW silver.vw_trip_data_green
AS
SELECT
    result.filepath(1) AS year,
    result.filepath(2) AS month,
    result.*
FROM
    OPENROWSET(
        BULK 'silver/trip_data_green/year=*/month=*/*.parquet',
        DATA_SOURCE = 'nyc_taxi_src',
        FORMAT = 'PARQUET'
    )
    WITH (
        vendor_id INT,
        lpep_pickup_datetime DATETIME2(7),
        lpep_dropoff_datetime DATETIME2(7),
        store_and_fwd_flag CHAR(1),
        rate_code_id INT,
        pu_location_id INT,
        do_location_id INT,
        passenger_count INT,
        trip_distance FLOAT,
        fare_amount FLOAT,
        extra FLOAT,
        mta_tax FLOAT,
        tip_amount FLOAT,
        tolls_amount FLOAT,
        ehail_fee INT,
        improvement_surcharge FLOAT,
        total_amount FLOAT,
        payment_type INT,
        trip_type INT,
        congestion_surcharge FLOAT
    ) AS [result];
GO
```
-- Preview the view
```sql
SELECT TOP(100) *
  FROM silver.vw_trip_data_green;
GO
```
Partition Pruning in Action
To query only January 2020 data:

```sql
SELECT *
FROM silver.vw_trip_data_green
WHERE year = '2020' AND month = '01';
```
This will only scan files in:

```Code
silver/trip_data_green/year=2020/month=01/
```
No other folders will be touched — this is true partition pruning.

Code Health Check
+------------------------+---------+--------------------------------------------------------------+
|       Checkpoint       | Status  | Notes                                                        |
+------------------------+---------+--------------------------------------------------------------+
| Database context       |   ✔     | USE nyc_taxi_ldw is correctly set                            |
+------------------------+---------+--------------------------------------------------------------+
| View drop safety       |   ✔     | DROP VIEW IF EXISTS ensures idempotency                      |
+------------------------+---------+--------------------------------------------------------------+
| File path wildcards    |   ✔     | year=*/month=*/*.parquet pattern is correct                  |
+------------------------+---------+--------------------------------------------------------------+
| Partition extraction   |   ✔     | filepath(1) and filepath(2) used properly                    |
+------------------------+---------+--------------------------------------------------------------+
| Column mapping         |   ✔     | Explicit schema defined in WITH clause                       |
+------------------------+---------+--------------------------------------------------------------+
| Data types             |   ✔     | All data types match expected schema                         |
+------------------------+---------+--------------------------------------------------------------+
| View logic             |   ✔     | No joins, no transformations — clean passthrough             |
+------------------------+---------+--------------------------------------------------------------+
| Query preview          |   ✔     | SELECT TOP(100) confirms view integrity                      |
+------------------------+---------+--------------------------------------------------------------+

Next Steps
Use this view as the source for Gold layer transformations

Integrate into reporting pipelines (Power BI, Spark, ML)

Apply filters on year and month to optimize performance

Optionally create additional views for other Silver datasets

Closing Insight
This view design reflects the lakehouse principle:

“Storage is cheap, compute is smart, and metadata should never get in the way of performance.”

By exposing partition columns via filepath(), you’ve unlocked true pruning and built a scalable, query-efficient interface to your Silver zone.
