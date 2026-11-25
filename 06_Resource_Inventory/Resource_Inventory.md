# Resource inventory

I compiled this inventory from the project exports and records I have. It does not confirm that any cloud resource is currently deployed or reachable.

| Resource | Identifier / configuration | Source |
|---|---|---|
| Azure subscription | `Azure subscription 1`; Pay-As-You-Go; Owner access was recorded for the project. | Project notes |
| Azure region | South Africa North | Project notes |
| Azure Data Factory | `lehlogonoloramphisa-df`; exports include a metadata-driven Full/Incremental pipeline for four tables, separate full Product pipeline, no trigger. Its system-assigned identity accessed ADLS. The factory and `datafactory-rg892` were later reported deleted. | `01_Azure_Data_Factory/ARM_Templates/` and project notes |
| Azure Data Lake Storage Gen2 | `awdata2022`, container `bronze`; Standard/LRS, hierarchical namespace enabled, Hot tier, public network access enabled, anonymous access disabled, TLS 1.2 minimum, 7-day soft delete. The account was reported deleted. | ADF linked service, Databricks notebook, project notes |
| SQL Server database | SQL Server 2022 Developer, `AdventureWorks2022`; recorded ONLINE with 71 tables. Local Docker container `sql-onprem` and volume were reported retained. The historical ADF connection used `localhost:1433`, SQL Authentication, SHIR, and trust-server-certificate enabled. Credentials are not included. | SQL deployment script and project notes |
| Local development host | Windows 10; Docker 29.9.2, Compose 5.6.1, WSL2 Ubuntu, JDK 17. Docker/API setup was recorded as corrected. | Project notes |
| Self-hosted integration runtime | `SHIR-AdventureWorks-Local`; historical host `DESKTOP-JNF9DC3`; its connection was recorded as tested. The export directory contains no installable registration configuration. | `01_Azure_Data_Factory/Integration_Runtime/` and project notes |
| Databricks workspace | `adb-adventureworks-dev`, resource group `rg-adventureworks-data-dev`, South Africa North; the workspace was reported deleted. | Project notes |
| Databricks access connector | `ac-adb-adventureworks-dev`; its system-assigned identity historically had Storage Blob Data Contributor on `awdata2022`; the connector was reported deleted. | Project notes |
| Databricks storage access | Credential `cred_aw_adls_managed_identity`, external location `extloc_aw_bronze`, URL `abfss://bronze@awdata2022.dfs.core.windows.net/`; this is the historical setup, not an active connection. | Project notes |
| Databricks cluster profile | `adb-aw-pyspark-dev`; single node, `Standard_DS3_v2`, Photon, 10-minute auto-termination; export state `TERMINATED`. | `03_Databricks/Compute_Configuration/cluster-settings.json` |
| Databricks catalog | `adb_adventureworks_dev`, with referenced `silver` and `gold` schemas; schema creation script included, no grants or catalog provisioning included. | Databricks notebooks and `03_Databricks/Unity_Catalog/` |
| Historical cost control | The project used a 14-day Trial Premium DBU allocation and a $3 budget notification. The DBU trial did not cover VM costs, and the alert was not a spending cap. | Project notes |
| Resource groups requiring inspection | The final contents of `rg-adventureworks-data-dev` are unknown. `Fabric_Azure_Workspace` previously contained `surelink-source` and `surelink-sql-servers`; confirm their purpose before making changes. | Project notes |
| Local data snapshot | Bronze source Parquet plus Silver and Gold Parquet outputs. | `04_Data/` |
| SQL backup | `02_SQL_Server/Database_Backups/AdventureWorks2022.bak` is present, but its integrity and restore have not been verified. Project notes mention a ZIP backup, but none was found in the checked project root. | `02_SQL_Server/Database_Backups/` and project notes |
| Recorded incremental run | `6cac908b-e9ba-422b-b243-00e7fc7bd56e`; Customer Copy/audit counts differed (4 vs 3). | `05_Documentation/Testing_Results/` |
| Source primary keys / watermarks | Customer: `CustomerID` / `ModifiedDate`; SalesOrderHeader: `SalesOrderID` / `ModifiedDate`; SalesOrderDetail: composite `SalesOrderID, SalesOrderDetailID` / `ModifiedDate`; Product: `ProductID` / `ModifiedDate`. | Project notes |

Project records say the main Data Factory, storage account, Databricks workspace, Access Connector, and Data Factory resource group were deleted. The final state of `rg-adventureworks-data-dev` remains unconfirmed. `Fabric_Azure_Workspace` was reported to contain `surelink-source` and `surelink-sql-servers`; confirm their purpose before making changes. Exported cluster state, linked-service metadata, and resource names do not prove a live deployment. No passwords, keys, or tokens are included here.
