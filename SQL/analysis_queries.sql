-- ============================================================
-- Amazon Warehouse Analytics - Analysis Queries
-- Covers: KPIs, Delivery, Inventory, Employees, Returns
-- ============================================================

-- ════════════════════════════════════════════════════════════
-- SECTION 1: EXECUTIVE KPI SUMMARY
-- ════════════════════════════════════════════════════════════

-- 1.1  Top-level business metrics
SELECT
    COUNT(DISTINCT order_id)                               AS total_orders,
    COUNT(DISTINCT customer_id)                            AS unique_customers,
    ROUND(SUM(revenue), 2)                                 AS total_revenue,
    ROUND(AVG(revenue), 2)                                 AS avg_order_value,
    ROUND(AVG(processing_time_hours), 2)                   AS avg_processing_hours,
    ROUND(SUM(on_time_delivery) * 100.0 / COUNT(*), 2)    AS on_time_delivery_pct,
    SUM(CASE WHEN order_status = 'Cancelled' THEN 1 END)   AS cancelled_orders,
    SUM(CASE WHEN order_status = 'Returned'  THEN 1 END)   AS returned_orders
FROM orders;

-- 1.2  Monthly revenue trend with MoM growth
WITH monthly AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m')       AS month,
        ROUND(SUM(revenue), 2)                 AS monthly_revenue,
        COUNT(*)                               AS order_count
    FROM orders
    GROUP BY 1
)
SELECT
    month,
    monthly_revenue,
    order_count,
    LAG(monthly_revenue) OVER (ORDER BY month)    AS prev_month_revenue,
    ROUND(
        (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month))
        * 100.0 / NULLIF(LAG(monthly_revenue) OVER (ORDER BY month), 0)
    , 2)                                           AS mom_growth_pct
FROM monthly
ORDER BY month;

-- ════════════════════════════════════════════════════════════
-- SECTION 2: DELIVERY PERFORMANCE
-- ════════════════════════════════════════════════════════════

-- 2.1  On-time delivery rate by region and sales channel
SELECT
    region,
    sales_channel,
    COUNT(*)                                            AS total_orders,
    SUM(on_time_delivery)                               AS on_time,
    ROUND(SUM(on_time_delivery) * 100.0 / COUNT(*), 2) AS on_time_pct,
    ROUND(AVG(processing_time_hours), 2)                AS avg_processing_hrs
FROM orders
GROUP BY region, sales_channel
ORDER BY on_time_pct DESC;

-- 2.2  Delivery delay distribution (days late)
SELECT
    DATEDIFF(delivery_date, promised_delivery_date) AS days_late,
    COUNT(*)                                        AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_orders
FROM orders
WHERE on_time_delivery = 0
GROUP BY 1
ORDER BY 1;

-- 2.3  Worst-performing months for on-time delivery
SELECT
    DATE_FORMAT(order_date, '%Y-%m')                    AS month,
    COUNT(*)                                            AS total_orders,
    ROUND(SUM(on_time_delivery) * 100.0 / COUNT(*), 2) AS on_time_pct
FROM orders
GROUP BY 1
ORDER BY on_time_pct ASC
LIMIT 10;

-- ════════════════════════════════════════════════════════════
-- SECTION 3: REVENUE & PRODUCT ANALYSIS
-- ════════════════════════════════════════════════════════════

-- 3.1  Revenue by category with profit margin
SELECT
    p.category,
    COUNT(DISTINCT o.order_id)         AS total_orders,
    SUM(o.quantity)                    AS units_sold,
    ROUND(SUM(o.revenue), 2)           AS total_revenue,
    ROUND(SUM(o.quantity * p.unit_cost), 2) AS total_cost,
    ROUND(SUM(o.revenue) - SUM(o.quantity * p.unit_cost), 2) AS gross_profit,
    ROUND(
        (SUM(o.revenue) - SUM(o.quantity * p.unit_cost))
        * 100.0 / NULLIF(SUM(o.revenue), 0)
    , 2)                               AS margin_pct
