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

### 3.2 Create Environment File (Key-Pair Authentication)

#### Step 1: Generate RSA Key Pair

```bash
# Create directory for keys
mkdir -p ~/.snowflake

# Generate 2048-bit RSA private key (unencrypted for automation)
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out ~/.snowflake/rsa_key.p8 -nocrypt

# Generate public key from private key
openssl rsa -in ~/.snowflake/rsa_key.p8 -pubout -out ~/.snowflake/rsa_key.pub

# Set secure permissions
chmod 600 ~/.snowflake/rsa_key.p8
chmod 644 ~/.snowflake/rsa_key.pub

# Display public key (you'll need this for Snowflake)
cat ~/.snowflake/rsa_key.pub
```

#### Step 2: Register Public Key in Snowflake

```sql
-- Run in Snowflake as ACCOUNTADMIN
-- Copy the public key content (without BEGIN/END headers)

ALTER USER your_username SET RSA_PUBLIC_KEY='MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...';

-- Verify key is set
DESC USER your_username;
```

#### Step 3: Create Environment File

```bash
# Create .env file with key-pair authentication
cat > .env << 'EOF'
# =============================================================================
# Snowflake Connection Settings (Key-Pair Authentication)
# =============================================================================

# Account identifier (e.g., xy12345.us-east-1)
SNOWFLAKE_ACCOUNT=your_account_identifier

# User
SNOWFLAKE_USER=your_username

# Key-Pair Authentication (REQUIRED for JWT auth)
SNOWFLAKE_AUTHENTICATOR=JWT
SNOWFLAKE_PRIVATE_KEY_PATH=/absolute/path/to/rsa_key.p8

# Optional: If your private key is encrypted with a passphrase
# SNOWFLAKE_PRIVATE_KEY_PASSPHRASE=your_passphrase

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

> ⚠️ **Important:** Use **absolute paths** for `SNOWFLAKE_PRIVATE_KEY_PATH` (e.g., `/Users/yourname/.snowflake/rsa_key.p8`), not relative paths like `~/.snowflake/`.

**Edit `.env` with your actual values:**
```bash
nano .env  # or use your preferred editor
```

#### Step 4: Test Key-Pair Connection

> ⚠️ **Important:** Complete [Section 3.3 Set Up Python Environment](#33-set-up-python-environment) first to install dependencies!

```bash
# Activate virtual environment (required!)
source venv/bin/activate

# Load environment variables
set -a && source .env && set +a

# Test connection with key-pair auth
python << 'EOF'
import snowflake.connector
import os
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization

# Read private key
key_path = os.path.expanduser(os.environ['SNOWFLAKE_PRIVATE_KEY_PATH'])
with open(key_path, 'rb') as key_file:
    private_key = serialization.load_pem_private_key(
        key_file.read(),
        password=None,
        backend=default_backend()
    )

# Get private key bytes
private_key_bytes = private_key.private_bytes(
    encoding=serialization.Encoding.DER,
    format=serialization.PrivateFormat.PKCS8,
    encryption_algorithm=serialization.NoEncryption()
)

# Connect using key-pair
conn = snowflake.connector.connect(
    account=os.environ['SNOWFLAKE_ACCOUNT'],
    user=os.environ['SNOWFLAKE_USER'],
    private_key=private_key_bytes,
    warehouse=os.environ.get('SNOWFLAKE_WAREHOUSE'),
    role=os.environ.get('SNOWFLAKE_ROLE')
)
print("✅ Key-pair authentication successful!")
print(f"   Connected as: {conn.cursor().execute('SELECT CURRENT_USER()').fetchone()[0]}")
conn.close()
EOF
```

> **Note:** You'll need to install the cryptography package: `pip install cryptography`

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
- Finding snowflake-labs/snowflake versions matching "~> 0.97.0"...
- Installing snowflake-labs/snowflake v0.97.0...

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

### 4.6 Terraform State Management (Important!)

> ⚠️ **Current Setup:** This demo uses a single local state file for simplicity. In production, each environment should have separate state.

#### Option A: Separate State Files (Recommended for Production)

```bash
# Development
terraform apply -var-file="environments/dev.tfvars" -state="terraform-dev.tfstate"

# Staging  
terraform apply -var-file="environments/staging.tfvars" -state="terraform-staging.tfstate"

# Production
terraform apply -var-file="environments/prod.tfvars" -state="terraform-prod.tfstate"
```

#### Option B: Terraform Workspaces

```bash
# Create workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch and apply
terraform workspace select dev
terraform apply -var-file="environments/dev.tfvars"

