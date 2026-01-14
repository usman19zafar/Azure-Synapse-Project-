NOTES — Creating External Tables in Synapse Serverless (2025 Edition)

One word

Essentials

Two words

Clean structure

Business analogy

You’re building a virtual warehouse: shelves (schemas), access gates (data sources), packaging rules (file formats), and catalog entries (external tables).
________________________________________________________________________________________________________________________________________________________________________
1. Purpose of This Lesson

Create your first external table in Synapse Serverless SQL using:

A logical database

Bronze/Silver/Gold schemas

External data source

External file format

External table pointing to CSV

________________________________________________________________________________________________________________________________________________________________________
2. Official Microsoft References

Use these for validation:

External tables overview
https://learn.microsoft.com/en-us/sql/t-sql/statements/create-external-table-transact-sql?view=sql-server-ver16&tabs=dedicated

External data sources
https://azure.microsoft.com/en-ca/products/synapse-analytics/?&ef_id=_k_CjwKCAiAmp3LBhAkEiwAJM2JUJPlOeQ4DPznaTnB4ZNjmfJjxbIL2fjqwYMdurOliePZsR7aGjtaYxoCm7wQAvD_BwE_k_&OCID=AIDcmmqz3gd78m_SEM__k_CjwKCAiAmp3LBhAkEiwAJM2JUJPlOeQ4DPznaTnB4ZNjmfJjxbIL2fjqwYMdurOliePZsR7aGjtaYxoCm7wQAvD_BwE_k_&gad_source=1&gad_campaignid=1634941648&gbraid=0AAAAADcJh_vthon2XxfadkI3tTksf5u-a&gclid=CjwKCAiAmp3LBhAkEiwAJM2JUJPlOeQ4DPznaTnB4ZNjmfJjxbIL2fjqwYMdurOliePZsR7aGjtaYxoCm7wQAvD_BwE

External file formats
https://learn.microsoft.com/en-us/azure/synapse-analytics/sql/develop-tables-external-tables?tabs=hadoop

OPENROWSET + CSV
https://learn.microsoft.com/en-us/azure/synapse-analytics/sql/query-single-csv-file

3. Folder + Schema Strategy (Bronze/Silver/Gold)
Code
Schemas:
bronze   = raw
silver   = cleaned
gold     = curated
Code
Data Lake:
 /bronze/source/entity/year=YYYY/month=MM/day=DD
 /silver/domain/entity/v1
 /gold/business/model/v1
4. Step‑by‑Step SQL (Simplest Form)
Step 1 — Create Logical Database
sql
USE master;
GO

CREATE DATABASE NYC_Taxi_LW;
GO

ALTER DATABASE NYC_Taxi_LW 
COLLATE Latin1_General_100_BIN2_UTF8;
GO
Step 2 — Create Schemas
sql
USE NYC_Taxi_LW;
GO

CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO
Step 3 — Create External Data Source
Points to your ADLS container.

sql
USE NYC_Taxi_LW;
GO

CREATE EXTERNAL DATA SOURCE NYC_Taxi_Source
WITH (
    LOCATION = 'https://<yourstorage>.dfs.core.windows.net/nyc-taxi-data'
);
GO
Step 4 — Create External File Format (CSV)
sql
USE NYC_Taxi_LW;
GO

CREATE EXTERNAL FILE FORMAT CSV_FileFormat
WITH (
    FORMAT_TYPE = DELIMITEDTEXT,
    FORMAT_OPTIONS (
        FIELD_TERMINATOR = ',',
        STRING_DELIMITER = '"',
        FIRST_ROW = 2,
        USE_TYPE_DEFAULT = FALSE,
        ENCODING = 'UTF8',
        PARSER_VERSION = '2.0'
    )
);
GO
Step 5 — Create External Table (Bronze Layer)
Column definitions come from your discovery script.
Example:

sql
USE NYC_Taxi_LW;
GO

CREATE EXTERNAL TABLE bronze.taxi_zone (
    LocationID INT,
    Borough VARCHAR(50),
    Zone VARCHAR(100),
    service_zone VARCHAR(50)
)
WITH (
    LOCATION = '/taxi_zone.csv',
    DATA_SOURCE = NYC_Taxi_Source,
    FILE_FORMAT = CSV_FileFormat
);
GO
6. Validate the Table
sql
SELECT TOP 100 * 
FROM bronze.taxi_zone;
7. What This Achieves
Code
+----------------------+-------------------------------------------+
| Object               | Purpose                                   |
+----------------------+-------------------------------------------+
| Database             | Logical warehouse                         |
| Schemas              | Bronze/Silver/Gold structure              |
| Data Source          | Path to ADLS container                    |
| File Format          | CSV rules                                 |
| External Table       | Virtual table over raw files              |
+----------------------+-------------------------------------------+
8. DAIS‑10 Summary
One word
Virtualization

Two words
Metadata warehouse

Business analogy
You didn’t move the goods — you just created a clean catalog so analysts can query without touching the storage layout.
