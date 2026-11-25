# Project rebuild runbook

This runbook describes how to rebuild the AdventureWorks2022 project from the files in this backup. Follow the phases in order and do not continue past a gate until its checks pass. The original Azure resources were deleted; exported names and historical results do not prove that any service is still available.

## What is needed before starting

### Accounts, access, and tools

- An Azure subscription with permission to create resource groups, Storage, Data Factory, and Databricks resources. Assigning managed-identity roles also requires the appropriate Azure RBAC permissions.
- Approval for the Azure region, network access, storage retention, and compute costs.
- A Windows host that can reach the SQL Server over TCP. Install Docker Desktop/WSL2 and SQL Server Management Studio (SSMS), or use an approved SQL Server 2022 instance.
- A Windows host for the Self-hosted Integration Runtime (SHIR). It may be the SQL Server host; if not, SQL Server must be reachable from it.
- An Azure Data Factory and Databricks workspace, plus an authorized Unity Catalog/metastore administrator.
- The SQL backup at `02_SQL_Server/Database_Backups/AdventureWorks2022.bak`.

### Choose the target values

Record these values before provisioning. Old names are examples only; resource-group contents were not confirmed, and storage-account names are globally unique.

| Setting | Required value or decision |
|---|---|
| Subscription and resource group | Use the approved subscription and a new or verified resource group. Do not delete unknown resources. |
| Azure region | Use the region approved for the subscription. Historical resources used South Africa North. |
| Storage account | Choose an available globally unique lowercase name. The old name was `awdata2022`. |
| ADLS container/filesystem | Use `bronze`; the datasets and notebook paths expect this name. |
| Data Factory | Choose an available name. The old factory name was `lehlogonoloramphisa-df`. |
| SQL endpoint | Use a hostname/IP reachable from SHIR. `localhost` works only when SHIR and SQL Server run on the same host. |
| SQL database | `AdventureWorks2022`. |
| Databricks catalog | `adb_adventureworks_dev`, unless that name conflicts with the target metastore. |
| Secrets | Obtain SQL credentials through an approved secret store or secure prompt. Never save them in notebooks or parameter files. |

If the storage account or catalog differs from the historical values, update every active ADF linked-service/ARM parameter and the active notebooks/validation SQL together. The original monolithic notebook is an archive, not part of the run order.

## Phase 1: Verify and restore SQL Server

1. Open PowerShell at the project root and check the backup file and checksum:

   ```powershell
   $backup = '.\02_SQL_Server\Database_Backups\AdventureWorks2022.bak'
   Get-Item $backup | Select-Object FullName, Length, LastWriteTimeUtc
   Get-FileHash $backup -Algorithm SHA256
   ```

   Keep the size and SHA-256 value with the rebuild notes. The local Parquet files under `04_Data` are snapshots for comparison; they are not a replacement for the SQL backup.

2. Check for an existing SQL Server container and data volume before creating anything:

   ```powershell
   docker ps -a --filter "name=sql-onprem"
   docker volume inspect adventureworks_sql_data
   ```

   If `sql-onprem` already exists, inspect its state and attached volume; start and reuse it only if it is the intended database. If Docker reports that `adventureworks_sql_data` does not exist (and the Docker daemon is reachable), the volume is absent. If the volume exists, inspect it before deciding whether to reuse it. Do not remove or replace an existing container or volume to make the runbook work. If using a Windows SQL Server installation instead, confirm that it is SQL Server 2022 Developer (or another approved edition) and that TCP connections are enabled.

