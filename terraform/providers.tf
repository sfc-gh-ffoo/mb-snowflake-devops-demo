# =============================================================================
# MB SNOWFLAKE DEVOPS DEMO
# Terraform Provider Configuration
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.97.0"
    }
  }

  # Backend configuration for state management
  # In production, use Snowflake's internal stage or cloud storage
  backend "local" {
    path = "terraform.tfstate"
  }
}

# Snowflake Provider Configuration
# =============================================================================
# Authentication via environment variables:
#
# Required for all methods:
#   export SNOWFLAKE_ACCOUNT="your_account"      # e.g., xy12345.us-east-1
#   export SNOWFLAKE_USER="your_user"
#
# Option 1: Key-Pair Authentication (Recommended)
#   export SNOWFLAKE_AUTHENTICATOR="JWT"
#   export SNOWFLAKE_PRIVATE_KEY_PATH="/absolute/path/to/rsa_key.p8"
#
# Option 2: Password Authentication
#   export SNOWFLAKE_PASSWORD="your_password"
#
# =============================================================================
provider "snowflake" {
  # Role is set via variable, other settings from environment variables
  role = var.snowflake_role
}

