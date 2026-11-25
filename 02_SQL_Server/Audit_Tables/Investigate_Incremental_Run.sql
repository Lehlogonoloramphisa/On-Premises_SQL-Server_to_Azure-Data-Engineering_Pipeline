USE [AdventureWorks2022];
GO

DECLARE @PipelineRunID UNIQUEIDENTIFIER =
    '6cac908b-e9ba-422b-b243-00e7fc7bd56e';

WITH CopyActivityRows AS
(
    SELECT TableName, CopyRows
    FROM
    (
        VALUES
            ('SalesOrderHeader', CONVERT(BIGINT, 40)),
            ('SalesOrderDetail', CONVERT(BIGINT, 96)),
            ('Customer', CONVERT(BIGINT, 4)),
            ('Product', CONVERT(BIGINT, 1))
    ) AS recorded(TableName, CopyRows)
),
AuditRows AS
(
    SELECT
        TableName,
        COUNT_BIG(*) AS AuditRecordCount,
        SUM(ExtractedRecords) AS AuditedRows,
        SUM(CASE WHEN LoadStatus = 'Succeeded' THEN 1 ELSE 0 END) AS SuccessRecords,
        SUM(CASE WHEN LoadStatus = 'Failed' THEN 1 ELSE 0 END) AS FailureRecords
    FROM etl.LoadAudit
    WHERE PipelineRunID = @PipelineRunID
    GROUP BY TableName
)
SELECT
    @PipelineRunID AS PipelineRunID,
    copy.TableName,
    copy.CopyRows AS RecordedCopyActivityRows,
    COALESCE(audit.AuditedRows, 0) AS AuditedRows,
    COALESCE(audit.AuditRecordCount, 0) AS AuditRecordCount,
    COALESCE(audit.SuccessRecords, 0) AS SuccessRecords,
    COALESCE(audit.FailureRecords, 0) AS FailureRecords,
    copy.CopyRows - COALESCE(audit.AuditedRows, 0) AS CopyMinusAuditRows
FROM CopyActivityRows AS copy
LEFT JOIN AuditRows AS audit
    ON audit.TableName = copy.TableName
ORDER BY copy.TableName;
GO
