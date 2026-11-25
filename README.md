# AdventureWorks Azure-to-Fabric Migration Project

Built a data engineering pipeline from a local SQL Server database through Azure Data Factory and Self-hosted Integration Runtime into Azure Data Lake Storage Gen2. The data was processed in Azure Databricks using PySpark and Delta Lake, then organised into Silver and Gold layers for analytical use.

The project demonstrates metadata-driven ingestion, full and incremental loading, data validation, dimensional modelling and Spark SQL investigation.

The original Azure environment was deleted after the project backup to avoid ongoing cloud costs. This repository preserves the implementation files, exported data, configuration details and historical test results. 

## Project Objectives

- Build a traditional Azure data engineering platform.
- Extract data from an on-premises SQL Server database.
- Implement metadata-driven ingestion using Azure Data Factory.
- Store raw data in Azure Data Lake Storage Gen2.
- Transform and validate data using Azure Databricks and PySpark.
- Implement Bronze, Silver and Gold data layers.
- Build fact and dimension tables for analytical workloads.
- Investigate incremental loading and Delta Lake MERGE operations.
- Analyse Spark SQL execution plans and query behaviour.
- Migrate the architecture to Microsoft Fabric.
- Compare the traditional Azure implementation with the Fabric architecture.

## Project Architecture

### Original Azure Platform

1. **Source system:** SQL Server 2022 with the `AdventureWorks2022` database, running locally in Docker.
2. **Ingestion and orchestration:** Azure Data Factory metadata-driven pipelines for full and incremental loads.
3. **Connectivity:** Self-hosted Integration Runtime connects Azure Data Factory to the local SQL Server instance.
4. **Storage:** Azure Data Lake Storage Gen2 stores raw source data in the Bronze layer using Parquet.
5. **Transformation:** Azure Databricks uses PySpark and Delta Lake to clean, validate and transform data into Silver tables.
6. **Analytics:** The Gold layer contains fact and dimension tables designed for analytical queries.

### Architecture Flow

```text
Local SQL Server
AdventureWorks2022
        |
        v
Self-hosted Integration Runtime
        |
        v
Azure Data Factory
Metadata-driven ingestion
Full and incremental loads
        |
        v
Azure Data Lake Storage Gen2
        |
        v
Bronze Layer
Raw Parquet files
        |
        v
Azure Databricks
PySpark and Spark SQL
        |
        v
Silver Layer
Cleaned and validated Delta tables
        |
        v
Gold Layer
Fact and dimension tables
        |
        v
Analytical queries and reporting
```

![Project architecture diagram showing the historical SQL Server, ADF/SHIR, ADLS Bronze, and Databricks Silver/Gold flow](05_Documentation/Architecture/AdventureWorks_Azure_Data_Pipeline_Architecture.png)

### Planned Microsoft Fabric Migration

The target architecture uses Microsoft Fabric to consolidate data ingestion, storage, processing and analytics.

Planned components:

- Fabric Data Factory for pipeline orchestration.
- OneLake for centralised data storage.
- Fabric Lakehouse for Bronze, Silver and Gold layers.
- Fabric Notebooks for PySpark transformations.
- Fabric Spark for distributed processing.
- Fabric Warehouse for SQL-based analytics.
- SQL Analytics Endpoint for querying Lakehouse tables.
- Power BI and Semantic Models for reporting.
- OneLake Shortcuts for accessing external data.

The Fabric migration has not started. The [Remaining Work Backlog](05_Documentation/Project_Progress/Remaining_Work_Backlog.md) records the outstanding tasks.

## Technology Stack

### Technologies Used

| Technology | Purpose |
|---|---|
| SQL Server 2022 | Local transactional source database |
| Docker Desktop | Runs the local SQL Server environment |
| SQL Server Management Studio | Database administration, SQL development and backup |
| Azure Data Factory | Pipeline orchestration and data ingestion |
| Self-hosted Integration Runtime | Connects ADF to local SQL Server |
| Azure Data Lake Storage Gen2 | Stores Bronze data |
| Azure Databricks | Data processing environment |
| Apache Spark | Distributed data processing |
| PySpark | Data cleaning, validation and transformation |
| Spark SQL | Analytical queries and execution plan investigation |
| Delta Lake | Transactional storage for Silver and Gold tables |
| Unity Catalog | Databricks data governance and access management |
| Azure Managed Identity | Authenticates Databricks access to ADLS |
| Python | Data processing and automation |
| SQL / T-SQL | Queries, stored procedures and validation |
| Parquet | Columnar data storage |
| Azure Storage Explorer | Data Lake file management and backup |
| PowerShell | Local administration and backup checks |

### Planned Fabric and Production Tools

