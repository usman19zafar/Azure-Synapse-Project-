
```code

Identify the percentage of cash and credit card trips by borough
Example Data As below
----------------------------------------------------------------------------------------------
borough	    total_trips	cash_trips	card_trips	cash_trips_percentage	card_trips_percentage
----------------------------------------------------------------------------------------------
Bronx	    2019	    751	        1268	    37.20	                62.80
Brooklyn	6435	    2192	      4243	    34.06	                65.94
----------------------------------------------------------------------------------------------
```

Option 1: GO COde

```sql

USE nyc_taxi_discovery;

WITH v_payment_type AS
(
    SELECT 
        CAST(JSON_VALUE(jsonDoc, '$.payment_type') AS SMALLINT) AS payment_type,
        CAST(JSON_VALUE(jsonDoc, '$.payment_type_desc') AS VARCHAR(20)) AS payment_type_desc
    FROM OPENROWSET(
            BULK 'payment_type.json',
            DATA_SOURCE = 'nyc_taxi_data_raw',
            FORMAT = 'CSV',
            PARSER_VERSION = '1.0',
            FIELDTERMINATOR = '0x0b',
            FIELDQUOTE = '0x0b',
            ROWTERMINATOR = '0x0a'
        )
        WITH (jsonDoc NVARCHAR(MAX)) AS src
),

v_taxi_zone AS
(
    SELECT 
        location_id,
        borough,
        zone,
        service_zone
    FROM OPENROWSET(
            BULK 'taxi_zone.csv',
            DATA_SOURCE = 'nyc_taxi_data_raw',
            FORMAT = 'CSV',
            PARSER_VERSION = '2.0',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n'
        )
        WITH (
            location_id SMALLINT 1,
            borough VARCHAR(50) 2,
            zone VARCHAR(100) 3,
            service_zone VARCHAR(50) 4
        ) AS src
),

v_trip_data AS
(
    SELECT *
    FROM OPENROWSET(
            BULK 'trip_data_green_parquet/**',
            FORMAT = 'PARQUET',
            DATA_SOURCE = 'nyc_taxi_data_raw'
        ) AS src
    WHERE lpep_dropoff_datetime > lpep_pickup_datetime
)

SELECT 
    tz.borough,
    COUNT(*) AS total_trips,

    SUM(CASE WHEN pt.payment_type_desc = 'Cash' THEN 1 ELSE 0 END) AS cash_trips,
    SUM(CASE WHEN pt.payment_type_desc = 'Credit card' THEN 1 ELSE 0 END) AS card_trips,

    ROUND(
        100.0 * SUM(CASE WHEN pt.payment_type_desc = 'Cash' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS cash_percentage,

    ROUND(
        100.0 * SUM(CASE WHEN pt.payment_type_desc = 'Credit card' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS card_percentage

FROM v_trip_data td
LEFT JOIN v_payment_type pt
    ON td.payment_type = pt.payment_type
LEFT JOIN v_taxi_zone tz
    ON td.PULocationID = tz.location_id

WHERE pt.payment_type_desc IN ('Cash', 'Credit card')

GROUP BY tz.borough
ORDER BY total_trips DESC;
```

Option 2:

go2

