-- =============================================================================
-- MB SNOWFLAKE DEVOPS DEMO
-- Stored Procedure: Refresh Customer 360 View
-- Description: Builds/refreshes the Customer 360 analytical table
-- =============================================================================

CREATE OR REPLACE PROCEDURE MARTS.SP_REFRESH_CUSTOMER_360()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    v_start_time TIMESTAMP_NTZ;
    v_row_count INTEGER;
    v_message VARCHAR;
BEGIN
    v_start_time := CURRENT_TIMESTAMP();
    
    -- Log start
    SYSTEM$LOG_INFO('Starting Customer 360 refresh');
    
    -- Merge customer data with transaction aggregations
    MERGE INTO MARTS.CUSTOMER_360 tgt
    USING (
        SELECT 
            c.customer_id,
            c.customer_name,
            c.customer_type,
            c.segment,
            c.registration_date,
            DATEDIFF(day, c.registration_date, CURRENT_DATE()) AS tenure_days,
            c.status,
            c.risk_rating,
            COALESCE(txn.total_transactions, 0) AS total_transactions,
            COALESCE(txn.total_transaction_value, 0) AS total_transaction_value,
            COALESCE(txn.avg_transaction_value, 0) AS avg_transaction_value,
            txn.last_transaction_date,
            DATEDIFF(day, txn.last_transaction_date, CURRENT_DATE()) AS days_since_last_txn,
            txn.preferred_channel
        FROM TRANSFORMED.CUSTOMER_PROFILE c
        LEFT JOIN (
            SELECT 
                customer_id,
                COUNT(*) AS total_transactions,
                SUM(amount_myr) AS total_transaction_value,
                AVG(amount_myr) AS avg_transaction_value,
                MAX(transaction_date) AS last_transaction_date,
                -- Get most frequent channel
                (SELECT channel 
                 FROM TRANSFORMED.CUSTOMER_TRANSACTIONS t2 
                 WHERE t2.customer_id = t1.customer_id 
                 GROUP BY channel 
                 ORDER BY COUNT(*) DESC 
                 LIMIT 1) AS preferred_channel
            FROM TRANSFORMED.CUSTOMER_TRANSACTIONS t1
            GROUP BY customer_id
        ) txn ON c.customer_id = txn.customer_id
    ) src
    ON tgt.customer_id = src.customer_id
    WHEN MATCHED THEN UPDATE SET
        tgt.customer_name = src.customer_name,
        tgt.customer_type = src.customer_type,
        tgt.segment = src.segment,
        tgt.registration_date = src.registration_date,
        tgt.tenure_days = src.tenure_days,
        tgt.status = src.status,
        tgt.risk_rating = src.risk_rating,
        tgt.total_transactions = src.total_transactions,
        tgt.total_transaction_value = src.total_transaction_value,
        tgt.avg_transaction_value = src.avg_transaction_value,
        tgt.last_transaction_date = src.last_transaction_date,
        tgt.days_since_last_txn = src.days_since_last_txn,
        tgt.preferred_channel = src.preferred_channel,
        tgt.updated_at = CURRENT_TIMESTAMP()
    WHEN NOT MATCHED THEN INSERT (
        customer_id, customer_name, customer_type, segment, registration_date,
        tenure_days, status, risk_rating, total_transactions, total_transaction_value,
        avg_transaction_value, last_transaction_date, days_since_last_txn, preferred_channel
    ) VALUES (
        src.customer_id, src.customer_name, src.customer_type, src.segment, src.registration_date,
        src.tenure_days, src.status, src.risk_rating, src.total_transactions, src.total_transaction_value,
        src.avg_transaction_value, src.last_transaction_date, src.days_since_last_txn, src.preferred_channel
    );
    
    -- Get row count
    SELECT COUNT(*) INTO v_row_count FROM MARTS.CUSTOMER_360;
    
    v_message := 'Customer 360 refresh completed. Rows: ' || v_row_count::VARCHAR || 
                 '. Duration: ' || DATEDIFF(second, v_start_time, CURRENT_TIMESTAMP())::VARCHAR || ' seconds';
    
    SYSTEM$LOG_INFO(v_message);
    
    RETURN v_message;
END;
$$;

-- Grant execute permission
GRANT USAGE ON PROCEDURE MARTS.SP_REFRESH_CUSTOMER_360() TO ROLE {{ROLE_PREFIX}}_ENGINEER;

