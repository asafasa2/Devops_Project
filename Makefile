# DevOps Practice Environment Makefile
# Comprehensive orchestration and management commands

.PHONY: help install setup clean build up down restart logs ps health test deploy backup restore

# Default environment
ENV ?= dev
SERVICE ?= all
REPLICAS ?= 1

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m

# Help target
help: ## Show this help message
	@echo "DevOps Practice Environment Management"
	@echo "======================================"
	@echo ""
	@echo "Usage: make <target> [ENV=<environment>] [SERVICE=<service>] [REPLICAS=<number>]"
	@echo ""
	@echo "Environments: dev (default), staging, prod, test"
	@echo "Services: all (default), app, db, monitoring, web, or specific service name"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-20s$(NC) %s\n", $$1, $$2}'

# Installation and setup
install: ## Install required dependencies
	@echo "$(BLUE)[INFO]$(NC) Installing dependencies..."
	@command -v docker >/dev/null 2>&1 || { echo "$(RED)[ERROR]$(NC) Docker is required but not installed"; exit 1; }
	@command -v docker-compose >/dev/null 2>&1 || { echo "$(RED)[ERROR]$(NC) Docker Compose is required but not installed"; exit 1; }
	@echo "$(GREEN)[SUCCESS]$(NC) Dependencies verified"

