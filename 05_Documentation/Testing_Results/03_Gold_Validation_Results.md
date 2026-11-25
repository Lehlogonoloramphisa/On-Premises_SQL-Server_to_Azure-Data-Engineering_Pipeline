# Gold layer validation results

## Evidence status

The results below were recorded during the project. Original execution output was not available for this review, and these checks have not been rerun.

## Validated table counts

| Gold table | Validated records |
|---|---:|
| DimDate | 1,139 |
| DimCustomer | 19,820 |
| DimProduct | 504 |
| FactSalesLine | 121,317 |
| FactSalesOrder | 31,465 |

## Recorded validation coverage

Validation covered:

- Fact table grain.
- Dimension relationships and date keys.
- Foreign-key relationships.
- Sales aggregations and reconciliation with source data.
- Monthly sales.
- Top products and top customers.

The FactSalesOrder query changed from `COUNT(DISTINCT SalesOrderID)` to `COUNT(*)`. The output remained consistent because the fact table contained one row per order. This relies on preserving that grain and uniqueness; keep a uniqueness check if the query is reused after the data model changes.
