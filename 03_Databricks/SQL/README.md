# Databricks SQL validation

Run `Validate_Medallion_Record_Counts.sql` after the Silver and Gold notebooks to compare the current tables with the counts from earlier project runs.

Use `Validate_Medallion_Keys_and_Relationships.sql` to check natural-key uniqueness and the Silver fact-source relationships.

The queries report `PASS` or `FAIL` rather than stopping execution. Expected counts are historical baselines, not guarantees for later source snapshots.
