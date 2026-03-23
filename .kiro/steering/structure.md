# Project Structure & Organization

## Root Directory Layout

```
devops-practice-environment/
├── .env*                    # Environment configuration files
├── docker-compose*.yml      # Docker Compose configurations
├── Makefile                 # Build automation and orchestration
├── Jenkinsfile             # CI/CD pipeline definition
├── README.md               # Project documentation
└── pod.yaml                # Kubernetes pod specification
```

## Core Directories

### `/services/` - Microservices
```
services/
├── api-gateway/            # Node.js API Gateway (port 4000)
├── frontend/              # React/TypeScript frontend (port 3000)
├── learning-service/      # Node.js learning content API (port 4001)
├── user-service/          # Python/Flask user management (port 4002)
├── lab-service/           # Java/Spring Boot lab environments (port 4003)
├── assessment-service/    # Python/Flask quiz system (port 4004)
└── cka-simulator/         # Kubernetes exam simulator
```

Each service follows this structure:
- `Dockerfile` - Container definition
- `package.json` / `requirements.txt` / `pom.xml` - Dependencies
- `src/` - Source code
- `tests/` - Unit and integration tests
- `.env.example` - Environment template

### `/database/` - Data Layer
```
database/
├── init/                  # Database initialization scripts
├── migrations/            # Schema migration files
├── learning-content/      # Learning module SQL data
├── scripts/              # Database utility scripts
├── backups/              # Database backup storage
└── redis/                # Redis configuration
```

### `/ansible/` - Configuration Management
```
ansible/
├── inventories/          # Environment-specific host definitions
│   ├── dev/
│   ├── staging/
│   └── prod/
├── playbooks/           # Ansible automation playbooks
├── roles/               # Reusable Ansible roles
│   ├── common/
│   ├── app_server/
│   ├── database/
│   ├── monitoring/
│   └── web_server/
└── lab-environments/    # Lab setup automation
```

### `/terraform/` - Infrastructure as Code
```
terraform/
├── main.tf              # Main Terraform configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── backend.tf           # State backend configuration
├── environments/        # Environment-specific configurations
└── modules/            # Reusable Terraform modules
    ├── networks/
    ├── services/
    └── volumes/
```

### `/monitoring/` - Observability Stack
```
monitoring/
├── grafana/
│   ├── dashboards/      # Pre-built dashboards
│   └── provisioning/    # Grafana configuration
├── prometheus/          # Metrics collection config
├── alertmanager/        # Alert routing config
├── elasticsearch/       # Search and analytics config
├── logstash/           # Log processing pipelines
├── kibana/             # Log visualization config
└── filebeat/           # Log shipping config
```

### `/jenkins/` - CI/CD Configuration
```
jenkins/
├── casc_configs/        # Jenkins Configuration as Code
├── pipelines/          # Pipeline definitions
├── plugins/            # Required Jenkins plugins
├── init-scripts/       # Initialization scripts
└── secrets/            # Secret templates
```

### `/nginx/` - Load Balancer & Reverse Proxy
```
nginx/
├── nginx.conf          # Base configuration
├── nginx.dev.conf      # Development overrides
├── nginx.prod.conf     # Production configuration
└── ssl/               # SSL certificates
```

### `/public/` - Static Learning Content
```
public/
├── index.html          # Main landing page
├── learning-*.html     # Learning module pages
├── *-quiz.html        # Assessment pages
├── cka-simulator*.html # Kubernetes simulator
├── css/               # Stylesheets
└── js/                # Client-side JavaScript
```

### `/scripts/` - Automation Scripts
```
scripts/
├── deploy*.sh          # Deployment automation
├── docker-compose-manager.sh  # Docker orchestration
├── terraform-deploy.sh # Infrastructure deployment
├── ansible-deploy.sh   # Configuration deployment
├── backup.sh          # Data backup utilities
└── verify-deployment.sh # Health verification
```

### `/tests/` - Testing Infrastructure
```
tests/
└── integration/        # End-to-end integration tests
    ├── run-all-tests.sh
    ├── deployment-test.sh
    ├── authentication-test.sh
    └── system-integration-test.sh
```

### `/data/` - Persistent Data (Runtime)
```
data/                   # Created at runtime, gitignored
├── postgres/          # PostgreSQL data
├── redis/             # Redis persistence
├── jenkins/           # Jenkins home
├── grafana/           # Grafana data
├── prometheus/        # Metrics storage
├── elasticsearch/     # Search indices
└── lab-workspaces/    # Lab session data
```

### `/logs/` - Application Logs (Runtime)
```
logs/                  # Created at runtime, gitignored
├── app/              # Application service logs
└── nginx/            # Web server logs
```

## File Naming Conventions

### Environment Files
- `.env` - Active environment (copied from specific env file)
- `.env.example` - Template with all variables
- `.env.dev` - Development environment
- `.env.staging` - Staging environment  
- `.env.prod` - Production environment
- `.env.test` - Testing environment

### Docker Compose Files
- `docker-compose.yml` - Base services configuration
- `docker-compose.dev.yml` - Development overrides
- `docker-compose.staging.yml` - Staging overrides
- `docker-compose.prod.yml` - Production overrides
- `docker-compose.test.yml` - Testing environment
- `docker-compose.minimal.yml` - Minimal service set

### Configuration Files
- `*.example` - Template files requiring customization
- `*.dev.*` - Development-specific configurations
- `*.prod.*` - Production-specific configurations
- `*.staging.*` - Staging-specific configurations

## Key Architectural Patterns

### Microservices Structure
Each service is self-contained with its own:
- Database schema and migrations
- API endpoints and documentation
- Health checks and monitoring
- Test suites and CI/CD integration
- Docker container and deployment config

### Environment Separation
Clear separation between environments using:
- Environment-specific Docker Compose files
- Ansible inventory separation
- Terraform workspace/variable separation
- Dedicated configuration files per environment

### Infrastructure as Code
All infrastructure defined in code:
- Docker containers for application services
- Terraform for cloud/VM infrastructure
- Ansible for configuration management
- Jenkins pipelines for automation

### Monitoring Integration
Comprehensive observability built-in:
- Health endpoints on all services
- Prometheus metrics collection
- Centralized logging with ELK
- Grafana dashboards for visualization
- Alert management with Alertmanager