USE [AdventureWorks2022];
GO

SET XACT_ABORT ON;
GO

-- New control rows start with a full load. A successful watermark update switches
-- them to incremental mode; the inclusive next watermark can re-read max-timestamp rows.
BEGIN TRANSACTION;

INSERT INTO etl.WatermarkControl
(
    TableName,
    WatermarkColumn,
    LastWatermarkValue,
    LoadType,
    IsActive,
    SourceSchema,
    SourceTable,
    SinkFolder,
    FullLoadFileName
)
SELECT
    seed.TableName,
    seed.WatermarkColumn,
    CONVERT(DATETIME2(3), '1900-01-01T00:00:00.000'),
    'Full',
    1,
    seed.SourceSchema,
    seed.SourceTable,
    seed.SinkFolder,
    seed.FullLoadFileName
FROM
(
    VALUES
        ('Customer', 'ModifiedDate', 'Sales', 'Customer', 'sales/customer', 'customer.parquet'),
        ('SalesOrderHeader', 'ModifiedDate', 'Sales', 'SalesOrderHeader', 'sales/salesorderheader', 'SalesOrderHeader.parquet'),
        ('SalesOrderDetail', 'ModifiedDate', 'Sales', 'SalesOrderDetail', 'sales/salesorderdetail', 'SalesOrderDetail.parquet'),
        ('Product', 'ModifiedDate', 'Production', 'Product', 'production/product', 'Product.parquet')
) AS seed(TableName, WatermarkColumn, SourceSchema, SourceTable, SinkFolder, FullLoadFileName)
WHERE NOT EXISTS
(
    SELECT 1
    FROM etl.WatermarkControl AS target
    WHERE target.TableName = seed.TableName
);

UPDATE target
SET
    FullLoadFileName = seed.FullLoadFileName,
    LastUpdated = SYSUTCDATETIME()
FROM etl.WatermarkControl AS target
INNER JOIN
(
    VALUES
        ('Customer', 'customer.parquet'),
        ('SalesOrderHeader', 'SalesOrderHeader.parquet'),
        ('SalesOrderDetail', 'SalesOrderDetail.parquet'),
        ('Product', 'Product.parquet')
) AS seed(TableName, FullLoadFileName)
    ON target.TableName = seed.TableName
WHERE target.FullLoadFileName IS NULL;

COMMIT TRANSACTION;
GO
