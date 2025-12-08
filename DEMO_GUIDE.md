# Mb Snowflake DevOps Demo Guide

A step-by-step presentation script for demonstrating Snowflake DevOps capabilities including Infrastructure as Code (IaC) and CI/CD pipelines.

> 📘 **First time setup?** Complete the [SETUP_GUIDE.md](SETUP_GUIDE.md) before running this demo.

---

## 📋 Demo Overview

| Duration | Audience | Prerequisites |
|----------|----------|---------------|
| 30-45 min | Data Engineers, DevOps, Platform Teams | Completed [SETUP_GUIDE.md](SETUP_GUIDE.md) |

### What You'll Demonstrate

1. **Infrastructure as Code** - Provisioning Snowflake resources with Terraform
2. **Environment Management** - Dev/Staging/Prod configurations
3. **Database Object Deployment** - Automated SQL migrations and views
4. **CI/CD Pipelines** - GitHub Actions for automated deployments
5. **Live Deployment** - Real-time infrastructure changes

---

## 🎬 Pre-Demo Checklist

Before starting the demo, ensure:

- [ ] Completed [SETUP_GUIDE.md](SETUP_GUIDE.md) (one-time setup)
- [ ] Terminal open in project directory
- [ ] Environment variables loaded
- [ ] Snowflake worksheet open (for verification)
- [ ] GitHub repository accessible
- [ ] Python venv activated

```bash
# Quick setup before demo
cd /Users/ffoo/mb-snowflake-devops-demo
source venv/bin/activate
set -a && source .env && set +a

# Verify connection works
echo "Account: $SNOWFLAKE_ACCOUNT"
echo "User: $SNOWFLAKE_USER"
```

---

## 🎯 Demo Script

### Part 1: Project Overview (5 min)

#### 1.1 Introduction

> *"Today I'll demonstrate how we've implemented DevOps best practices for Snowflake, bringing the same Infrastructure as Code and CI/CD capabilities you'd expect in modern software development to our data platform."*

#### 1.2 Show Project Structure

```bash
# Display the project structure
tree -L 2 --dirsfirst
```

**Talking Points:**
```
mb-snowflake-devops-demo/
├── terraform/              ← Infrastructure as Code
│   ├── environments/       ← Dev, Staging, Prod configs
│   ├── main.tf            ← Resource definitions
│   └── providers.tf       ← Snowflake connection
├── snowflake/             ← Database objects (SQL)
│   ├── migrations/        ← Versioned schema changes
│   └── objects/           ← Views, stored procedures
├── .github/workflows/     ← CI/CD automation
└── scripts/               ← Deployment utilities
```

> *"Everything is version-controlled. No more manual changes in the Snowflake UI that get lost or can't be reproduced."*

---

### Part 2: Infrastructure as Code with Terraform (10 min)

#### 2.1 Show Terraform Configuration

```bash
# Show the main Terraform configuration
cat terraform/main.tf
```

**Highlight:**
- Databases, schemas, warehouses, roles all defined as code
- Dynamic resource creation using `for_each`
- Naming conventions enforced automatically

#### 2.2 Environment Configurations

```bash
# Compare dev vs prod configurations
echo "=== DEVELOPMENT ===" && head -30 terraform/environments/dev.tfvars
echo ""
echo "=== PRODUCTION ===" && head -30 terraform/environments/prod.tfvars
```

**Talking Points:**

| Setting | Dev | Prod |
|---------|-----|------|
| Warehouse Size | XSMALL | MEDIUM/LARGE |
| Auto Suspend | 60s | 300s |
| Data Retention | 1 day | 90 days |
| Credit Quota | 100 | 1000 |

> *"Same code, different configurations. We can spin up identical environments with predictable settings."*

#### 2.3 Run Terraform Plan

```bash
cd terraform
terraform plan -var-file="environments/dev.tfvars"
```

**Explain:**
> *"The plan shows exactly what will be created, modified, or destroyed. No surprises. This is reviewed before any changes are applied."*

#### 2.4 Apply Infrastructure (Optional - Live Demo)

```bash
# Only if you want to show a live deployment
terraform apply -var-file="environments/dev.tfvars"
```

Type `yes` to confirm.

#### 2.5 Verify in Snowflake

```sql
-- Run in Snowflake Worksheet
SHOW DATABASES LIKE 'MB_DEMO%';
SHOW WAREHOUSES LIKE 'MB_DEMO%';
SHOW ROLES LIKE 'MB_DEMO%';
```

> *"Everything we defined in code is now provisioned in Snowflake. Fully traceable, repeatable, and auditable."*

---

### Part 3: Database Objects Deployment (10 min)

#### 3.1 Show Migration Files

```bash
# Display versioned migrations
ls -la snowflake/migrations/
cat snowflake/migrations/V001__initial_schema_setup.sql | head -50
```

**Explain:**
> *"Migrations are versioned like code. V001 runs before V002. Each migration is idempotent - it can run multiple times safely."*

#### 3.2 Show Analytical Views

```bash
cat snowflake/objects/views/vw_transaction_analytics.sql
```

**Highlight the views:**
- `VW_REALTIME_TRANSACTIONS` - Last 30 days with categorizations
- `VW_MERCHANT_PERFORMANCE` - Aggregated merchant analytics  
- `VW_CUSTOMER_SEGMENTATION` - RFM-based segmentation
- `VW_DAILY_KPI` - YoY and WoW comparisons

#### 3.3 Show Stored Procedures

```bash
cat snowflake/objects/stored_procedures/sp_refresh_customer_360.sql
```