setup: install ## Initial setup of the environment
	@echo "$(BLUE)[INFO]$(NC) Setting up DevOps Practice Environment..."
	@cp -n .env.example .env || echo "$(YELLOW)[WARNING]$(NC) .env file already exists"
	@mkdir -p data/{postgres,redis,jenkins,grafana,prometheus,elasticsearch,nginx-cache,lab-workspaces}
	@mkdir -p logs/{nginx,app}
	@mkdir -p backups
	@mkdir -p test-results
	@mkdir -p coverage
	@chmod +x scripts/*.sh
	@echo "$(GREEN)[SUCCESS]$(NC) Environment setup complete"

# Docker Compose operations
build: ## Build service images
	@echo "$(BLUE)[INFO]$(NC) Building images for $(ENV) environment..."
	@./scripts/docker-compose-manager.sh build $(SERVICE)

up: ## Start services
	@echo "$(BLUE)[INFO]$(NC) Starting services in $(ENV) environment..."
	@ENVIRONMENT=$(ENV) ./scripts/docker-compose-manager.sh up $(SERVICE)

down: ## Stop and remove services
	@echo "$(BLUE)[INFO]$(NC) Stopping services in $(ENV) environment..."
	@ENVIRONMENT=$(ENV) ./scripts/docker-compose-manager.sh down $(SERVICE)

restart: ## Restart services
	@echo "$(BLUE)[INFO]$(NC) Restarting services in $(ENV) environment..."
	@ENVIRONMENT=$(ENV) ./scripts/docker-compose-manager.sh restart $(SERVICE)

logs: ## Show service logs
	@ENVIRONMENT=$(ENV) ./scripts/docker-compose-manager.sh logs $(SERVICE)

ps: ## Show running services
	@ENVIRONMENT=$(ENV) ./scripts/docker-compose-manager.sh ps

health: ## Check service health
	@ENVIRONMENT=$(ENV) ./scripts/docker-compose-manager.sh health $(SERVICE)

scale: ## Scale services (usage: make scale SERVICE=api-gateway REPLICAS=3)
	@echo "$(BLUE)[INFO]$(NC) Scaling $(SERVICE) to $(REPLICAS) replicas..."
	@ENVIRONMENT=$(ENV) ./scripts/docker-compose-manager.sh scale $(SERVICE) $(REPLICAS)

# Development shortcuts
dev-up: ## Start development environment
	@$(MAKE) up ENV=dev

dev-down: ## Stop development environment
	@$(MAKE) down ENV=dev

dev-logs: ## Show development logs
	@$(MAKE) logs ENV=dev

dev-build: ## Build development images
	@$(MAKE) build ENV=dev

# Staging shortcuts
staging-up: ## Start staging environment
	@$(MAKE) up ENV=staging

staging-down: ## Stop staging environment
	@$(MAKE) down ENV=staging

staging-deploy: ## Deploy to staging
	@$(MAKE) deploy ENV=staging

# Production shortcuts
prod-deploy: ## Deploy to production
	@$(MAKE) deploy ENV=prod

prod-health: ## Check production health
	@$(MAKE) health ENV=prod

prod-logs: ## Show production logs
	@$(MAKE) logs ENV=prod

# Testing
test: ## Run all tests
	@echo "$(BLUE)[INFO]$(NC) Running test suite..."
	@./scripts/docker-compose-manager.sh test

test-unit: ## Run unit tests only
	@echo "$(BLUE)[INFO]$(NC) Running unit tests..."
	@docker-compose -f docker-compose.test.yml up -d postgres-test redis-test
	@sleep 10
	@docker-compose -f docker-compose.test.yml run --rm api-gateway-test npm test
	@docker-compose -f docker-compose.test.yml run --rm user-service-test python -m pytest
	@docker-compose -f docker-compose.test.yml run --rm assessment-service-test python -m pytest
	@docker-compose -f docker-compose.test.yml down

test-integration: ## Run integration tests
	@echo "$(BLUE)[INFO]$(NC) Running integration tests..."
	@docker-compose -f docker-compose.test.yml up -d
	@sleep 30
	@docker-compose -f docker-compose.test.yml run --rm integration-tests
	@docker-compose -f docker-compose.test.yml down

test-e2e: ## Run end-to-end tests
	@echo "$(BLUE)[INFO]$(NC) Running e2e tests..."
	@docker-compose -f docker-compose.test.yml up -d
	@sleep 30
	@docker-compose -f docker-compose.test.yml run --rm e2e-tests
	@docker-compose -f docker-compose.test.yml down

# Deployment
deploy: ## Deploy to specified environment
	@echo "$(BLUE)[INFO]$(NC) Deploying to $(ENV) environment..."
	@./scripts/deploy.sh $(ENV)

rollback: ## Rollback deployment
	@echo "$(BLUE)[INFO]$(NC) Rolling back $(ENV) environment..."
	@./scripts/rollback.sh $(ENV)

# Database operations
db-migrate: ## Run database migrations
	@echo "$(BLUE)[INFO]$(NC) Running database migrations..."
	@ENVIRONMENT=$(ENV) docker-compose -f docker-compose.yml -f docker-compose.$(ENV).yml exec postgres psql -U devops_user -d devops_practice -f /opt/scripts/migrate.sh

db-backup: ## Backup database
	@echo "$(BLUE)[INFO]$(NC) Backing up database..."
	@ENVIRONMENT=$(ENV) ./scripts/docker-compose-manager.sh backup

db-restore: ## Restore database from backup
	@echo "$(BLUE)[INFO]$(NC) Restoring database..."
	@ENVIRONMENT=$(ENV) ./scripts/docker-compose-manager.sh restore

# Monitoring and maintenance
monitor: ## Open monitoring dashboards
	@echo "$(BLUE)[INFO]$(NC) Opening monitoring dashboards..."
	@echo "Grafana: http://localhost:3001 (admin/admin123)"
	@echo "Prometheus: http://localhost:9090"
	@echo "Kibana: http://localhost:5601"
	@echo "Jenkins: http://localhost:8080 (admin/admin123)"

backup: ## Backup all volumes
	@echo "$(BLUE)[INFO]$(NC) Backing up volumes..."
	@ENVIRONMENT=$(ENV) ./scripts/docker-compose-manager.sh backup

restore: ## Restore volumes from backup
	@echo "$(BLUE)[INFO]$(NC) Restoring volumes..."
	@ENVIRONMENT=$(ENV) ./scripts/docker-compose-manager.sh restore

clean: ## Clean up unused resources
	@echo "$(BLUE)[INFO]$(NC) Cleaning up unused resources..."
	@./scripts/docker-compose-manager.sh clean

clean-all: ## Clean up everything including volumes
	@echo "$(YELLOW)[WARNING]$(NC) This will remove all containers, images, and volumes!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo ""; \
		docker-compose -f docker-compose.yml -f docker-compose.dev.yml down -v --remove-orphans; \
		docker-compose -f docker-compose.yml -f docker-compose.staging.yml down -v --remove-orphans; \
		docker-compose -f docker-compose.yml -f docker-compose.prod.yml down -v --remove-orphans; \
		docker-compose -f docker-compose.test.yml down -v --remove-orphans; \
		docker system prune -af --volumes; \
		rm -rf data/* logs/* backups/* test-results/* coverage/*; \
		echo "$(GREEN)[SUCCESS]$(NC) Complete cleanup finished"; \
	else \
		echo ""; \
		echo "$(BLUE)[INFO]$(NC) Cleanup cancelled"; \
	fi

# Ansible operations
ansible-deploy: ## Deploy using Ansible
	@echo "$(BLUE)[INFO]$(NC) Deploying with Ansible..."
	@cd ansible && ansible-playbook -i inventories/$(ENV)/hosts.yml playbooks/container-deploy.yml

ansible-health: ## Check service health with Ansible
	@echo "$(BLUE)[INFO]$(NC) Checking service health with Ansible..."
	@cd ansible && ansible-playbook -i inventories/$(ENV)/hosts.yml playbooks/service-health.yml

ansible-config: ## Update configurations with Ansible
	@echo "$(BLUE)[INFO]$(NC) Updating configurations with Ansible..."
	@cd ansible && ansible-playbook -i inventories/$(ENV)/hosts.yml playbooks/config-management.yml

ansible-maintenance: ## Run maintenance tasks with Ansible
	@echo "$(BLUE)[INFO]$(NC) Running maintenance tasks with Ansible..."
	@cd ansible && ansible-playbook -i inventories/$(ENV)/hosts.yml playbooks/maintenance.yml

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

# Security operations
security-scan: ## Run security scans
	@echo "$(BLUE)[INFO]$(NC) Running security scans..."
	@docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
		-v $(PWD):/src aquasec/trivy fs --security-checks vuln /src

security-update: ## Update security configurations
	@echo "$(BLUE)[INFO]$(NC) Updating security configurations..."
	@cd ansible && ansible-playbook -i inventories/$(ENV)/hosts.yml playbooks/user-security.yml

# Documentation
docs: ## Generate documentation
	@echo "$(BLUE)[INFO]$(NC) Generating documentation..."
	@mkdir -p docs
	@echo "# DevOps Practice Environment" > docs/README.md
	@echo "Generated on: $$(date)" >> docs/README.md
	@echo "" >> docs/README.md
	@echo "## Services Status" >> docs/README.md
	@ENVIRONMENT=$(ENV) ./scripts/docker-compose-manager.sh ps >> docs/README.md

# Quick start
quick-start: setup dev-up ## Quick start development environment
	@echo "$(GREEN)[SUCCESS]$(NC) Development environment is ready!"
	@echo ""
	@echo "Access points:"
	@echo "  Frontend: http://localhost:3000"
	@echo "  API Gateway: http://localhost:4000"
	@echo "  Grafana: http://localhost:3001 (admin/admin123)"
	@echo "  Jenkins: http://localhost:8080 (admin/admin123)"
	@echo ""
	@echo "Use 'make logs' to view logs or 'make help' for more commands"

# Status check
status: ## Show environment status
	@echo "$(BLUE)[INFO]$(NC) Environment Status for $(ENV):"
	@echo "=================================="
	@ENVIRONMENT=$(ENV) ./scripts/docker-compose-manager.sh ps
	@echo ""
	@ENVIRONMENT=$(ENV) ./scripts/docker-compose-manager.sh health

# Validation
validate: ## Validate configuration files
	@echo "$(BLUE)[INFO]$(NC) Validating configurations..."
	@cd terraform && terraform validate
	@cd ansible && ansible-playbook --syntax-check playbooks/site.yml
	@docker-compose -f docker-compose.yml -f docker-compose.dev.yml config >/dev/null
	@echo "$(GREEN)[SUCCESS]$(NC) All configurations are valid"

# CI/CD Pipeline Commands
setup-pipeline: ## Setup CI/CD pipeline infrastructure
	@./scripts/pipeline-setup.sh $(ENV)

health-check: ## Run health checks on deployed services
	@./scripts/verify-deployment.sh $(ENV)

verify-deployment: ## Verify deployment status
	@./scripts/verify-deployment.sh $(ENV)

# ── DevOps Lab Platform ───────────────────────────────────────────────────────
lab-build: ## Build devops-lab/base-linux:latest image (Phase 1/2 — Linux labs)
	@echo "$(BLUE)[INFO]$(NC) Building devops-lab/base-linux:latest..."
	@docker build -t devops-lab/base-linux:latest devops-lab-platform/lab-images/base-linux/
	@echo "$(GREEN)[SUCCESS]$(NC) Image built: devops-lab/base-linux:latest"

networking-build: ## Build devops-lab/networking-lab:latest image (Phase 3 — Networking labs)
	@echo "$(BLUE)[INFO]$(NC) Building devops-lab/networking-lab:latest..."
	@docker build -t devops-lab/networking-lab:latest devops-lab-platform/lab-images/networking-lab/
	@echo "$(GREEN)[SUCCESS]$(NC) Image built: devops-lab/networking-lab:latest"

cicd-build: ## Build devops-lab/cicd-lab:latest image (Phase 4 — CI/CD labs)
	@echo "$(BLUE)[INFO]$(NC) Building devops-lab/cicd-lab:latest..."
	@docker build -t devops-lab/cicd-lab:latest devops-lab-platform/lab-images/cicd-lab/
	@echo "$(GREEN)[SUCCESS]$(NC) Image built: devops-lab/cicd-lab:latest"

monitoring-build: ## Build devops-lab/monitoring-lab:latest image (Phase 6 — Monitoring labs)
	@echo "$(BLUE)[INFO]$(NC) Building devops-lab/monitoring-lab:latest..."
	@docker build -t devops-lab/monitoring-lab:latest devops-lab-platform/lab-images/monitoring-lab/
	@echo "$(GREEN)[SUCCESS]$(NC) Image built: devops-lab/monitoring-lab:latest"

security-build: ## Build devops-lab/security-lab:latest image (Phase 7 — Security labs)
	@echo "$(BLUE)[INFO]$(NC) Building devops-lab/security-lab:latest..."
	@docker build -t devops-lab/security-lab:latest devops-lab-platform/lab-images/security-lab/
	@echo "$(GREEN)[SUCCESS]$(NC) Image built: devops-lab/security-lab:latest"

lab-build-all: lab-build networking-build cicd-build terraform-build ansible-build monitoring-build security-build ## Build all lab images

lab-backend: ## Run FastAPI backend on host (port 8000)
	@echo "$(BLUE)[INFO]$(NC) Starting FastAPI backend on http://localhost:8000"
	@cd devops-lab-platform && pip install -q -r backend/requirements.txt
	@cd devops-lab-platform && uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload

lab-frontend: ## Run Vite dev server (port 3000)
	@echo "$(BLUE)[INFO]$(NC) Starting Vite dev server on http://localhost:3000"
	@cd services/frontend && npm install && npm run dev

lab-install-ttyd: ## Install ttyd (macOS: brew, Linux: download binary)
	@echo "$(BLUE)[INFO]$(NC) Installing ttyd..."
	@if [ "$$(uname)" = "Darwin" ]; then \
		brew install ttyd; \
	else \
		curl -L https://github.com/tsl0922/ttyd/releases/latest/download/ttyd.x86_64 -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd; \
	fi
	@echo "$(GREEN)[SUCCESS]$(NC) ttyd installed: $$(ttyd --version 2>&1 || echo 'check path')"

lab-clean: ## Remove all devops-lab-* containers, images, and networks
	@echo "$(YELLOW)[WARNING]$(NC) Removing all devops-lab containers and networks..."
	@docker ps -a --filter "label=devops-lab.managed=true" -q | xargs -r docker rm -f
	@docker network ls --filter "name=devops-lab-net-" -q | xargs -r docker network rm
	@echo "$(GREEN)[SUCCESS]$(NC) Lab resources cleaned"

terraform-build: ## Build devops-lab/terraform-lab:latest image (Phase 5 — Terraform labs)
	@echo "$(BLUE)[INFO]$(NC) Building devops-lab/terraform-lab:latest..."
	@docker build -t devops-lab/terraform-lab:latest devops-lab-platform/lab-images/terraform-lab/
	@echo "$(GREEN)[SUCCESS]$(NC) Image built: devops-lab/terraform-lab:latest"

ansible-build: ## Build devops-lab/ansible-lab:latest image (Phase 5 — Ansible labs)
	@echo "$(BLUE)[INFO]$(NC) Building devops-lab/ansible-lab:latest..."
	@docker build -t devops-lab/ansible-lab:latest devops-lab-platform/lab-images/ansible-lab/
	@echo "$(GREEN)[SUCCESS]$(NC) Image built: devops-lab/ansible-lab:latest"