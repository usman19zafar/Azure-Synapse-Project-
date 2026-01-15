1, “Fixing Exclusive Lock Errors: Identifying and Killing Blocking Sessions in Synapse SQL”
Summary:  
A walkthrough of how an ALTER DATABASE operation fails due to an active session, how to identify the blocking session using sys.dm_exec_sessions, and how to safely kill it using KILL <session_id>.

2, “Database Not Showing in Synapse or SSMS? UI Cache vs Live Metadata Explained”

Summary:  
A practical guide on why a database appears in the USE dropdown but not in the Object Explorer, and how a simple refresh or reconnect resolves the stale UI cache.

3, “Workspace vs Linked: Understanding Synapse Control Boundaries”

Summary:  
A clear explanation of the difference between workspace‑owned resources (SQL endpoint, artifacts, pipelines) and linked external systems (ADLS Gen2, SQL DB, Cosmos DB), including why your data lake always appears under Linked Services.

4, “HADOOP vs NATIVE External Data Sources: Choosing the Right Protocol in Synapse SQL”

Summary:  
A comparison of file‑based access (HADOOP) vs database‑engine access (NATIVE), explaining when to use each, how they behave, and why serverless SQL uses HADOOP for data lake files.

