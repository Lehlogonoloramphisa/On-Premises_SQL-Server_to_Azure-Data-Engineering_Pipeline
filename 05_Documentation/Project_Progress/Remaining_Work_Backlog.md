# Remaining work backlog

This backlog tracks the work that remains incomplete. Historical test results are documented separately and are not current environment validation.

## Rebuild and backup

- Confirm whether `rg-adventureworks-data-dev` contains remaining resources before cleanup.
- The local `AdventureWorks2022.bak` file is present, but restore/integrity verification remains outstanding.
- Rebuild cloud resources only after confirming the subscription, region, target resource groups, access permissions, and cost controls.
- Review the prior ADLS network setting before recreation: public network access was enabled, while anonymous access was disabled. Apply the target organization's network policy rather than copying this setting by default.

## Ingestion

- Investigate the recorded Customer Copy count (4) versus audit count (3) using the saved run ID and the SQL diagnostic query.
- Design and test a watermark strategy that is safe for equal timestamps, retries, and late-arriving rows. CDC or SQL Change Tracking is a candidate, but retention and source-database configuration must be decided before enabling it.
- Expand the metadata-driven configuration toward the original 20–100-table goal only after selecting additional source tables, keys, watermark columns, and load types.
- Exercise failure/recovery behavior and verify that failed Copy operations are both audited and surfaced as pipeline failures.

## Silver and data quality

- Define explicit source schemas and fail/quarantine rules for invalid rows. The current record has quality checks but no agreed quarantine location or reject policy.
- Add a deterministic tie-breaker or row-hash conflict policy for different row versions with equal `ModifiedDate`; validate it using replayed inputs.
- Extend the isolated Product merge test into repeatable tests for insert, update, no change, equal timestamps, and reruns.

## Gold modelling

- Define surrogate-key generation and persistence for dimensions before changing the fact foreign keys.
- Implement SCD Type 1 and Type 2 only after selecting tracked attributes, effective-date boundaries, current-row behavior, and late-arriving change policy.
- The recorded “province-change” test requires a source attribute representing province/address history; the current Gold customer dimension retains IDs and account number rather than customer names or address attributes. Confirm the source/join design before implementing that test.

## Spark experimentation

- Complete a controlled, synthetic-data performance lab: deliberate skew, small files, wide shuffles, broadcast versus sort-merge joins, repartition versus coalesce, cache, and AQE.
- `03_Databricks/Notebooks/04_Spark_Performance_Lab.ipynb` provides a small synthetic-data harness for these experiments; it has not been run in a rebuilt workspace.
- Evaluate OPTIMIZE/Z-ORDER only where table size and query patterns justify it. Record before/after plans, data volume, cluster configuration, and timings.
- Compare CSV, JSON, Parquet, and Delta, and compare `save()` with `saveAsTable()` using isolated test data.
- Investigate Azure SQL as an additional target when a target environment and credentials are available.

## Microsoft Fabric migration

Migration has not started. After the Azure source and transformations are reproducible, implement and compare:

- Fabric Data Factory metadata-driven ingestion.
- OneLake storage and Bronze/Silver Lakehouse tables.
- Shortcuts to retained ADLS data where appropriate.
- Fabric notebook versions of the PySpark transformations.
- Gold Warehouse structures and SQL analytics endpoint.
- A semantic model and a documented Azure-versus-Fabric comparison.

## Production readiness

- Establish Git branches/PR review and a repeatable deployment process.
- Configure monitoring, alerts, logging, retries, and recovery procedures.
- Run a pipeline failure/recovery drill and write a root-cause analysis.
- Define workspace permissions, test row-level security, and document governance/operations.
- Use a secrets manager for credentials and establish disaster-recovery and cost-management procedures.
- Kafka/Event Hubs material was supplementary learning; practical exercises were not confirmed and should remain outside the core migration scope unless separately requested.