> *"Even complex business logic like Customer 360 is version-controlled and deployed automatically."*

#### 3.4 Run Deployment Script

```bash
cd ..
export DRY_RUN=true  # Safe mode for demo
python scripts/deploy_objects.py
```

**Explain:**
> *"The script connects to Snowflake, runs migrations in order, then deploys stored procedures and views. All automated, all logged."*

---

### Part 4: CI/CD Pipeline Demo (10 min)

#### 4.1 Show GitHub Workflows

```bash
ls -la .github/workflows/
cat .github/workflows/terraform-plan.yml | head -60
```

#### 4.2 Explain the Pipeline Flow

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
│  │ (Automatic)  │   │ (After Dev)     │   │ (Manual Approval│   │
│  └──────────────┘   └─────────────────┘   └─────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

**Talking Points:**
- Every PR gets a security scan and terraform plan
- Plan is posted as a comment for review
- Merge to main auto-deploys to Dev, then Staging
- Production requires manual approval

#### 4.3 Show Live PR (Optional)

```bash
# Create a demo branch
git checkout -b demo/add-new-feature

# Make a small change
echo "-- Demo change" >> snowflake/objects/views/vw_transaction_analytics.sql

# Commit and push
git add .
git commit -m "demo: Add comment to views"
git push -u origin demo/add-new-feature

# Create PR
gh pr create --title "Demo: CI/CD Pipeline" --body "Demonstrating automated workflows"
```

> *"Watch GitHub Actions - it's already running security scans and generating a terraform plan."*

#### 4.4 Show Workflow Status

```bash
gh run list --limit 5
```

---

### Part 5: Live Changes Demo (5 min)

#### 5.1 Make an Infrastructure Change

```bash
# Edit warehouse size in dev.tfvars
# Change: size = "XSMALL" → size = "SMALL"
```

```bash
cd terraform
terraform plan -var-file="environments/dev.tfvars"
```

**Show the plan output highlighting the change:**
> *"Terraform shows exactly what will change. The warehouse size will be updated from XSMALL to SMALL."*

#### 5.2 Show Rollback Capability

> *"If something goes wrong, we can revert the code and re-apply. Terraform will bring the infrastructure back to the previous state. Full audit trail in Git."*

---

### Part 6: Summary & Benefits (5 min)

#### Key Benefits Demonstrated

| Benefit | How It's Achieved |
|---------|-------------------|
| **Version Control** | All changes tracked in Git |
| **Repeatability** | Same code = same infrastructure |
| **Visibility** | PR reviews before deployment |
| **Automation** | CI/CD reduces manual errors |
| **Security** | Secrets in GitHub, scanned code |
| **Auditability** | Complete history of all changes |
| **Environment Parity** | Dev/Staging/Prod from same code |

#### Cost Savings

> *"By automating Snowflake provisioning:*
> - *Reduced setup time from days to minutes*
> - *Eliminated configuration drift*
> - *Standardized security controls*
> - *Enabled self-service for teams"*

---

## 🔧 Troubleshooting During Demo

### Terraform Plan Fails

```bash
# Check environment variables
echo $SNOWFLAKE_ACCOUNT
echo $SNOWFLAKE_AUTHENTICATOR

# Reload if needed
set -a && source .env && set +a
```

### Connection Issues

```bash
# Test Python connection
python << 'EOF'
import snowflake.connector
import os
print(f"Account: {os.environ.get('SNOWFLAKE_ACCOUNT')}")
print(f"User: {os.environ.get('SNOWFLAKE_USER')}")
EOF
```

### GitHub CLI Not Working

```bash
# Login to GitHub CLI
gh auth login
```

---

## 📎 Quick Commands Reference

```bash
# Pre-Demo Setup
cd /Users/ffoo/mb-snowflake-devops-demo
source venv/bin/activate
set -a && source .env && set +a

# Terraform (using Makefile)
make plan                 # Plan dev environment
make apply                # Apply dev environment

# Terraform (direct commands)
cd terraform
terraform init
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"

# Deploy SQL Objects
cd ..
export DRY_RUN=true       # Safe mode for demo
python scripts/deploy_objects.py

# Git/GitHub
git status
git checkout -b demo/feature-branch
gh pr create --title "Demo PR" --body "Demo"
gh pr list
gh run list
```

---

## 🎤 Q&A Preparation

**Q: How do you handle secrets?**
> Secrets are stored in GitHub Secrets, never in code. For local development, we use `.env` files that are gitignored.

**Q: What about existing Snowflake resources?**
> Terraform can import existing resources. We can gradually bring existing infrastructure under management.

**Q: How do you handle database migrations in production?**
> Migrations are versioned and tested in Dev/Staging first. Production deployments require approval and can be rolled back.

**Q: What's the learning curve?**
> Terraform syntax is straightforward. Most engineers can be productive within a week. The investment pays off quickly in reduced manual work.

**Q: How do you handle emergencies?**
> We have workflow_dispatch triggers for manual deployments, and ACCOUNTADMIN access for true emergencies. All actions are logged.

---

## 📚 Additional Resources

- [Snowflake Terraform Provider Docs](https://registry.terraform.io/providers/Snowflake-Labs/snowflake/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/)

---

## 📖 Related Documentation

| Document | Description |
|----------|-------------|
| [SETUP_GUIDE.md](SETUP_GUIDE.md) | Complete setup instructions |
| [README.md](README.md) | Project overview |
| `terraform/environments/*.tfvars` | Environment configurations |

---

**Demo Created By:** DevOps Team  
**Last Updated:** December 2024

