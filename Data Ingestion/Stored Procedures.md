Stored Procedures — Notes
1. Definition

A stored procedure is a named database object that contains one or more SQL statements stored on the server.

When executed, the statements inside the procedure run in the exact order they were written.
_____________________________________________________________________________________________________________________________________________________________________
2. Key Capabilities

Stored procedures can:

Accept input parameters

Return output values

Execute multiple SQL statements

Declare and use variables

Include control‑flow logic (IF, WHILE, etc.)

Call other stored procedures

_____________________________________________________________________________________________________________________________________________________________________
3. Example Concept

A simple stored procedure might:

Accept a parameter (e.g., @borough)

Run a SELECT statement filtered by that parameter

Return the results to the caller

Execution uses:

```Code
EXEC procedure_name parameter_value
```
_____________________________________________________________________________________________________________________________________________________________________
4. Benefits of Stored Procedures

4.1 Encapsulation

Reusable logic can be wrapped inside a procedure so you don’t repeat code across scripts.

4.2 Ease of Maintenance

Updating the stored procedure updates the logic for all consumers automatically.

4.3 Impact Analysis

Because procedures live in the database, it’s easier to understand dependencies and impacts when tables change.

4.4 Security

Users can be granted permission to execute a stored procedure without direct access to underlying tables.

This allows:

Restricted access

Controlled exposure of sensitive data

Cleaner permission models

_____________________________________________________________________________________________________________________________________________________________________
5. Limitations in Synapse Serverless SQL

5.1 Limited T‑SQL Support

Only a subset of SQL Server T‑SQL features are supported.

You must ensure your code uses Synapse‑supported syntax.

5.2 Partial Stored Procedure Implementation

Some SQL Server stored procedure features are not yet available in Synapse.

Microsoft continues to expand support, but currently:

Certain control‑flow features are limited

Some metadata operations are restricted

Dynamic SQL works, but with constraints

5.3 Reference Documentation

Synapse provides:

A list of supported T‑SQL statements

A list of stored procedure limitations

SEE TECHNICAL DOCUMENTATION!
_____________________________________________________________________________________________________________________________________________________________________
6. When to Use Stored Procedures

Stored procedures are ideal when you need:

Repeated execution of the same logic

Parameterized operations (e.g., year/month partitions)

Encapsulation of complex SQL

Controlled access to data

Automation of CTAS or ETL patterns

_____________________________________________________________________________________________________________________________________________________________________
7. When NOT to Use Stored Procedures

Avoid stored procedures when:

You need features not supported in Synapse

You require heavy transformations better suited for Spark

You need dynamic partitioning without manual loops

_____________________________________________________________________________________________________________________________________________________________________
8. Summary

Stored procedures in Synapse:

Provide encapsulation, reusability, and security

Allow parameterized execution

Are essential for patterns like partitioned CTAS

Have limitations compared to full SQL Server

Must use Synapse‑supported T‑SQL only

They are a foundational tool for building repeatable, maintainable, and secure data engineering workflows.

_____________________________________________________________________________________________________________________________________________________________________

1. STORED PROCEDURE MASTER SOP

One‑word anchor: Encapsulation

Two‑word logic: Repeatable Logic

1.1 Purpose
Stored procedures encapsulate reusable SQL logic inside a named database object.
They allow parameterized execution, automation, and controlled access to underlying data.

1.2 When to Use Stored Procedures
Use stored procedures when you need:

Repeated execution of the same SQL pattern

Parameterized operations (e.g., year/month partitions)

Encapsulation of CTAS logic

Controlled access to tables

Automation of multi‑step workflows

Dynamic SQL generation (e.g., dynamic table names, dynamic folder paths)

1.3 Stored Procedure Structure (Canonical Pattern)
```sql
CREATE PROCEDURE schema.procedure_name
(
    @param1 datatype,
    @param2 datatype
)
AS
BEGIN
    -- variable declarations
    -- dynamic SQL construction
    -- EXEC(@sql)
END;
GO
```
1.4 Stored Procedure Execution
```sql
EXEC schema.procedure_name 'value1', 'value2';
```
1.5 Benefits

Encapsulation

One place to maintain logic.

Reusability

Call the same logic repeatedly with different parameters.

Security

Users can execute procedures without direct table access.

Maintainability
Updating the procedure updates all consumers.

Automation
Ideal for partitioned CTAS patterns.

1.6 Limitations in Synapse Serverless SQL
Only a subset of T‑SQL is supported

No transaction control (no BEGIN TRAN / COMMIT)