3. If no SQL Server is available, install SQL Server 2022 Developer or create a new local container. For Docker, use the official SQL Server 2022 image, a persistent volume, and port `1433`. Only do this after confirming that neither the container nor volume already exists. This example prompts for the SA password rather than putting it in the command:

   ```powershell
   $securePassword = Read-Host 'Enter a strong local SA password' -AsSecureString
   $env:MSSQL_SA_PASSWORD = [System.Net.NetworkCredential]::new('', $securePassword).Password
   try {
       docker volume create adventureworks_sql_data
       docker run --name sql-onprem `
           --publish 1433:1433 `
           --env ACCEPT_EULA=Y `
           --env MSSQL_PID=Developer `
           --env MSSQL_SA_PASSWORD `
           --volume adventureworks_sql_data:/var/opt/mssql `
           --detach mcr.microsoft.com/mssql/server:2022-latest
   }
   finally {
       Remove-Item Env:\MSSQL_SA_PASSWORD -ErrorAction SilentlyContinue
       Remove-Variable securePassword -ErrorAction SilentlyContinue
   }
   ```

   Wait for SQL Server to finish starting before connecting:

   ```powershell
   docker ps --filter "name=sql-onprem"
   docker logs sql-onprem
   ```

   Docker keeps container configuration locally, so this is for a development machine only, not a production credential pattern.

4. Make the backup accessible to the SQL Server service. For Docker, create a readable backup directory in the container and copy the file from the project folder:

   ```powershell
   $backup = (Resolve-Path '.\02_SQL_Server\Database_Backups\AdventureWorks2022.bak').Path
   docker exec sql-onprem mkdir -p /var/opt/mssql/backup
   docker cp $backup sql-onprem:/var/opt/mssql/backup/AdventureWorks2022.bak
   docker exec --user 0 sql-onprem chown mssql:mssql /var/opt/mssql/backup/AdventureWorks2022.bak
   ```

   If SQL Server is installed on Windows, copy the file to a directory readable by its service account instead. Connect with SSMS to the SQL endpoint (for the historical local setup, `localhost,1433`) and use the credential configured for that server.

5. In SSMS, run the following against the backup path as seen by SQL Server. For the Docker steps above, use `/var/opt/mssql/backup/AdventureWorks2022.bak`; for Windows SQL Server, use the Windows path to the copied file. Resolve every logical file name and file type from `RESTORE FILELISTONLY` before restoring:

   ```sql
   RESTORE VERIFYONLY
   FROM DISK = N'/var/opt/mssql/backup/AdventureWorks2022.bak';

   RESTORE FILELISTONLY
   FROM DISK = N'/var/opt/mssql/backup/AdventureWorks2022.bak';
   ```

   Stop if `VERIFYONLY` fails. If `AdventureWorks2022` already exists, do not overwrite it; confirm with its owner before taking any replacement action.

6. If the database is absent, restore it using the logical names from the previous result. Replace each placeholder with the actual logical name and a valid data/log path for the SQL Server host. For the Docker image above, use paths under `/var/opt/mssql/data/`; for Windows SQL Server, use the instance's data directory. Add one `MOVE` clause for every data or log file listed by `FILELISTONLY`. Do not add `WITH REPLACE`.

   ```sql
   RESTORE DATABASE [AdventureWorks2022]
   FROM DISK = N'/var/opt/mssql/backup/AdventureWorks2022.bak'
   WITH
       MOVE N'<logical-data-name>' TO N'/var/opt/mssql/data/AdventureWorks2022.mdf',
       MOVE N'<logical-log-name>'  TO N'/var/opt/mssql/data/AdventureWorks2022_log.ldf',
       RECOVERY,
       STATS = 5;
   ```

7. Verify the database is online and the four source tables are present. Compare counts with the historical run; a different count may simply mean the restored source snapshot differs.

   ```sql
   SELECT name, state_desc
   FROM sys.databases
   WHERE name = N'AdventureWorks2022';

   USE [AdventureWorks2022];
   GO

   SELECT N'Sales.Customer' AS SourceTable, COUNT_BIG(*) AS SourceRows
   FROM Sales.Customer
   UNION ALL
   SELECT N'Sales.SalesOrderHeader', COUNT_BIG(*) FROM Sales.SalesOrderHeader
   UNION ALL
   SELECT N'Sales.SalesOrderDetail', COUNT_BIG(*) FROM Sales.SalesOrderDetail
   UNION ALL
   SELECT N'Production.Product', COUNT_BIG(*) FROM Production.Product;
   ```

8. In SSMS, open and execute `02_SQL_Server/Database_Scripts/Project_ETL_Objects.sql` against `AdventureWorks2022`. It creates or updates the ETL schema, audit/control tables, and stored procedures, including the `FullLoadFileName` migration.

