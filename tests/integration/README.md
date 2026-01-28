# Integration Tests

This directory contains comprehensive integration tests for the DevOps Practice Environment. These tests validate the complete system functionality, including service-to-service communication, authentication, database connectivity, load balancer functionality, and monitoring systems.

## Test Suites

### 1. System Integration Tests (`system-integration-test.sh`)
- **Database Connectivity**: Tests PostgreSQL and Redis connectivity
- **Service Health**: Validates all microservice health endpoints
- **Service Communication**: Tests API Gateway routing to all services
- **Load Balancer**: Validates Nginx load balancer functionality
- **Monitoring Systems**: Tests Prometheus, Grafana, and ELK stack
- **Data Persistence**: Validates database and cache functionality
- **Network Connectivity**: Tests inter-service network communication

### 2. Authentication & Authorization Tests (`authentication-test.sh`)
- **User Registration**: Tests user creation with validation
- **User Authentication**: Tests login and JWT token generation
- **JWT Validation**: Tests token validation across services
- **Cross-Service Auth**: Tests authentication propagation
- **Authorization Levels**: Tests role-based access control
- **Session Management**: Tests session handling and logout

### 3. Load Balancer Tests (`load-balancer-test.sh`)
- **Basic Functionality**: Tests Nginx health and response headers
- **Traffic Routing**: Tests frontend, API, and static file routing
- **Load Balancing**: Tests request distribution algorithms
- **SSL Configuration**: Tests HTTPS and security headers
- **Error Handling**: Tests 404, upstream errors, and timeouts
- **Caching**: Tests static file and API response caching
- **Health Monitoring**: Tests health checks and metrics

## Running Tests

### Prerequisites
- Docker and Docker Compose installed
- All services running via `docker-compose up -d`
- `curl`, `jq`, and `bc` utilities available

### Run All Tests
```bash
# Run all integration test suites
./tests/integration/run-all-tests.sh

# Run with specific environment
ENVIRONMENT=staging ./tests/integration/run-all-tests.sh
```

### Run Individual Test Suites
```bash
# System integration tests only
./tests/integration/run-all-tests.sh --system

# Authentication tests only
./tests/integration/run-all-tests.sh --auth

# Load balancer tests only
./tests/integration/run-all-tests.sh --lb
```

### Run Individual Scripts
```bash
# Run system integration tests directly
./tests/integration/system-integration-test.sh

# Run authentication tests directly
./tests/integration/authentication-test.sh

# Run load balancer tests directly
./tests/integration/load-balancer-test.sh
```

## Configuration

### Environment Variables
- `ENVIRONMENT`: Target environment (default: `dev`)
- `BASE_URL`: Load balancer URL (default: `http://localhost`)
- `API_URL`: API Gateway URL (default: `http://localhost:4000`)
- `FRONTEND_URL`: Frontend URL (default: `http://localhost:3000`)
- `GRAFANA_URL`: Grafana URL (default: `http://localhost:3001`)
- `PROMETHEUS_URL`: Prometheus URL (default: `http://localhost:9090`)
- `KIBANA_URL`: Kibana URL (default: `http://localhost:5601`)

### Example with Custom Configuration
```bash
ENVIRONMENT=prod \
BASE_URL=https://devops-practice.example.com \
API_URL=https://api.devops-practice.example.com \
./tests/integration/run-all-tests.sh
```

## Test Results

### Console Output
Tests provide colored console output:
- 🔵 **Blue**: Test suite headers and information
- 🟡 **Yellow**: Individual test descriptions
- 🟢 **Green**: Successful tests and final success message
- 🔴 **Red**: Failed tests and error messages

### Log Files
Detailed logs are stored in `tests/integration/logs/`:
- `system-integration-YYYYMMDD_HHMMSS.log`
- `auth-test-YYYYMMDD_HHMMSS.log`
- `load-balancer-test-YYYYMMDD_HHMMSS.log`
- `integration-test-report-YYYYMMDD_HHMMSS.html`

### HTML Report
The test runner generates a comprehensive HTML report with:
- Test suite summary with pass/fail counts
- Individual test suite results
- Log file excerpts
- Timestamp and environment information

## Test Coverage

### Requirements Coverage
These integration tests validate the following requirements from the specification:

#### Requirement 1.1 - Container Orchestration
- ✅ Web application deployment with microservices
- ✅ Container restart and health checks
- ✅ Service discovery between microservices
- ✅ Service port exposure and external access

#### Requirement 1.2 - Infrastructure Provisioning
- ✅ Network configuration validation
- ✅ Multi-environment support testing
- ✅ State consistency across environments

#### Requirement 1.3 - Service Communication
- ✅ API Gateway routing functionality
- ✅ Microservice-to-microservice communication
- ✅ Database connectivity from all services
- ✅ Authentication token propagation

#### Requirement 1.4 - Monitoring and Logging
- ✅ Log collection from all services
- ✅ Metrics collection and visualization
- ✅ Health monitoring and alerting
- ✅ Error tracking and analysis

#### Requirement 1.5 - Load Balancing
- ✅ Traffic distribution across services
- ✅ Health checks and failover
- ✅ SSL termination and security headers
- ✅ Static file serving and caching

## Troubleshooting

### Common Issues

#### Services Not Ready
```bash
# Check service status
docker-compose ps

# View service logs
docker-compose logs [service-name]

# Restart services
docker-compose restart
```

#### Network Connectivity Issues
```bash
# Check Docker networks
docker network ls

# Inspect network configuration
docker network inspect [network-name]
```

#### Database Connection Issues
```bash
# Test PostgreSQL connectivity
docker exec dev-postgres pg_isready -U devops_user -d devops_practice

# Test Redis connectivity
docker exec dev-redis redis-cli ping
```

#### Authentication Test Failures
```bash
# Check user service logs
docker-compose logs user-service

# Verify JWT secret configuration
docker-compose exec api-gateway env | grep JWT
```

### Test Debugging

#### Enable Verbose Output
```bash
# Run with bash debug mode
bash -x ./tests/integration/system-integration-test.sh
```

#### Check Individual Service Health
```bash
# Test each service individually
curl -f http://localhost:4000/health  # API Gateway
curl -f http://localhost:4001/health  # Learning Service
curl -f http://localhost:4002/health  # User Service
curl -f http://localhost:4003/health  # Lab Service
curl -f http://localhost:4004/health  # Assessment Service
```

#### Validate Database Schema
```bash
# Connect to PostgreSQL and check tables
docker exec -it dev-postgres psql -U devops_user -d devops_practice -c "\dt"
```

## Contributing

When adding new integration tests:

1. Follow the existing test structure and naming conventions
2. Include proper error handling and logging
3. Add test descriptions and requirement references
4. Update this README with new test coverage
5. Ensure tests are idempotent and can run multiple times
6. Add appropriate cleanup for any test data created

## Dependencies

### Required Tools
- `curl`: HTTP client for API testing
- `jq`: JSON processor for response parsing
- `bc`: Calculator for floating-point arithmetic
- `docker`: Container management
- `docker-compose`: Multi-container orchestration

### Optional Tools
- `nc` (netcat): Network connectivity testing
- `timeout`: Command timeout handling
- `grep`: Text pattern matching
- `awk`/`sed`: Text processing

Install missing dependencies:
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install curl jq bc netcat-openbsd coreutils

# macOS
brew install curl jq bc netcat coreutils

# CentOS/RHEL
sudo yum install curl jq bc nmap-ncat coreutils
```