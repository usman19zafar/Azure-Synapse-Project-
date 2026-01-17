GOLD LAYER 

 Full Bronze → Silver → Gold Pipeline
```Code
                                   ┌──────────────────────────────┐
                                   │        RAW DATA (CSV)        │
                                   │  green_tripdata_YYYY-MM.csv  │
                                   └───────────────┬──────────────┘
                                                   │
                                                   ▼
                         ┌──────────────────────────────────────────────────┐
                         │                    BRONZE LAYER                  │
                         ├──────────────────────────────────────────────────┤
                         │ External Table: bronze.trip_data_green_csv       │
                         │   • Reads raw CSV                                │
                         │   • No transformations                           │
                         │                                                  │
                         │ View: bronze.vw_trip_data_green_csv              │
                         │   • Adds year, month                             │
                         │   • Fixes schema drift (ehail_fee)               │
                         └───────────────┬──────────────────────────────────┘
                                         │
                                         ▼
                         ┌──────────────────────────────────────────────────┐
                         │                    SILVER LAYER                  │
                         ├──────────────────────────────────────────────────┤
                         │ Stored Procedure: silver.usp_silver_trip_data_   │
                         │                     green(year, month)           │
                         │   • Filters by year/month                        │
                         │   • Writes Parquet via CTAS                      │
                         │   • Drops external table metadata                │
                         │                                                  │
                         │ Output Folder Structure:                         │
                         │   silver/trip_data_green/                        │
                         │       └── year=YYYY/                             │
                         │             └── month=MM/                        │
                         │                   └── *.parquet (1–3 files)      │
                         │                                                  │
                         │ View: silver.vw_trip_data_green                  │
                         │   • OPENROWSET over partitioned Parquet          │
                         │   • filepath(1) → year                           │
                         │   • filepath(2) → month                          │
                         │   • Enables partition pruning                    │
                         └───────────────┬──────────────────────────────────┘
                                         │
                                         ▼
                         ┌──────────────────────────────────────────────────┐
                         │                    GOLD LAYER                    │
                         ├──────────────────────────────────────────────────┤
                         │ Joins + Aggregations:                            │
                         │   • trip_data_green (Silver)                     │
                         │   • taxi_zone_lookup (borough)                   │
                         │   • calendar_dim (day of week, weekend flag)     │
                         │                                                  │
                         │ Derived Metrics:                                 │
                         │   • cash_trip_count                              │
                         │   • card_trip_count                              │
                         │   • trip_day_of_week                             │
                         │   • is_weekend_flag                              │
                         │   • borough                                      │
                         │                                                  │
                         │ Output: fact_payment_behavior (Parquet)          │
                         │   • Partitioned by year/month                    │
                         │   • Optimized for reporting                      │
                         └──────────────────────────────────────────────────┘
```
Business Requirements + Non‑Functional Requirements + Data Mapping + Gold Schema Definition
1. BUSINESS REQUIREMENTS

