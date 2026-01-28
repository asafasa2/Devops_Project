#!/bin/bash

# System Integration Test Suite
# Tests service-to-service communication, authentication, database connectivity, and load balancer functionality

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${ENVIRONMENT:-dev}
BASE_URL=${BASE_URL:-http://localhost}
API_URL=${API_URL:-http://localhost:4000}
FRONTEND_URL=${FRONTEND_URL:-http://localhost:3000}
GRAFANA_URL=${GRAFANA_URL:-http://localhost:3001}
KIBANA_URL=${KIBANA_URL:-http://localhost:5601}
PROMETHEUS_URL=${PROMETHEUS_URL:-http://localhost:9090}

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Logging
LOG_FILE="tests/integration/logs/system-integration-$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
    log "Starting: $1"
}

print_test() {
    echo -e "${YELLOW}Testing: $1${NC}"
    log "Test: $1"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    log "SUCCESS: $1"
    PASSED_TESTS=$((PASSED_TESTS + 1))
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    log "ERROR: $1"
    FAILED_TESTS=$((FAILED_TESTS + 1))
}

# Wait for service to be ready
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=${3:-30}
    local attempt=1
    
    print_test "Waiting for $service_name to be ready"
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            print_success "$service_name is ready"
            return 0
        fi
        
        echo "Attempt $attempt/$max_attempts - $service_name not ready yet..."
        sleep 5
        attempt=$((attempt + 1))
    done
    
    print_error "$service_name failed to start within timeout"
    return 1
}

# Test database connectivity
test_database_connectivity() {
    print_header "Database Connectivity Tests"
    
    # Test PostgreSQL connectivity
    print_test "PostgreSQL database connectivity"
    if docker exec ${ENVIRONMENT}-postgres pg_isready -U devops_user -d devops_practice > /dev/null 2>&1; then
        print_success "PostgreSQL is accessible"
    else
        print_error "PostgreSQL is not accessible"
    fi
    
    # Test Redis connectivity
    print_test "Redis cache connectivity"
    if docker exec ${ENVIRONMENT}-redis redis-cli ping | grep -q "PONG"; then
        print_success "Redis is accessible"
    else
        print_error "Redis is not accessible"
    fi
    
    # Test database schema
    print_test "Database schema validation"
    TABLES=$(docker exec ${ENVIRONMENT}-postgres psql -U devops_user -d devops_practice -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")
    if [ "$TABLES" -gt 0 ]; then
        print_success "Database schema is initialized (found $TABLES tables)"
    else
        print_error "Database schema is not properly initialized"
    fi
}

# Test service health endpoints
test_service_health() {
    print_header "Service Health Tests"
    
    # Test API Gateway health
    print_test "API Gateway health endpoint"
    if curl -s -f "$API_URL/health" > /dev/null; then
        print_success "API Gateway health endpoint is responding"
    else
        print_error "API Gateway health endpoint is not responding"
    fi
    
    # Test individual service health through API Gateway
    services=("learning" "user" "assessment" "lab")
    for service in "${services[@]}"; do
        print_test "$service service health via API Gateway"
        if curl -s -f "$API_URL/api/$service/health" > /dev/null; then
            print_success "$service service is healthy"
        else
            print_error "$service service is not healthy"
        fi
    done
    
    # Test frontend accessibility
    print_test "Frontend application accessibility"
    if curl -s -f "$FRONTEND_URL" > /dev/null; then
        print_success "Frontend is accessible"
    else
        print_error "Frontend is not accessible"
    fi
}

# Test service-to-service communication
test_service_communication() {
    print_header "Service-to-Service Communication Tests"
    
    # Create test user for authentication tests
    print_test "User registration via API Gateway"
    TEST_USER_EMAIL="test-$(date +%s)@example.com"
    TEST_USER_PASSWORD="TestPassword123!"
    
    REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/api/user/register" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$TEST_USER_EMAIL\",\"password\":\"$TEST_USER_PASSWORD\",\"username\":\"testuser$(date +%s)\"}")
    
    if echo "$REGISTER_RESPONSE" | grep -q "success\|created\|registered"; then
        print_success "User registration successful"
    else
        print_error "User registration failed: $REGISTER_RESPONSE"
        return 1
    fi
    
    # Test user authentication
    print_test "User authentication via API Gateway"
    AUTH_RESPONSE=$(curl -s -X POST "$API_URL/api/user/login" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$TEST_USER_EMAIL\",\"password\":\"$TEST_USER_PASSWORD\"}")
    
    JWT_TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
    
    if [ -n "$JWT_TOKEN" ]; then
        print_success "User authentication successful"
    else
        print_error "User authentication failed: $AUTH_RESPONSE"
        return 1
    fi
    
    # Test authenticated API calls
    print_test "Authenticated learning content retrieval"
    CONTENT_RESPONSE=$(curl -s -H "Authorization: Bearer $JWT_TOKEN" "$API_URL/api/learning/modules")
    
    if echo "$CONTENT_RESPONSE" | grep -q "modules\|content\|learning"; then
        print_success "Learning content retrieval successful"
    else
        print_error "Learning content retrieval failed: $CONTENT_RESPONSE"
    fi
    
    # Test assessment service communication
    print_test "Assessment service communication"
    ASSESSMENT_RESPONSE=$(curl -s -H "Authorization: Bearer $JWT_TOKEN" "$API_URL/api/assessment/quizzes")
    
    if echo "$ASSESSMENT_RESPONSE" | grep -q "quizzes\|assessments" || [ "$(echo "$ASSESSMENT_RESPONSE" | jq -r 'type' 2>/dev/null)" = "array" ]; then
        print_success "Assessment service communication successful"
    else
        print_error "Assessment service communication failed: $ASSESSMENT_RESPONSE"
    fi
    
    # Test lab service communication
    print_test "Lab service communication"
    LAB_RESPONSE=$(curl -s -H "Authorization: Bearer $JWT_TOKEN" "$API_URL/api/lab/templates")
    
    if echo "$LAB_RESPONSE" | grep -q "templates\|labs" || [ "$(echo "$LAB_RESPONSE" | jq -r 'type' 2>/dev/null)" = "array" ]; then
        print_success "Lab service communication successful"
    else
        print_error "Lab service communication failed: $LAB_RESPONSE"
    fi
}

# Test load balancer functionality
test_load_balancer() {
    print_header "Load Balancer Tests"
    
    # Test Nginx load balancer health
    print_test "Nginx load balancer health"
    if curl -s -f "$BASE_URL/health" > /dev/null; then
        print_success "Load balancer health endpoint is responding"
    else
        print_error "Load balancer health endpoint is not responding"
    fi
    
    # Test frontend routing through load balancer
    print_test "Frontend routing through load balancer"
    if curl -s -f "$BASE_URL/" | grep -q "DevOps\|Learning\|Practice"; then
        print_success "Frontend is accessible through load balancer"
    else
        print_error "Frontend is not accessible through load balancer"
    fi
    
    # Test API routing through load balancer
    print_test "API routing through load balancer"
    if curl -s -f "$BASE_URL/api/health" > /dev/null; then
        print_success "API is accessible through load balancer"
    else
        print_error "API is not accessible through load balancer"
    fi
    
    # Test static file serving
    print_test "Static file serving through load balancer"
    if curl -s -f "$BASE_URL/static/css/main.css" > /dev/null || curl -s -f "$BASE_URL/assets/" > /dev/null; then
        print_success "Static files are served through load balancer"
    else
        print_error "Static files are not properly served through load balancer"
    fi
}

# Test monitoring and logging systems
test_monitoring_systems() {
    print_header "Monitoring and Logging Systems Tests"
    
    # Test Prometheus
    print_test "Prometheus metrics collection"
    if curl -s -f "$PROMETHEUS_URL/api/v1/targets" | grep -q "up"; then
        print_success "Prometheus is collecting metrics"
    else
        print_error "Prometheus is not collecting metrics properly"
    fi
    
    # Test Grafana
    print_test "Grafana dashboard accessibility"
    if curl -s -f "$GRAFANA_URL/api/health" > /dev/null; then
        print_success "Grafana is accessible"
    else
        print_error "Grafana is not accessible"
    fi
    
    # Test Elasticsearch
    print_test "Elasticsearch cluster health"
    ES_HEALTH=$(curl -s "http://localhost:9200/_cluster/health" | grep -o '"status":"[^"]*' | cut -d'"' -f4)
    if [ "$ES_HEALTH" = "green" ] || [ "$ES_HEALTH" = "yellow" ]; then
        print_success "Elasticsearch cluster is healthy (status: $ES_HEALTH)"
    else
        print_error "Elasticsearch cluster is not healthy (status: $ES_HEALTH)"
    fi
    
    # Test Kibana
    print_test "Kibana log visualization"
    if curl -s -f "$KIBANA_URL/api/status" > /dev/null; then
        print_success "Kibana is accessible"
    else
        print_error "Kibana is not accessible"
    fi
    
    # Test log ingestion
    print_test "Log ingestion pipeline"
    LOG_COUNT=$(curl -s "http://localhost:9200/_cat/indices" | grep -c "logstash" || echo "0")
    if [ "$LOG_COUNT" -gt 0 ]; then
        print_success "Logs are being ingested (found $LOG_COUNT logstash indices)"
    else
        print_error "No logs are being ingested"
    fi
}

# Test data persistence
test_data_persistence() {
    print_header "Data Persistence Tests"
    
    # Test database data persistence
    print_test "Database data persistence"
    USER_COUNT=$(docker exec ${ENVIRONMENT}-postgres psql -U devops_user -d devops_practice -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | tr -d ' ' || echo "0")
    if [ "$USER_COUNT" -gt 0 ]; then
        print_success "Database contains persistent data (found $USER_COUNT users)"
    else
        print_error "Database does not contain expected data"
    fi
    
    # Test Redis cache functionality
    print_test "Redis cache functionality"
    docker exec ${ENVIRONMENT}-redis redis-cli SET test_key "test_value" > /dev/null
    CACHE_VALUE=$(docker exec ${ENVIRONMENT}-redis redis-cli GET test_key)
    if [ "$CACHE_VALUE" = "test_value" ]; then
        print_success "Redis cache is functioning properly"
        docker exec ${ENVIRONMENT}-redis redis-cli DEL test_key > /dev/null
    else
        print_error "Redis cache is not functioning properly"
    fi
    
    # Test volume mounts
    print_test "Volume mount persistence"
    VOLUME_COUNT=$(docker volume ls | grep -c "${ENVIRONMENT}" || echo "0")
    if [ "$VOLUME_COUNT" -gt 0 ]; then
        print_success "Persistent volumes are mounted (found $VOLUME_COUNT volumes)"
    else
        print_error "Persistent volumes are not properly mounted"
    fi
}

# Test network connectivity
test_network_connectivity() {
    print_header "Network Connectivity Tests"
    
    # Test inter-service network connectivity
    print_test "Database network connectivity from services"
    if docker exec ${ENVIRONMENT}-api-gateway nc -z postgres 5432 2>/dev/null; then
        print_success "Services can connect to database"
    else
        print_error "Services cannot connect to database"
    fi
    
    print_test "Cache network connectivity from services"
    if docker exec ${ENVIRONMENT}-api-gateway nc -z redis 6379 2>/dev/null; then
        print_success "Services can connect to cache"
    else
        print_error "Services cannot connect to cache"
    fi
    
    # Test network isolation
    print_test "Network isolation between tiers"
    NETWORKS=$(docker network ls | grep -c "${ENVIRONMENT}" || echo "0")
    if [ "$NETWORKS" -ge 3 ]; then
        print_success "Network isolation is properly configured (found $NETWORKS networks)"
    else
        print_error "Network isolation is not properly configured"
    fi
}

# Main test execution
main() {
    print_header "DevOps Practice Environment - System Integration Tests"
    log "Starting system integration tests for environment: $ENVIRONMENT"
    
    # Wait for all services to be ready
    wait_for_service "$API_URL/health" "API Gateway" 60
    wait_for_service "$FRONTEND_URL" "Frontend" 30
    wait_for_service "$GRAFANA_URL/api/health" "Grafana" 30
    wait_for_service "$PROMETHEUS_URL/-/ready" "Prometheus" 30
    
    # Run all test suites
    test_database_connectivity
    test_service_health
    test_service_communication
    test_load_balancer
    test_monitoring_systems
    test_data_persistence
    test_network_connectivity
    
    # Print final results
    print_header "Test Results Summary"
    echo -e "${BLUE}Total Tests: $TOTAL_TESTS${NC}"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}All integration tests passed successfully!${NC}"
        log "All integration tests passed successfully!"
        exit 0
    else
        echo -e "${RED}Some integration tests failed. Check the log file: $LOG_FILE${NC}"
        log "Integration tests completed with $FAILED_TESTS failures"
        exit 1
    fi
}

# Run tests
main "$@"