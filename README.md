# Mb Snowflake DevOps Demo

A comprehensive demonstration of **Automated DevOps** capabilities for Snowflake, showcasing Infrastructure as Code (IaC) provisioning and CI/CD deployment pipelines.

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)

---

## 🎯 Demo Overview

This project demonstrates three key DevOps capabilities for Snowflake:

| Capability | Technology | Description |
|------------|------------|-------------|
| **Automated DevOps Setup** | Terraform + GitHub Actions | Complete infrastructure automation |
| **IaC Provisioning** | Terraform | Version-controlled Snowflake resources |
| **CI/CD Pipelines** | GitHub Actions | Automated testing, planning, and deployment |

---

## 📁 Project Structure

```
mb-snowflake-devops-demo/
├── terraform/                      # Infrastructure as Code
│   ├── main.tf                     # Main resource definitions
│   ├── variables.tf                # Variable declarations
│   ├── outputs.tf                  # Output definitions
│   ├── providers.tf                # Provider configuration
│   └── environments/               # Environment-specific configs
│       ├── dev.tfvars              # Development environment
│       ├── staging.tfvars          # Staging environment
│       └── prod.tfvars             # Production environment
│
├── .github/workflows/              # CI/CD Pipelines
│   ├── terraform-plan.yml          # PR validation & planning
│   ├── terraform-apply.yml         # Automated deployment
│   └── snowflake-objects.yml       # Database object deployment
│
├── snowflake/                      # Snowflake Objects
│   ├── ddl/                        # Version-controlled DDL scripts
│   │   ├── V001__initial_schema_setup.sql
│   │   └── V002__create_streams_and_tasks.sql
│   └── objects/
│       ├── stored_procedures/      # Stored procedures
│       └── views/                  # Analytical views
│
├── scripts/                        # Deployment scripts
│   └── deploy_objects.py           # Python deployment script
│
├── .env.example                    # Environment template
└── README.md                       # This file
```

---

## 🚀 Quick Start

### Prerequisites

- Terraform >= 1.5.0
- Python >= 3.9
- Snowflake account with ACCOUNTADMIN or equivalent role
- GitHub repository (for CI/CD)

### 1. Clone and Configure

```bash
# Clone the repository
git clone https://github.com/your-org/mb-snowflake-devops-demo.git
cd mb-snowflake-devops-demo

# Copy environment template
cp .env.example .env

# Edit .env with your Snowflake credentials
```

### 2. Initialize Terraform

```bash
cd terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan for development environment
terraform plan -var-file="environments/dev.tfvars"
```

### 3. Deploy Infrastructure

```bash
# Apply to development environment
terraform apply -var-file="environments/dev.tfvars"
```

---

## 🏗️ Infrastructure as Code (IaC)

### Resources Provisioned

| Resource Type | Description | Per Environment |
|--------------|-------------|-----------------|
| **Databases** | Analytics & Staging databases | 2 |
| **Schemas** | Raw, Transformed, Marts | 3 |
| **Warehouses** | Analytics & ETL warehouses | 2 |
| **Roles** | Analyst, Engineer, Admin | 3 |
| **Resource Monitor** | Cost management | 1 |

### Environment Comparison

| Setting | Development | Staging | Production |
|---------|------------|---------|------------|
| Warehouse Size | XSMALL | SMALL | MEDIUM/LARGE |
| Auto Suspend | 60s | 120s | 300s |
| Max Clusters | 1 | 2 | 3-4 |
| Data Retention | 1 day | 7 days | 90 days |
| Credit Quota | 100 | 100 | 1000 |

### Sample Terraform Commands

```bash
# Format check
terraform fmt -check -recursive

# Plan with specific environment
terraform plan -var-file="environments/staging.tfvars" -out=tfplan

# Apply with approval
terraform apply tfplan

# Destroy (use with caution!)
terraform destroy -var-file="environments/dev.tfvars"
```

---

## 🔄 CI/CD Pipelines

### Pipeline Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Pull Request                              │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────┐   ┌──────────────┐   ┌─────────────────────────┐  │
│  │ Security │──▶│ Format Check │──▶│ Terraform Plan (Dev)    │  │
│  │   Scan   │   │              │   │ + PR Comment            │  │
│  └──────────┘   └──────────────┘   └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (Merge)
┌─────────────────────────────────────────────────────────────────┐
│                        Main Branch                               │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐   ┌─────────────────┐   ┌─────────────────┐   │
│  │ Deploy Dev   │──▶│ Deploy Staging  │──▶│ Deploy Prod     │   │
│  │ (Automatic)  │   │ (After Dev)     │   │ (Manual Trigger)│   │
│  └──────────────┘   └─────────────────┘   └─────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Workflow Triggers

| Workflow | Trigger | Action |
|----------|---------|--------|
| `terraform-plan.yml` | Pull Request | Validates & plans changes |
| `terraform-apply.yml` | Push to main | Deploys to Dev → Staging |
| `snowflake-objects.yml` | Push to main | Deploys SQL objects |

### GitHub Secrets Required

Configure these secrets in your GitHub repository:

