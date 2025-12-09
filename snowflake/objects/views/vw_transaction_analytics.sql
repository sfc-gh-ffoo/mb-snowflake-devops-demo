-- =============================================================================
-- MB SNOWFLAKE DEVOPS DEMO
-- Views: Transaction Analytics
-- Description: Analytical views for transaction data
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Real-time Transaction Dashboard View
-- -----------------------------------------------------------------------------
CREATE OR REPLACE SECURE VIEW MARTS.VW_REALTIME_TRANSACTIONS AS
SELECT 
    transaction_id,
    customer_id,
    transaction_date,
    transaction_time,
    transaction_type,
    amount_myr,
    currency,
    merchant_name,
    merchant_category,
    channel,
    status,
    -- Time-based categorization
    CASE 
        WHEN transaction_time < '06:00:00' THEN 'Night (00:00-06:00)'
        WHEN transaction_time < '12:00:00' THEN 'Morning (06:00-12:00)'
        WHEN transaction_time < '18:00:00' THEN 'Afternoon (12:00-18:00)'
        ELSE 'Evening (18:00-24:00)'
    END AS time_period,
    -- Transaction size category
    CASE 
        WHEN amount_myr < 100 THEN 'Small (<100)'
        WHEN amount_myr < 1000 THEN 'Medium (100-1000)'
        WHEN amount_myr < 10000 THEN 'Large (1000-10000)'
        ELSE 'Very Large (>10000)'
    END AS transaction_size,
    created_at
FROM TRANSFORMED.CUSTOMER_TRANSACTIONS
WHERE transaction_date >= DATEADD(day, -30, CURRENT_DATE());

-- -----------------------------------------------------------------------------
-- Merchant Performance View
-- -----------------------------------------------------------------------------
CREATE OR REPLACE SECURE VIEW MARTS.VW_MERCHANT_PERFORMANCE AS
SELECT 
    merchant_category,
    merchant_name,
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(amount_myr) AS total_volume_myr,
    AVG(amount_myr) AS avg_transaction_myr,
    MIN(transaction_date) AS first_transaction,
    MAX(transaction_date) AS last_transaction
FROM TRANSFORMED.CUSTOMER_TRANSACTIONS
WHERE status = 'COMPLETED'
GROUP BY merchant_category, merchant_name;

-- -----------------------------------------------------------------------------
-- Customer Segmentation View
-- -----------------------------------------------------------------------------
CREATE OR REPLACE SECURE VIEW MARTS.VW_CUSTOMER_SEGMENTATION AS
SELECT 
    c.customer_id,
    c.segment AS original_segment,
    c.risk_rating,
    c.tenure_days,
    c.total_transactions,
    c.total_transaction_value,
    c.avg_transaction_value,
    c.days_since_last_txn,
    -- RFM Score Components
    CASE 
        WHEN c.days_since_last_txn <= 7 THEN 5
        WHEN c.days_since_last_txn <= 30 THEN 4
        WHEN c.days_since_last_txn <= 90 THEN 3
        WHEN c.days_since_last_txn <= 180 THEN 2
        ELSE 1
    END AS recency_score,
    CASE 
        WHEN c.total_transactions >= 100 THEN 5
        WHEN c.total_transactions >= 50 THEN 4
        WHEN c.total_transactions >= 20 THEN 3
        WHEN c.total_transactions >= 5 THEN 2
        ELSE 1
    END AS frequency_score,
    CASE 
        WHEN c.total_transaction_value >= 100000 THEN 5
        WHEN c.total_transaction_value >= 50000 THEN 4
        WHEN c.total_transaction_value >= 10000 THEN 3
        WHEN c.total_transaction_value >= 1000 THEN 2
        ELSE 1
    END AS monetary_score,
    -- Derived segment
    CASE 
        WHEN c.days_since_last_txn <= 30 AND c.total_transactions >= 50 AND c.total_transaction_value >= 50000 THEN 'Champions'
        WHEN c.days_since_last_txn <= 30 AND c.total_transactions >= 20 THEN 'Loyal Customers'
        WHEN c.days_since_last_txn <= 30 AND c.total_transactions < 5 THEN 'New Customers'
        WHEN c.days_since_last_txn > 90 AND c.total_transactions >= 20 THEN 'At Risk'
        WHEN c.days_since_last_txn > 180 THEN 'Dormant'
        ELSE 'Regular'
    END AS rfm_segment
FROM MARTS.CUSTOMER_360 c;

-- -----------------------------------------------------------------------------
-- Daily KPI View
-- -----------------------------------------------------------------------------
CREATE OR REPLACE SECURE VIEW MARTS.VW_DAILY_KPI AS
SELECT 
    summary_date,
    SUM(total_transactions) AS total_transactions,
    SUM(total_amount_myr) AS total_volume_myr,
    SUM(unique_customers) AS active_customers,
    SUM(total_amount_myr) / NULLIF(SUM(total_transactions), 0) AS avg_transaction_value,
    -- Year-over-year comparison
    LAG(SUM(total_transactions), 365) OVER (ORDER BY summary_date) AS yoy_transactions,
    LAG(SUM(total_amount_myr), 365) OVER (ORDER BY summary_date) AS yoy_volume,
    -- Week-over-week comparison  
    LAG(SUM(total_transactions), 7) OVER (ORDER BY summary_date) AS wow_transactions,
    LAG(SUM(total_amount_myr), 7) OVER (ORDER BY summary_date) AS wow_volume
FROM MARTS.DAILY_TRANSACTION_SUMMARY
GROUP BY summary_date
ORDER BY summary_date DESC

-- Demo change