9. Execute `02_SQL_Server/Control_Tables/Seed_WatermarkControl.sql`. Confirm that four active rows exist and that their schemas, source tables, sink folders, baseline filenames, and load types are correct:

   ```sql
   SELECT TableName, SourceSchema, SourceTable, SinkFolder,
          FullLoadFileName, LoadType, LastWatermarkValue, IsActive
   FROM etl.WatermarkControl
   ORDER BY TableName;
   ```

   For a new empty Bronze container, the four rows must start as `Full`. The seed script intentionally preserves the load state and watermark of existing rows.

10. If this is a new, empty Bronze destination but the restored database has rows in `Incremental` state, first verify that replacing baseline files is intended. Temporarily set `@ConfirmBronzeReset = 1` in `02_SQL_Server/Control_Tables/Reset_WatermarkControl_For_Full_Load.sql`, execute it once, verify all four rows are `Full`, then restore the script's default value of `0`. The script fails by default as a safety check.

**Gate:** do not provision ingestion until the backup is verified/restored, the database is online, the ETL objects exist, and the four control rows match the intended source and Bronze destination.

## Phase 2: Create the Azure foundation

1. In the Azure portal, select the approved subscription and create or select the approved resource group and region. Inspect existing resources before reusing a group; the final contents of `rg-adventureworks-data-dev` and `Fabric_Azure_Workspace` were not confirmed.

2. Create an ADLS Gen2 storage account with hierarchical namespace enabled. In the Azure portal, select the approved redundancy and access tier; the historical configuration used Standard/LRS and Hot tier. Set TLS 1.2 minimum, disable anonymous access, and configure the approved soft-delete retention (historically seven days). Apply the target organization's network policy; public network access was enabled historically and should not be copied by default.

3. Create a filesystem/container named `bronze`. Record the full endpoint:

   ```text
   https://<storage-account>.dfs.core.windows.net
   ```

4. Create an Azure Data Factory in the same approved region and enable its system-assigned managed identity. In the storage account or `bronze` container, open **Access control (IAM)**, add a role assignment for **Storage Blob Data Contributor**, and select the Data Factory managed identity as the member. Use the narrowest approved scope and allow time for the role assignment to propagate.

5. In Data Factory Studio, open **Manage > Integration runtimes > New**, choose **Azure, Self-Hosted**, and name it `SHIR-AdventureWorks-Local`. Download and install the runtime on the approved Windows host, register it to this factory using the key shown in the setup flow, and confirm its status is **Running**. Never save the registration key in this project.

6. Confirm the SHIR host can reach SQL Server on TCP `1433` (or the configured port), resolve the SQL hostname, and authenticate to `AdventureWorks2022`. ADF cannot use `localhost` to reach a SQL Server on a different machine.

**Gate:** the storage filesystem exists, the Data Factory identity has write access, and the SHIR is online from a host that can reach SQL Server.

## Phase 3: Deploy and test ADF

1. Confirm the SQL endpoint, database, login, password/secret, and ADLS endpoint selected in the previous phases. The exported SQL linked service defaults to server `localhost`, database `AdventureWorks2022`, and login `sa`; `localhost` is correct only when SHIR and SQL Server are on the same host. The export also sets `encrypt` to `optional` and `trustServerCertificate` to `true`; review those values against the target security policy. If using a dedicated SQL login instead of the local `sa` account, grant it read access to the four source tables and control table plus execute access to the ETL procedures, then test both reads and procedure calls.