```sql
WITH v_payment_type AS
(
    SELECT CAST(JSON_VALUE(jsonDoc, '$.payment_type') AS SMALLINT) payment_type,
            CAST(JSON_VALUE(jsonDoc, '$.payment_type_desc') AS VARCHAR(15)) payment_type_desc
    FROM OPENROWSET(
        BULK 'payment_type.json',
        DATA_SOURCE = 'nyc_taxi_data_raw',
        FORMAT = 'CSV',
        PARSER_VERSION = '1.0', 
        FIELDTERMINATOR = '0x0b',
        FIELDQUOTE = '0x0b',
        ROWTERMINATOR = '0x0a'
    )
    WITH
    (
        jsonDoc NVARCHAR(MAX)
    ) AS payment_type
),
v_taxi_zone AS
(
    SELECT
        *
    FROM
        OPENROWSET(
            BULK 'taxi_zone.csv',
            DATA_SOURCE = 'nyc_taxi_data_raw',
            FORMAT = 'CSV',
            PARSER_VERSION = '2.0',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n'
        ) 
        WITH (
            location_id SMALLINT 1,
            borough VARCHAR(15) 2,
            zone VARCHAR(50) 3,
            service_zone VARCHAR(15) 4
        )AS [result]
),
v_trip_data AS
(
    SELECT
        *
    FROM
        OPENROWSET(
            BULK 'trip_data_green_parquet/year=2021/month=01/**',
            FORMAT = 'PARQUET',
            DATA_SOURCE = 'nyc_taxi_data_raw'
        ) AS [result]
)
SELECT 
       v_taxi_zone.borough, 
       COUNT(1) AS total_trips,
       SUM(CASE WHEN v_payment_type.payment_type_desc = 'Cash' THEN 1 ELSE 0 END) AS cash_trips,
       SUM(CASE WHEN v_payment_type.payment_type_desc = 'Credit card' THEN 1 ELSE 0 END) AS card_trips,
       CAST((SUM(CASE WHEN v_payment_type.payment_type_desc = 'Cash' THEN 1 ELSE 0 END)/ CAST(COUNT(1) AS DECIMAL)) * 100 AS DECIMAL(5, 2)) AS cash_trips_percentage,
       CAST((SUM(CASE WHEN v_payment_type.payment_type_desc = 'Credit card' THEN 1 ELSE 0 END)/ CAST(COUNT(1) AS DECIMAL)) * 100 AS DECIMAL(5, 2)) AS card_trips_percentage
  FROM v_trip_data 
  LEFT JOIN v_payment_type ON (v_trip_data.payment_type = v_payment_type.payment_type)
  LEFT JOIN v_taxi_zone    ON (v_trip_data.PULocationId = v_taxi_zone.location_id)
WHERE v_payment_type.payment_type_desc IN ('Cash', 'Credit card')
GROUP BY v_taxi_zone.borough
ORDER BY v_taxi_zone.borough;



```sql

GO

USE nyc_taxi_discovery;

WITH v_payment_type AS
(
    SELECT 
        CAST(JSON_VALUE(jsonDoc, '$.payment_type') AS SMALLINT) AS payment_type,
        CAST(JSON_VALUE(jsonDoc, '$.payment_type_desc') AS VARCHAR(20)) AS payment_type_desc
    FROM OPENROWSET(
            BULK 'payment_type.json',
            DATA_SOURCE = 'nyc_taxi_data_raw',
            FORMAT = 'CSV',
            PARSER_VERSION = '1.0',
            FIELDTERMINATOR = '0x0b',
            FIELDQUOTE = '0x0b',
            ROWTERMINATOR = '0x0a'
        )
        WITH (jsonDoc NVARCHAR(MAX)) AS src
),

v_taxi_zone AS
(
    SELECT 
        location_id,
        borough,
        zone,
        service_zone
    FROM OPENROWSET(
            BULK 'taxi_zone.csv',
            DATA_SOURCE = 'nyc_taxi_data_raw',
            FORMAT = 'CSV',
            PARSER_VERSION = '2.0',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n'
        )
        WITH (
            location_id SMALLINT 1,
            borough VARCHAR(50) 2,
            zone VARCHAR(100) 3,
            service_zone VARCHAR(50) 4
        ) AS src
),

v_trip_data AS
(
    SELECT *
    FROM OPENROWSET(
            BULK 'trip_data_green_parquet/**',
            FORMAT = 'PARQUET',
            DATA_SOURCE = 'nyc_taxi_data_raw'
        ) AS src
    WHERE lpep_dropoff_datetime > lpep_pickup_datetime
)

