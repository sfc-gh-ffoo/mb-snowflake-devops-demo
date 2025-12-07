# Mb Snowflake DevOps Demo - Detailed Setup Guide

This guide walks you through the complete setup of the Mb Snowflake DevOps Demo, from prerequisites to full deployment.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Snowflake Account Setup](#2-snowflake-account-setup)
3. [Local Development Setup](#3-local-development-setup)
4. [Terraform Configuration](#4-terraform-configuration)
5. [GitHub Actions Setup](#5-github-actions-setup)
6. [Deployment Walkthrough](#6-deployment-walkthrough)
7. [Verification & Testing](#7-verification--testing)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Prerequisites

### Required Software

| Software | Minimum Version | Installation |
|----------|----------------|--------------|
| **Terraform** | >= 1.5.0 | [terraform.io/downloads](https://www.terraform.io/downloads) |
| **Python** | >= 3.9 | [python.org](https://www.python.org/downloads/) |
| **Git** | >= 2.0 | [git-scm.com](https://git-scm.com/downloads) |
| **GitHub CLI** | >= 2.0 | `brew install gh` or [cli.github.com](https://cli.github.com/) |

### Verify Installations

```bash
# Check all versions
terraform --version   # Should be >= 1.5.0
python3 --version     # Should be >= 3.9
git --version         # Should be >= 2.0
gh --version          # Should be >= 2.0
```

### Required Access

- ✅ **Snowflake Account** with `ACCOUNTADMIN` role (or equivalent permissions)
- ✅ **GitHub Repository** (public or private)
- ✅ **GitHub Actions** enabled on your repository

---

## 2. Snowflake Account Setup

### 2.1 Get Your Snowflake Account Details

Log into Snowflake and retrieve:

```
Account Identifier: <orgname>-<account_name> or <account_locator>.<region>
Example: xy12345.us-east-1 or myorg-myaccount
```

To find your account identifier:
```sql
-- Run in Snowflake worksheet
SELECT CURRENT_ACCOUNT(), CURRENT_REGION();
```

### 2.2 Create a Service Account (Recommended for CI/CD)

```sql
-- Run as ACCOUNTADMIN in Snowflake

-- 1. Create the service account user
CREATE USER IF NOT EXISTS SVC_DEVOPS_TERRAFORM
    PASSWORD = 'YourSecurePassword123!'  -- Change this!
    LOGIN_NAME = 'svc_devops_terraform'
    DISPLAY_NAME = 'DevOps Terraform Service Account'
    MUST_CHANGE_PASSWORD = FALSE
    DEFAULT_ROLE = 'ACCOUNTADMIN'
    DEFAULT_WAREHOUSE = 'COMPUTE_WH';

-- 2. Grant necessary role
GRANT ROLE ACCOUNTADMIN TO USER SVC_DEVOPS_TERRAFORM;

-- Note: For production, create a custom role with limited permissions
```

### 2.3 (Optional) Set Up Key-Pair Authentication

For enhanced security, use RSA key-pair instead of password:

```bash
# Generate RSA key pair (run locally)
cd ~/.ssh
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out snowflake_key.p8 -nocrypt
openssl rsa -in snowflake_key.p8 -pubout -out snowflake_key.pub

# Display the public key (you'll need this)
cat snowflake_key.pub
```

```sql
-- In Snowflake, assign the public key to the user
ALTER USER SVC_DEVOPS_TERRAFORM SET RSA_PUBLIC_KEY='MIIBIjANBgkq...';
```

---

## 3. Local Development Setup

### 3.1 Initialize Git Repository (If Starting Locally)

If you already have the project locally (not cloned), initialize Git:

```bash
cd /Users/ffoo/mb-snowflake-devops-demo

# Initialize Git repository
git init

# Create .gitignore if it doesn't exist
cat >> .gitignore << 'EOF'
# Environment files
.env
*.env.local

# Terraform
.terraform/
*.tfstate
*.tfstate.*
*.tfplan
.terraform.lock.hcl

# Python
venv/
__pycache__/
*.pyc

# IDE
.idea/
.vscode/
*.swp

# OS
.DS_Store
Thumbs.db
EOF

# Stage all files
git add .

# Create initial commit
git commit -m "Initial commit: Snowflake DevOps Demo"
```

### 3.1b Push to GitHub

```bash
# Create a new repository on GitHub first, then:
# Option 1: Using GitHub CLI (recommended)
gh repo create mb-snowflake-devops-demo --public --source=. --remote=origin --push

# Option 2: Manual (if you created repo on GitHub web)
git remote add origin https://github.com/YOUR-USERNAME/mb-snowflake-devops-demo.git
git branch -M main
git push -u origin main
```

### 3.2 Create Environment File

```bash
# Create .env file from template
cat > .env << 'EOF'
# =============================================================================
# Snowflake Connection Settings
# =============================================================================

# Account identifier (e.g., xy12345.us-east-1)
SNOWFLAKE_ACCOUNT=your_account_identifier

# Authentication
SNOWFLAKE_USER=your_username
SNOWFLAKE_PASSWORD=your_password

# Default connection settings
SNOWFLAKE_WAREHOUSE=COMPUTE_WH
SNOWFLAKE_DATABASE=MB_DEMO_DEV_ANALYTICS
SNOWFLAKE_ROLE=ACCOUNTADMIN

# Environment (dev/staging/prod)
ENVIRONMENT=dev

# Deployment settings
DRY_RUN=true
EOF
```

**Edit `.env` with your actual credentials:**
```bash
nano .env  # or use your preferred editor
```

### 3.3 Set Up Python Environment

```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Verify installation
python -c "import snowflake.connector; print('✅ Snowflake connector installed')"
```

### 3.4 Load Environment Variables

```bash
# Export environment variables
set -a
source .env
set +a

# Verify variables are set
echo "Account: $SNOWFLAKE_ACCOUNT"
echo "User: $SNOWFLAKE_USER"
echo "Database: $SNOWFLAKE_DATABASE"
```

---

## 4. Terraform Configuration

### 4.1 Initialize Terraform

```bash
cd terraform

# Initialize Terraform (downloads providers)
terraform init
```

Expected output:
```
Initializing provider plugins...
- Finding snowflake-labs/snowflake versions matching "~> 0.87.0"...
- Installing snowflake-labs/snowflake v0.87.0...

Terraform has been successfully initialized!
```

### 4.2 Validate Configuration

```bash
# Check syntax and configuration
terraform validate

# Format check
terraform fmt -check -recursive
```

### 4.3 Review Environment Configurations

The project includes three environment configurations:

| Environment | File | Warehouse Size | Data Retention |
|-------------|------|----------------|----------------|
| Development | `environments/dev.tfvars` | XSMALL | 1 day |
| Staging | `environments/staging.tfvars` | SMALL | 7 days |
| Production | `environments/prod.tfvars` | MEDIUM/LARGE | 90 days |

### 4.4 Plan Infrastructure Changes

```bash
# Plan for development environment
terraform plan -var-file="environments/dev.tfvars"
```

Review the plan output carefully. You should see resources to be created:
- 2 Databases (analytics, staging)
- 3 Schemas (raw, transformed, marts)
- 2 Warehouses (analytics, etl)
- 3 Roles (analyst, engineer, admin)
- 1 Resource Monitor

### 4.5 Apply Infrastructure

```bash
# Apply to development environment
terraform apply -var-file="environments/dev.tfvars"
```

Type `yes` when prompted to confirm.

---

## 5. GitHub Actions Setup

### 5.1 Push to GitHub

```bash
# Add remote (if not already set)
git remote add origin https://github.com/your-org/mb-snowflake-devops-demo.git

# Push to GitHub
git push -u origin main
```

### 5.2 Configure GitHub Secrets

Navigate to: **Repository → Settings → Secrets and variables → Actions → New repository secret**

Add the following secrets:

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `SNOWFLAKE_ACCOUNT` | Account identifier | `xy12345.us-east-1` |
| `SNOWFLAKE_USER` | Service account username | `svc_devops_terraform` |
| `SNOWFLAKE_PASSWORD` | Service account password | `YourSecurePassword123!` |
| `SNOWFLAKE_WAREHOUSE` | Default warehouse | `COMPUTE_WH` |
| `SNOWFLAKE_DATABASE` | Target database | `MB_DEMO_DEV_ANALYTICS` |
| `SNOWFLAKE_ROLE` | Deployment role | `ACCOUNTADMIN` |

**Using GitHub CLI:**
```bash
# Set secrets via CLI
gh secret set SNOWFLAKE_ACCOUNT --body "xy12345.us-east-1"
gh secret set SNOWFLAKE_USER --body "svc_devops_terraform"
gh secret set SNOWFLAKE_PASSWORD --body "YourSecurePassword123!"
gh secret set SNOWFLAKE_WAREHOUSE --body "COMPUTE_WH"
gh secret set SNOWFLAKE_DATABASE --body "MB_DEMO_DEV_ANALYTICS"
gh secret set SNOWFLAKE_ROLE --body "ACCOUNTADMIN"
```

### 5.3 Configure GitHub Environments (Recommended)

For approval workflows, set up environments:

1. Go to **Repository → Settings → Environments**
2. Create environments: `development`, `staging`, `production`
3. For `staging` and `production`, add:
   - Required reviewers
   - Environment protection rules
   - Deployment branch restrictions

### 5.4 Verify Workflow Files

Ensure these workflow files exist in `.github/workflows/`:

| Workflow | Purpose | Trigger |
|----------|---------|---------|
| `terraform-plan.yml` | Validates & plans on PRs | Pull Request |
| `terraform-apply.yml` | Deploys infrastructure | Push to main |
| `snowflake-objects.yml` | Deploys SQL objects | Push to main |

---

## 6. Deployment Walkthrough

### 6.1 Deploy Infrastructure (Terraform)

```bash
# From repository root
cd terraform

# Development
terraform apply -var-file="environments/dev.tfvars"

# Staging (after dev is verified)
terraform apply -var-file="environments/staging.tfvars"

# Production (use with caution!)
terraform apply -var-file="environments/prod.tfvars"
```

### 6.2 Deploy Database Objects (SQL)

```bash
# Go back to repo root
cd ..

# Activate virtual environment (if not active)
source venv/bin/activate

# Set environment variables
export ENVIRONMENT=dev
export DRY_RUN=false

# Run deployment
python scripts/deploy_objects.py
```

### 6.3 Verify Deployment in Snowflake

```sql
-- Run in Snowflake Worksheet

-- Check databases
SHOW DATABASES LIKE 'MB_DEMO%';

-- Check schemas
USE DATABASE MB_DEMO_DEV_ANALYTICS;
SHOW SCHEMAS;

-- Check tables
USE SCHEMA RAW;
SHOW TABLES;

USE SCHEMA TRANSFORMED;
SHOW TABLES;

USE SCHEMA MARTS;
SHOW TABLES;
SHOW VIEWS;

-- Check warehouses
SHOW WAREHOUSES LIKE 'MB_DEMO%';

-- Check roles
SHOW ROLES LIKE 'MB_DEMO%';
```

---

## 7. Verification & Testing

### 7.1 Test the Analytical Views

```sql
-- Set context
USE DATABASE MB_DEMO_DEV_ANALYTICS;
USE SCHEMA MARTS;
USE WAREHOUSE MB_DEMO_DEV_ANALYTICS_WH;

-- Test views (they'll be empty until data is loaded)
SELECT * FROM VW_REALTIME_TRANSACTIONS LIMIT 10;
SELECT * FROM VW_MERCHANT_PERFORMANCE LIMIT 10;
SELECT * FROM VW_CUSTOMER_SEGMENTATION LIMIT 10;
SELECT * FROM VW_DAILY_KPI LIMIT 10;
```

### 7.2 Load Sample Data (Optional)

```sql
-- Insert sample transaction data
INSERT INTO RAW.CUSTOMER_TRANSACTIONS_RAW 
(record_id, transaction_id, customer_id, transaction_date, transaction_type, 
 amount, currency, merchant_name, merchant_category, channel, status)
VALUES
('R001', 'TXN001', 'C001', '2024-01-15 10:30:00', 'PURCHASE', '150.00', 'MYR', 'Store A', 'Retail', 'Online', 'COMPLETED'),
('R002', 'TXN002', 'C002', '2024-01-15 11:45:00', 'PURCHASE', '250.50', 'MYR', 'Store B', 'Food', 'POS', 'COMPLETED'),
('R003', 'TXN003', 'C001', '2024-01-15 14:20:00', 'TRANSFER', '1000.00', 'MYR', 'N/A', 'Transfer', 'Mobile', 'COMPLETED');

-- Insert sample customer data
INSERT INTO RAW.CUSTOMER_PROFILE_RAW
(record_id, customer_id, customer_name, customer_type, segment, registration_date, status, risk_rating)
VALUES
('CP001', 'C001', 'John Doe', 'Individual', 'Premium', '2023-01-01', 'ACTIVE', 'LOW'),
('CP002', 'C002', 'Jane Smith', 'Individual', 'Standard', '2023-06-15', 'ACTIVE', 'MEDIUM');
```

### 7.3 Test Stored Procedure

```sql
-- Call the Customer 360 refresh procedure
CALL MARTS.SP_REFRESH_CUSTOMER_360();

-- Verify results
SELECT * FROM MARTS.CUSTOMER_360;
```

### 7.4 Test CI/CD Pipeline

```bash
# Create a feature branch
git checkout -b feature/test-workflow

# Make a minor change
echo "# Test" >> terraform/main.tf

# Commit and push
git add .
git commit -m "Test: Trigger CI/CD pipeline"
git push -u origin feature/test-workflow

# Create a pull request
gh pr create --title "Test: CI/CD Pipeline" --body "Testing the workflow"
```

Observe:
- GitHub Actions should trigger `terraform-plan.yml`
- A plan should be posted as a PR comment
- After merge, `terraform-apply.yml` should deploy changes

---

## 8. Troubleshooting

### Common Issues

#### Issue: Terraform init fails

```
Error: Failed to query available provider packages
```

**Solution:**
```bash
# Clear Terraform cache
rm -rf .terraform .terraform.lock.hcl
terraform init
```

#### Issue: Snowflake connection fails

```
Error: 250001: Could not connect to Snowflake backend
```

**Solution:**
1. Verify account identifier format
2. Check network connectivity to Snowflake
3. Verify username/password
4. Check if your IP is allowed (network policies)

```bash
# Test connection
python3 << 'EOF'
import snowflake.connector
import os

conn = snowflake.connector.connect(
    account=os.environ['SNOWFLAKE_ACCOUNT'],
    user=os.environ['SNOWFLAKE_USER'],
    password=os.environ['SNOWFLAKE_PASSWORD']
)
print("✅ Connection successful!")
conn.close()
EOF
```

#### Issue: GitHub Actions fails with "secret not found"

**Solution:**
1. Verify all secrets are configured in repository settings
2. Check secret names match exactly (case-sensitive)
3. Ensure workflow has access to the environment

#### Issue: Terraform state lock

```
Error: Error acquiring the state lock
```

**Solution:**
```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

#### Issue: Permission denied on Snowflake objects

**Solution:**
```sql
-- Check current role
SELECT CURRENT_ROLE();

-- Use ACCOUNTADMIN or appropriate role
USE ROLE ACCOUNTADMIN;
```

---

## Quick Reference Commands

```bash
# Terraform
make init                 # Initialize Terraform
make plan                 # Plan dev environment
make plan-staging         # Plan staging environment
make apply                # Apply dev environment
make destroy              # Destroy dev environment
make fmt                  # Format Terraform files
make validate             # Validate configuration

# SQL Objects
make deploy-objects       # Deploy Snowflake objects
make lint                 # Lint SQL files

# Python Setup
make setup                # Setup Python virtual environment

# GitHub Workflows (via CLI)
gh workflow run "Terraform Apply" --field environment=dev
gh workflow run "Deploy Snowflake Objects" --field environment=dev --field dry_run=true
```

---

## Next Steps

1. ✅ Complete the setup following this guide
2. 📝 Review and customize `terraform/environments/*.tfvars` for your needs
3. 🔐 Set up key-pair authentication for production
4. 🛡️ Configure GitHub environment protection rules
5. 📊 Load your data and start using the analytics views

---

**Need help?** Open an issue in the repository or contact the DevOps team.

