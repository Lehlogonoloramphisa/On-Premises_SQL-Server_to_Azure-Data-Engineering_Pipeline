# Known issues and open validation items

## Evidence status

This list tracks unresolved project items, separating confirmed limitations from questions that need the original environment or execution evidence.

## Confirmed technical limitations

### Inclusive watermark re-reads matching timestamps

The ADF extraction uses an inclusive watermark comparison (`>=`). Rows whose watermark value equals the saved watermark can be extracted again. This may produce repeated data, repeated audit work, or apparent count discrepancies.

**Next step:** choose and test a watermark strategy that handles timestamp precision and late-arriving rows (for example, an overlap window plus deterministic deduplication, or a carefully designed exclusive boundary). Validate restart and failure-retry behavior before changing production predicates.

### Equal-timestamp changes are not detected by Silver merges

The current merge condition `ModifiedDate > target.ModifiedDate` does not update a target when the incoming record has a different payload but the same `ModifiedDate`.

**Next step:** confirm whether same-timestamp versions are possible. If so, add a reliable tie-breaker/version token or define and test a deterministic conflict policy. Do not assume a timestamp alone uniquely orders changes.

## Unresolved discrepancy

For incremental run `6cac908b-e9ba-422b-b243-00e7fc7bd56e`, the Customer Copy activity reported 4 rows but the audit table recorded 3. I noticed the discrepancy but did not complete the investigation.

**Next step:** retrieve the run's ADF activity output, source/copy counts, and matching `etl.LoadAudit` row; verify the audit procedure parameter mapping and determine whether any row was filtered, retried, or recorded under a different table/run identifier.

`02_SQL_Server/Audit_Tables/Investigate_Incremental_Run.sql` provides a starting comparison using the recorded Copy activity counts; it does not resolve or explain the discrepancy.

## Environment and evidence gaps

- Unity Catalog optional file events returned 403; forced creation was used and file events were left unresolved. Verify the needed permissions and whether file events are required for the rebuilt environment.
- The pass/fail results in this folder are from earlier project runs. Original execution logs, screenshots, query output, and performance traces were not available, so they have not been independently checked.
- `AdventureWorks2022.bak` is present locally, but its integrity and restore have not been verified. Project notes mention a ZIP backup, but none was found in the checked project root.
- The final contents of `rg-adventureworks-data-dev` were not confirmed. `Fabric_Azure_Workspace` previously contained `surelink-source` and `surelink-sql-servers`; do not remove them without identifying their purpose.
- Performance results use a relatively small dataset and are observations, not proof of production-scale performance.
- The local notebook files can be structurally validated, but cloud execution requires the target Databricks workspace, catalog, storage access, SQL Server, ADF linked services, and SHIR.
- ADF now audits and explicitly fails after a Copy failure, and records/fails a watermark-update error instead of reporting the run as successful. The full-to-incremental transition and both failure paths still need testing in the target ADF environment.

## Rebuild exit criteria

Before calling the rebuilt project validated:

1. Re-run ADF connectivity, initial full-load, incremental-load, watermark, and audit tests; retain run IDs and activity/audit evidence.
2. Reconcile copy activity counts with audit rows, including the outstanding Customer discrepancy if historical evidence is available.
3. Re-run Silver uniqueness, null/quality, row-count, and merge tests, including equal-timestamp and retry cases.
4. Re-run Gold grain, relationship, date-key, foreign-key, and aggregate reconciliation checks.
5. Re-benchmark Spark using representative production-scale data and record cluster/query conditions.