SELECT 
    tz.borough,
    COUNT(*) AS total_trips,

    SUM(CASE WHEN pt.payment_type_desc = 'Cash' THEN 1 ELSE 0 END) AS cash_trips,
    SUM(CASE WHEN pt.payment_type_desc = 'Credit card' THEN 1 ELSE 0 END) AS card_trips,

    ROUND(
        100.0 * SUM(CASE WHEN pt.payment_type_desc = 'Cash' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS cash_percentage,

    ROUND(
        100.0 * SUM(CASE WHEN pt.payment_type_desc = 'Credit card' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS card_percentage

FROM v_trip_data td
LEFT JOIN v_payment_type pt
    ON td.payment_type = pt.payment_type
LEFT JOIN v_taxi_zone tz
    ON td.PULocationID = tz.location_id

WHERE pt.payment_type_desc IN ('Cash', 'Credit card')

GROUP BY tz.borough
ORDER BY total_trips DESC;

go2


WITH v_payment_type AS
(
    SELECT CAST(JSON_VALUE(jsonDoc, '$.payment_type') AS SMALLINT) payment_type,
            CAST(JSON_VALUE(jsonDoc, '$.payment_type_desc') AS VARCHAR(15)) payment_type_desc
    FROM OPENROWSET(
        BULK 'payment_type.json',
        DATA_SOURCE = 'nyc_taxi_data_raw',
        FORMAT = 'CSV',
        PARSER_VERSION = '1.0', 
        FIELDTERMINATOR = '0x0b',
        FIELDQUOTE = '0x0b',
        ROWTERMINATOR = '0x0a'
    )
    WITH
    (
        jsonDoc NVARCHAR(MAX)
    ) AS payment_type
),
v_taxi_zone AS
(
    SELECT
        *
    FROM
        OPENROWSET(
            BULK 'taxi_zone.csv',
            DATA_SOURCE = 'nyc_taxi_data_raw',
            FORMAT = 'CSV',
            PARSER_VERSION = '2.0',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n'
        ) 
        WITH (
            location_id SMALLINT 1,
            borough VARCHAR(15) 2,
            zone VARCHAR(50) 3,
            service_zone VARCHAR(15) 4
        )AS [result]
),
v_trip_data AS
(
    SELECT
        *
    FROM
        OPENROWSET(
            BULK 'trip_data_green_parquet/year=2021/month=01/**',
            FORMAT = 'PARQUET',
            DATA_SOURCE = 'nyc_taxi_data_raw'
        ) AS [result]
)
SELECT 
       v_taxi_zone.borough, 
       COUNT(1) AS total_trips,
       SUM(CASE WHEN v_payment_type.payment_type_desc = 'Cash' THEN 1 ELSE 0 END) AS cash_trips,
       SUM(CASE WHEN v_payment_type.payment_type_desc = 'Credit card' THEN 1 ELSE 0 END) AS card_trips,
       CAST((SUM(CASE WHEN v_payment_type.payment_type_desc = 'Cash' THEN 1 ELSE 0 END)/ CAST(COUNT(1) AS DECIMAL)) * 100 AS DECIMAL(5, 2)) AS cash_trips_percentage,
       CAST((SUM(CASE WHEN v_payment_type.payment_type_desc = 'Credit card' THEN 1 ELSE 0 END)/ CAST(COUNT(1) AS DECIMAL)) * 100 AS DECIMAL(5, 2)) AS card_trips_percentage
  FROM v_trip_data 
  LEFT JOIN v_payment_type ON (v_trip_data.payment_type = v_payment_type.payment_type)
  LEFT JOIN v_taxi_zone    ON (v_trip_data.PULocationId = v_taxi_zone.location_id)
WHERE v_payment_type.payment_type_desc IN ('Cash', 'Credit card')
GROUP BY v_taxi_zone.borough
ORDER BY v_taxi_zone.borough;
```

HIGH‑LEVEL DIFFERENCE
The only real structural difference between the two queries is:

Query 1 (GO)
Uses wildcard ingestion for trip data:

Code
trip_data_green_parquet/**
Query 2 (GO2)
Uses hard‑coded partition:

Code
trip_data_green_parquet/year=2021/month=01/**
Everything else is nearly identical except for:

minor VARCHAR length differences

SELECT * vs explicit column list

ordering by total_trips vs borough

CAST vs ROUND differences

But the core efficiency difference comes from the trip data ingestion strategy.

🟩 ASCII COMPARISON TABLE
Code
+------------------------------+------------------------------+------------------------------+-------------------------------+
| Feature                      | Query 1 (GO)                 | Query 2 (GO2)                | Which Is Better?              |
+------------------------------+------------------------------+------------------------------+-------------------------------+
| Trip data ingestion          | Wildcard: /**                | Hard-coded: year=2021/month=01 | Query 1                       |
|                              | Reads ALL partitions         | Reads ONE month only         | More scalable & future-proof  |
+------------------------------+------------------------------+------------------------------+-------------------------------+
| Performance                  | Reads more files             | Reads fewer files            | Query 2 (faster for 1 month)  |
|                              | Slightly slower              | Very fast                    | But not scalable              |
+------------------------------+------------------------------+------------------------------+-------------------------------+
| Scalability                  | High                         | Low                          | Query 1                       |
|                              | Auto-detects new data        | Must manually update path    |                               |
+------------------------------+------------------------------+------------------------------+-------------------------------+
| Maintenance                  | Zero maintenance             | High maintenance             | Query 1                       |
|                              | No path changes needed       | Must change year/month       |                               |
+------------------------------+------------------------------+------------------------------+-------------------------------+
| Data completeness            | Full dataset                 | Only Jan 2021                | Query 1                       |
|                              | Better for analytics         | Limited scope                |                               |
+------------------------------+------------------------------+------------------------------+-------------------------------+
| Percentage calculation       | ROUND + NULLIF               | CAST inside CAST             | Query 1                       |
|                              | Cleaner & safer              | More verbose                 |                               |
+------------------------------+------------------------------+------------------------------+-------------------------------+
| Ordering                     | ORDER BY total_trips DESC    | ORDER BY borough             | Depends on business need      |
+------------------------------+------------------------------+------------------------------+-------------------------------+
| Taxi zone schema             | Explicit columns             | SELECT *                     | Query 1                       |
|                              | Cleaner, safer               | Less controlled              |                               |
+------------------------------+------------------------------+------------------------------+-------------------------------+
| Payment type VARCHAR length  | VARCHAR(20)                  | VARCHAR(15)                  | Query 1                       |
|                              | More flexible                | Slightly restrictive         |                               |
+------------------------------+------------------------------+------------------------------+-------------------------------+
| Overall robustness           | Higher                       | Medium                       | Query 1                       |
+------------------------------+------------------------------+------------------------------+-------------------------------+
| Overall efficiency           | Slightly slower (more data)  | Faster (less data)           | Query 2 (but only for 1 month)|
+------------------------------+------------------------------+------------------------------+-------------------------------+
```
FINAL VERDICT (Architect‑Level)

Query 1 (GO) is the better query overall.

Why?

It is scalable

It is future‑proof

It automatically reads all years, all months

It requires zero maintenance

It uses cleaner percentage logic

It uses explicit schema

It is production‑ready

Query 2 (GO2) is faster ONLY because it reads less data.
But:

It is not scalable

It is not future‑proof

It requires manual updates

It only analyzes one month

It is not suitable for real analytics

In real data engineering:
Scalability > short‑term speed  
Maintainability > hard‑coded paths  
Wildcard ingestion > fixed partitions

```code
So Query 1 wins.
```

BUSINESS REQUIREMENT → TECHNICAL TRANSLATION
The business wants:

For each borough

Count total trips

Count cash trips

Count credit card trips

Compute percentage of each payment type

Using three datasets:

trip data

taxi zone lookup

payment type lookup

This query satisfies that requirement exactly.

CTE‑BY‑CTE EXPLANATION
trip_data CTE

```sql

WITH trip_data AS (
    SELECT *
    FROM OPENROWSET(
            BULK 'trip_data_green_parquet/**',
            FORMAT = 'PARQUET',
            DATA_SOURCE = 'nyc_taxi_data_raw'
        ) AS t
    WHERE lpep_dropoff_datetime > lpep_pickup_datetime
),
```
What this does:
Reads all green taxi Parquet files using /** wildcard

Uses your DATA_SOURCE root

Loads the entire dataset into a logical table called trip_data

Applies a data quality filter:

dropoff must be after pickup

removes corrupted or impossible trips

Why this matters:
You cannot compute payment percentages on dirty data.
This ensures only valid trips enter the business calculation.

taxi_zone CTE

```sql
taxi_zone AS (
    SELECT *
    FROM OPENROWSET(
            BULK 'taxi_zone.csv',
            FORMAT = 'CSV',
            PARSER_VERSION = '2.0',
            FIRSTROW = 2,
            DATA_SOURCE = 'nyc_taxi_data_raw'
        )
        WITH (
            location_id SMALLINT 1,
            borough VARCHAR(50) 2,
            zone VARCHAR(100) 3,
            service_zone VARCHAR(50) 4
        ) AS tz
),
```
What this does:
Reads the taxi zone lookup

Maps:

location_id → numeric ID

borough → Manhattan, Brooklyn, etc.

zone → neighborhood

service_zone → dispatch zone

Why this matters:
Trip data only contains numeric IDs.
The business requirement needs borough names, not numbers.

This CTE converts IDs → boroughs.

payment_type CTE

```sql
payment_type AS (
    SELECT *
    FROM OPENROWSET(
            BULK 'payment_type.csv',
            FORMAT = 'CSV',
            PARSER_VERSION = '2.0',
            FIRSTROW = 2,
            DATA_SOURCE = 'nyc_taxi_data_raw'
        )
        WITH (
            payment_type SMALLINT 1,
            payment_desc VARCHAR(50) 2
        ) AS pt
)
```

What this does:
Reads the payment type lookup

Converts:

1 → “Credit card”

2 → “Cash”

etc.

Why this matters:
The business requirement explicitly says:

“Use the description, not the numeric codes.”

This CTE satisfies that.

JOIN LOGIC EXPLANATION
```sql
FROM trip_data td
JOIN taxi_zone tz
    ON td.PULocationID = tz.location_id
JOIN payment_type pt
    ON td.payment_type = pt.payment_type
What this does:
First join:
trip_data → taxi_zone
```
Converts pickup location ID → borough name

Second join:
trip_data → payment_type

Converts payment code → payment description

Why this matters:
This is where the three datasets merge into one enriched dataset.

After these joins, each row now has:

borough

payment description

trip facts

This is the foundation for the business metric.

AGGREGATION + PERCENTAGE LOGIC
```sql
SELECT 
    tz.borough,
    COUNT(*) AS total_trips,
Counts all trips per borough.
```
```sql
    SUM(CASE WHEN pt.payment_desc = 'Cash' THEN 1 ELSE 0 END) AS cash_trips,
Counts only cash trips.
```
```sql
    SUM(CASE WHEN pt.payment_desc = 'Credit card' THEN 1 ELSE 0 END) AS card_trips,
Counts only credit card trips.
```
Percentages
```sql
ROUND(
    100.0 * SUM(CASE WHEN pt.payment_desc = 'Cash' THEN 1 ELSE 0 END) 
    / COUNT(*), 
    2
) AS cash_percentage,
100.0 ensures floating‑point math
```
Divides cash trips by total trips

Rounds to 2 decimals

Same logic for credit card percentage.

FINAL OUTPUT MEANING
sql
GROUP BY tz.borough
ORDER BY total_trips DESC;
What this does:
Groups results by borough

Sorts boroughs by total trip volume

Why this matters:
This produces a business‑ready report:

Borough	Total Trips	Cash Trips	Card Trips	Cash %	Card %
Exactly what the requirement asked for.

SUMMARY OF THE ENTIRE QUERY
This query:

Cleans the data

Enriches it with borough names

Enriches it with payment descriptions

Computes total trips

Computes cash vs card trips

Computes percentages

Produces a clean borough‑level financial breakdown

This is a complete business solution, not just SQL.
