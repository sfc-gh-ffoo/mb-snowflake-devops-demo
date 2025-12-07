# =============================================================================
# MB SNOWFLAKE DEVOPS DEMO
# Production Environment Configuration
# =============================================================================

environment  = "prod"
project_name = "mb_demo"

# -----------------------------------------------------------------------------
# Databases
# -----------------------------------------------------------------------------
databases = [
  {
    name                        = "analytics"
    comment                     = "Analytics database for production"
    data_retention_time_in_days = 90
  },
  {
    name                        = "staging"
    comment                     = "Staging area for data ingestion"
    data_retention_time_in_days = 30
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
# Warehouses - Production sizes with auto-scaling
# -----------------------------------------------------------------------------
warehouses = [
  {
    name                = "analytics"
    size                = "MEDIUM"
    auto_suspend        = 300
    auto_resume         = true
    min_cluster_count   = 1
    max_cluster_count   = 4
    scaling_policy      = "STANDARD"
    initially_suspended = true
    resource_monitor    = ""
    comment             = "Analytics workload warehouse - Production"
  },
  {
    name                = "etl"
    size                = "LARGE"
    auto_suspend        = 300
    auto_resume         = true
    min_cluster_count   = 1
    max_cluster_count   = 3
    scaling_policy      = "ECONOMY"
    initially_suspended = true
    resource_monitor    = ""
    comment             = "ETL processing warehouse - Production"
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
  environment = "production"
  owner       = "devops-team"
  cost_center = "IT-001"
}

