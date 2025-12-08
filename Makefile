# =============================================================================
# MB SNOWFLAKE DEVOPS DEMO
# Makefile for common operations
# =============================================================================

.PHONY: help init plan apply destroy fmt validate lint deploy-objects setup

# Default target
help:
	@echo "Mb Snowflake DevOps Demo"
	@echo "=============================="
	@echo ""
	@echo "Terraform Commands:"
	@echo "  make init          - Initialize Terraform"
	@echo "  make plan          - Plan changes (dev environment)"
	@echo "  make plan-staging  - Plan changes (staging environment)"
	@echo "  make plan-prod     - Plan changes (prod environment)"
	@echo "  make apply         - Apply changes (dev environment)"
	@echo "  make apply-staging - Apply changes (staging environment)"
	@echo "  make apply-prod    - Apply changes (prod environment)"
	@echo "  make destroy       - Destroy resources (dev environment)"
	@echo "  make fmt           - Format Terraform files"
	@echo "  make validate      - Validate Terraform configuration"
	@echo ""
	@echo "SQL Commands:"
	@echo "  make lint          - Lint SQL files with sqlfluff"
	@echo "  make deploy-objects - Deploy Snowflake objects (migrations, views, procedures)"
	@echo ""
	@echo "Setup Commands:"
	@echo "  make setup         - Setup Python virtual environment"
	@echo ""

# Terraform commands
init:
	cd terraform && terraform init

fmt:
	cd terraform && terraform fmt -recursive

validate: init
	cd terraform && terraform validate

plan: init
	cd terraform && terraform plan -var-file="environments/dev.tfvars"

plan-staging: init
	cd terraform && terraform plan -var-file="environments/staging.tfvars"

plan-prod: init
	cd terraform && terraform plan -var-file="environments/prod.tfvars"

apply: init
	cd terraform && terraform apply -var-file="environments/dev.tfvars"

apply-staging: init
	cd terraform && terraform apply -var-file="environments/staging.tfvars"

apply-prod: init
	cd terraform && terraform apply -var-file="environments/prod.tfvars"

destroy:
	cd terraform && terraform destroy -var-file="environments/dev.tfvars"

# SQL commands
lint:
	sqlfluff lint snowflake/ --dialect snowflake --exclude-rules L016,L031

deploy-objects:
	python scripts/deploy_objects.py

# Setup commands
setup:
	python3 -m venv venv
	. venv/bin/activate && pip install -r requirements.txt
	@echo ""
	@echo "Setup complete! Activate with: source venv/bin/activate"