2. Deploy the standard ADF child-resource template from `01_Azure_Data_Factory/ARM_Templates/ARMTemplateForFactory.json` to the resource group containing the already-created factory. In the Azure portal, open **Deploy a custom template** at resource-group scope, load this template, and enter the target parameters below. Use `ARMTemplateParametersForFactory.json` as the parameter reference. The template creates pipelines, datasets, linked services, and the SHIR reference; it does not create the Data Factory resource itself.

   Supply these parameters for the target environment. `factoryName` must exactly match the Data Factory created in Phase 2:

   - `factoryName`
   - `LS_SQLServer_AdventureWorks_properties_typeProperties_server`
   - `LS_SQLServer_AdventureWorks_properties_typeProperties_database`
   - `LS_SQLServer_AdventureWorks_properties_typeProperties_userName`
   - `LS_SQLServer_AdventureWorks_password` (secure string)
   - `AzureDataLakeStorage1_properties_typeProperties_url`

   Enter the password only in the deployment's secure parameter field or approved secret integration. Do not put it in the checked-in parameter JSON. Use the root standard template/parameter pair; the `linkedTemplates/ArmTemplate_master.json` wrapper additionally requires a hosted nested-template URL and SAS token.

3. In ADF Studio, open **Manage > Linked services**. Edit the deployed `LS_SQLServer_AdventureWorks` and `AzureDataLakeStorage1` if necessary, then use **Test connection** for each. The SQL linked service must reference `SHIR-AdventureWorks-Local`; the ADLS linked service must use the Data Factory system-assigned identity and the selected storage endpoint.

4. Confirm that these objects are present and point to the selected endpoints: `PL_Copy_Customer_To_Bronze`, `PL_FullLoad_Product_To_Bronze`, `DS_SQL_WatermarkControl`, `DS_SQL_AdventureWorks_Source`, `DS_ADLS_AdventureWorks_Bronze`, `LS_SQLServer_AdventureWorks`, and `AzureDataLakeStorage1`.

5. Do not create a scheduled trigger yet. Trigger cadence, time zone, start date, and late-arriving-data policy have not been decided. Start each test run manually with **Add trigger > Trigger now** so it receives a run ID visible in **Monitor**.

6. Prefer a new, empty `bronze` filesystem for the first Full run. If reusing one, confirm the target baseline paths are empty; do not assume Copy will overwrite existing files. Run `PL_Copy_Customer_To_Bronze` once with all four control rows in `Full` state. In **Monitor**, confirm sequential `ForEach` processing and successful Copy, watermark, and audit activities for every table.

7. Confirm these baseline files exist in the `bronze` filesystem:

   | Table | Directory | File |
   |---|---|---|
   | Customer | `sales/customer/` | `customer.parquet` |
   | SalesOrderHeader | `sales/salesorderheader/` | `SalesOrderHeader.parquet` |
   | SalesOrderDetail | `sales/salesorderdetail/` | `SalesOrderDetail.parquet` |
   | Product | `production/product/` | `Product.parquet` |

   Check `etl.WatermarkControl`: each successful row should have an updated watermark and `LoadType = 'Incremental'`. Compare copied counts with the historical baseline (Customer 19,820; SalesOrderHeader 31,465; SalesOrderDetail 121,317; Product 504; total 173,106), allowing for a different source snapshot.

8. Run the same pipeline one more time in `Incremental` mode. It writes run-specific files such as `Customer_<RunId>.parquet` under each table's `incremental/` directory. The Silver notebook reads from these directories, so confirm each exists and contains Parquet output before proceeding. The inclusive `>=` watermark can re-copy rows at the maximum timestamp; investigate missing files or unexpected counts rather than skipping the check.

9. For every run, save the ADF run ID, per-table Copy rows, audit rows, and before/after watermark values. The recorded historical run `6cac908b-e9ba-422b-b243-00e7fc7bd56e` had a Customer mismatch (4 copied, 3 audited). `02_SQL_Server/Audit_Tables/Investigate_Incremental_Run.sql` contains that historical run ID and counts; update its run ID and recorded Copy counts before using it for a different run.

10. Test a controlled Copy failure only in a test environment. Confirm that the failure is audited and that the pipeline ends as **Failed**. Do not inject a failure into a production pipeline.

11. Test the watermark-update failure path in an isolated test environment. Confirm that the failure audit is written and the pipeline ends as **Failed**; do not alter procedures or permissions in a production database.

12. The primary metadata pipeline already loads Product. Skip `PL_FullLoad_Product_To_Bronze` unless specifically testing it against a clean, isolated destination. Both pipelines write to the Product baseline path, so do not run them against the same target at the same time.

