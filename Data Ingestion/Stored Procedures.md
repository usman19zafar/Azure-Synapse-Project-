Stored Procedures — Summary Notes
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
