# =============================================================================
# MB SNOWFLAKE DEVOPS DEMO
# Terraform Variables
# =============================================================================

# -----------------------------------------------------------------------------
# Environment Configuration
# -----------------------------------------------------------------------------
variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "mb_demo"
}

# -----------------------------------------------------------------------------
# Snowflake Connection
# -----------------------------------------------------------------------------
variable "snowflake_role" {
  description = "Snowflake role for Terraform operations"
  type        = string
  default     = "ACCOUNTADMIN"
}

variable "snowflake_private_key_path" {
  description = "Path to RSA private key for key-pair authentication (leave empty for password auth)"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Database Configuration
# -----------------------------------------------------------------------------
variable "databases" {
  description = "List of databases to create"
  type = list(object({
    name                        = string
    comment                     = string
    data_retention_time_in_days = number
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Warehouse Configuration
# -----------------------------------------------------------------------------
variable "warehouses" {
  description = "List of warehouses to create"
  type = list(object({
    name                = string
    size                = string
    auto_suspend        = number
    auto_resume         = bool
    min_cluster_count   = number
    max_cluster_count   = number
    scaling_policy      = string
    initially_suspended = bool
    resource_monitor    = string
    comment             = string
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Role Configuration
# -----------------------------------------------------------------------------
variable "roles" {
  description = "List of roles to create"
  type = list(object({
    name    = string
    comment = string
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Schema Configuration
# -----------------------------------------------------------------------------
variable "schemas" {
  description = "List of schemas to create"
  type = list(object({
    name     = string
    database = string
    comment  = string
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Tags for Resource Management
# -----------------------------------------------------------------------------
variable "tags" {
  description = "Tags for resource organization"
  type = object({
    project     = string
    environment = string
    owner       = string
    cost_center = string
  })
}