**Gate:** all four baseline files and incremental directories are present, watermarks and audits are reconciled, and the failure path has been tested outside production.

## Phase 4: Create Databricks and Unity Catalog

1. Create the Databricks workspace only after approving the region, compute budget, and auto-termination settings. The historical cluster was a single `Standard_DS3_v2` node with Photon and ten-minute auto-termination; it was terminated before the workspace was deleted and is a reference, not a requirement.

2. In the Azure portal, create or select an Access Connector for Azure Databricks with a system-assigned managed identity. In the storage account or `bronze` container, use **Access control (IAM)** to grant that identity **Storage Blob Data Contributor** at the narrowest approved scope. This is separate from the Data Factory identity.

3. Confirm that a Unity Catalog metastore is assigned to the workspace. As an authorized catalog administrator, open **Catalog Explorer > Catalogs > Create catalog** and create or select `adb_adventureworks_dev`. Set or confirm its approved managed-storage location. Open `03_Databricks/Unity_Catalog/01_Create_Development_Schemas.sql` in the Databricks SQL editor and run it to create the `silver` and `gold` schemas.

4. In **Catalog Explorer > External Data > Credentials**, create a credential using the Azure managed identity and the Access Connector resource ID. Then create an external location using that credential and this URL:

   ```text
   abfss://bronze@<storage-account>.dfs.core.windows.net/
   ```

   Grant the notebook identity `READ FILES` on the external location and the required catalog/schema/table permissions (`USE CATALOG`, `USE SCHEMA`, and table creation/modification as needed). The catalog also needs an approved managed location for tables created by `saveAsTable`. Do not enable optional file events unless required and authorized; the historical setup returned 403 for file events.

5. If the storage account differs from `awdata2022`, update the `bronze_path` in the active notebooks `01_Bronze_Validation.ipynb` and `02_Silver_Transformations.ipynb`. If the catalog name differs, update the catalog references in the notebooks and Databricks SQL validation files as well.

6. In the workspace, open **Compute > Create compute**. Select a currently supported Databricks Runtime compatible with these PySpark notebooks, a node type approved for the subscription, and a single-node/small development configuration. The historical snapshot used Runtime `18.x`, `Standard_DS3_v2`, Photon, and ten-minute auto-termination; use those only if still available and approved. Enable auto-termination.

7. Import the active notebooks from `03_Databricks/Notebooks/` into a workspace folder using **Workspace > Import**: `01_Bronze_Validation.ipynb`, `02_Silver_Transformations.ipynb`, `03_Gold_Analytics.ipynb`, and `04_Spark_Performance_Lab.ipynb`. Do not use the archived `00_Original_Monolithic_Archive.ipynb` as a rebuild notebook. Attach the development compute to the imported notebooks.

8. Before running a notebook, verify access by listing the `bronze` filesystem from the notebook context. Do not run transformation cells until this succeeds.

**Gate:** the notebook identity can read all four Bronze folders, and it can create/use the intended Unity Catalog schemas and tables.

## Phase 5: Run notebooks and validate the layers

Run the active notebooks in this order:

1. `03_Databricks/Notebooks/01_Bronze_Validation.ipynb` — verify the filesystem and the Customer, SalesOrderHeader, SalesOrderDetail, and Product directories.
2. `03_Databricks/Notebooks/02_Silver_Transformations.ipynb` — build or merge Silver Delta tables. It reads both baseline Parquet files and the incremental directories; complete the ADF incremental pass first.
3. Check Silver row counts, primary-key uniqueness, duplicate handling, null/data-quality checks, and merge results before continuing.
4. `03_Databricks/Notebooks/03_Gold_Analytics.ipynb` — create Gold dimensions and facts from the Silver tables.
5. In Databricks SQL Editor, run `03_Databricks/SQL/Validate_Medallion_Record_Counts.sql`. It reports `PASS` or `FAIL` against historical counts; confirm all expected tables appear and investigate any `FAIL`. If the source snapshot differs, document the new expected counts rather than silently treating historical counts as current.
6. In Databricks SQL Editor, run `03_Databricks/SQL/Validate_Medallion_Keys_and_Relationships.sql`. Review each violation count; all checks should be zero unless an exception is understood and documented.
7. Reconcile Gold grain and aggregates. Historical counts were DimDate 1,139; DimCustomer 19,820; DimProduct 504; FactSalesLine 121,317; FactSalesOrder 31,465. FactSalesLine should have one row per order line; FactSalesOrder one row per order.
8. Run `03_Databricks/Notebooks/04_Spark_Performance_Lab.ipynb` separately, using its small synthetic-data default. Record the runtime/cluster, input sizes, plans, durations, row counts, and deviations. Skip its optional temporary-file experiment if the workspace disallows the path.

