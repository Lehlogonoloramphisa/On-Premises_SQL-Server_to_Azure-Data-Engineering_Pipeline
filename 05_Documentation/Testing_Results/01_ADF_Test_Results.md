# Azure Data Factory test results

## Evidence status

The results below come from earlier ADF runs. Original execution logs, screenshots, and query outputs were not available for this review, so the results have not been independently re-run or verified.

## Test summary

| Test | Recorded result |
|---|---|
| SQL Server linked service connection | Passed |
| ADLS Gen2 linked service connection | Passed |
| Self-hosted Integration Runtime connection | Passed |
| Metadata Lookup | Passed |
| Sequential ForEach processing | Passed |
| Dynamic Copy activity | Passed |
| Watermark update | Passed |
| Audit stored procedure execution | Passed |
| Full load | Passed |
| Incremental load | Passed |

## Initial full-load results

| Source table | Expected records loaded |
|---|---:|
| Sales.Customer | 19,820 |
| Sales.SalesOrderHeader | 31,465 |
| Sales.SalesOrderDetail | 121,317 |
| Production.Product | 504 |
| **Total** | **173,106** |

The separate Product full-load pipeline also copied 504 rows.

## Incremental pipeline run

Recorded run ID: `6cac908b-e9ba-422b-b243-00e7fc7bd56e`

| Table | Copy activity rows |
|---|---:|
| SalesOrderHeader | 40 |
| SalesOrderDetail | 96 |
| Customer | 4 |
| Product | 1 |

The watermark updates and audit activities were recorded as successful.

The repository includes `../../02_SQL_Server/Audit_Tables/Investigate_Incremental_Run.sql` to compare these Copy activity counts with the audit rows for this run. It requires access to `AdventureWorks2022` and has not been run against the database.

### Outstanding audit discrepancy

The Customer Copy activity reported 4 rows, while the audit table recorded 3. I noted the discrepancy but did not complete the investigation. The count should not be treated as reconciled until the source, Copy output, stored-procedure parameters, and audit row for this run have been compared.
