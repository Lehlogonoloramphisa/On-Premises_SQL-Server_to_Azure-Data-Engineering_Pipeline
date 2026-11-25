USE [AdventureWorks2022];
GO

SET XACT_ABORT ON;
GO

-- Set this to 1 only after verifying that the target Bronze folders are empty
-- or that replacing their full-load files is intended.
DECLARE @ConfirmBronzeReset BIT = 0;

IF @ConfirmBronzeReset <> 1
BEGIN
    ;THROW 51000, 'Confirm the Bronze reset before initializing full loads.', 1;
END;

IF EXISTS
(
    SELECT expected_tables.TableName
    FROM
    (
        VALUES
            ('Customer'),
            ('SalesOrderHeader'),
            ('SalesOrderDetail'),
            ('Product')
    ) AS expected_tables(TableName)
    LEFT JOIN etl.WatermarkControl AS configured
        ON configured.TableName = expected_tables.TableName
    WHERE configured.TableName IS NULL
)
BEGIN
    ;THROW 51001, 'Run Seed_WatermarkControl.sql before resetting full loads.', 1;
END;

BEGIN TRANSACTION;

UPDATE etl.WatermarkControl
SET
    LoadType = 'Full',
    LastWatermarkValue = CONVERT(DATETIME2(3), '1900-01-01T00:00:00.000'),
    FullLoadFileName = CASE TableName
        WHEN 'Customer' THEN 'customer.parquet'
        WHEN 'SalesOrderHeader' THEN 'SalesOrderHeader.parquet'
        WHEN 'SalesOrderDetail' THEN 'SalesOrderDetail.parquet'
        WHEN 'Product' THEN 'Product.parquet'
    END,
    LastUpdated = SYSUTCDATETIME()
WHERE TableName IN ('Customer', 'SalesOrderHeader', 'SalesOrderDetail', 'Product');

COMMIT TRANSACTION;
GO
