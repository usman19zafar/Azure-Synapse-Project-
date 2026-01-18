GOLD LAYER — TRIP AGGREGATION QUERY (FINAL NOTES + CODE)

1. Objective

          Build the Gold-layer aggregated trip table by joining four Silver-layer datasets and producing a small, analytics-ready dataset.
          This SELECT statement will later be wrapped inside a stored procedure to support month-by-month incremental processing.
____________________________________________________________________________________________________________________________________________________________________________
2. Source Tables

Table	Layer	Purpose

    vw_trip_data_green	Silver (View)	Main trip data with partition columns exposed (year, month)
    taxi_zone	Silver	Lookup for borough names
    calendar	Silver	Day name + weekend/weekday logic
    payment_type	Silver	Lookup for payment descriptions

____________________________________________________________________________________________________________________________________________________________________________
3. Design Requirements

Functional:

    Extract year, month, borough, trip date, day name, weekend flag.
    Aggregate trip counts by payment type (credit vs cash).

Non‑functional:

    Must support monthly processing without recalculating all history.
    Must use partition pruning via the Silver view.
    Must produce a small Gold table for fast reporting.
    Must be suitable for CTAS inside a stored procedure.

____________________________________________________________________________________________________________________________________________________________________________
4. Final Aggregation Query (Fully Annotated)

```sql
SELECT 
    td.year,
    td.month,
    tz.borough,
    CONVERT(DATE, td.lpep_pickup_datetime) AS trip_date,
    cal.day_name AS trip_day,
    CASE 
        WHEN cal.day_name IN ('Saturday','Sunday') THEN 'Y' 
        ELSE 'N' 
    END AS trip_day_weekend_ind,
    SUM(CASE WHEN pt.description = 'Credit card' THEN 1 ELSE 0 END) AS card_trip_count,
    SUM(CASE WHEN pt.description = 'Cash' THEN 1 ELSE 0 END) AS cash_trip_count
FROM silver.vw_trip_data_green td
JOIN silver.taxi_zone tz 
    ON td.pu_location_id = tz.location_id
JOIN silver.calendar cal 
    ON cal.date = CONVERT(DATE, td.lpep_pickup_datetime)
JOIN silver.payment_type pt 
    ON td.payment_type = pt.payment_type
WHERE td.year = '2020'
  AND td.month = '01'
GROUP BY 
    td.year,
    td.month,
    tz.borough,
    CONVERT(DATE, td.lpep_pickup_datetime),
    cal.day_name;
```
____________________________________________________________________________________________________________________________________________________________________________
5. Explanation of Each Section

A. SELECT Clause

    td.year, td.month → required for partitioning and monthly processing.
    tz.borough → lookup from taxi zone table.
    CONVERT(DATE, td.lpep_pickup_datetime) → removes time component; defines trip_date.
    cal.day_name → Monday/Tuesday/etc.
    Weekend flag → 'Y' for Sat/Sun, 'N' otherwise.
    Two SUM(CASE…) expressions → aggregated trip counts by payment type.

B. FROM — Base Trip Data

    Uses the Silver view to ensure partition pruning.
    Provides clean, structured trip data.

C. JOIN 1 — Taxi Zone

    Maps pickup location ID → borough.

D. JOIN 2 — Calendar

    Converts pickup datetime to date-only to match calendar.date..
    Provides day_name and supports weekend logic.

E. JOIN 3 — Payment Type

    Converts numeric payment_type → descriptive text.
    Enables credit vs cash aggregation.

F. WHERE — Month Filter

    Restricts processing to a single month.
    Supports the non-functional requirement:
    process one month at a time without recalculating history.
    Later replaced with stored procedure parameters.

G. GROUP BY — Aggregation Grain
Grouping ensures one row per:

    year × month × borough × trip_date × day_name
    This reduces millions of raw rows to ~193 aggregated rows.

____________________________________________________________________________________________________________________________________________________________________________
6. What the Final Output Represents

Each row in the Gold table contains:

    Year
    Month
    Borough
    Trip date
    Day name
    Weekend indicator
    Count of credit card trips
    Count of cash trips

This dataset is:

    Small
    Partitioned
    Fast for reporting
    Aligned with medallion architecture
____________________________________________________________________________________________________________________________________________________________________________
7. Next Step
This SELECT statement will be embedded inside a CTAS statement and wrapped in a stored procedure to support:

Parameterized year/month

Incremental monthly loads

Automated Gold table creation
