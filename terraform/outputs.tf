# =============================================================================
# MB SNOWFLAKE DEVOPS DEMO
# Terraform Outputs
# =============================================================================

output "databases" {
  description = "Created Snowflake databases"
  value = {
    for k, v in snowflake_database.databases : k => {
      name    = v.name
      comment = v.comment
    }
  }
}

output "warehouses" {
  description = "Created Snowflake warehouses"
  value = {
    for k, v in snowflake_warehouse.warehouses : k => {
      name = v.name
      size = v.warehouse_size
    }
  }
}

output "roles" {
  description = "Created Snowflake roles"
  value = {
    for k, v in snowflake_role.roles : k => {
      name = v.name
    }
  }
}

output "schemas" {
  description = "Created Snowflake schemas"
  value = {
    for k, v in snowflake_schema.schemas : k => {
      database = v.database
      name     = v.name
    }
  }
}

output "resource_monitor" {
  description = "Resource monitor for cost management"
  value = {
    name         = snowflake_resource_monitor.main.name
    credit_quota = snowflake_resource_monitor.main.credit_quota
  }
}

output "environment_summary" {
  description = "Summary of deployed environment"
  value = {
    environment    = var.environment
    project        = var.project_name
    database_count = length(snowflake_database.databases)
    schema_count   = length(snowflake_schema.schemas)
    warehouse_count = length(snowflake_warehouse.warehouses)
    role_count     = length(snowflake_role.roles)
  }
}

