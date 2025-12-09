-- =============================================================================
-- MB SNOWFLAKE DEVOPS DEMO
-- Migration: V002 - Create Streams and Tasks for CDC
-- Description: Sets up change data capture and automated processing
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Streams for Change Data Capture
-- -----------------------------------------------------------------------------

-- Stream on raw transactions for CDC
CREATE STREAM IF NOT EXISTS RAW.TRANSACTIONS_STREAM 
    ON TABLE RAW.CUSTOMER_TRANSACTIONS_RAW
    APPEND_ONLY = FALSE
    SHOW_INITIAL_ROWS = FALSE;

-- Stream on raw customer profiles for CDC
CREATE STREAM IF NOT EXISTS RAW.CUSTOMER_PROFILE_STREAM
    ON TABLE RAW.CUSTOMER_PROFILE_RAW
    APPEND_ONLY = FALSE
    SHOW_INITIAL_ROWS = FALSE;

-- -----------------------------------------------------------------------------
-- Tasks for Automated Processing
-- -----------------------------------------------------------------------------

-- Task to process new transactions from stream
CREATE OR REPLACE TASK TRANSFORMED.PROCESS_TRANSACTIONS_TASK
    WAREHOUSE = '{{WAREHOUSE_NAME}}'
    SCHEDULE = '5 MINUTE'
    ALLOW_OVERLAPPING_EXECUTION = FALSE
    WHEN SYSTEM$STREAM_HAS_DATA('RAW.TRANSACTIONS_STREAM')
AS
    MERGE INTO TRANSFORMED.CUSTOMER_TRANSACTIONS tgt
    USING (
        SELECT DISTINCT
            transaction_id,
            customer_id,
            TRY_TO_DATE(transaction_date, 'YYYY-MM-DD') AS transaction_date,
            TRY_TO_TIME(SUBSTR(transaction_date, 12, 8)) AS transaction_time,
            transaction_type,
            TRY_TO_DECIMAL(amount, 18, 2) AS amount,
            currency,
            CASE 
                WHEN currency = 'MYR' THEN TRY_TO_DECIMAL(amount, 18, 2)
                WHEN currency = 'USD' THEN TRY_TO_DECIMAL(amount, 18, 2) * 4.47
                WHEN currency = 'SGD' THEN TRY_TO_DECIMAL(amount, 18, 2) * 3.31
                ELSE TRY_TO_DECIMAL(amount, 18, 2)
            END AS amount_myr,
            merchant_name,
            merchant_category,
            channel,
            status,
            TRUE AS is_valid
        FROM RAW.TRANSACTIONS_STREAM
        WHERE METADATA$ACTION = 'INSERT'
    ) src
    ON tgt.transaction_id = src.transaction_id
    WHEN MATCHED THEN UPDATE SET
        tgt.amount = src.amount,
        tgt.status = src.status,
        tgt.updated_at = CURRENT_TIMESTAMP()
    WHEN NOT MATCHED THEN INSERT (
        transaction_id, customer_id, transaction_date, transaction_time,
        transaction_type, amount, currency, amount_myr, merchant_name,
        merchant_category, channel, status, is_valid
    ) VALUES (
        src.transaction_id, src.customer_id, src.transaction_date, src.transaction_time,
        src.transaction_type, src.amount, src.currency, src.amount_myr, src.merchant_name,
        src.merchant_category, src.channel, src.status, src.is_valid
    );

-- Task to update daily summary (runs after transaction processing)
-- Note: Must be in same schema as predecessor task
CREATE OR REPLACE TASK TRANSFORMED.UPDATE_DAILY_SUMMARY_TASK
    WAREHOUSE = '{{WAREHOUSE_NAME}}'
    AFTER TRANSFORMED.PROCESS_TRANSACTIONS_TASK
AS
    MERGE INTO MARTS.DAILY_TRANSACTION_SUMMARY tgt
    USING (
        SELECT 
            t.transaction_date AS summary_date,
            COALESCE(c.segment, 'UNKNOWN') AS customer_segment,
            t.transaction_type,
            t.channel,
            COUNT(*) AS total_transactions,
            SUM(t.amount_myr) AS total_amount_myr,
            AVG(t.amount_myr) AS avg_amount_myr,
            COUNT(DISTINCT t.customer_id) AS unique_customers
        FROM TRANSFORMED.CUSTOMER_TRANSACTIONS t
        LEFT JOIN TRANSFORMED.CUSTOMER_PROFILE c ON t.customer_id = c.customer_id
        WHERE t.transaction_date >= DATEADD(day, -7, CURRENT_DATE())
        GROUP BY 1, 2, 3, 4
    ) src
    ON tgt.summary_date = src.summary_date 
        AND tgt.customer_segment = src.customer_segment
        AND tgt.transaction_type = src.transaction_type
        AND tgt.channel = src.channel
    WHEN MATCHED THEN UPDATE SET
        tgt.total_transactions = src.total_transactions,
        tgt.total_amount_myr = src.total_amount_myr,
        tgt.avg_amount_myr = src.avg_amount_myr,
        tgt.unique_customers = src.unique_customers,
        tgt.created_at = CURRENT_TIMESTAMP()
    WHEN NOT MATCHED THEN INSERT (
        summary_date, customer_segment, transaction_type, channel,
        total_transactions, total_amount_myr, avg_amount_myr, unique_customers
    ) VALUES (
        src.summary_date, src.customer_segment, src.transaction_type, src.channel,
        src.total_transactions, src.total_amount_myr, src.avg_amount_myr, src.unique_customers
    )
