# Spark performance test results

## Evidence status

These observations come from tests on the available dataset. They have not been independently remeasured and do not establish production-scale performance improvements.

## Recorded observations

| Test | Observed result |
|---|---|
| FactSalesLine storage | 1 file, 1,091,205 bytes |
| FactSalesOrder storage | 1 file, 448,828 bytes |
| Monthly sales query duration | Approximately 0.1 seconds |
| Monthly sales output | 38 records |
| Monthly sales shuffle input | Approximately 5 KiB |
| Header/detail join output | 121,317 records |
| Adaptive Query Execution (AQE) | Coalesced 200 partitions into one per side |
| Join strategy | SortMergeJoin |
| Spill | None observed |
| Skew | None observed |

The files and dataset were small, so the timing, shuffle, and join observations should not be extrapolated to larger workloads. Before making optimization decisions, benchmark with representative production volume, concurrency, cluster configuration, and repeatable query conditions.