```Code
+----------------------------------------------------------------------------------------------+
| BUSINESS REQUIREMENT SUMMARY                                                                 |
+----------------------------------------------------------------------------------------------+
| Goal: Increase credit card usage to 90% of all taxi payments.                                |
|                                                                                              |
| The NYC Taxi & Limousine Commission wants to:                                                |
|  - Understand current ratio of cash vs card payments                                         |
|  - Track progress over time                                                                  |
|  - Run targeted campaigns to influence customer behavior                                     |
|                                                                                              |
| Required insights:                                                                           |
|  - Number of trips paid by CASH                                                              |
|  - Number of trips paid by CARD                                                              |
|  - Payment behavior by DAY OF WEEK                                                           |
|  - WEEKDAY vs WEEKEND behavior                                                               |
|  - Payment behavior by BOROUGH                                                               |
+----------------------------------------------------------------------------------------------+
```
2. NON‑FUNCTIONAL REQUIREMENTS
```Code
+----------------------------------------------------------------------------------------------+
| NON-FUNCTIONAL REQUIREMENT SUMMARY                                                           |
+----------------------------------------------------------------------------------------------+
| Data volume: Hundreds of millions of trips per month.                                        |
|                                                                                              |
| Requirements:                                                                                |
|  - Gold layer must be AGGREGATED for fast reporting                                          |
|  - Must support INCREMENTAL processing (month-by-month)                                      |
|  - Must NOT reprocess historical data unnecessarily                                          |
|  - Must be PARTITIONED by YEAR and MONTH                                                     |
|  - Must avoid creating multiple redundant tables                                             |
|  - Should use FLAGS instead of separate tables for variations                                |
+----------------------------------------------------------------------------------------------+
```
3. GOLD LAYER — REQUIRED DATA ITEMS
```Code
+---------------------------+---------------------------------------------------------------+
| DATA ITEM                 | PURPOSE                                                       |
+---------------------------+---------------------------------------------------------------+
| year                      | Partitioning + incremental processing                         |
| month                     | Partitioning + incremental processing                         |
| borough                   | Campaign targeting by location                                |
| trip_day_of_week          | Identify behavior by weekday/weekend                          |
| is_weekend_flag           | Simplifies reporting logic                                    |
| cash_trip_count           | Number of trips paid by cash                                  |
| card_trip_count           | Number of trips paid by card                                  |
+---------------------------+---------------------------------------------------------------+
```
4. SOURCE DATA MAPPING (SILVER → GOLD)
```Code
+---------------------------+---------------------------+--------------------------------+
| GOLD COLUMN               | SOURCE                    | LOGIC / TRANSFORMATION         |
+---------------------------+---------------------------+--------------------------------+
| year                      | silver.trip_data_green    | Direct from partition          |
| month                     | silver.trip_data_green    | Direct from partition          |
| borough                   | taxi_zone_lookup          | Join on pickup location        |
| trip_day_of_week          | calendar_dim              | Derived from pickup datetime   |
| is_weekend_flag           | calendar_dim              | Sat/Sun = 1, else 0            |
| cash_trip_count           | trip_data + payment_type  | payment_type = CASH            |
| card_trip_count           | trip_data + payment_type  | payment_type = CARD            |
+---------------------------+---------------------------+--------------------------------+
```
5. GOLD TABLE STRUCTURE (FINAL)
```Code
+----------------------------------------------------------------------------------------------+
| GOLD TABLE: fact_payment_behavior                                                            |
+----------------------------------------------------------------------------------------------+
| year (string)                                                                                |
| month (string)                                                                               |
| borough (string)                                                                             |
| trip_day_of_week (string)                                                                    |
| is_weekend_flag (int)                                                                        |
| cash_trip_count (bigint)                                                                     |
| card_trip_count (bigint)                                                                     |
+----------------------------------------------------------------------------------------------+
```
6. LOGICAL FLOW (ASCII DIAGRAM)
```Code
                 ┌──────────────────────┐
                 │      SILVER          │
                 │  trip_data_green     │
                 └─────────┬────────────┘
                           │
                           ▼
        ┌──────────────────────────────┐
        │   JOIN WITH LOOKUP TABLES    │
        │  - taxi_zone_lookup          │
        │  - calendar_dim              │
        └─────────┬────────────────────┘
                  │
                  ▼
        ┌──────────────────────────────┐
        │   DERIVE BUSINESS METRICS    │
        │  - cash_trip_count           │
        │  - card_trip_count           │
        │  - is_weekend_flag           │
        │  - trip_day_of_week          │
        └─────────┬────────────────────┘
                  │
                  ▼
        ┌──────────────────────────────┐
        │        GOLD LAYER            │
        │ fact_payment_behavior.parquet│
        │ partitioned by year/month    │
        └──────────────────────────────┘
```
7. KEY DESIGN PRINCIPLES
```Code
+----------------------------------------------------------------------------------------------+
| DESIGN PRINCIPLES                                                                            |
+----------------------------------------------------------------------------------------------+
| 1. Partition by year/month for efficient pruning                                             |
| 2. Aggregate at Gold layer to reduce report latency                                          |
| 3. Use flags instead of multiple tables                                                      |
| 4. Support incremental monthly loads                                                         |
| 5. Avoid reprocessing historical data                                                        |
| 6. Keep schema simple and reporting-friendly                                                 |
+----------------------------------------------------------------------------------------------+
```
8. SUMMARY (GITHUB‑READY)
```Code
This Gold layer design supports the NYC Taxi Commission’s business goal of increasing credit card
usage by providing aggregated, partitioned, and campaign-ready metrics. The table captures payment
behavior by borough, day of week, and weekend/weekday classification, while supporting incremental
monthly processing and efficient partition pruning. This structure ensures fast reporting, low cost,
and minimal duplication across the analytical pipeline.
```
