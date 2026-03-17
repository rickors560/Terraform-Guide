.PHONY: init plan apply destroy fmt validate docs lint cost clean help

# ──────────────────────────────────────────────
# Configuration
# ──────────────────────────────────────────────
ENV          ?= dev
COMPONENT    ?=
PROJECT      ?= myapp
AWS_REGION   ?= ap-south-1

# Resolve the target directory
ifdef COMPONENT
  TARGET_DIR := components/$(COMPONENT)
else
  TARGET_DIR := environments/$(ENV)
endif

# Common Terraform flags
TF_FLAGS     := -var-file=../../environments/$(ENV)/terraform.tfvars
TF_PLAN_FILE := tfplan

# ──────────────────────────────────────────────
# Colors
# ──────────────────────────────────────────────
BLUE   := \033[0;34m
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
RESET  := \033[0m

# ──────────────────────────────────────────────
# Targets
# ──────────────────────────────────────────────

## help: Show this help message
help:
	@echo ""
	@echo "$(BLUE)Terraform AWS Masterclass — Makefile$(RESET)"
	@echo ""
	@echo "$(GREEN)Usage:$(RESET)"
	@echo "  make <target> [ENV=dev|staging|prod] [COMPONENT=vpc|eks|rds|...]"
	@echo ""
	@echo "$(GREEN)Examples:$(RESET)"
	@echo "  make init                    # Init dev environment"
	@echo "  make plan ENV=staging        # Plan staging environment"
	@echo "  make apply ENV=prod          # Apply prod environment"
	@echo "  make plan COMPONENT=vpc      # Plan VPC component for dev"
	@echo "  make destroy ENV=dev         # Destroy dev environment"
	@echo "  make fmt                     # Format all Terraform files"
	@echo "  make lint                    # Run TFLint on all modules"
	@echo ""
	@echo "$(GREEN)Targets:$(RESET)"
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## /  /' | sort
	@echo ""

## init: Initialize Terraform working directory
init:
	@echo "$(BLUE)Initializing Terraform in $(TARGET_DIR)...$(RESET)"
	@cd $(TARGET_DIR) && terraform init

## plan: Generate and show an execution plan
plan:
	@echo "$(BLUE)Planning Terraform in $(TARGET_DIR) (ENV=$(ENV))...$(RESET)"
	@cd $(TARGET_DIR) && terraform plan -out=$(TF_PLAN_FILE)

## apply: Apply the planned changes
apply:
	@echo "$(YELLOW)Applying Terraform in $(TARGET_DIR) (ENV=$(ENV))...$(RESET)"
	@cd $(TARGET_DIR) && terraform apply $(TF_PLAN_FILE)

## destroy: Destroy all managed infrastructure
destroy:
	@echo "$(RED)Destroying Terraform in $(TARGET_DIR) (ENV=$(ENV))...$(RESET)"
	@cd $(TARGET_DIR) && terraform destroy

## fmt: Format all Terraform files recursively
fmt:
	@echo "$(BLUE)Formatting Terraform files...$(RESET)"
	@terraform fmt -recursive .
	@echo "$(GREEN)Done.$(RESET)"

## validate: Validate Terraform configuration in target directory
validate:
	@echo "$(BLUE)Validating Terraform in $(TARGET_DIR)...$(RESET)"
	@cd $(TARGET_DIR) && terraform validate

## docs: Generate documentation for all modules
docs:
	@echo "$(BLUE)Generating module documentation...$(RESET)"
	@for dir in modules/*/; do \
		if [ -f "$$dir/main.tf" ]; then \
			echo "  Generating docs for $$dir"; \
			terraform-docs markdown table "$$dir" > "$$dir/README.md"; \
		fi; \
	done
	@echo "$(GREEN)Done.$(RESET)"

## lint: Run TFLint on all Terraform directories
lint:
	@echo "$(BLUE)Running TFLint...$(RESET)"
	@for dir in modules/*/ components/*/ environments/*/; do \
		if [ -f "$$dir/main.tf" ]; then \
			echo "  Linting $$dir"; \
			cd "$$dir" && tflint --init && tflint && cd - > /dev/null; \
		fi; \
	done
	@echo "$(GREEN)Done.$(RESET)"

## cost: Estimate infrastructure costs with Infracost
cost:
	@echo "$(BLUE)Estimating costs for $(TARGET_DIR)...$(RESET)"
	@cd $(TARGET_DIR) && infracost breakdown --path .

## clean: Remove Terraform caches and plan files
clean:
	@echo "$(BLUE)Cleaning Terraform caches and plan files...$(RESET)"
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "tfplan" -delete 2>/dev/null || true
	@find . -type f -name "*.tfstate.backup" -delete 2>/dev/null || true
	@find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "$(GREEN)Done.$(RESET)"

## bootstrap-init: Initialize the bootstrap backend
bootstrap-init:
	@echo "$(BLUE)Initializing bootstrap...$(RESET)"
	@cd bootstrap && terraform init

## bootstrap-apply: Create the S3 + DynamoDB backend
bootstrap-apply:
	@echo "$(BLUE)Applying bootstrap...$(RESET)"
	@cd bootstrap && terraform plan -out=$(TF_PLAN_FILE) && terraform apply $(TF_PLAN_FILE)

## bootstrap-destroy: Destroy the backend (use with extreme caution)
bootstrap-destroy:
	@echo "$(RED)Destroying bootstrap backend...$(RESET)"
	@cd bootstrap && terraform destroy

## check: Run all pre-commit hooks on all files
check:
	@echo "$(BLUE)Running pre-commit hooks...$(RESET)"
	@pre-commit run --all-files

## security: Run Checkov security scan
security:
	@echo "$(BLUE)Running Checkov security scan...$(RESET)"
	@checkov -d $(TARGET_DIR) --framework terraform

.DEFAULT_GOAL := help