| Technology | Planned purpose |
|---|---|
| Microsoft Fabric | Target data engineering platform |
| Fabric Data Factory | Pipeline orchestration |
| OneLake | Centralised storage |
| Fabric Lakehouse | Medallion architecture |
| Fabric Notebooks | PySpark transformations |
| Fabric Warehouse | SQL analytical workloads |
| Power BI | Reporting and visualisation |
| Semantic Models | Business measures and relationships |
| Git and GitHub | Version control |
| GitHub Actions or Azure DevOps | CI/CD automation |
| Azure Key Vault | Secrets management |
| Microsoft Entra ID | Identity and access management |
| Azure Monitor | Resource monitoring |
| Log Analytics | Log investigation |
| Microsoft Purview | Data governance and lineage |

## Data Source

The project uses the AdventureWorks2022 sample database running on SQL Server 2022 Developer Edition in a local Docker container.

The database contains 71 tables across several schemas, including Sales, Production, Person, HumanResources and Purchasing.

The initial ingestion scope included four tables:

| Source table | Initial row count |
|---|---:|
| Sales.Customer | 19,820 |
| Sales.SalesOrderHeader | 31,465 |
| Sales.SalesOrderDetail | 121,317 |
| Production.Product | 504 |
| **Total** | **173,106** |

## Azure Data Factory Implementation

### Metadata-Driven Ingestion

Azure Data Factory was used to build a metadata-driven ingestion process.

Rather than creating a separate pipeline for every source table, the pipeline reads configuration records from a SQL Server control table and uses the metadata to determine which tables to process.

The control table is:

`etl.WatermarkControl`

Its configuration fields include:

- TableName
- SourceSchema
- SourceTable
- WatermarkColumn
- LastWatermarkValue
- LoadType
- SinkFolder
- IsActive

The pipeline uses this metadata to identify active tables, construct source queries and determine destination folders in ADLS Gen2.

### Pipelines

**`PL_Copy_Customer_To_Bronze`**

The main metadata-driven pipeline contains:

1. Lookup to retrieve active table metadata.
2. Sequential ForEach to process configured tables.
3. Dynamic Copy activity to extract SQL Server data.
4. Parquet output to the Bronze container.
5. Watermark update after successful copying.
6. Audit logging for pipeline execution.

**`PL_FullLoad_Product_To_Bronze`**

A separate pipeline performs a full load of the Production.Product table.

### Supporting SQL Objects

- `etl.WatermarkControl`
- `etl.LoadAudit`
- `etl.usp_UpdateWatermark`
- `etl.usp_InsertLoadAudit`

These objects support pipeline configuration, watermark management and execution auditing.

### Incremental Loading

The ingestion process uses a watermark column such as `ModifiedDate` to identify records for extraction.

The implementation uses a greater-than-or-equal-to watermark condition. This helps account for records sharing timestamps, but it also introduces the possibility of reprocessing records.

The current approach requires further improvement to provide more reliable change detection.

## Bronze Layer

The Bronze layer stores raw data extracted from SQL Server.

| Property | Implementation |
|---|---|
| Storage | Azure Data Lake Storage Gen2 |
| File format | Parquet |
| Source | AdventureWorks2022 |
| Ingestion | Azure Data Factory |
| Organisation | Table-based destination folders |

The Bronze layer preserves extracted source data before applying transformation logic.

## Silver Layer

Azure Databricks and PySpark were used to clean, validate and transform the Bronze data.

Catalog: `adb_adventureworks_dev`

Schema: `silver`

| Table | Row count |
|---|---:|
| customer | 19,820 |
| salesorderheader | 31,465 |
| salesorderdetail | 121,317 |
| product | 504 |
| **Total** | **173,106** |

### Transformations and Validation

The Silver implementation includes:

- Reading raw Parquet files.
- Cleaning and standardising data.
- Deduplicating records using business keys and ModifiedDate ordering.
- Checking primary key uniqueness.
- Performing null and data quality checks.
- Creating managed Delta tables.
- Testing incremental MERGE operations.

The Product table was used to demonstrate incremental updates and inserts through Delta MERGE.

Customer, SalesOrderHeader and SalesOrderDetail MERGE tests were no-op runs because the source records matched the existing baseline.

The relevant recorded data quality checks reported zero issues.

## Gold Layer

The Gold layer contains analytical fact and dimension tables.

Catalog: `adb_adventureworks_dev`

Schema: `gold`

### Dimension Tables

| Table | Row count |
|---|---:|
| dim_date | 1,139 |
| dim_customer | 19,820 |
| dim_product | 504 |

### Fact Tables

| Table | Grain | Row count |
|---|---|---:|
| fact_sales_line | One row per SalesOrderID and SalesOrderDetailID | 121,317 |
| fact_sales_order | One row per SalesOrderID | 31,465 |

### Data Modelling

The Gold layer follows a dimensional modelling approach.

