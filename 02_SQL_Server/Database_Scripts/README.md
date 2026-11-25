# SQL Server deployment order

1. Run `Project_ETL_Objects.sql` against `AdventureWorks2022`. It creates the `etl` schema and missing tables if needed, migrates `FullLoadFileName`, and creates or alters the stored procedures.
2. Run `../Control_Tables/Seed_WatermarkControl.sql`. It inserts missing rows for Customer, SalesOrderHeader, SalesOrderDetail, and Product with `LoadType = 'Full'`; for existing rows it fills a missing full-load filename without resetting the watermark or load state.
3. If the restored database has existing watermark rows but the new Bronze destination is empty, inspect them. Only after confirming that a full reload is intended, set `@ConfirmBronzeReset = 1` in `../Control_Tables/Reset_WatermarkControl_For_Full_Load.sql` and run it.
4. Use `../Audit_Tables/Investigate_Incremental_Run.sql` to inspect the audit side of the recorded incremental-run discrepancy.

New full-load rows start at `1900-01-01` to avoid skipping source history, but the full-load query does not filter by that watermark. After a successful copy, `usp_UpdateWatermark` records the source maximum and changes `LoadType` to `Incremental`. The next incremental run uses the inclusive `>=` boundary and may re-read rows at that timestamp.

The consolidated object script is the canonical definition. The `Audit_Tables` and `Stored_Procedures` folders document and support diagnostics without duplicating those object definitions.
