Column‑Level Transformations — Clean Notes + Working Code

One word
Duration

Two words
Time difference

Business analogy
You’re measuring how long each taxi “occupied the road,” the same way a hotel measures how long a guest occupies a room.

Working SQL (Your Version With Wildcard Path)

```sql
USE nyc_taxi_discovery;
```
```sql
SELECT 
    DATEDIFF(minute, lpep_pickup_datetime, lpep_dropoff_datetime) / 60 AS from_hour,
    (DATEDIFF(minute, lpep_pickup_datetime, lpep_dropoff_datetime) / 60) + 1 AS to_hour,
    COUNT(1) AS number_of_trips
FROM
    OPENROWSET(
        BULK 'trip_data_green_parquet/**',
        FORMAT = 'PARQUET',
        DATA_SOURCE = 'nyc_taxi_data_raw'
    ) AS trip_data
GROUP BY 
    DATEDIFF(minute, lpep_pickup_datetime, lpep_dropoff_datetime) / 60,
    (DATEDIFF(minute, lpep_pickup_datetime, lpep_dropoff_datetime) / 60) + 1
ORDER BY 
    from_hour, 
    to_hour;
```      

This is the correct, clean, and scalable version.
It reads all Parquet files across all months and all nested Spark folders.

Mechanical Truth Behind the Query
1. DATEDIFF(minute, pickup, dropoff)
Returns the trip duration in minutes.

2. Dividing by 60
Converts minutes → hours.

3. from_hour
The lower bound of the duration bucket.

4. to_hour
The upper bound (exclusive).

5. Grouping
Aggregates the number of trips per hour‑range.

6. Ordering
Makes the output readable from shortest trips → longest trips.

Why this Version Works 
our used trip_data_green_parquet/**
This wildcard solves all path issues:

no need to specify month folders

no need to specify filenames

no need to worry about Spark’s random part‑file names

no need to adjust paths for each lesson

This is the professional way to read partitioned Parquet in Serverless SQL.

Our DATA_SOURCE root is correct
we aligned it to:

```Code
abfss://nyctaxidata@786.dfs.core.windows.net/raw/
```

This is the correct root for all future lessons.

✔ Our query now scales to the entire dataset
The instructor’s version only reads January.
Yours reads the entire year.

Conceptual Notes (Cleaned and Structured)

Column‑level transformations

Used to reshape or derive new values from existing columns.

Examples:

formatting dates

combining strings

extracting substrings

computing durations

deriving metrics from multiple columns

Duration calculation

Taxi trips have:

lpep_pickup_datetime

lpep_dropoff_datetime

Duration = difference between these two timestamps.

Using DATEDIFF

DATEDIFF(minute, start, end) returns the difference in minutes.

Bucketizing durations

To group trips into hour‑ranges:

divide minutes by 60

floor division gives the lower bound

add 1 gives the upper bound

Data quality issues

Negative durations occur when:

dropoff < pickup
These rows should be filtered out.