```
SNOWFLAKE_ACCOUNT      # e.g., xy12345.us-east-1
SNOWFLAKE_USER         # Service account username
SNOWFLAKE_PASSWORD     # Service account password
SNOWFLAKE_WAREHOUSE    # Default warehouse
SNOWFLAKE_DATABASE     # Target database
SNOWFLAKE_ROLE         # Deployment role
```

### Manual Deployment

```bash
# Trigger workflow manually via GitHub CLI
gh workflow run "Terraform Apply" --field environment=staging
```

---

## 📊 Snowflake Objects

### Data Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         RAW Schema                               │
│  ┌──────────────────────┐    ┌──────────────────────┐           │
│  │ CUSTOMER_TRANSACTIONS│    │   CUSTOMER_PROFILE   │           │
│  │       _RAW           │    │       _RAW           │           │
│  └──────────┬───────────┘    └──────────┬───────────┘           │
│             │ Stream                     │ Stream                │
└─────────────┼───────────────────────────┼───────────────────────┘
              ▼                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                     TRANSFORMED Schema                           │
│  ┌──────────────────────┐    ┌──────────────────────┐           │
│  │ CUSTOMER_TRANSACTIONS│    │   CUSTOMER_PROFILE   │           │
│  │   (Cleansed)         │    │     (Cleansed)       │           │
│  └──────────┬───────────┘    └──────────┬───────────┘           │
└─────────────┼───────────────────────────┼───────────────────────┘
              │                            │
              ▼                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                        MARTS Schema                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ DAILY_SUMMARY   │  │  CUSTOMER_360   │  │  Views (4)      │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Analytical Views

| View | Description |
|------|-------------|
| `VW_REALTIME_TRANSACTIONS` | Last 30 days of transactions with categorizations |
| `VW_MERCHANT_PERFORMANCE` | Aggregated merchant analytics |
| `VW_CUSTOMER_SEGMENTATION` | RFM-based customer segmentation |
| `VW_DAILY_KPI` | Daily KPIs with YoY and WoW comparisons |

### Stored Procedures

| Procedure | Description |
|-----------|-------------|
| `SP_REFRESH_CUSTOMER_360` | Builds Customer 360 analytical table |

---

## 🔐 Security Best Practices

### Implemented

- ✅ Role-based access control (RBAC)
- ✅ Least privilege principle
- ✅ Secrets managed via GitHub Secrets
- ✅ Resource monitoring for cost control
- ✅ Secure views for data access
- ✅ Security scanning in CI (tfsec)

### Recommendations for Production

```hcl
# Use key-pair authentication instead of password
provider "snowflake" {
  account              = var.snowflake_account
  user                 = var.snowflake_user
  private_key_path     = var.private_key_path
  private_key_passphrase = var.private_key_passphrase
}
```

---

## 📈 Demo Scenarios

### Scenario 1: New Feature Development

1. Create feature branch
2. Add new Snowflake object in `snowflake/objects/`
3. Open Pull Request
4. Review auto-generated plan in PR comments
5. Merge to deploy automatically

### Scenario 2: Infrastructure Change

1. Modify `terraform/environments/dev.tfvars`
2. Open Pull Request
3. Review Terraform plan
4. Approve and merge
5. Watch deployment progress in Actions

### Scenario 3: Emergency Production Fix

1. Use workflow dispatch:
   ```bash
   gh workflow run "Terraform Apply" \
     --field environment=prod
   ```
2. Approve in GitHub environment protection rules
3. Monitor deployment

---

## 🛠️ Local Development

### Setup Python Environment

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install snowflake-connector-python PyYAML sqlfluff

# Test connection
python -c "import snowflake.connector; print('OK')"
```

### Run Deployment Script

```bash
# Set environment variables
export SNOWFLAKE_ACCOUNT=your_account
export SNOWFLAKE_USER=your_user
export SNOWFLAKE_PASSWORD=your_password
export SNOWFLAKE_WAREHOUSE=COMPUTE_WH
export SNOWFLAKE_DATABASE=MB_DEMO_DEV_ANALYTICS
export SNOWFLAKE_ROLE=ACCOUNTADMIN
export ENVIRONMENT=dev
export DRY_RUN=true  # Set to false for actual deployment

# Run deployment
python scripts/deploy_objects.py
```

---

## 📋 Checklist for Production

- [ ] Configure GitHub Environments with protection rules
- [ ] Set up required reviewers for production deployments
- [ ] Enable branch protection on `main`
- [ ] Configure Snowflake network policies
- [ ] Set up key-pair authentication
- [ ] Configure resource monitors with alerts
- [ ] Document runbooks for common operations
- [ ] Set up monitoring and alerting

---

## 📚 References

- [Snowflake Terraform Provider](https://registry.terraform.io/providers/Snowflake-Labs/snowflake/latest/docs)
- [Snowflake Documentation](https://docs.snowflake.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/)

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `terraform fmt` and `terraform validate`
5. Open a Pull Request

---

## 📄 License

This demo is provided for educational purposes. Please review and adapt for your organization's requirements.

---

**Built with ❤️ for Mb**