terraform workspace select staging
terraform apply -var-file="environments/staging.tfvars"
```

#### Option C: Remote Backend (Best Practice)

For team collaboration, use a remote backend like S3, Azure Blob, or Terraform Cloud. Update `providers.tf`:

```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "snowflake/dev/terraform.tfstate"  # Change per environment
    region = "us-east-1"
  }
}
```

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

#### Option A: Password Authentication (Simple)

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `SNOWFLAKE_ACCOUNT` | Account identifier | `xy12345.us-east-1` |
| `SNOWFLAKE_USER` | Service account username | `svc_devops_terraform` |
| `SNOWFLAKE_PASSWORD` | Service account password | `YourSecurePassword123!` |
| `SNOWFLAKE_WAREHOUSE` | Default warehouse | `COMPUTE_WH` |
| `SNOWFLAKE_DATABASE` | Target database | `MB_DEMO_DEV_ANALYTICS` |
| `SNOWFLAKE_ROLE` | Deployment role | `ACCOUNTADMIN` |

```bash
# Set secrets via CLI (password auth)
gh secret set SNOWFLAKE_ACCOUNT --body "xy12345.us-east-1"
gh secret set SNOWFLAKE_USER --body "svc_devops_terraform"
gh secret set SNOWFLAKE_PASSWORD --body "YourSecurePassword123!"
gh secret set SNOWFLAKE_WAREHOUSE --body "COMPUTE_WH"
gh secret set SNOWFLAKE_DATABASE --body "MB_DEMO_DEV_ANALYTICS"
gh secret set SNOWFLAKE_ROLE --body "ACCOUNTADMIN"
```

#### Option B: Key-Pair Authentication (Recommended for Production)

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `SNOWFLAKE_ACCOUNT` | Account identifier | `xy12345.us-east-1` |
| `SNOWFLAKE_USER` | Service account username | `svc_devops_terraform` |
| `SNOWFLAKE_PRIVATE_KEY` | Private key content (base64) | See below |
| `SNOWFLAKE_WAREHOUSE` | Default warehouse | `COMPUTE_WH` |
| `SNOWFLAKE_DATABASE` | Target database | `MB_DEMO_DEV_ANALYTICS` |
| `SNOWFLAKE_ROLE` | Deployment role | `ACCOUNTADMIN` |

```bash
# Encode private key to base64 (required for GitHub secrets)
cat ~/.snowflake/rsa_key.p8 | base64 | pbcopy  # Copies to clipboard on macOS

# Set secrets via CLI (key-pair auth)
gh secret set SNOWFLAKE_ACCOUNT --body "xy12345.us-east-1"
gh secret set SNOWFLAKE_USER --body "svc_devops_terraform"
gh secret set SNOWFLAKE_PRIVATE_KEY < <(cat ~/.snowflake/rsa_key.p8 | base64)
gh secret set SNOWFLAKE_WAREHOUSE --body "COMPUTE_WH"
gh secret set SNOWFLAKE_DATABASE --body "MB_DEMO_DEV_ANALYTICS"
gh secret set SNOWFLAKE_ROLE --body "ACCOUNTADMIN"
```

> **Note:** The GitHub workflows use password auth by default. For key-pair auth in CI/CD, you'll need to update the workflow files to decode the private key.

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

> ⚠️ **Important:** Each environment uses separate Terraform state. Deploy environments one at a time.

#### Deploy Development Environment

```bash
cd terraform

# Load environment variables
set -a && source ../.env && set +a

# Plan first (review changes)
terraform plan -var-file="environments/dev.tfvars"

# Apply changes
terraform apply -var-file="environments/dev.tfvars"
# Type 'yes' to confirm
```

#### Deploy Staging Environment

```bash
# Plan staging
terraform plan -var-file="environments/staging.tfvars"

# Apply staging (after dev is verified)
terraform apply -var-file="environments/staging.tfvars"
```

#### Deploy Production Environment

```bash
# Plan production
terraform plan -var-file="environments/prod.tfvars"

# Apply production (use with caution!)
terraform apply -var-file="environments/prod.tfvars"
```

### 6.2 Deploy Database Objects (SQL)

Database objects must be deployed to each environment separately.

#### Deploy to Development

```bash
cd /Users/ffoo/mb-snowflake-devops-demo
source venv/bin/activate
set -a && source .env && set +a

# Set environment
export ENVIRONMENT=dev
export SNOWFLAKE_DATABASE=MB_DEMO_DEV_ANALYTICS
export DRY_RUN=false

# Run deployment
python scripts/deploy_objects.py
```

#### Deploy to Staging

```bash
# Set staging environment
export ENVIRONMENT=staging
export SNOWFLAKE_DATABASE=MB_DEMO_STAGING_ANALYTICS
export DRY_RUN=false

