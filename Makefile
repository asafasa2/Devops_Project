# DevOps Practice Environment Makefile

.PHONY: help dev staging prod terraform-init terraform-plan terraform-apply ansible-config clean

# Default environment
ENV ?= dev

help: ## Show this help message
	@echo "DevOps Practice Environment"
	@echo "=========================="
	@echo ""
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Docker Compose Commands
dev: ## Start development environment
	@./scripts/deploy.sh dev up

staging: ## Start staging environment
	@./scripts/deploy.sh staging up

prod: ## Start production environment
	@./scripts/deploy.sh prod up

stop: ## Stop all services for specified environment
	@./scripts/deploy.sh $(ENV) down

restart: ## Restart all services for specified environment
	@./scripts/deploy.sh $(ENV) restart

logs: ## Show logs for specified environment
	@./scripts/deploy.sh $(ENV) logs

status: ## Show service status for specified environment
	@./scripts/deploy.sh $(ENV) ps

# Terraform Commands
terraform-init: ## Initialize Terraform
	@./scripts/terraform-deploy.sh $(ENV) init

terraform-plan: ## Plan Terraform changes
	@./scripts/terraform-deploy.sh $(ENV) plan

terraform-apply: ## Apply Terraform changes
	@./scripts/terraform-deploy.sh $(ENV) apply

terraform-destroy: ## Destroy Terraform infrastructure
	@./scripts/terraform-deploy.sh $(ENV) destroy

terraform-output: ## Show Terraform outputs
	@./scripts/terraform-deploy.sh $(ENV) output

# Ansible Commands
ansible-config: ## Run Ansible site configuration
	@./scripts/ansible-deploy.sh $(ENV) site.yml

ansible-deploy: ## Run Ansible deployment
	@./scripts/ansible-deploy.sh $(ENV) deploy.yml

ansible-maintenance: ## Run Ansible maintenance tasks
	@./scripts/ansible-deploy.sh $(ENV) maintenance.yml

# Full deployment workflow
deploy-full: terraform-init terraform-apply ansible-config dev ## Full deployment: Terraform + Ansible + Docker

# Cleanup Commands
clean: ## Clean up Docker resources
	@echo "🧹 Cleaning up Docker resources..."
	@docker system prune -f
	@docker volume prune -f
	@echo "✅ Cleanup completed"

clean-all: ## Clean up everything including volumes
	@echo "🧹 Cleaning up all Docker resources..."
	@docker system prune -a -f
	@docker volume prune -f
	@echo "✅ Complete cleanup finished"

# Development helpers
check-deps: ## Check if required dependencies are installed
	@echo "🔍 Checking dependencies..."
	@command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed"; exit 1; }
	@command -v docker-compose >/dev/null 2>&1 || { echo "❌ Docker Compose is required but not installed"; exit 1; }
	@command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform is required but not installed"; exit 1; }
	@command -v ansible >/dev/null 2>&1 || { echo "❌ Ansible is required but not installed"; exit 1; }
	@echo "✅ All dependencies are installed"

validate: ## Validate configuration files
	@echo "🔍 Validating configurations..."
	@cd terraform && terraform validate
	@cd ansible && ansible-playbook --syntax-check playbooks/site.yml
	@docker-compose -f docker-compose.yml -f docker-compose.dev.yml config >/dev/null
	@echo "✅ All configurations are valid"

# Quick start
quick-start: check-deps validate dev ## Quick start: Check deps, validate, and start dev environment