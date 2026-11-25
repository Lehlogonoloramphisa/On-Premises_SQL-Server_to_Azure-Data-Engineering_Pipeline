# Databricks and Silver test results

## Evidence status

These results come from earlier project runs. The original workspace logs and query outputs were not available for this review, and the tests have not been rerun in a current workspace.

## Silver table results

| Table | Final row count | Recorded validation |
|---|---:|---|
| Silver Customer | 19,820 | Passed |
| Silver SalesOrderHeader | 31,465 | Passed |
| Silver SalesOrderDetail | 121,317 | Passed |
| Silver Product | 504 | Passed |
| **Total** | **173,106** | **Passed** |

Tests covered:

- Primary-key uniqueness.
- Duplicate removal.
- Null and data-quality checks.
- Incremental `MERGE` behavior.
- Silver record-count validation.

The Customer, SalesOrderHeader, and SalesOrderDetail incremental `MERGE` tests made no changes because the incoming records matched the existing rows. A separate Product test demonstrated an update and an insert.

## Interpretation and limitations

- The no-change merges demonstrate the recorded behavior for those matching inputs; they do not prove that all change patterns are handled.
- The inclusive watermark predicate (`>=`) re-extracts rows with a timestamp equal to the stored watermark. This can create repeated source rows and makes deduplication/audit reconciliation important.
- The merge predicate `ModifiedDate > target.ModifiedDate` cannot distinguish two different versions that have identical `ModifiedDate` values. A tie-breaking version key or an explicit equal-timestamp conflict policy is needed if such records can occur.

See [06_Known_Issues.md](./06_Known_Issues.md) for the open items and recommended follow-up.
