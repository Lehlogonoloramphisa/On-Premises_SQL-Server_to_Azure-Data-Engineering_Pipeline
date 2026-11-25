WITH expected AS
(
    SELECT 'adb_adventureworks_dev.silver.customer' AS table_name, CAST(19820 AS BIGINT) AS expected_rows
    UNION ALL SELECT 'adb_adventureworks_dev.silver.salesorderheader', CAST(31465 AS BIGINT)
    UNION ALL SELECT 'adb_adventureworks_dev.silver.salesorderdetail', CAST(121317 AS BIGINT)
    UNION ALL SELECT 'adb_adventureworks_dev.silver.product', CAST(504 AS BIGINT)
    UNION ALL SELECT 'adb_adventureworks_dev.gold.dim_date', CAST(1139 AS BIGINT)
    UNION ALL SELECT 'adb_adventureworks_dev.gold.dim_customer', CAST(19820 AS BIGINT)
    UNION ALL SELECT 'adb_adventureworks_dev.gold.dim_product', CAST(504 AS BIGINT)
    UNION ALL SELECT 'adb_adventureworks_dev.gold.fact_sales_line', CAST(121317 AS BIGINT)
    UNION ALL SELECT 'adb_adventureworks_dev.gold.fact_sales_order', CAST(31465 AS BIGINT)
),
actual AS
(
    SELECT 'adb_adventureworks_dev.silver.customer' AS table_name, COUNT(*) AS actual_rows
    FROM adb_adventureworks_dev.silver.customer
    UNION ALL
    SELECT 'adb_adventureworks_dev.silver.salesorderheader', COUNT(*)
    FROM adb_adventureworks_dev.silver.salesorderheader
    UNION ALL
    SELECT 'adb_adventureworks_dev.silver.salesorderdetail', COUNT(*)
    FROM adb_adventureworks_dev.silver.salesorderdetail
    UNION ALL
    SELECT 'adb_adventureworks_dev.silver.product', COUNT(*)
    FROM adb_adventureworks_dev.silver.product
    UNION ALL
    SELECT 'adb_adventureworks_dev.gold.dim_date', COUNT(*)
    FROM adb_adventureworks_dev.gold.dim_date
    UNION ALL
    SELECT 'adb_adventureworks_dev.gold.dim_customer', COUNT(*)
    FROM adb_adventureworks_dev.gold.dim_customer
    UNION ALL
    SELECT 'adb_adventureworks_dev.gold.dim_product', COUNT(*)
    FROM adb_adventureworks_dev.gold.dim_product
    UNION ALL
    SELECT 'adb_adventureworks_dev.gold.fact_sales_line', COUNT(*)
    FROM adb_adventureworks_dev.gold.fact_sales_line
    UNION ALL
    SELECT 'adb_adventureworks_dev.gold.fact_sales_order', COUNT(*)
    FROM adb_adventureworks_dev.gold.fact_sales_order
)
SELECT
    expected.table_name,
    expected.expected_rows,
    actual.actual_rows,
    CASE
        WHEN expected.expected_rows = actual.actual_rows THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status
FROM expected
INNER JOIN actual
    ON actual.table_name = expected.table_name
ORDER BY expected.table_name;
