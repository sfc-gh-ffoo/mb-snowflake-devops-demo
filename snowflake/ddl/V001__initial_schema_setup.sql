-- =============================================================================
-- MB SNOWFLAKE DEVOPS DEMO
-- Migration: V001 - Initial Schema Setup
-- Description: Creates base tables for the analytics platform
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Ensure Schemas Exist (idempotent)
-- -----------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS RAW COMMENT = 'Raw data landing zone';
CREATE SCHEMA IF NOT EXISTS TRANSFORMED COMMENT = 'Cleansed and validated data';
CREATE SCHEMA IF NOT EXISTS MARTS COMMENT = 'Business-ready data marts';

-- -----------------------------------------------------------------------------
-- RAW Schema - Landing Zone Tables
-- -----------------------------------------------------------------------------

-- Customer transactions landing table
CREATE TABLE IF NOT EXISTS RAW.CUSTOMER_TRANSACTIONS_RAW (
    record_id           VARCHAR(100),
    transaction_id      VARCHAR(50),
    customer_id         VARCHAR(50),
    transaction_date    VARCHAR(30),
    transaction_type    VARCHAR(20),
    amount              VARCHAR(50),
    currency            VARCHAR(10),
    merchant_name       VARCHAR(200),
    merchant_category   VARCHAR(100),
    channel             VARCHAR(50),
    status              VARCHAR(20),
    _load_timestamp     TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _source_file        VARCHAR(500),
    _batch_id           VARCHAR(100)
);

-- Customer profile landing table  
CREATE TABLE IF NOT EXISTS RAW.CUSTOMER_PROFILE_RAW (
    record_id           VARCHAR(100),
    customer_id         VARCHAR(50),
    customer_name       VARCHAR(200),
    customer_type       VARCHAR(50),
    segment             VARCHAR(50),
    registration_date   VARCHAR(30),
    status              VARCHAR(20),
    risk_rating         VARCHAR(20),
    _load_timestamp     TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _source_file        VARCHAR(500),
    _batch_id           VARCHAR(100)
);

-- -----------------------------------------------------------------------------
-- TRANSFORMED Schema - Cleansed and Validated Data
-- -----------------------------------------------------------------------------

-- Cleansed customer transactions
CREATE TABLE IF NOT EXISTS TRANSFORMED.CUSTOMER_TRANSACTIONS (
    transaction_id      VARCHAR(50) NOT NULL,
    customer_id         VARCHAR(50) NOT NULL,
    transaction_date    DATE NOT NULL,
    transaction_time    TIME,
    transaction_type    VARCHAR(20),
    amount              DECIMAL(18,2),
    currency            VARCHAR(10),
    amount_myr          DECIMAL(18,2),
    merchant_name       VARCHAR(200),
    merchant_category   VARCHAR(100),
    channel             VARCHAR(50),
    status              VARCHAR(20),
    is_valid            BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_transactions PRIMARY KEY (transaction_id)
);

-- Cleansed customer profile
CREATE TABLE IF NOT EXISTS TRANSFORMED.CUSTOMER_PROFILE (
    customer_id         VARCHAR(50) NOT NULL,
    customer_name       VARCHAR(200),
    customer_type       VARCHAR(50),
    segment             VARCHAR(50),
    registration_date   DATE,
    status              VARCHAR(20),
    risk_rating         VARCHAR(20),
    created_at          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_customer PRIMARY KEY (customer_id)
);

-- -----------------------------------------------------------------------------
-- MARTS Schema - Business-Ready Tables
-- -----------------------------------------------------------------------------

-- Daily transaction summary
CREATE TABLE IF NOT EXISTS MARTS.DAILY_TRANSACTION_SUMMARY (
    summary_date            DATE NOT NULL,
    customer_segment        VARCHAR(50),
    transaction_type        VARCHAR(20),
    channel                 VARCHAR(50),
    total_transactions      INTEGER,
    total_amount_myr        DECIMAL(18,2),
    avg_amount_myr          DECIMAL(18,2),
    unique_customers        INTEGER,
    created_at              TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_daily_summary PRIMARY KEY (summary_date, customer_segment, transaction_type, channel)
);

-- Customer 360 view table
CREATE TABLE IF NOT EXISTS MARTS.CUSTOMER_360 (
    customer_id             VARCHAR(50) NOT NULL,
    customer_name           VARCHAR(200),
    customer_type           VARCHAR(50),
    segment                 VARCHAR(50),
    registration_date       DATE,
    tenure_days             INTEGER,
    status                  VARCHAR(20),
    risk_rating             VARCHAR(20),
    total_transactions      INTEGER,
    total_transaction_value DECIMAL(18,2),
    avg_transaction_value   DECIMAL(18,2),
    last_transaction_date   DATE,
    days_since_last_txn     INTEGER,
    preferred_channel       VARCHAR(50),
    created_at              TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at              TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_customer_360 PRIMARY KEY (customer_id)
);

