JOINING MULTIPLE FILES USING OPENROWSET

One word: Integration

Two words: File joining

Business analogy:  

Imagine two departments in a company. One department tracks transactions (trip data). Another maintains a lookup directory (taxi zones). Each department has its own spreadsheet. To answer a company‑wide question — “How many trips originated from each borough?” — you merge the spreadsheets using a shared key: LocationID.
______________________________________________________________________________________________________________________________________________________________________________________
1. Problem Statement

You want to calculate number of trips made from each borough for January 2020 (Green Taxi).

Trip data contains:

PULocationID (pickup)

DOLocationID (dropoff)

Taxi zone lookup contains:

location_id

borough

zone

service_zone

To get borough‑level trip counts, you must join the two datasets on LocationID.

______________________________________________________________________________________________________________________________________________________________________________________
2. Data Quality Check (Mandatory Before Join)

You must confirm that the join key (PULocationID) is populated.

If it contains NULLs, the join will fail or drop rows.

```sql
USE nyc_taxi_discovery;

SELECT TOP 100 *
FROM OPENROWSET(
        BULK 'trip_data_green_parquet/year=2020/month=01/',
        FORMAT = 'PARQUET',
        DATA_SOURCE = 'nyc_taxi_data_raw'
    ) AS result
WHERE PULocationID IS NULL;
```
If this returns 0 rows, the join key is clean.

Two‑word logic: Key integrity

Business analogy: If employee IDs are missing, payroll can’t match employees to departments.

______________________________________________________________________________________________________________________________________________________________________________________
3. Joining Two Files Using OPENROWSET

OPENROWSET behaves like a virtual table.

So instead of:

```sql
FROM TableA
JOIN TableB ON ...
```
You use:

```sql
FROM OPENROWSET(...) AS A
JOIN OPENROWSET(...) AS B ON ...
```
Two‑word logic: Virtual tables

Business analogy: Treating two CSV/Parquet files as if they were database tables.

______________________________________________________________________________________________________________________________________________________________________________________
4. Full Combined Query (Clean, Correct, Workbook‑Ready)
```sql
SELECT 
    taxi_zone.borough, 
    COUNT(1) AS number_of_trips
FROM OPENROWSET(
        BULK 'trip_data_green_parquet/year=2020/month=01/',
        FORMAT = 'PARQUET',
        DATA_SOURCE = 'nyc_taxi_data_raw'
    ) AS trip_data
JOIN OPENROWSET(
        BULK 'abfss://nyc-taxi-data@synapsecoursedl.dfs.core.windows.net/raw/taxi_zone.csv',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        FIRSTROW = 2
    )
    WITH (
        location_id SMALLINT 1,
        borough VARCHAR(15) 2,
        zone VARCHAR(50) 3,
        service_zone VARCHAR(15) 4
    ) AS taxi_zone
ON trip_data.PULocationID = taxi_zone.location_id
GROUP BY taxi_zone.borough
ORDER BY number_of_trips;
```
This produces the borough‑level trip counts.

______________________________________________________________________________________________________________________________________________________________________________________
5. Why the Join Works

Both datasets share LocationID

Trip data uses it as pickup location

Taxi zone file maps it to borough name

JOIN aligns the two

GROUP BY aggregates trips per borough

ORDER BY ranks boroughs by trip volume

Two‑word logic: Shared key

Business analogy: Customer ID lets you merge sales data with customer demographics.

______________________________________________________________________________________________________________________________________________________________________________________
6. Charting the Results (Synapse Studio)

Once the query runs:

Choose Bar Chart

Category = borough

Value = number_of_trips

This visually confirms Manhattan has the highest trip volume.

Two‑word logic: Visual confirmation

Business analogy: Turning a pivot table into a dashboard.

______________________________________________________________________________________________________________________________________________________________________________________
7. SOP Micro‑Steps (Your Preferred Style)

Load trip data (Parquet).

Validate join key (PULocationID).

Load taxi zone lookup (CSV).

Define schema using WITH.

Join on PULocationID = location_id.

Group by borough.

Count trips.

Order results.

Visualize (optional).

______________________________________________________________________________________________________________________________________________________________________________________
8. Optional Extensions

A join diagram

A debugging version (detect mismatched LocationIDs)

A DAIS‑10 interpretation (Join = Alignment Layer)

A Synapse pipeline version

A two‑word logic workbook page`
