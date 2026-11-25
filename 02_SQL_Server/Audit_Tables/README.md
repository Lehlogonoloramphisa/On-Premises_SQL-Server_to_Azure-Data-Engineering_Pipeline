# Audit diagnostics

`Investigate_Incremental_Run.sql` compares the ADF Copy activity counts from run `6cac908b-e9ba-422b-b243-00e7fc7bd56e` with the rows in `etl.LoadAudit`. The Customer count discrepancy (4 copied versus 3 audited) remains unresolved; the query surfaces the audit-side records but does not explain the missing count.

The canonical `etl.LoadAudit` table definition and `etl.usp_InsertLoadAudit` procedure remain in `../Database_Scripts/Project_ETL_Objects.sql` to avoid maintaining duplicate definitions.