FROM orders o
JOIN products p ON o.product_id = p.product_id
WHERE o.order_status NOT IN ('Cancelled')
GROUP BY p.category
ORDER BY total_revenue DESC;

-- 3.2  Top 20 products by revenue (with CTE)
WITH product_revenue AS (
    SELECT
        o.product_id,
        p.product_name,
        p.category,
        p.rating,
        COUNT(DISTINCT o.order_id)   AS orders,
        SUM(o.quantity)              AS units_sold,
        ROUND(SUM(o.revenue), 2)     AS revenue,
        RANK() OVER (ORDER BY SUM(o.revenue) DESC) AS revenue_rank
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    WHERE o.order_status NOT IN ('Cancelled')
    GROUP BY o.product_id, p.product_name, p.category, p.rating
)
SELECT * FROM product_revenue
WHERE revenue_rank <= 20
ORDER BY revenue_rank;

-- 3.3  Revenue contribution by region (Pareto analysis)
WITH region_rev AS (
    SELECT
        region,
        ROUND(SUM(revenue), 2) AS revenue
    FROM orders
    WHERE order_status NOT IN ('Cancelled')
    GROUP BY region
),
cumulative AS (
    SELECT
        region,
        revenue,
        SUM(revenue) OVER (ORDER BY revenue DESC) AS cum_revenue,
        SUM(revenue) OVER ()                       AS total_revenue
    FROM region_rev
)
SELECT
    region,
    revenue,
    ROUND(revenue * 100.0 / total_revenue, 2)     AS revenue_pct,
    ROUND(cum_revenue * 100.0 / total_revenue, 2) AS cumulative_pct
FROM cumulative
ORDER BY revenue DESC;

-- ════════════════════════════════════════════════════════════
-- SECTION 4: INVENTORY MANAGEMENT
-- ════════════════════════════════════════════════════════════

-- 4.1  Inventory health across warehouses
SELECT
    warehouse_id,
    COUNT(*)                                         AS sku_count,
    SUM(CASE WHEN stock_status = 'In Stock'    THEN 1 END) AS in_stock,
    SUM(CASE WHEN stock_status = 'Low Stock'   THEN 1 END) AS low_stock,
    SUM(CASE WHEN stock_status = 'Out of Stock' THEN 1 END) AS out_of_stock,
    ROUND(AVG(stock_quantity), 0)                    AS avg_stock_qty,
    SUM(stock_quantity)                              AS total_units
FROM inventory
GROUP BY warehouse_id
ORDER BY warehouse_id;

-- 4.2  Inventory turnover rate (orders / avg stock)
SELECT
    i.warehouse_id,
    p.category,
    SUM(o.quantity)                                   AS units_sold,
    AVG(i.stock_quantity)                             AS avg_stock,
    ROUND(SUM(o.quantity) / NULLIF(AVG(i.stock_quantity), 0), 2) AS turnover_rate
FROM inventory i
JOIN products p  ON i.product_id  = p.product_id
JOIN orders   o  ON o.product_id  = i.product_id
WHERE o.order_status NOT IN ('Cancelled', 'Returned')
GROUP BY i.warehouse_id, p.category
ORDER BY turnover_rate DESC;

-- 4.3  Items below reorder level that need restocking
SELECT
    i.product_id,
    p.product_name,
    p.category,
    i.warehouse_id,
    i.stock_quantity,
    i.reorder_level,
    i.reorder_level - i.stock_quantity AS shortage,
    i.last_restock_date,
    DATEDIFF(CURDATE(), i.last_restock_date) AS days_since_restock
FROM inventory i
JOIN products p ON i.product_id = p.product_id
WHERE i.stock_quantity < i.reorder_level
ORDER BY shortage DESC
LIMIT 50;

-- 4.4  Overstock items (stock > 90% of max level)
SELECT
    i.product_id,
    p.product_name,
    i.warehouse_id,
    i.stock_quantity,
    i.max_stock_level,
    ROUND(i.stock_quantity * 100.0 / i.max_stock_level, 1) AS utilization_pct,
    i.days_in_stock
