# =============================================================================
# MB SNOWFLAKE DEVOPS DEMO
# Staging Environment Configuration
# =============================================================================

environment  = "staging"
project_name = "mb_demo"

# -----------------------------------------------------------------------------
# Databases
# -----------------------------------------------------------------------------
databases = [
  {
    name                        = "analytics"
    comment                     = "Analytics database for staging"
    data_retention_time_in_days = 7
  },
  {
    name                        = "staging"
    comment                     = "Staging area for data ingestion"
    data_retention_time_in_days = 3
  }
]

# -----------------------------------------------------------------------------
# Schemas
# -----------------------------------------------------------------------------
schemas = [
  {
    name     = "raw"
    database = "analytics"
    comment  = "Raw data landing zone"
  },
  {
    name     = "transformed"
    database = "analytics"
    comment  = "Transformed data layer"
  },
  {
    name     = "marts"
    database = "analytics"
    comment  = "Business data marts"
  }
]

# -----------------------------------------------------------------------------
# Warehouses - Medium sizes for staging
# -----------------------------------------------------------------------------
warehouses = [
  {
    name                = "analytics"
    size                = "SMALL"
    auto_suspend        = 120
    auto_resume         = true
    min_cluster_count   = 1
    max_cluster_count   = 3
    scaling_policy      = "STANDARD"
    initially_suspended = true
    resource_monitor    = ""
    comment             = "Analytics workload warehouse - Updated for CI/CD test"
  },
  {
    name                = "etl"
    size                = "SMALL"
    auto_suspend        = 120
    auto_resume         = true
    min_cluster_count   = 1
    max_cluster_count   = 2
    scaling_policy      = "STANDARD"
    initially_suspended = true
    resource_monitor    = ""
    comment             = "ETL processing warehouse"
  }
]

# -----------------------------------------------------------------------------
# Roles
# -----------------------------------------------------------------------------
roles = [
  {
    name    = "analyst"
    comment = "Read-only analyst role"
  },
  {
    name    = "engineer"
    comment = "Data engineering role"
  },
  {
    name    = "admin"
    comment = "Administrative role"
  }
]

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
tags = {
  project     = "mb-snowflake-demo"
  environment = "staging"
  owner       = "devops-team"
  cost_center = "IT-001"
}

