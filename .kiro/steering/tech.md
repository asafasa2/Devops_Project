# Technology Stack & Build System

## Core Technologies

### Frontend
- **React 19** with TypeScript
- **Vite** for build tooling and development server
- **React Router** for navigation
- **TanStack Query** for API state management
- **Axios** for HTTP requests

### Backend Services
- **Node.js** (API Gateway, Learning Service)
- **Python/Flask** (User Service, Assessment Service)
- **Java/Spring Boot** (Lab Service)
- **Express.js** with middleware (CORS, Helmet, Rate Limiting)

### Databases & Caching
- **PostgreSQL 15** for primary data storage
- **Redis 7** for caching and session management

### Infrastructure & DevOps
- **Docker & Docker Compose** for containerization
- **Jenkins** for CI/CD pipelines
- **Ansible** for configuration management
- **Terraform** for infrastructure as code
- **Nginx** for load balancing and reverse proxy

### Monitoring & Observability
- **Prometheus** for metrics collection
- **Grafana** for dashboards and visualization
- **ELK Stack** (Elasticsearch, Logstash, Kibana) for logging
- **cAdvisor** for container metrics
- **Node Exporter** for system metrics

## Build Commands

### Development Environment
```bash
# Quick start development
make quick-start

# Start specific services
make dev-up SERVICE=api-gateway
make dev-logs SERVICE=frontend

# Build and restart
make dev-build && make dev-up
```

### Docker Operations
```bash
# Build all services
make build

# Start environment-specific stack
make up ENV=staging
make down ENV=prod

# Scale services
make scale SERVICE=api-gateway REPLICAS=3
```

### Testing
```bash
# Run all tests
make test

# Run specific test types
make test-unit
make test-integration
make test-e2e

# Security scanning
make security-scan
```

### Database Operations
```bash
# Run migrations
make db-migrate ENV=dev

# Backup/restore
make db-backup ENV=prod
make db-restore ENV=staging
```

### Infrastructure Management
```bash
# Terraform operations
make terraform-init ENV=prod
make terraform-plan ENV=staging
make terraform-apply ENV=prod

# Ansible deployment
make ansible-deploy ENV=staging
make ansible-health ENV=prod
```

## Service-Specific Commands

### Frontend (React/Vite)
```bash
cd services/frontend
npm run dev          # Development server
npm run build        # Production build
npm run preview      # Preview production build
```

### Node.js Services
```bash
cd services/api-gateway
npm start            # Production
npm run dev          # Development with nodemon
npm test             # Jest tests
```

### Python Services
```bash
cd services/user-service
python app.py        # Start Flask app
pytest               # Run tests
pytest --cov=.       # Tests with coverage
```

### Java Service
```bash
cd services/lab-service
mvn spring-boot:run  # Development
mvn test             # Run tests
mvn package          # Build JAR
```

## Environment Configuration

### Environment Files
- `.env` - Active environment configuration
- `.env.dev` - Development settings
- `.env.staging` - Staging environment
- `.env.prod` - Production settings
- `.env.test` - Testing configuration

### Docker Compose Files
- `docker-compose.yml` - Base configuration
- `docker-compose.dev.yml` - Development overrides
- `docker-compose.staging.yml` - Staging overrides
- `docker-compose.prod.yml` - Production overrides
- `docker-compose.test.yml` - Testing environment

## Port Allocation

### Application Services
- Frontend: 3000
- API Gateway: 4000
- Learning Service: 4001
- User Service: 4002
- Lab Service: 4003
- Assessment Service: 4004

### Infrastructure Services
- Nginx: 80, 443
- PostgreSQL: 5432
- Redis: 6379
- Jenkins: 8080, 50000

### Monitoring Services
- Grafana: 3001
- Prometheus: 9090
- Kibana: 5601
- Elasticsearch: 9200
- cAdvisor: 8083

## Health Checks

All services implement `/health` endpoints for monitoring and load balancer health checks. Use `make health` to check all service status.