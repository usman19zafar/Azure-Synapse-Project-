```code

Partition pruning delivers a very real business utility: it prevents analytics systems from wasting time and money scanning data that has nothing to do with the question being asked. In a modern data lake, where datasets are often organized by folders such as year and month, pruning allows the query engine to jump directly to the relevant partitions instead of reading every file in the entire hierarchy. This serves the specific business need of cost‑efficient, high‑performance analytics at scale, ensuring that dashboards refresh quickly, data scientists iterate faster, and operational workloads remain predictable. Without partition pruning, every query becomes a full‑dataset scan—leading to dramatically higher compute costs, slower insights, overloaded systems, and unacceptable latency for any organization working with terabytes or petabytes of data. In short, pruning is the difference between a system that scales gracefully and one that collapses under its own weight.

```

Partition Pruning in Synapse Serverless — Final Notes (With Query Embedded)
1. Why Partition Pruning Matters
Big‑data systems must avoid scanning entire datasets. Partition pruning allows the engine to read only the folders that match the filter, dramatically reducing scanned data and improving performance.

__________________________________________________________________________________________________________________________________________________________________________
2. The Limitation: External Tables Cannot Prune Partitions
Synapse Serverless external tables do not expose partition keys (like year and month).
Because of this:

They cannot target specific folders

They always scan all files in the dataset

Even a WHERE clause on pickup time does not prune partitions

This applies to CSV, Parquet, and Delta external tables.

__________________________________________________________________________________________________________________________________________________________________________
3. The Discovery Lesson Solution: filepath()
Using filepath(1) and filepath(2) inside an OPENROWSET wildcard path exposes:
```code
year → from the first wildcard

month → from the second wildcard
```
This allows the WHERE clause to prune partitions.

__________________________________________________________________________________________________________________________________________________________________________
4. The Recommended Microsoft Solution: View + OPENROWSET
To achieve partition pruning in Synapse Serverless, Microsoft recommends:

OPENROWSET + filepath() + VIEW
A view:

Wraps the SELECT logic

Exposes year and month as columns

Allows users to filter partitions directly

Enables Synapse to prune folders efficiently

__________________________________________________________________________________________________________________________________________________________________________
5. The Partition‑Aware View (Final Query to Include in Notes)
This is the canonical Bronze‑layer view that enables partition pruning:

```sql
DROP VIEW IF EXISTS bronze.vw_trip_data_green_csv
GO

CREATE VIEW bronze.vw_trip_data_green_csv
AS
SELECT
    result.filepath(1) AS year,
    result.filepath(2) AS month,
    result.*
FROM
    OPENROWSET(
        BULK 'raw/trip_data_green_csv/year=*/month=*/*.csv',
        DATA_SOURCE = 'nyc_taxi_src',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE
    )
    WITH (
        VendorID INT,
        lpep_pickup_datetime datetime2(7),
        lpep_dropoff_datetime datetime2(7),
        store_and_fwd_flag CHAR(1),
        RatecodeID INT,
        PULocationID INT,
        DOLocationID INT,
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
    ) AS [result]
GO

SELECT TOP(100) *
FROM bronze.vw_trip_data_green_csv
GO
```
__________________________________________________________________________________________________________________________________________________________________________
6. Testing Partition Pruning
Without WHERE clause
~2.3M rows

~209 MB scanned

With WHERE clause
```sql
WHERE year = 2020 AND month = 01
```
~447k rows

~41 MB scanned

Only ~1/7 of the data scanned

Much faster response

This proves that the view successfully prunes partitions.

__________________________________________________________________________________________________________________________________________________________________________
7. Final Recommendation
Until Microsoft adds native partition support to external tables:

Always use:
Views + OPENROWSET + filepath()  
for partitioned datasets in Synapse Serverless.

This is the most performant, most flexible, and Microsoft‑endorsed method today.
