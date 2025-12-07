#!/usr/bin/env bash
# =============================================================================
# MB SNOWFLAKE DEVOPS DEMO
# Interactive Demo Script
# =============================================================================
#
# This script provides a guided walkthrough of the Snowflake DevOps demo,
# showcasing Infrastructure as Code and CI/CD capabilities.
#
# Usage:
#   chmod +x scripts/demo.sh
#   ./scripts/demo.sh
#
# Prerequisites:
#   - Terraform installed
#   - Python 3.9+ with venv activated
#   - Snowflake credentials configured in .env
#   - GitHub CLI (gh) installed and authenticated
#
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}  $1${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_step() {
    echo -e "${CYAN}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_code() {
    echo -e "${WHITE}   \$ $1${NC}"
}

pause() {
    echo ""
    read -p "$(echo -e ${YELLOW}Press Enter to continue...${NC})" </dev/tty
    echo ""
}

confirm() {
    echo ""
    read -p "$(echo -e ${YELLOW}$1 [y/N]: ${NC})" response </dev/tty
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# =============================================================================
# Demo Sections
# =============================================================================

show_welcome() {
    clear
    echo ""
    echo -e "${PURPLE}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════════╗
    ║                                                                    ║
    ║     ███╗   ███╗██████╗     ███████╗███╗   ██╗ ██████╗ ██╗    ██╗  ║
    ║     ████╗ ████║██╔══██╗    ██╔════╝████╗  ██║██╔═══██╗██║    ██║  ║
    ║     ██╔████╔██║██████╔╝    ███████╗██╔██╗ ██║██║   ██║██║ █╗ ██║  ║
    ║     ██║╚██╔╝██║██╔══██╗    ╚════██║██║╚██╗██║██║   ██║██║███╗██║  ║
    ║     ██║ ╚═╝ ██║██████╔╝    ███████║██║ ╚████║╚██████╔╝╚███╔███╔╝  ║
    ║     ╚═╝     ╚═╝╚═════╝     ╚══════╝╚═╝  ╚═══╝ ╚═════╝  ╚══╝╚══╝   ║
    ║                                                                    ║
    ║              SNOWFLAKE DEVOPS DEMO                                ║
    ║              Infrastructure as Code & CI/CD                       ║
    ║                                                                    ║
    ╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
    echo -e "${WHITE}This interactive demo will walk you through:${NC}"
    echo ""
    echo -e "  ${CYAN}1.${NC} Project Structure Overview"
    echo -e "  ${CYAN}2.${NC} Terraform Infrastructure as Code"
    echo -e "  ${CYAN}3.${NC} Snowflake Resource Provisioning"
    echo -e "  ${CYAN}4.${NC} Database Object Deployment"
    echo -e "  ${CYAN}5.${NC} CI/CD Pipeline Demonstration"
    echo -e "  ${CYAN}6.${NC} Complete Deployment Walkthrough"
    echo ""
    pause
}

check_prerequisites() {
    print_header "PREREQUISITE CHECK"
    
    local all_good=true
    
    # Check Terraform
    print_step "Checking Terraform..."
    if command -v terraform &> /dev/null; then
        version=$(terraform --version | head -n1)
        print_success "Terraform installed: $version"
    else
        print_error "Terraform not installed"
        all_good=false
    fi
    
    # Check Python
    print_step "Checking Python..."
    if command -v python3 &> /dev/null; then
        version=$(python3 --version)
        print_success "Python installed: $version"
    else
        print_error "Python 3 not installed"
        all_good=false
    fi
    
    # Check GitHub CLI
    print_step "Checking GitHub CLI..."
    if command -v gh &> /dev/null; then
        version=$(gh --version | head -n1)
        print_success "GitHub CLI installed: $version"
    else
        print_warning "GitHub CLI not installed (optional for CI/CD demo)"
    fi
    
    # Check environment variables
    print_step "Checking Snowflake environment variables..."
    if [[ -n "$SNOWFLAKE_ACCOUNT" && -n "$SNOWFLAKE_USER" ]]; then
        print_success "Snowflake credentials configured"
        print_info "Account: $SNOWFLAKE_ACCOUNT"
        print_info "User: $SNOWFLAKE_USER"
    else
        print_warning "Snowflake credentials not set"
        print_info "Run: source .env (after configuring .env file)"
    fi
    
    echo ""
    if $all_good; then
        print_success "All required prerequisites met!"
    else
        print_warning "Some prerequisites are missing. Demo may be limited."
    fi
    
    pause
}

demo_project_structure() {
    print_header "PROJECT STRUCTURE OVERVIEW"
    
    echo -e "${WHITE}This project follows a well-organized structure for DevOps:${NC}"
    echo ""
    
    cd "$PROJECT_ROOT"
    
    print_step "Displaying project tree..."
    echo ""
    
    # Display structured tree manually for better control
    echo -e "${CYAN}mb-snowflake-devops-demo/${NC}"
    echo "├── terraform/                    # Infrastructure as Code"
    echo "│   ├── main.tf                   # Main resource definitions"
    echo "│   ├── variables.tf              # Variable declarations"
    echo "│   ├── outputs.tf                # Output definitions"
    echo "│   ├── providers.tf              # Provider configuration"
    echo "│   └── environments/             # Environment configs"
    echo "│       ├── dev.tfvars            # Development"
    echo "│       ├── staging.tfvars        # Staging"
    echo "│       └── prod.tfvars           # Production"
    echo "│"
    echo "├── .github/workflows/            # CI/CD Pipelines"
    echo "│   ├── terraform-plan.yml        # PR validation"
    echo "│   ├── terraform-apply.yml       # Deployment"
    echo "│   └── snowflake-objects.yml     # SQL deployment"
    echo "│"
    echo "├── snowflake/                    # Database Objects"
    echo "│   ├── migrations/               # Versioned migrations"
    echo "│   └── objects/                  # Stored procs & views"
    echo "│"
    echo "├── scripts/                      # Automation scripts"
    echo "│   ├── deploy_objects.py         # Python deployer"
    echo "│   └── demo.sh                   # This demo script"
    echo "│"
    echo "├── Makefile                      # Shortcut commands"
    echo "├── requirements.txt              # Python dependencies"
    echo "└── README.md                     # Documentation"
    echo ""
    
    print_info "Key components:"
    echo -e "  • ${WHITE}terraform/${NC}    - Snowflake infrastructure definitions"
    echo -e "  • ${WHITE}snowflake/${NC}    - SQL scripts for database objects"
    echo -e "  • ${WHITE}.github/${NC}      - Automated CI/CD workflows"
    echo ""
    
    pause
}

demo_terraform_iac() {
    print_header "TERRAFORM INFRASTRUCTURE AS CODE"
    
    cd "$PROJECT_ROOT/terraform"
    
    echo -e "${WHITE}Terraform manages Snowflake resources declaratively:${NC}"
    echo ""
    
    # Show resources managed
    print_step "Resources managed by Terraform:"
    echo ""
    echo "  📦 Databases      - Analytics & Staging databases"
    echo "  📂 Schemas        - RAW, TRANSFORMED, MARTS layers"
    echo "  🏭 Warehouses     - Analytics & ETL compute"
    echo "  👥 Roles          - Analyst, Engineer, Admin"
    echo "  📊 Resource Monitor - Cost management"
    echo ""
    
    pause
    
    # Show provider configuration
    print_step "Snowflake Provider Configuration (providers.tf):"
    echo ""
    print_code "cat providers.tf"
    echo ""
    head -30 providers.tf | sed 's/^/  /'
    echo ""
    
    pause
    
    # Show environment comparison
    print_step "Environment Configuration Comparison:"
    echo ""
    echo "┌──────────────────┬─────────────┬──────────────┬──────────────┐"
    echo "│ Setting          │ Development │ Staging      │ Production   │"
    echo "├──────────────────┼─────────────┼──────────────┼──────────────┤"
    echo "│ Warehouse Size   │ XSMALL      │ SMALL        │ MEDIUM/LARGE │"
    echo "│ Auto Suspend     │ 60s         │ 120s         │ 300s         │"
    echo "│ Max Clusters     │ 1           │ 2            │ 3-4          │"
    echo "│ Data Retention   │ 1 day       │ 7 days       │ 90 days      │"
    echo "│ Credit Quota     │ 100         │ 100          │ 1000         │"
    echo "└──────────────────┴─────────────┴──────────────┴──────────────┘"
    echo ""
    
    pause
    
    # Initialize Terraform
    if confirm "Initialize Terraform and show available commands?"; then
        print_step "Initializing Terraform..."
        print_code "terraform init"
        echo ""
        terraform init 2>&1 | tail -10
        echo ""
        print_success "Terraform initialized!"
        echo ""
        
        print_step "Validating configuration..."
        print_code "terraform validate"
        terraform validate
        echo ""
    fi
    
    pause
}

demo_terraform_plan() {
    print_header "TERRAFORM PLAN (Dev Environment)"
    
    cd "$PROJECT_ROOT/terraform"
    
    echo -e "${WHITE}The plan command shows what changes Terraform will make:${NC}"
    echo ""
    
    if [[ -z "$SNOWFLAKE_ACCOUNT" ]]; then
        print_warning "Snowflake credentials not configured."
        print_info "Showing example plan output instead..."
        echo ""
        echo "  Terraform will perform the following actions:"
        echo ""
        echo "  ${GREEN}+ snowflake_database.databases[\"analytics\"]${NC}"
        echo "  ${GREEN}+ snowflake_database.databases[\"staging\"]${NC}"
        echo "  ${GREEN}+ snowflake_schema.schemas[\"analytics_raw\"]${NC}"
        echo "  ${GREEN}+ snowflake_schema.schemas[\"analytics_transformed\"]${NC}"
        echo "  ${GREEN}+ snowflake_schema.schemas[\"analytics_marts\"]${NC}"
        echo "  ${GREEN}+ snowflake_warehouse.warehouses[\"analytics\"]${NC}"
        echo "  ${GREEN}+ snowflake_warehouse.warehouses[\"etl\"]${NC}"
        echo "  ${GREEN}+ snowflake_role.roles[\"analyst\"]${NC}"
        echo "  ${GREEN}+ snowflake_role.roles[\"engineer\"]${NC}"
        echo "  ${GREEN}+ snowflake_role.roles[\"admin\"]${NC}"
        echo "  ${GREEN}+ snowflake_resource_monitor.main${NC}"
        echo ""
        echo "  Plan: 11 to add, 0 to change, 0 to destroy."
        echo ""
    else
        if confirm "Run terraform plan for development environment?"; then
            print_step "Running Terraform plan..."
            print_code "terraform plan -var-file=\"environments/dev.tfvars\""
            echo ""
            terraform plan -var-file="environments/dev.tfvars" 2>&1
            echo ""
        fi
    fi
    
    pause
}

demo_sql_objects() {
    print_header "SNOWFLAKE DATABASE OBJECTS"
    
    cd "$PROJECT_ROOT"
    
    echo -e "${WHITE}Database objects are version-controlled as SQL files:${NC}"
    echo ""
    
    print_step "Migration files (versioned schema changes):"
    echo ""
    ls -la snowflake/migrations/*.sql 2>/dev/null | awk '{print "  " $NF}' || echo "  No migration files found"
    echo ""
    
    print_step "Stored Procedures:"
    echo ""
    ls -la snowflake/objects/stored_procedures/*.sql 2>/dev/null | awk '{print "  " $NF}' || echo "  No stored procedure files found"
    echo ""
    
    print_step "Views:"
    echo ""
    ls -la snowflake/objects/views/*.sql 2>/dev/null | awk '{print "  " $NF}' || echo "  No view files found"
    echo ""
    
    pause
    
    # Show data architecture
    print_step "Data Architecture (Medallion Pattern):"
    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────────┐"
    echo "  │                         RAW Schema                               │"
    echo "  │  ┌──────────────────────┐    ┌──────────────────────┐           │"
    echo "  │  │ CUSTOMER_TRANSACTIONS│    │   CUSTOMER_PROFILE   │           │"
    echo "  │  │       _RAW           │    │       _RAW           │           │"
    echo "  │  └──────────┬───────────┘    └──────────┬───────────┘           │"
    echo "  │             │ Stream                     │ Stream                │"
    echo "  └─────────────┼───────────────────────────┼───────────────────────┘"
    echo "                ▼                            ▼"
    echo "  ┌─────────────────────────────────────────────────────────────────┐"
    echo "  │                     TRANSFORMED Schema                           │"
    echo "  │  ┌──────────────────────┐    ┌──────────────────────┐           │"
    echo "  │  │ CUSTOMER_TRANSACTIONS│    │   CUSTOMER_PROFILE   │           │"
    echo "  │  │   (Cleansed)         │    │     (Cleansed)       │           │"
    echo "  │  └──────────┬───────────┘    └──────────┬───────────┘           │"
    echo "  └─────────────┼───────────────────────────┼───────────────────────┘"
    echo "                │                            │"
    echo "                ▼                            ▼"
    echo "  ┌─────────────────────────────────────────────────────────────────┐"
    echo "  │                        MARTS Schema                              │"
    echo "  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │"
    echo "  │  │ DAILY_SUMMARY   │  │  CUSTOMER_360   │  │  Views (4)      │  │"
    echo "  │  └─────────────────┘  └─────────────────┘  └─────────────────┘  │"
    echo "  └─────────────────────────────────────────────────────────────────┘"
    echo ""
    
    pause
    
    # Show sample view
    print_step "Sample View: VW_CUSTOMER_SEGMENTATION (RFM Analysis)"
    echo ""
    head -40 snowflake/objects/views/vw_transaction_analytics.sql | sed 's/^/  /'
    echo ""
    
    pause
}

demo_cicd_pipeline() {
    print_header "CI/CD PIPELINE OVERVIEW"
    
    cd "$PROJECT_ROOT"
    
    echo -e "${WHITE}GitHub Actions automates the deployment workflow:${NC}"
    echo ""
    
    print_step "Pipeline Flow:"
    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────────┐"
    echo "  │                        Pull Request                              │"
    echo "  ├─────────────────────────────────────────────────────────────────┤"
    echo "  │  ┌──────────┐   ┌──────────────┐   ┌─────────────────────────┐  │"
    echo "  │  │ Security │──▶│ Format Check │──▶│ Terraform Plan (Dev)    │  │"
    echo "  │  │   Scan   │   │              │   │ + PR Comment            │  │"
    echo "  │  └──────────┘   └──────────────┘   └─────────────────────────┘  │"
    echo "  └─────────────────────────────────────────────────────────────────┘"
    echo "                              │"
    echo "                              ▼ (Merge)"
    echo "  ┌─────────────────────────────────────────────────────────────────┐"
    echo "  │                        Main Branch                               │"
    echo "  ├─────────────────────────────────────────────────────────────────┤"
    echo "  │  ┌──────────────┐   ┌─────────────────┐   ┌─────────────────┐   │"
    echo "  │  │ Deploy Dev   │──▶│ Deploy Staging  │──▶│ Deploy Prod     │   │"
    echo "  │  │ (Automatic)  │   │ (After Dev)     │   │ (Manual Trigger)│   │"
    echo "  │  └──────────────┘   └─────────────────┘   └─────────────────┘   │"
    echo "  └─────────────────────────────────────────────────────────────────┘"
    echo ""
    
    pause
    
    print_step "Available Workflows:"
    echo ""
    echo "  📄 terraform-plan.yml"
    echo "     • Trigger: Pull Request to main/develop"
    echo "     • Actions: Security scan, format check, plan"
    echo "     • Output: Plan posted as PR comment"
    echo ""
    echo "  📄 terraform-apply.yml"
    echo "     • Trigger: Push to main, or manual dispatch"
    echo "     • Actions: Plan and apply to environments"
    echo "     • Flow: Dev → Staging → Production"
    echo ""
    echo "  📄 snowflake-objects.yml"
    echo "     • Trigger: Changes to snowflake/ directory"
    echo "     • Actions: Lint SQL, deploy objects"
    echo "     • Support: Dry-run mode for testing"
    echo ""
    
    pause
    
    # Show workflow dispatch
    print_step "Manual Workflow Triggers (via GitHub CLI):"
    echo ""
    print_code "# Deploy infrastructure to specific environment"
    print_code "gh workflow run 'Terraform Apply' --field environment=dev"
    echo ""
    print_code "# Deploy SQL objects with dry-run"
    print_code "gh workflow run 'Deploy Snowflake Objects' --field environment=dev --field dry_run=true"
    echo ""
    
    pause
}

demo_deploy_objects() {
    print_header "DATABASE OBJECT DEPLOYMENT"
    
    cd "$PROJECT_ROOT"
    
    echo -e "${WHITE}Deploy Snowflake objects using the Python script:${NC}"
    echo ""
    
    print_step "Deployment script: scripts/deploy_objects.py"
    echo ""
    echo "  Features:"
    echo "  • Versioned migrations support"
    echo "  • Stored procedure deployment"
    echo "  • View deployment"
    echo "  • Dry-run mode for testing"
    echo "  • Environment-specific placeholders"
    echo ""
    
    # Check if credentials are set
    if [[ -z "$SNOWFLAKE_ACCOUNT" ]]; then
        print_warning "Snowflake credentials not configured."
        print_info "Set environment variables first:"
        echo ""
        print_code "source .env"
        echo ""
        print_info "Showing dry-run example..."
        echo ""
        export DRY_RUN=true
    fi
    
    if confirm "Run deployment script in DRY-RUN mode?"; then
        print_step "Running deployment (dry-run mode)..."
        echo ""
        export DRY_RUN=true
        export ENVIRONMENT=dev
        
        if [[ -n "$SNOWFLAKE_ACCOUNT" ]]; then
            python3 scripts/deploy_objects.py 2>&1 || {
                print_warning "Script execution failed (expected if not connected)"
                echo ""
            }
        else
            print_info "Skipping actual execution (no credentials)"
            echo ""
            echo "  Would execute:"
            echo "    1. Connect to Snowflake"
            echo "    2. Deploy migrations (V001, V002)"
            echo "    3. Deploy stored procedures (sp_refresh_customer_360.sql)"
            echo "    4. Deploy views (vw_transaction_analytics.sql)"
            echo "    5. Disconnect"
            echo ""
        fi
    fi
    
    pause
}

demo_full_workflow() {
    print_header "COMPLETE DEPLOYMENT WORKFLOW"
    
    cd "$PROJECT_ROOT"
    
    echo -e "${WHITE}Full deployment workflow simulation:${NC}"
    echo ""
    
    print_step "Step 1: Developer creates feature branch"
    print_code "git checkout -b feature/add-new-view"
    echo ""
    
    print_step "Step 2: Developer adds new SQL view"
    print_code "echo 'CREATE VIEW...' > snowflake/objects/views/vw_new_feature.sql"
    echo ""
    
    print_step "Step 3: Developer commits and pushes"
    print_code "git add . && git commit -m 'feat: add new feature view'"
    print_code "git push -u origin feature/add-new-view"
    echo ""
    
    print_step "Step 4: Developer creates Pull Request"
    print_code "gh pr create --title 'Add new feature view' --body '...'"
    echo ""
    
    print_step "Step 5: CI/CD automatically runs:"
    echo "  • 🔍 SQL linting (sqlfluff)"
    echo "  • 🛡️ Security scan (tfsec)"
    echo "  • 📋 Terraform plan (if TF files changed)"
    echo "  • 💬 Plan posted as PR comment"
    echo ""
    
    print_step "Step 6: After PR approval and merge:"
    echo "  • 🚀 Auto-deploy to Development"
    echo "  • 🚀 Auto-deploy to Staging (after Dev succeeds)"
    echo "  • ⏸️ Production requires manual approval"
    echo ""
    
    print_step "Step 7: Monitor deployment in GitHub Actions"
    print_code "gh run list --workflow terraform-apply.yml"
    echo ""
    
    pause
}

show_makefile_commands() {
    print_header "AVAILABLE MAKEFILE COMMANDS"
    
    cd "$PROJECT_ROOT"
    
    echo -e "${WHITE}Quick reference for common operations:${NC}"
    echo ""
    
    make help 2>/dev/null || {
        echo "  Terraform Commands:"
        echo "    make init          - Initialize Terraform"
        echo "    make plan          - Plan changes (dev environment)"
        echo "    make plan-staging  - Plan changes (staging environment)"
        echo "    make plan-prod     - Plan changes (prod environment)"
        echo "    make apply         - Apply changes (dev environment)"
        echo "    make destroy       - Destroy resources (dev environment)"
        echo "    make fmt           - Format Terraform files"
        echo "    make validate      - Validate Terraform configuration"
        echo ""
        echo "  SQL Commands:"
        echo "    make lint          - Lint SQL files"
        echo "    make deploy-objects - Deploy Snowflake objects"
        echo ""
        echo "  Setup Commands:"
        echo "    make setup         - Setup Python environment"
    }
    echo ""
    
    pause
}

show_summary() {
    print_header "DEMO SUMMARY"
    
    echo -e "${WHITE}What we covered:${NC}"
    echo ""
    echo "  ✅ Project structure and organization"
    echo "  ✅ Terraform Infrastructure as Code for Snowflake"
    echo "  ✅ Environment-specific configurations (dev/staging/prod)"
    echo "  ✅ Database object deployment (migrations, views, procedures)"
    echo "  ✅ CI/CD pipeline with GitHub Actions"
    echo "  ✅ Complete workflow from development to production"
    echo ""
    
    echo -e "${WHITE}Key Benefits:${NC}"
    echo ""
    echo "  🔄 Version Control    - All changes tracked in Git"
    echo "  🔁 Repeatability      - Same code deploys identical infrastructure"
    echo "  👁️ Visibility         - PR reviews catch issues early"
    echo "  🚀 Automation         - Reduce manual errors and save time"
    echo "  🔐 Security           - Secrets managed in GitHub, not in code"
    echo "  📊 Auditability       - Complete history of all changes"
    echo ""
    
    echo -e "${WHITE}Next Steps:${NC}"
    echo ""
    echo "  1. Configure your Snowflake credentials in .env"
    echo "  2. Run 'make apply' to deploy development infrastructure"
    echo "  3. Run 'python scripts/deploy_objects.py' to deploy SQL objects"
    echo "  4. Set up GitHub secrets for CI/CD"
    echo "  5. Create a feature branch and test the workflow"
    echo ""
    
    echo -e "${GREEN}Thank you for exploring the Mb Snowflake DevOps Demo!${NC}"
    echo ""
}

# =============================================================================
# Main Menu
# =============================================================================

show_menu() {
    clear
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}          ${WHITE}MB SNOWFLAKE DEVOPS DEMO${NC}                       ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${CYAN}1.${NC} Check Prerequisites"
    echo -e "  ${CYAN}2.${NC} Project Structure Overview"
    echo -e "  ${CYAN}3.${NC} Terraform Infrastructure as Code"
    echo -e "  ${CYAN}4.${NC} Terraform Plan Demo"
    echo -e "  ${CYAN}5.${NC} Snowflake Database Objects"
    echo -e "  ${CYAN}6.${NC} CI/CD Pipeline Overview"
    echo -e "  ${CYAN}7.${NC} Deploy Objects Demo"
    echo -e "  ${CYAN}8.${NC} Complete Workflow Demo"
    echo -e "  ${CYAN}9.${NC} Makefile Commands Reference"
    echo ""
    echo -e "  ${CYAN}A.${NC} ${GREEN}Run Full Demo (All Sections)${NC}"
    echo -e "  ${CYAN}Q.${NC} Quit"
    echo ""
    echo -n -e "${YELLOW}Select an option: ${NC}"
}

run_full_demo() {
    show_welcome
    check_prerequisites
    demo_project_structure
    demo_terraform_iac
    demo_terraform_plan
    demo_sql_objects
    demo_cicd_pipeline
    demo_deploy_objects
    demo_full_workflow
    show_makefile_commands
    show_summary
}

# =============================================================================
# Main Entry Point
# =============================================================================

main() {
    # Check if running in interactive mode
    if [[ "$1" == "--full" ]]; then
        run_full_demo
        exit 0
    fi
    
    while true; do
        show_menu
        read -r choice </dev/tty
        
        case $choice in
            1) check_prerequisites ;;
            2) demo_project_structure ;;
            3) demo_terraform_iac ;;
            4) demo_terraform_plan ;;
            5) demo_sql_objects ;;
            6) demo_cicd_pipeline ;;
            7) demo_deploy_objects ;;
            8) demo_full_workflow ;;
            9) show_makefile_commands ;;
            [aA]) run_full_demo ;;
            [qQ]) 
                echo ""
                print_success "Thank you for using the demo!"
                echo ""
                exit 0
                ;;
            *)
                print_error "Invalid option. Please try again."
                sleep 1
                ;;
        esac
    done
}

# Run main function
main "$@"