**Gate:** retain ADF run IDs and notebook/query results. Historical counts and performance results are comparisons, not evidence that the rebuilt source matches.

## Phase 6: Close design gaps before production use

The following items are not decided by the exported files and should not be guessed during a rebuild:

- ADF trigger type, cadence, time zone, and late-arriving-data policy.
- Watermark behavior for equal timestamps, retries, and late-arriving rows. The current `>=` boundary can re-read rows.
- Silver merge behavior for different payloads with equal `ModifiedDate`; the current `>` condition cannot detect those versions.
- Gold surrogate-key generation, persistence, fact mapping, SCD Type 1/2 attributes, and effective-date rules.
- The source/address join and actual province attribute needed for a province-change test.
- Source schema enforcement, rejected-row rules, quarantine location, access, and retention.
- Whether SQL Change Tracking or CDC is appropriate and how its retention/operational cost will be managed.

The current customer dimension does not contain customer names or address history. Do not invent a province field or resolve equal timestamps arbitrarily.

## Troubleshooting during the rebuild

| Symptom | Check |
|---|---|
| ADF cannot connect to SQL Server | Confirm SHIR is **Running**, the SQL hostname resolves from the SHIR host, TCP `1433` is open, and the linked service uses that hostname rather than `localhost` for a remote SQL Server. |
| ADF gets an ADLS authorization error | Confirm the Data Factory managed identity has `Storage Blob Data Contributor` on the correct storage scope and the linked service uses that identity. |
| Databricks gets a 403 or cannot list Bronze | Confirm the Access Connector identity's storage role, the storage credential/external location, and the notebook principal's `READ FILES` and catalog permissions. |
| Silver reports a missing Parquet path | Confirm the Full and Incremental ADF runs completed and that each table's baseline file and `incremental/` directory contain Parquet files. |
| Silver reports a missing variable such as `customer_latest` | Use the separate notebooks in the documented order. The original monolithic notebook is archived and is not the rebuild entry point. |
| Historical counts do not match | Compare the restored SQL source, ADF activity counts, and notebook counts. The recorded values are baselines from a prior run, not guaranteed counts for another backup. |

## Phase 7: Productionize and then begin Fabric

After the Azure rebuild is reproducible:

1. Establish source control, branch/PR review, secret handling, and repeatable deployment/teardown procedures.
2. Configure monitoring, alerts, operational logs, retries, recovery, permissions, row-level security, and governance.
3. Run an approved failure/recovery drill and document the outcome.
4. Begin the separate Fabric implementation: Data Factory, OneLake/Lakehouse, notebooks, Gold Warehouse/SQL analytics endpoint, semantic model, and Azure-versus-Fabric comparison.
5. Keep Kafka/Event Hubs experiments separate; they were supplementary learning, not part of the completed migration.

## Rebuild completion checklist

- [ ] Backup checksum recorded; `RESTORE VERIFYONLY` and database restore succeeded.
- [ ] ETL objects and four control rows verified; the intended initial `LoadType` is `Full`.
- [ ] Azure identities, storage access, SHIR, and both ADF linked-service tests passed.
- [ ] Full and incremental ADF runs completed; files, watermarks, and audit rows were checked.
- [ ] Copy-failure and watermark-failure paths were tested in an isolated environment.
- [ ] Silver and Gold notebooks completed; row counts, keys, relationships, and aggregates were reviewed.
- [ ] Remaining design decisions and unresolved differences were documented.
- [ ] No secrets, SHIR keys, or credentials were added to the project files.
