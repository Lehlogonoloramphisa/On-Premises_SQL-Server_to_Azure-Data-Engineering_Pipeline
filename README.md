# AdventureWorks Azure-to-Fabric migration project

Built a pipeline from local SQL Server through ADF and SHIR into ADLS Bronze, transformed the data in Databricks Silver and Gold, and recorded tests for each stage. The Azure environment was later deleted, so this backup brings together the project files and results from that work; the cloud tests have not been rerun during this local review.

## Project objective and architecture

The original objective was to build a traditional Azure data engineering platform and then migrate the solution to Microsoft Fabric. This is an Azure-to-Fabric migration project using a SQL Server transactional database.

### Original Azure platform

1. **Source system:** SQL Server 2022 with the `AdventureWorks2022` database.
2. **Ingestion and orchestration:** Azure Data Factory metadata-driven pipelines for full and incremental loads, using a Self-hosted Integration Runtime to reach local SQL Server.
3. **Storage:** Azure Data Lake Storage Gen2 Bronze layer with source data stored as Parquet files.
4. **Transformations:** Azure Databricks with PySpark and Delta Lake creates the Silver tables.
5. **Analytics:** The Gold layer provides dimensional models with fact and dimension tables.

### Future Microsoft Fabric migration

The planned target includes OneLake, a Lakehouse, a Warehouse, and Fabric Data Factory. The migration has not started; the [remaining-work backlog](05_Documentation/Project_Progress/Remaining_Work_Backlog.md) records the outstanding work.

![Project architecture diagram showing the historical SQL Server, ADF/SHIR, ADLS Bronze, and Databricks Silver/Gold flow](05_Documentation/Architecture/AdventureWorks_Azure_Data_Pipeline_Architecture.png)

## Project folders

| Folder | Contents |
|---|---|
| `01_Azure_Data_Factory` | ADF pipeline/dataset/linked-service exports, ARM templates, and runtime notes |
| `02_SQL_Server` | SQL ETL objects, watermark seed, audit diagnostics, and AdventureWorks backup |
| `03_Databricks` | Layer notebooks, cluster snapshot, Unity Catalog setup, and validation SQL |
| `04_Data` | Local Bronze, Silver, and Gold Parquet snapshots |
| `05_Documentation` | Architecture, testing evidence, lessons, troubleshooting, and follow-up work |
| `06_Resource_Inventory` | Historical resource names and cloud lifecycle status |

## Rebuild steps

The [step-by-step rebuild runbook](05_Documentation/Project_Progress/Rebuild_Runbook.md) takes the project from backup verification and local SQL restore through Azure/SHIR setup, ADF deployment and testing, Databricks/Unity Catalog setup, notebook execution, and validation. It also tracks the remaining modelling, production, and Fabric work.

Before rebuilding Azure, confirm the subscription, region, resource-group contents, access, cost controls, and deployment settings. No credentials or secrets are stored in this repository.

## Historical testing results

The historical ADF, Silver, Gold, Spark, and troubleshooting results are in [Testing_Results](05_Documentation/Testing_Results/). The Customer Copy/audit mismatch, inclusive watermark behavior, and equal-timestamp merge limitation remain open.
