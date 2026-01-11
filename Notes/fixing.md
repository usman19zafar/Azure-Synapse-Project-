The Core Goal
We are trying to ingest raw text files into Synapse Serverless SQL correctly, even when:

the delimiter changes

the file format changes

the data contains commas

the data contains tabs

the data contains quotes

the parser gets confused

In other words:

We are teaching the SQL parser how to correctly understand each file’s structure.

This is foundational Data Architecture work.

What Each Code Block Achieves
Unquoted CSV (vendor_unquoted.csv)
Goal: Demonstrate what happens when a CSV contains commas inside the data but has no quotes or escape characters.

Outcome:  
The parser breaks the row → truncates the vendor name → misreads columns.

This teaches you:

“If the data contains commas, you must protect them.”

Escaped CSV (vendor_escaped.csv)
Goal: Show how to fix the problem using an escape character.

Outcome:  
The parser treats the escaped comma as literal text, not a delimiter.

This teaches you:

“Escape characters protect delimiters inside data.”

Quoted CSV (vendor.csv)
Goal: Show the second fix — using quotes around fields.

Outcome:  
The parser treats the entire quoted string as one column.

This teaches you:

“Quotes are the safest way to protect complex text.”

TSV File (trip_type.tsv)
Goal: Show how to ingest a file that uses TAB instead of comma.

Outcome:  
The parser reads the file correctly only when you specify:

Code
FIELDTERMINATOR = '0x09'
This teaches you:

“Different file formats require different terminators.”

The Architectural Purpose Behind All This
You are building the skill every Data Architect must master:

Understanding and controlling how raw data is parsed.
Because in real pipelines:

Data comes from many sources

Formats are inconsistent

Delimiters vary

Vendors make mistakes

Files contain hidden characters

Parsers break silently

Your job is to make ingestion:

predictable

repeatable

robust

schema‑safe

production‑ready

This is why we test:

unquoted CSV

escaped CSV

quoted CSV

TSV

different terminators

different encodings

You’re learning how to control the parser, not just run queries.

The One‑Sentence Summary
Through this code, we are achieving reliable ingestion of messy real‑world text files by explicitly teaching SQL how to interpret each file’s delimiter, escape rules, and quoting rules.
