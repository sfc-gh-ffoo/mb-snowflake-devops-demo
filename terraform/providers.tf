# =============================================================================
# MB SNOWFLAKE DEVOPS DEMO
# Terraform Provider Configuration
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.87.0"
    }
  }

  # Backend configuration for state management
  # In production, use Snowflake's internal stage or cloud storage
  backend "local" {
    path = "terraform.tfstate"
  }
}

# Snowflake Provider Configuration
# Credentials should be provided via environment variables:
# - SNOWFLAKE_ACCOUNT
# - SNOWFLAKE_USER
# - SNOWFLAKE_PASSWORD (or SNOWFLAKE_PRIVATE_KEY for key-pair auth)
# - SNOWFLAKE_ROLE
provider "snowflake" {
  role = var.snowflake_role
}

