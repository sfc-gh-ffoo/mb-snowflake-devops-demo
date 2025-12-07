# =============================================================================
# MB SNOWFLAKE DEVOPS DEMO
# Development Environment Configuration
# =============================================================================

environment  = "dev"
project_name = "mb_demo"

# -----------------------------------------------------------------------------
# Databases
# -----------------------------------------------------------------------------
databases = [
  {
    name                        = "analytics"
    comment                     = "Analytics database for development"
    data_retention_time_in_days = 1
  },
  {
    name                        = "staging"
    comment                     = "Staging area for data ingestion"
    data_retention_time_in_days = 1
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
# Warehouses - Smaller sizes for dev
# -----------------------------------------------------------------------------
warehouses = [
  {
    name                = "analytics"
    size                = "XSMALL"
    auto_suspend        = 60
    auto_resume         = true
    min_cluster_count   = 1
    max_cluster_count   = 1
    scaling_policy      = "STANDARD"
    initially_suspended = true
    resource_monitor    = ""
    comment             = "Analytics workload warehouse"
  },
  {
    name                = "etl"
    size                = "XSMALL"
    auto_suspend        = 60
    auto_resume         = true
    min_cluster_count   = 1
    max_cluster_count   = 1
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
  environment = "development"
  owner       = "devops-team"
  cost_center = "IT-001"
}