# Run deployment
python scripts/deploy_objects.py
```

#### Deploy to Production

```bash
# Set production environment
export ENVIRONMENT=prod
export SNOWFLAKE_DATABASE=MB_DEMO_PROD_ANALYTICS
export DRY_RUN=false

# Run deployment
python scripts/deploy_objects.py
```

### 6.3 Verify Deployment in Snowflake

#### Verify Development Environment

```sql
-- Check dev databases
SHOW DATABASES LIKE 'MB_DEMO_DEV%';

-- Check dev schemas
USE DATABASE MB_DEMO_DEV_ANALYTICS;
SHOW SCHEMAS;

-- Check tables and views
SHOW TABLES IN SCHEMA RAW;
SHOW TABLES IN SCHEMA TRANSFORMED;
SHOW TABLES IN SCHEMA MARTS;
SHOW VIEWS IN SCHEMA MARTS;

-- Check warehouses and roles
SHOW WAREHOUSES LIKE 'MB_DEMO_DEV%';
SHOW ROLES LIKE 'MB_DEMO_DEV%';
```

#### Verify Staging Environment

```sql
-- Check staging databases
SHOW DATABASES LIKE 'MB_DEMO_STAGING%';

USE DATABASE MB_DEMO_STAGING_ANALYTICS;
SHOW SCHEMAS;
SHOW TABLES IN SCHEMA MARTS;
SHOW VIEWS IN SCHEMA MARTS;

SHOW WAREHOUSES LIKE 'MB_DEMO_STAGING%';
SHOW ROLES LIKE 'MB_DEMO_STAGING%';
```

#### Verify Production Environment

```sql
-- Check prod databases
SHOW DATABASES LIKE 'MB_DEMO_PROD%';

USE DATABASE MB_DEMO_PROD_ANALYTICS;
SHOW SCHEMAS;
SHOW TABLES IN SCHEMA MARTS;
SHOW VIEWS IN SCHEMA MARTS;

SHOW WAREHOUSES LIKE 'MB_DEMO_PROD%';
SHOW ROLES LIKE 'MB_DEMO_PROD%';
```

### 6.4 Environment Summary

After deploying all environments, you should have:

| Environment | Database | Warehouse | Roles |
|-------------|----------|-----------|-------|
| **Dev** | `MB_DEMO_DEV_ANALYTICS` | `MB_DEMO_DEV_ANALYTICS_WH`, `MB_DEMO_DEV_ETL_WH` | `MB_DEMO_DEV_ANALYST`, `MB_DEMO_DEV_ENGINEER`, `MB_DEMO_DEV_ADMIN` |
| **Staging** | `MB_DEMO_STAGING_ANALYTICS` | `MB_DEMO_STAGING_ANALYTICS_WH`, `MB_DEMO_STAGING_ETL_WH` | `MB_DEMO_STAGING_ANALYST`, `MB_DEMO_STAGING_ENGINEER`, `MB_DEMO_STAGING_ADMIN` |
| **Prod** | `MB_DEMO_PROD_ANALYTICS` | `MB_DEMO_PROD_ANALYTICS_WH`, `MB_DEMO_PROD_ETL_WH` | `MB_DEMO_PROD_ANALYST`, `MB_DEMO_PROD_ENGINEER`, `MB_DEMO_PROD_ADMIN` |

---

## 7. Verification & Testing

### 7.1 Test the Analytical Views

```sql
-- Set context (use your configured warehouse, e.g., COMPUTE_WH)
USE DATABASE MB_DEMO_DEV_ANALYTICS;
USE SCHEMA MARTS;
USE WAREHOUSE COMPUTE_WH;  -- Or MB_DEMO_DEV_ANALYTICS_WH if created by Terraform