FROM inventory i
JOIN products p ON i.product_id = p.product_id
WHERE i.stock_quantity > i.max_stock_level * 0.90
ORDER BY utilization_pct DESC
LIMIT 50;

-- ════════════════════════════════════════════════════════════
-- SECTION 5: EMPLOYEE PRODUCTIVITY
-- ════════════════════════════════════════════════════════════

-- 5.1  Employee performance leaderboard (window function)
SELECT
    e.employee_id,
    e.employee_name,
    e.role,
    e.warehouse_id,
    e.shift,
    e.orders_handled,
    ROUND(e.error_rate * 100, 3)      AS error_rate_pct,
    ROUND(e.attendance_rate * 100, 1) AS attendance_pct,
    e.performance_score,
    RANK() OVER (PARTITION BY e.warehouse_id ORDER BY e.performance_score DESC) AS rank_in_wh,
    RANK() OVER (ORDER BY e.performance_score DESC)                              AS overall_rank
FROM employees e
ORDER BY overall_rank
LIMIT 30;

-- 5.2  Orders processed per employee with productivity tier
WITH emp_stats AS (
    SELECT
        e.employee_id,
        e.employee_name,
        e.role,
        e.shift,
        COUNT(o.order_id)              AS orders_processed,
        ROUND(AVG(o.processing_time_hours), 2) AS avg_processing_hrs,
        ROUND(AVG(o.on_time_delivery) * 100, 2) AS on_time_pct
    FROM employees e
    JOIN orders o ON e.employee_id = o.employee_id
    GROUP BY e.employee_id, e.employee_name, e.role, e.shift
)
SELECT
    *,
    CASE
        WHEN orders_processed >= PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY orders_processed) OVER ()
             THEN 'High Performer'
        WHEN orders_processed >= PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY orders_processed) OVER ()
             THEN 'Average Performer'
        ELSE 'Needs Improvement'
    END AS performance_tier
FROM emp_stats
ORDER BY orders_processed DESC;

-- 5.3  Shift-wise productivity comparison
SELECT
    e.shift,
    COUNT(DISTINCT e.employee_id)              AS employees,
    COUNT(o.order_id)                          AS total_orders,
    ROUND(COUNT(o.order_id) / COUNT(DISTINCT e.employee_id), 0) AS orders_per_employee,
    ROUND(AVG(o.processing_time_hours), 2)     AS avg_processing_hrs,
    ROUND(AVG(o.on_time_delivery) * 100, 2)    AS on_time_pct
FROM employees e
JOIN orders o ON e.employee_id = o.employee_id
GROUP BY e.shift
ORDER BY orders_per_employee DESC;

-- ════════════════════════════════════════════════════════════
-- SECTION 6: RETURNS ANALYSIS
-- ════════════════════════════════════════════════════════════

-- 6.1  Return rate by category
SELECT
    p.category,
    COUNT(DISTINCT o.order_id)  AS total_orders,
    COUNT(DISTINCT r.return_id) AS total_returns,
    ROUND(COUNT(DISTINCT r.return_id) * 100.0 / COUNT(DISTINCT o.order_id), 2) AS return_rate_pct,
    ROUND(SUM(r.refund_amount), 2)   AS total_refunded,
    ROUND(AVG(r.refund_amount), 2)   AS avg_refund
FROM orders   o
JOIN products p  ON o.product_id = p.product_id
LEFT JOIN returns r ON o.order_id  = r.order_id
GROUP BY p.category
ORDER BY return_rate_pct DESC;

-- 6.2  Top return reasons and financial impact
SELECT
    return_reason,
    COUNT(*)                       AS return_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_returns,
    ROUND(SUM(refund_amount), 2)   AS total_refund,
    ROUND(AVG(refund_amount), 2)   AS avg_refund,
    ROUND(SUM(restocking_fee), 2)  AS total_restocking_fees