The implementation includes:

- Date dimension.
- Customer dimension.
- Product dimension.
- Sales line fact table.
- Sales order fact table.
- Relationships between fact and dimension tables.
- Date keys for order, due and shipment dates.
- Aggregated sales analysis.

Validation included fact table grain, dimension relationships, date keys, foreign keys and sales aggregations against the source data.

Natural keys were used in the current implementation. Surrogate keys and practical SCD Type 1 and Type 2 implementation remain outstanding.

## Spark SQL and Performance Investigation

The project includes investigation of Spark SQL execution plans and query behaviour.

Topics explored:

- SQL aggregations.
- Window functions.
- Common Table Expressions.
- Subqueries.
- Temporary views.
- Join strategies.
- Shuffle operations.
- Partitioning.
- Adaptive Query Execution.
- Broadcast joins.
- Sort-merge joins.
- Delta Lake optimisation concepts.

### Recorded Observations

| Gold table | File count | Approximate size |
|---|---:|---:|
| fact_sales_line | 1 | 1,091,205 bytes |
| fact_sales_order | 1 | 448,828 bytes |

A monthly sales query showed a Photon Broadcast Hash Join, column pruning and partial and final aggregation.

Replacing `COUNT(DISTINCT SalesOrderID)` with `COUNT(*)` on the one-row-per-order fact table produced the same 38 monthly result rows.

The recorded query job took approximately 0.1 seconds, with two tasks, approximately 11.4 KiB of input and approximately 5 KiB of shuffle data.

A separate SalesOrderHeader and SalesOrderDetail query showed a Sort-Merge Join and shuffle exchanges on both sides. Adaptive Query Execution coalesced the 200 initial shuffle partitions to one partition per side.

These observations come from a relatively small dataset and do not represent production-scale performance benchmarks.

## Historical Testing Results

Historical ADF, Silver, Gold, Spark and troubleshooting results are stored in [Testing Results](05_Documentation/Testing_Results/).

### Azure Data Factory

| Test | Result |
|---|---|
| SQL Server linked service | Passed |
| ADLS Gen2 linked service | Passed |
| Self-hosted Integration Runtime | Passed |
| Metadata Lookup | Passed |
| Sequential ForEach | Passed |
| Dynamic Copy activity | Passed |
| Watermark update procedure | Passed |
| Audit procedure execution | Passed |
| Initial full load | Completed |
| Incremental load | Completed |

Initial full-load ingestion processed 173,106 records across four tables.

A later incremental run used:

`6cac908b-e9ba-422b-b243-00e7fc7bd56e`

| Table | Copy activity rows |
|---|---:|
| SalesOrderHeader | 40 |
| SalesOrderDetail | 96 |
| Customer | 4 |
| Product | 1 |

A discrepancy remains between the Customer Copy activity count of four and the audit table count of three.

### Databricks and Silver

Validation included:

- Initial Silver table row counts.
- Primary key uniqueness.
- Null and data quality checks.
- Deduplication.
- Delta table creation.
- Incremental MERGE testing.
- Product update and insert testing.

The recorded Silver row counts totalled 173,106.

### Gold Validation

Validation included:

- Fact table grain.
- Dimension relationships.
- Date key relationships.
- Foreign key checks.
- Sales aggregations.
- Monthly sales.
- Top products.
- Top customers.

Aggregated results were reconciled against the source data.

### Known Technical Limitations

1. The current watermark strategy uses `>=`, which may reprocess records sharing timestamps.
2. Silver MERGE logic based on `ModifiedDate` does not reliably detect every change when timestamps are identical.
3. The Customer Copy activity and audit count discrepancy remains unresolved.
4. A comprehensive data quarantine framework has not been implemented.
5. Surrogate keys and practical SCD Type 1 and Type 2 logic remain outstanding.
6. Large-scale performance testing has not been performed.
7. Delta optimisation and small-file experiments remain incomplete.
8. The Fabric migration has not started.

## Project Status

| Phase | Description | Status |
|---|---|---|
| 1 | Azure Data Factory and metadata-driven ingestion | Core implementation completed |
| 2 | Databricks Bronze and Silver processing | Core implementation completed |
| 3 | Gold dimensional modelling | Partially completed |
| 4 | Spark SQL and performance investigation | Partially completed |
| 5 | Microsoft Fabric migration | Not started |
| 6 | Production readiness and deployment | Partially completed |

## Remaining Work

### Data Engineering

- Improve incremental change detection.
- Investigate SQL Server Change Tracking and CDC.
- Expand ingestion to additional source tables.
- Implement surrogate keys.
- Implement SCD Type 1 and Type 2.
- Add row hashing for change detection.
- Build a data quarantine and error-handling framework.
- Compare Parquet and Delta Lake behaviour.
- Test Delta schema enforcement and time travel.

