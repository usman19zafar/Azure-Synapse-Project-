FINAL NOTES — Views in Synapse Serverless SQL
One‑Word: Abstraction
Two‑Words: Semantic Layer
Business Analogy:
External tables expose the entire warehouse.
Views give users a curated showroom.

____________________________________________________________________________________________________________________________________________________________________________________________________________
2, What a View Actually Is
A view is a virtual table defined by a SELECT statement.

It has rows and columns

It does not store data

It simply replays the SELECT every time someone queries it

It hides complexity from users

Views sit above external tables and above OPENROWSET.

____________________________________________________________________________________________________________________________________________________________________________________________________________
3, Why Views Matter in Serverless SQL
A. They hide complexity
OPENROWSET requires:

storage account

container

folder

file format

parser version

wildcard patterns

A view hides all of that.

B. They restrict exposure
External tables expose all columns in the file.
Views allow you to:

show only selected columns

hide sensitive fields

rename columns

apply filters

enforce row‑level restrictions

C. They allow summarization
You can create views that return:

aggregates

grouped data

business‑friendly shapes

D. They support layered modeling
You can build:

Bronze views → raw

Silver views → cleaned

Gold views → business‑ready

Views can be built on top of other views, forming a semantic hierarchy.

____________________________________________________________________________________________________________________________________________________________________________________________________________
4 Where Views Fit in the Architecture
External Table
Reads files exactly as they are.
No filtering.
No column selection.
No transformations.

View
Adds meaning, structure, and restrictions.

This is the beginning of your semantic layer — the layer that business users, analysts, and applications actually query.

____________________________________________________________________________________________________________________________________________________________________________________________________________
5 Syntax (Simple and Clean)

```sql
CREATE VIEW schema.view_name AS
SELECT ...
FROM ...
WHERE ...

```
Column list is optional.
Schema name is optional.
The SELECT must return a valid tabular result.

____________________________________________________________________________________________________________________________________________________________________________________________________________
6 Examples (Instructor’s Scenarios)
A. View on OPENROWSET

```sql
CREATE VIEW bronze.vendor_view AS
SELECT *
FROM OPENROWSET(
        BULK 'raw/vendor.csv',
        DATA_SOURCE = 'nyc_taxi_src',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0'
     ) AS rows;
```

Purpose: hide OPENROWSET complexity.

B. View on an External Table
```sql
CREATE VIEW silver.taxi_zone_brooklyn AS
SELECT
    LocationID,
    Borough,
    Zone
FROM bronze.taxi_zone
WHERE Borough = 'Brooklyn';
```
Purpose: restrict columns + filter rows.

C. View joining OPENROWSET + External Table

```sql
CREATE VIEW silver.vendor_zone AS
SELECT v.vendor_name, z.Zone
FROM OPENROWSET(...) v
JOIN bronze.taxi_zone z
    ON v.vendor_id = z.LocationID;
```
Purpose: combine two different access methods.

D. View on top of another view

```sql
CREATE VIEW gold.brooklyn_summary AS
SELECT Borough, COUNT(*) AS trip_count
FROM silver.taxi_zone_brooklyn
GROUP BY Borough;
```
Purpose: layered modeling.

____________________________________________________________________________________________________________________________________________________________________________________________________________
7 Key Takeaways (Workbook‑Ready)
Views provide:
Column restriction

Row filtering

Aggregation

Joins

Security boundaries

Semantic modeling

Simpler user experience

Views do NOT:
Store data

Improve performance by themselves

Replace external tables

Change the underlying file structure

Views ARE:
The first step toward a curated, governed data model

The foundation of Bronze → Silver → Gold architecture

The abstraction layer that hides storage complexity
____________________________________________________________________________________________________________________________________________________________________________________________________________
8 What You’re Ready For Next
You now understand:

External tables = raw access

Views = curated access

OPENROWSET = ad‑hoc access
