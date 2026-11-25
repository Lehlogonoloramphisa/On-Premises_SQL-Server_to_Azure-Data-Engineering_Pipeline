SELECT
    'Silver customer duplicate CustomerID groups' AS check_name,
    CAST(COUNT(*) AS BIGINT) AS violation_count
FROM
(
    SELECT CustomerID
    FROM adb_adventureworks_dev.silver.customer
    GROUP BY CustomerID
    HAVING CustomerID IS NULL OR COUNT(*) > 1
) AS violations

UNION ALL

SELECT
    'Silver salesorderheader duplicate or null SalesOrderID groups',
    CAST(COUNT(*) AS BIGINT)
FROM
(
    SELECT SalesOrderID
    FROM adb_adventureworks_dev.silver.salesorderheader
    GROUP BY SalesOrderID
    HAVING SalesOrderID IS NULL OR COUNT(*) > 1
) AS violations

UNION ALL

SELECT
    'Silver salesorderdetail duplicate or null composite-key groups',
    CAST(COUNT(*) AS BIGINT)
FROM
(
    SELECT SalesOrderID, SalesOrderDetailID
    FROM adb_adventureworks_dev.silver.salesorderdetail
    GROUP BY SalesOrderID, SalesOrderDetailID
    HAVING SalesOrderID IS NULL
        OR SalesOrderDetailID IS NULL
        OR COUNT(*) > 1
) AS violations

UNION ALL

SELECT
    'Silver product duplicate or null ProductID groups',
    CAST(COUNT(*) AS BIGINT)
FROM
(
    SELECT ProductID
    FROM adb_adventureworks_dev.silver.product
    GROUP BY ProductID
    HAVING ProductID IS NULL OR COUNT(*) > 1
) AS violations

UNION ALL

SELECT
    'Silver detail rows without a matching order',
    CAST(COUNT(*) AS BIGINT)
FROM adb_adventureworks_dev.silver.salesorderdetail AS detail
LEFT ANTI JOIN adb_adventureworks_dev.silver.salesorderheader AS header
    ON detail.SalesOrderID = header.SalesOrderID

UNION ALL

SELECT
    'Silver detail rows without a matching product',
    CAST(COUNT(*) AS BIGINT)
FROM adb_adventureworks_dev.silver.salesorderdetail AS detail
LEFT ANTI JOIN adb_adventureworks_dev.silver.product AS product
    ON detail.ProductID = product.ProductID

UNION ALL

SELECT
    'Silver orders without a matching customer',
    CAST(COUNT(*) AS BIGINT)
FROM adb_adventureworks_dev.silver.salesorderheader AS header
LEFT ANTI JOIN adb_adventureworks_dev.silver.customer AS customer
    ON header.CustomerID = customer.CustomerID

UNION ALL

SELECT
    'Gold FactSalesLine duplicate order-line keys',
    CAST(COUNT(*) AS BIGINT)
FROM
(
    SELECT SalesOrderID, SalesOrderDetailID
    FROM adb_adventureworks_dev.gold.fact_sales_line
    GROUP BY SalesOrderID, SalesOrderDetailID
    HAVING SalesOrderID IS NULL
        OR SalesOrderDetailID IS NULL
        OR COUNT(*) > 1
) AS violations

UNION ALL

SELECT
    'Gold FactSalesOrder duplicate or null SalesOrderID',
    CAST(COUNT(*) AS BIGINT)
FROM
(
    SELECT SalesOrderID
    FROM adb_adventureworks_dev.gold.fact_sales_order
    GROUP BY SalesOrderID
    HAVING SalesOrderID IS NULL OR COUNT(*) > 1
) AS violations;
