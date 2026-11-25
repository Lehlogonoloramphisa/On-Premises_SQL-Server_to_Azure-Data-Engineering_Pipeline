# Lessons learned

## Environment and operations

- Docker Desktop and WSL2 needed troubleshooting before SQL Server development could continue.
- A Self-hosted Integration Runtime connected local SQL Server to Azure Data Factory. Its host availability and registration need to be checked again after a rebuild.
- Databricks Trial DBUs did not cover the underlying Azure VM cost. The recorded $3 budget alert was only a notification, not a spending cap; compute still needs explicit cost controls and shutdown.
- Managed identities and Storage Blob Data Contributor access avoided storing storage keys in notebooks.
- Unity Catalog optional file-event setup returned 403. Forced external-location creation was used, but optional file events remained unresolved.

## Ingestion and data correctness

- A metadata-driven pipeline can process multiple tables with a sequential `ForEach`, but each source needs a reviewed control-table row.
- The inclusive `ModifiedDate >= watermark` predicate avoids missing rows that share a timestamp, but it also re-reads matching rows. Changing it blindly to `>` could miss data; a tie-safe watermark or CDC/Change Tracking design needs testing.
- Audit activity counts need to be reconciled with Copy activity outputs. The recorded Customer run differed by one row, and that discrepancy remains unresolved.
- A watermark should advance only after a successful copy. Failure-path tests need to prove that failed copies are audited and still fail the pipeline.

## Databricks and modelling

- In the Unity Catalog environment, `input_file_name()` was unsupported, so `_metadata.file_path` was used instead.
- Silver deduplication and merges handle repeated extracts, but `ModifiedDate > target.ModifiedDate` cannot detect a different payload with an equal timestamp.
- The Gold fact grain was validated as one row per order line or one row per sales order. `COUNT(*)` is valid for FactSalesOrder only while that grain is maintained.
- The customer source did not include the names needed by the intended model, so the available identifiers and account numbers were retained rather than inventing names.
- Small local datasets help validate correctness but do not establish production-scale performance.

## Backup and migration

- Backup presence and restorability both need verification; copying a file alone does not prove SQL Server can restore it.
- The project started with a ShoppingMart dataset goal and changed to AdventureWorks2022 during implementation. Confirm the source scope and model requirements before extending pipelines or dimensions.