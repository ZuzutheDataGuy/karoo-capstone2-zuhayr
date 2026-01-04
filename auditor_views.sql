/* =========================================================
   Supplier Health Monitoring View
   ========================================================= */

CREATE OR ALTER VIEW dbo.v_supplier_health AS
WITH cert_dates AS (
    SELECT
        c.supplier_id,
        DATEADD(YEAR, 1, c.issue_date) AS cert_expiry_date,
        ROW_NUMBER() OVER (
            PARTITION BY c.supplier_id
            ORDER BY c.issue_date DESC
        ) AS rn
    FROM dbo.Certifications c
),
order_activity AS (
    SELECT
        supplier_id,
        COUNT(*) AS orders_last_90d
    FROM dbo.Orders
    WHERE order_date >= DATEADD(DAY, -90, GETDATE())
    GROUP BY supplier_id
),
harvest_window AS (
    SELECT
        supplier_id,
        harvest_date,
        quantity_kg,
        AVG(quantity_kg) OVER (
            PARTITION BY supplier_id
            ORDER BY harvest_date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS rolling_avg_yield,
        ROW_NUMBER() OVER (
            PARTITION BY supplier_id
            ORDER BY harvest_date DESC
        ) AS rn
    FROM dbo.Harvest_Log
)

SELECT
    s.supplier_id,
    s.farm_name,
    s.region,

    CASE
        WHEN cd.cert_expiry_date IS NULL THEN 'Unknown'
        WHEN cd.cert_expiry_date < GETDATE() THEN 'Expired'
        WHEN cd.cert_expiry_date <= DATEADD(DAY, 30, GETDATE()) THEN 'Expiring Soon'
        ELSE 'Valid'
    END AS cert_status,

    COALESCE(o.orders_last_90d, 0) AS orders_90d,
    h.quantity_kg AS latest_yield,
    h.rolling_avg_yield

FROM dbo.Suppliers s
LEFT JOIN cert_dates cd
    ON s.supplier_id = cd.supplier_id AND cd.rn = 1
LEFT JOIN order_activity o
    ON s.supplier_id = o.supplier_id
LEFT JOIN harvest_window h
    ON s.supplier_id = h.supplier_id AND h.rn = 1;
GO


/* =========================================================
   Risk-Flagging Query
   ========================================================= */

SELECT *
FROM dbo.v_supplier_health
WHERE
    cert_status IN ('Expired', 'Expiring Soon')
    OR orders_90d = 0
    OR (
        latest_yield IS NOT NULL
        AND rolling_avg_yield IS NOT NULL
        AND latest_yield < rolling_avg_yield * 0.8
    );
