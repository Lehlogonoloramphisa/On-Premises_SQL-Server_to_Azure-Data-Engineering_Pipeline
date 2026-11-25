# Project assessment

## What I have in this project folder

- The ADF exports include a metadata-driven pipeline that branches between full and incremental loads, a separate Product full-load pipeline, and a Copy-failure path that audits and explicitly fails the pipeline. The four-table control seed includes baseline filenames; a row switches from Full to Incremental only after its watermark procedure succeeds.
- The SQL Server ETL definitions are in `02_SQL_Server/Database_Scripts/Project_ETL_Objects.sql`: `etl.LoadAudit`, `etl.WatermarkControl`, `etl.usp_InsertLoadAudit`, and `etl.usp_UpdateWatermark`. The script creates the `etl` schema when it is missing.
- Bronze, Silver, and Gold Parquet outputs are saved under `04_Data`.
- The original Databricks notebook contains the medallion transformations, but a saved execution shows a `NameError` when the initial customer Silver table is created: `customer_latest` is not initialized in that notebook.
- I split the notebooks into Bronze, Silver, and Gold entry points. The Silver notebook initializes its customer inputs from Bronze and uses all customer incremental files; the original notebook remains archived as `03_Databricks/Notebooks/00_Original_Monolithic_Archive.ipynb`.
- The historical ADF, Silver, Gold, Spark performance, and troubleshooting results are collected in `05_Documentation/Testing_Results`, with evidence gaps and unresolved issues called out.
- A synthetic-data Spark lab and standalone SQL checks cover medallion record counts, natural-key uniqueness, and referential relationships.
- The detailed [rebuild runbook](./Rebuild_Runbook.md) gives the ordered setup and validation steps, including gates for backup, cloud cost/access, ADF, Databricks, and later Fabric work.

## Historical phase status

| Phase | Recorded status |
|---|---|
| Azure ingestion | Core implementation complete; ADF, SHIR, ADLS, metadata-driven ingestion, watermarking, and auditing were tested. |
| Databricks and Silver | Core transformations, Delta tables, deduplication, validation, and merges complete. |
| Gold modelling | Facts and dimensions complete; surrogate keys and SCD Type 1/2 remain outstanding. |
| Spark optimization | Execution plans inspected; the controlled performance lab remains to be run. |
| Microsoft Fabric | Not started. |
| Production readiness | Partial; deployment, monitoring, recovery, permissions, RLS, and governance exercises remain. |
| Backup/cloud cleanup | Main backup and deletion steps complete; backup restore and final resource-group contents are not verified. |

## Gaps and next actions

| Priority | Finding | Status / next action |
|---|---|---|
| High | Restored control rows may have an old watermark/load state while the new Bronze destination is empty. | The pipeline now branches between Full and Incremental loads and uses baseline filenames. Review restored rows; use the guarded reset only if replacing baseline files is intended. |
| High | There is no ADF trigger. | Decide the schedule/event type, cadence, time zone, and backfill policy before creating one. |
| High | SQL linked-service credentials, integration-runtime availability, and ADLS/Databricks permissions cannot be validated from exported files. | Validate these in the target Azure environment and keep credentials in managed secret stores. |
| Medium | The `Audit_Tables` and `Stored_Procedures` folders contain guidance and diagnostics, but not separate definitions for the audit table or stored procedures; the canonical definitions remain in the consolidated SQL script. | Keep one canonical definition for now; split the deployment scripts only after choosing the deployment runner and execution order. |
| Medium | The Databricks folders include setup and validation guidance, but there is no catalog, storage credential, or external-location provisioning. | Confirm catalog ownership, storage credential, external location, and workspace permissions before adding provisioning scripts or shared modules. |
| Medium | SalesOrderHeader and SalesOrderDetail use metadata rows in the generic copy pipeline rather than dedicated pipeline definitions. | Both are in the starter rows, based on the recorded successful runs. Validate source access, overlapping watermark behavior, and counts during rebuild. |
| Low | Resource inventory and operational documentation were absent. | A baseline inventory, architecture overview, and notebook troubleshooting notes are now included. |
| High | The Azure-to-Fabric phase has not started; main Azure resources were deleted. | `Remaining_Work_Backlog.md` tracks follow-up work. Verify resource-group contents and cost/access requirements before rebuilding. |
| Medium | Surrogate keys, SCD Type 1/2, effective dating, and row-hash change detection were not implemented. | Define dimension attributes, key persistence, equal-timestamp handling, and the province/address source before implementation. |
| Medium | Schema enforcement and quarantine rules were not completed. | Agree on schema evolution, reject criteria, and quarantine storage/retention before enabling enforcement. |
| Medium | The controlled Spark performance lab, alternate file-format comparison, and `save()`/`saveAsTable()` comparison remain incomplete. | `03_Databricks/Notebooks/04_Spark_Performance_Lab.ipynb` provides a synthetic-data harness. Run it in the rebuilt workspace and capture repeatable before-and-after measurements. Format and save API comparisons remain open. |
| Medium | Practical production readiness (Git workflow, deployment, monitoring, recovery, permissions, RLS, governance) remains incomplete. | Track this in `Remaining_Work_Backlog.md`; implementation depends on rebuilding the target environments and agreeing operational ownership. |
| High | Backup restore and final cloud resource-group contents have not been verified. | The `.bak` file is present locally; the ZIP was not found in the checked project root. Verify the restore and inspect `rg-adventureworks-data-dev` and `Fabric_Azure_Workspace` before cleanup. |

## What I have and have not validated

Local checks covered notebook JSON, cell ordering, and Python syntax. End-to-end execution still requires the configured Databricks workspace, catalog, ADLS access, SQL Server, and ADF integration runtime.