-- Test views (they'll be empty until data is loaded)
SELECT * FROM VW_REALTIME_TRANSACTIONS LIMIT 10;
SELECT * FROM VW_MERCHANT_PERFORMANCE LIMIT 10;
SELECT * FROM VW_CUSTOMER_SEGMENTATION LIMIT 10;
SELECT * FROM VW_DAILY_KPI LIMIT 10;
```

### 7.2 Load Sample Data (Optional)

Load sample data to test the data pipeline:

```sql
-- Set context
USE DATABASE MB_DEMO_DEV_ANALYTICS;
USE WAREHOUSE COMPUTE_WH;

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

-- Verify data was inserted
SELECT COUNT(*) FROM RAW.CUSTOMER_TRANSACTIONS_RAW;
SELECT COUNT(*) FROM RAW.CUSTOMER_PROFILE_RAW;
```

### 7.3 Test Stored Procedure

```sql
-- Call the Customer 360 refresh procedure
CALL MARTS.SP_REFRESH_CUSTOMER_360();

-- Verify results
SELECT * FROM MARTS.CUSTOMER_360;
```

### 7.4 Test Streams and Tasks (Optional)

```sql
-- Check streams have captured changes
SELECT * FROM RAW.TRANSACTIONS_STREAM;
SELECT * FROM RAW.CUSTOMER_PROFILE_STREAM;

-- Note: Tasks are created SUSPENDED by default
-- To enable automatic processing, run:
-- ALTER TASK TRANSFORMED.PROCESS_TRANSACTIONS_TASK RESUME;
-- ALTER TASK TRANSFORMED.UPDATE_DAILY_SUMMARY_TASK RESUME;
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
3. Verify key-pair authentication is configured correctly
4. Ensure `SNOWFLAKE_AUTHENTICATOR=JWT` is set
5. Check if your IP is allowed (network policies)

```bash
# Verify environment variables are set
echo "SNOWFLAKE_ACCOUNT=$SNOWFLAKE_ACCOUNT"
echo "SNOWFLAKE_AUTHENTICATOR=$SNOWFLAKE_AUTHENTICATOR"
echo "SNOWFLAKE_PRIVATE_KEY_PATH=$SNOWFLAKE_PRIVATE_KEY_PATH"

# Reload environment if needed
set -a && source .env && set +a
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
# Initial Setup (run once)
cd /Users/ffoo/mb-snowflake-devops-demo
source venv/bin/activate
set -a && source .env && set +a

# Terraform Commands
make init                 # Initialize Terraform
make plan                 # Plan dev environment
make plan-staging         # Plan staging environment
make plan-prod            # Plan prod environment
make apply                # Apply dev environment
make apply-staging        # Apply staging environment
make apply-prod           # Apply prod environment
make destroy              # Destroy dev environment
make fmt                  # Format Terraform files
make validate             # Validate configuration

# Direct Terraform (alternative to make)
cd terraform
terraform init
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"

# SQL Objects Deployment
make deploy-objects       # Deploy Snowflake objects
make lint                 # Lint SQL files

# Or run directly
python scripts/deploy_objects.py

# Python Setup (run once)
make setup                # Setup Python virtual environment

# GitHub Workflows (via CLI)
gh workflow run "Terraform Apply" --field environment=dev
gh workflow run "Deploy Snowflake Objects" --field environment=dev --field dry_run=true

# Git Commands
git status
gh pr list
gh run list
```

---

## 9. Deployment Checklist

Use this checklist to ensure each environment is fully deployed:

### Development Environment ✅

- [ ] Terraform applied: `terraform apply -var-file="environments/dev.tfvars"`
- [ ] SQL objects deployed: `ENVIRONMENT=dev python scripts/deploy_objects.py`
- [ ] Verified databases: `SHOW DATABASES LIKE 'MB_DEMO_DEV%'`
- [ ] Verified schemas: RAW, TRANSFORMED, MARTS exist
- [ ] Verified tables and views created
- [ ] Sample data loaded (optional)
- [ ] Stored procedure tested

### Staging Environment ✅

- [ ] Terraform applied: `terraform apply -var-file="environments/staging.tfvars"`
- [ ] SQL objects deployed: `ENVIRONMENT=staging python scripts/deploy_objects.py`
- [ ] Verified databases: `SHOW DATABASES LIKE 'MB_DEMO_STAGING%'`
- [ ] Verified all objects created

### Production Environment ✅

- [ ] Terraform applied: `terraform apply -var-file="environments/prod.tfvars"`
- [ ] SQL objects deployed: `ENVIRONMENT=prod python scripts/deploy_objects.py`
- [ ] Verified databases: `SHOW DATABASES LIKE 'MB_DEMO_PROD%'`
- [ ] Verified all objects created
- [ ] Tasks enabled (if needed): `ALTER TASK ... RESUME`

### CI/CD Pipeline ✅

- [ ] GitHub repository created
- [ ] GitHub secrets configured
- [ ] GitHub environments created (development, staging, production)
- [ ] Protection rules set for staging/production
- [ ] Test PR created and workflows verified

---

## Next Steps

1. ✅ Complete the setup following this guide
2. 📝 Review and customize `terraform/environments/*.tfvars` for your needs
3. 🔐 Set up key-pair authentication for production
4. 🛡️ Configure GitHub environment protection rules
5. 📊 Load your data and start using the analytics views
6. 🔄 Test the CI/CD pipeline with a sample PR

---

## 📖 Related Documentation

| Document | Description |
|----------|-------------|
| [DEMO_GUIDE.md](DEMO_GUIDE.md) | Presentation script for demos |
| [README.md](README.md) | Project overview |
| `terraform/environments/*.tfvars` | Environment configurations |

---

**Need help?** Open an issue in the repository or contact the DevOps team.