No TRY/CATCH

No table‑valued parameters

No temporary tables inside procedures

Dynamic SQL works but must be executed via EXEC(@sql)
_____________________________________________________________________________________________________________________________________________________________________

2. LINE‑BY‑LINE BREAKDOWN OF THE PARTITION PROCEDURE
One‑word anchor: Dissection
Two‑word logic: Mechanical Truth

Below is the annotated breakdown of the stored procedure you are using for partitioned CTAS.

2.1 Procedure Header
```sql
CREATE PROCEDURE silver.usp_silver_trip_data_green
(
    @year  VARCHAR(4),
    @month VARCHAR(2)
)
```
Creates a procedure in the silver schema

Accepts two parameters: year and month

These parameters control which partition is written

2.2 Build dynamic table name
```sql
DECLARE @tableName NVARCHAR(200) =
    CONCAT('silver.trip_data_green_', @year, '_', @month);
```
Creates a unique table name per partition

Example: silver.trip_data_green_2020_01

2.3 Build dynamic folder path
```sql
DECLARE @location NVARCHAR(500) =
    CONCAT('silver/trip_data_green/year=', @year, '/month=', @month);
Creates a unique folder path per partition
```
Example: silver/trip_data_green/year=2020/month=01

2.4 Build the dynamic CTAS statement
```sql
DECLARE @sql NVARCHAR(MAX) = '
    IF OBJECT_ID(''' + @tableName + ''') IS NOT NULL
        DROP EXTERNAL TABLE ' + @tableName + ';
Drops the external table for that partition if it exists
```
Prevents metadata conflicts

```sql
    CREATE EXTERNAL TABLE ' + @tableName + '
    WITH
    (
        DATA_SOURCE = nyc_taxi_src,
        LOCATION = ''' + @location + ''',
        FILE_FORMAT = parquet_file_format
    )
Creates a new external table
```
Writes Parquet files to the partition folder

```Code
    AS
    SELECT *
    FROM bronze.trip_data_green_csv
    WHERE YEAR(lpep_pickup_datetime) = ' + @year + '
      AND MONTH(lpep_pickup_datetime) = ' + @month + ';
';
```
Filters raw CSV by year/month

Ensures only the correct partition is written

Uses YEAR() and MONTH() because raw CSV has no year/month columns

2.5 Execute the dynamic SQL
```Code
EXEC(@sql);
Runs the CTAS statement
```
Creates the partitioned Parquet output

Registers the external table

3. DECISION TREE — STORED PROCEDURES VS SPARK
One‑word anchor: Choice
Two‑word logic: Right Tool

3.1 Decision Tree (ASCII)
```Code
                           +-----------------------------+
                           |   Do you need partitioned   |
                           |   writes (year/month/day)?  |
                           +--------------+--------------+
                                          |
                              +-----------+-----------+
                              |                       |
                             YES                     NO
                              |                       |
                +-------------+-------------+         |
                |                           |         |
   Is the dataset small enough        Is CTAS enough? |
   for Serverless SQL?                (single folder)  |
                |                           |         |
        +-------+-------+                   |         |
        |               |                   |         |
       YES             NO                  YES       NO
        |               |                   |         |
Use Stored Proc     Use Spark         Use CTAS     Use Spark
(CTAS per
partition)         (native
                    partitioning)     (simple
                                        write)     (complex
                                                        logic)
```
3.2 When to Use Stored Procedures (Serverless SQL)
Use stored procedures when:

You need partitioned CTAS

You need parameterized execution

You need repeatable SQL logic

You want metadata‑driven automation

You want to avoid Spark overhead

Data volume is moderate (tens or hundreds of GB)

3.3 When to Use Spark
Use Spark when:

You need native partitioned writes

You need schema evolution

You need Delta Lake

You need large‑scale transformations

You need complex joins, aggregations, or window functions

Data volume is large (hundreds of GB → TB scale)

3.4 Summary Table
```Code
+----------------------+-------------------------------+-------------------------------+
| Requirement          | Stored Procedure (Serverless) | Spark                         |
+----------------------+-------------------------------+-------------------------------+
| Partitioned writes   | Workaround (CTAS per part)    | Native, automatic             |
| Large datasets       | Not ideal                     | Ideal                         |
| Complex transforms   | Limited                       | Full support                  |
| Delta Lake           | Not supported                 | Fully supported               |
| Automation           | Excellent                     | Good                          |
| Cost                 | Very low                      | Higher                        |
+----------------------+-------------------------------+-------------------------------+
```