### Spark Optimisation

- Compare broadcast and sort-merge joins.
- Investigate data skew.
- Test repartition and coalesce.
- Measure shuffle behaviour.
- Test caching.
- Investigate small-file problems.
- Compare Delta OPTIMIZE and Z-ORDER.
- Record before-and-after performance metrics.

### Microsoft Fabric Migration

- Recreate ingestion pipelines using Fabric Data Factory.
- Build Bronze, Silver and Gold Lakehouse layers.
- Migrate PySpark notebooks.
- Compare Databricks and Fabric Spark environments.
- Explore OneLake Shortcuts.
- Build a Fabric Warehouse or SQL-based Gold layer.
- Create semantic models.
- Connect Power BI reports.
- Document migration differences and lessons learned.

### Production Readiness

- Organise the project using Git branches.
- Implement automated testing and deployment.
- Configure monitoring and logging.
- Test retry and failure-handling processes.
- Document troubleshooting and root cause analysis.
- Review identity, permissions and data access.
- Explore data governance and lineage.

## Backup and Azure Resource Cleanup

The Azure environment was removed after the backup process to avoid ongoing cloud costs.

The backup includes exported pipeline definitions, linked service and dataset configurations, SQL scripts, a database backup, Databricks notebooks, exported Silver and Gold data, architecture documentation and resource configuration details.

The local SQL Server Docker container and its data volume were retained.

The Azure services described in this README are historical project resources. They must be recreated before continuing the cloud implementation.

See the [Rebuild Runbook](05_Documentation/Project_Progress/Rebuild_Runbook.md) for the restoration and setup process.

## Project Folder Overview

| Folder | Contents |
|---|---|
| `01_Azure_Data_Factory` | ADF pipeline, dataset and linked service exports, ARM templates and runtime notes |
| `02_SQL_Server` | SQL ETL objects, watermark seed, audit diagnostics and AdventureWorks backup |
| `03_Databricks` | Layer notebooks, cluster snapshot, Unity Catalog setup and validation SQL |
| `04_Data` | Local Bronze, Silver and Gold Parquet snapshots |
| `05_Documentation` | Architecture, testing evidence, lessons, troubleshooting and remaining work |
| `06_Resource_Inventory` | Historical resource names and cloud lifecycle status |

## Rebuild Steps

The [Step-by-Step Rebuild Runbook](05_Documentation/Project_Progress/Rebuild_Runbook.md) covers:

1. Backup verification.
2. Local SQL Server restoration.
3. Azure resource setup.
4. Self-hosted Integration Runtime configuration.
5. Azure Data Factory deployment and testing.
6. Databricks and Unity Catalog setup.
7. Notebook execution.
8. Data validation.
9. Remaining modelling, production and Fabric migration work.

Before rebuilding Azure, confirm the subscription, region, resource group contents, access permissions, cost controls and deployment settings.

No credentials or secrets are stored in this repository.

## Repository Structure

This tree reflects the files in this backup. Fabric services are described as a future target; there is no Fabric implementation folder in the repository.

```text
Azure_Fabric_Migration_Project_Backup/
├── .gitattributes
├── README.md
├── 01_Azure_Data_Factory/
│   ├── ARM_Templates/
│   │   ├── factory/
│   │   └── linkedTemplates/
│   ├── Datasets/
│   ├── Integration_Runtime/
│   ├── Linked_Services/
│   ├── Pipelines/
│   │   ├── PL_Copy_Customer_To_Bronze_support_live/
│   │   └── PL_FullLoad_Product_To_Bronze_support_live/
│   └── Triggers/
├── 02_SQL_Server/
│   ├── Audit_Tables/
│   ├── Control_Tables/
│   ├── Database_Backups/
│   ├── Database_Scripts/
│   └── Stored_Procedures/
├── 03_Databricks/
│   ├── Compute_Configuration/
│   ├── Configuration/
│   ├── Notebooks/
│   ├── SQL/
│   └── Unity_Catalog/
├── 04_Data/
│   ├── Bronze/
│   │   ├── production/product/
│   │   │   └── incremental/
│   │   └── sales/
│   │       ├── customer/incremental/
│   │       ├── salesorderdetail/incremental/
│   │       └── salesorderheader/incremental/
│   ├── Silver/
│   │   ├── customer/
│   │   ├── product/
│   │   ├── salesorderdetail/
│   │   └── salesorderheader/
│   └── Gold/
│       ├── dim_customer/
│       ├── dim_date/
│       ├── dim_product/
│       ├── fact_sales_line/
│       └── fact_sales_order/
├── 05_Documentation/
│   ├── Architecture/
│   ├── Lessons/
│   ├── Project_Progress/
│   ├── Testing_Results/
│   └── Troubleshooting/
└── 06_Resource_Inventory/
```