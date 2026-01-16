```code
Summary — Ingesting Data from Bronze to Silver Using Serverless SQL
This section introduces how to transform raw Bronze‑layer data into optimized Silver‑layer datasets using Serverless SQL Pools. The core mechanism is the CREATE EXTERNAL TABLE AS SELECT (CETAS) statement, which lets you read data from storage, apply transformations, and write the transformed output back to storage in a new format such as Parquet or Delta. CETAS behaves like the familiar “CREATE TABLE AS SELECT” from relational databases, but instead of creating a physical table, it writes files to a storage location and registers an external table on top of them.

You begin by reading raw data using OPENROWSET, external tables, or views. The SELECT portion can include joins, filters, aggregations, column removal, or flattening of semi‑structured formats like JSON. This enables common transformation scenarios: converting CSV/JSON to Parquet for analytical performance, removing sensitive or unnecessary columns for compliance or cost reduction, flattening nested structures for easier querying, pre‑aggregating data for reporting, or preparing fact/dimension structures for a warehouse.

Once transformed, CETAS writes the output to a specified folder using a defined external data source and file format, both of which must already exist. The resulting external table becomes immediately queryable by downstream users. While Serverless SQL is excellent for format conversion and lightweight transformations, more complex ETL workloads may be better suited to Dedicated SQL Pools or Spark. Still, CETAS provides a powerful, cost‑efficient way to build Silver‑layer datasets directly from raw storage using SQL alone.
```