FROM returns
GROUP BY return_reason
ORDER BY return_count DESC;

-- 6.3  Monthly return trend vs. orders
WITH monthly_orders AS (
    SELECT DATE_FORMAT(order_date, '%Y-%m') AS month, COUNT(*) AS orders
    FROM orders GROUP BY 1
),
monthly_returns AS (
    SELECT DATE_FORMAT(return_date, '%Y-%m') AS month, COUNT(*) AS returns,
           ROUND(SUM(refund_amount), 2) AS refund_total
    FROM returns GROUP BY 1
)
SELECT
    mo.month,
    mo.orders,
    COALESCE(mr.returns, 0)      AS returns,
    COALESCE(mr.refund_total, 0) AS refund_total,
    ROUND(COALESCE(mr.returns, 0) * 100.0 / mo.orders, 2) AS return_rate_pct
FROM monthly_orders mo
LEFT JOIN monthly_returns mr ON mo.month = mr.month
ORDER BY mo.month;

-- ════════════════════════════════════════════════════════════
-- SECTION 7: ADVANCED - CTE + WINDOW FUNCTIONS
-- ════════════════════════════════════════════════════════════

-- 7.1  Running total revenue with 7-day moving average
WITH daily_revenue AS (
    SELECT
        order_date,
        ROUND(SUM(revenue), 2)  AS daily_rev,
        COUNT(*)                AS daily_orders
    FROM orders
    WHERE order_status NOT IN ('Cancelled')
    GROUP BY order_date
)
SELECT
    order_date,
    daily_rev,
    daily_orders,
    SUM(daily_rev) OVER (ORDER BY order_date)                   AS running_total,
    ROUND(AVG(daily_rev) OVER (
        ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2)                                                         AS moving_avg_7d
FROM daily_revenue
ORDER BY order_date;

-- 7.2  Customer segmentation by order value (RFM-lite)
WITH customer_stats AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id)           AS frequency,
        ROUND(SUM(revenue), 2)             AS monetary,
        MAX(order_date)                    AS last_order_date,
        DATEDIFF(CURDATE(), MAX(order_date)) AS recency_days
    FROM orders
    WHERE order_status NOT IN ('Cancelled')
    GROUP BY customer_id
)
SELECT
    customer_id,
    frequency,
    monetary,
    recency_days,
    CASE
        WHEN recency_days <= 30  AND frequency >= 5 AND monetary >= 1000 THEN 'Champion'
        WHEN recency_days <= 60  AND frequency >= 3                       THEN 'Loyal'
        WHEN recency_days <= 90                                           THEN 'Potential'
        WHEN recency_days  > 180 AND frequency = 1                       THEN 'Lost'
        ELSE 'At Risk'
    END AS customer_segment
FROM customer_stats
ORDER BY monetary DESC;

-- 7.3  Warehouse efficiency scorecard (composite metric)
WITH wh_metrics AS (
    SELECT
        e.warehouse_id,
        COUNT(DISTINCT e.employee_id)                         AS headcount,
        COUNT(DISTINCT o.order_id)                            AS orders_processed,
        ROUND(AVG(o.processing_time_hours), 2)                AS avg_processing_hrs,
        ROUND(SUM(o.on_time_delivery)*100.0/COUNT(o.order_id), 2) AS on_time_pct,
        ROUND(AVG(e.performance_score), 2)                    AS avg_emp_score,
        ROUND(AVG(e.error_rate) * 100, 3)                     AS avg_error_rate_pct
    FROM employees e
    JOIN orders o ON e.employee_id = o.employee_id
    GROUP BY e.warehouse_id
)
SELECT
    *,
    ROUND(
        (on_time_pct * 0.4) +
        (avg_emp_score * 10 * 0.3) +
        ((1 - avg_error_rate_pct / 100) * 100 * 0.3)
    , 2) AS efficiency_score
FROM wh_metrics
ORDER BY efficiency_score DESC;
