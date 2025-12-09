# =============================================================================
# MB SNOWFLAKE DEVOPS DEMO
# Main Terraform Configuration
# =============================================================================

locals {
  name_prefix = upper("${var.project_name}_${var.environment}")
}

# -----------------------------------------------------------------------------
# Databases
# -----------------------------------------------------------------------------
resource "snowflake_database" "databases" {
  for_each = { for db in var.databases : db.name => db }

  name                        = "${local.name_prefix}_${upper(each.value.name)}"
  comment                     = each.value.comment
  data_retention_time_in_days = each.value.data_retention_time_in_days
}

# -----------------------------------------------------------------------------
# Schemas
# -----------------------------------------------------------------------------
resource "snowflake_schema" "schemas" {
  for_each = { for schema in var.schemas : "${schema.database}_${schema.name}" => schema }

  database = snowflake_database.databases[each.value.database].name
  name     = upper(each.value.name)
  comment  = each.value.comment

  depends_on = [snowflake_database.databases]
}

# -----------------------------------------------------------------------------
# Warehouses
# -----------------------------------------------------------------------------
resource "snowflake_warehouse" "warehouses" {
  for_each = { for wh in var.warehouses : wh.name => wh }

  name                = "${local.name_prefix}_${upper(each.value.name)}_WH"
  warehouse_size      = each.value.size
  auto_suspend        = each.value.auto_suspend
  auto_resume         = each.value.auto_resume
  min_cluster_count   = each.value.min_cluster_count
  max_cluster_count   = each.value.max_cluster_count
  scaling_policy      = each.value.scaling_policy
  initially_suspended = each.value.initially_suspended
  comment             = each.value.comment
}

# -----------------------------------------------------------------------------
# Roles (using account_role for newer provider versions)
# -----------------------------------------------------------------------------
resource "snowflake_account_role" "roles" {
  for_each = { for role in var.roles : role.name => role }

  name    = "${local.name_prefix}_${upper(each.value.name)}"
  comment = each.value.comment
}

# -----------------------------------------------------------------------------
# Role Grants - Database Access
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "database_usage" {
  for_each = { for role in var.roles : role.name => role }

  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.roles[each.key].name
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.databases["analytics"].name
  }

  depends_on = [snowflake_account_role.roles, snowflake_database.databases]
}

# -----------------------------------------------------------------------------
# Role Grants - Warehouse Access
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "warehouse_usage" {
  for_each = { for role in var.roles : role.name => role }

  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.roles[each.key].name
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.warehouses["analytics"].name
  }

  depends_on = [snowflake_account_role.roles, snowflake_warehouse.warehouses]
}

# -----------------------------------------------------------------------------
# Resource Monitor for Cost Management
# -----------------------------------------------------------------------------
resource "snowflake_resource_monitor" "main" {
  name         = "${local.name_prefix}_MONITOR"
  credit_quota = var.environment == "prod" ? 1000 : 100

  frequency       = "MONTHLY"
  start_timestamp = "IMMEDIATELY"

  notify_triggers           = [75, 90, 100]
  suspend_trigger           = 100
  suspend_immediate_trigger = 110

  notify_users = []
}

# Test
