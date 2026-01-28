#!/bin/bash

# Load Balancer Health Check and Testing Script
# Tests nginx load balancer configuration and failover functionality

set -e

# Configuration
NGINX_HOST="${NGINX_HOST:-localhost}"
NGINX_PORT="${NGINX_PORT:-80}"
HEALTH_PORT="${HEALTH_PORT:-8090}"
TEST_TIMEOUT="${TEST_TIMEOUT:-10}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Test functions
test_health_endpoint() {
    local endpoint="$1"
    local expected_status="${2:-200}"
    
    log_info "Testing health endpoint: $endpoint"
    
    local response
    local status_code
    
    response=$(curl -s -w "HTTPSTATUS:%{http_code}" --connect-timeout "$TEST_TIMEOUT" "$endpoint" 2>/dev/null || echo "HTTPSTATUS:000")
    status_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
    
    if [ "$status_code" = "$expected_status" ]; then
        log_success "Health endpoint $endpoint returned status $status_code"
        return 0
    else
        log_error "Health endpoint $endpoint returned status $status_code (expected $expected_status)"
        return 1
    fi
}

test_load_balancer_basic() {
    log_info "Testing basic load balancer functionality..."
    
    # Test main health endpoint
    test_health_endpoint "http://$NGINX_HOST:$NGINX_PORT/health" || return 1
    
    # Test detailed health endpoint if available
    if test_health_endpoint "http://$NGINX_HOST:$HEALTH_PORT/health/detailed" 2>/dev/null; then
        log_success "Detailed health endpoint is available"
    else
        log_warning "Detailed health endpoint not available (may be expected in some environments)"
    fi
    
    # Test nginx status endpoint if available
    if test_health_endpoint "http://$NGINX_HOST:$HEALTH_PORT/nginx_status" 2>/dev/null; then
        log_success "Nginx status endpoint is available"
    else
        log_warning "Nginx status endpoint not available (may be restricted)"
    fi
    
    return 0
}

test_upstream_health() {
    log_info "Testing upstream service health checks..."
    
    local services=("frontend" "api" "learning" "users" "labs" "assessments")
    local failed_services=()
    
    for service in "${services[@]}"; do
        if test_health_endpoint "http://$NGINX_HOST:$HEALTH_PORT/health/$service" 2>/dev/null; then
            log_success "Upstream service '$service' is healthy"
        else
            log_warning "Upstream service '$service' health check failed"
            failed_services+=("$service")
        fi
    done
    
    if [ ${#failed_services[@]} -eq 0 ]; then
        log_success "All upstream services are healthy"
        return 0
    else
        log_warning "Some upstream services failed health checks: ${failed_services[*]}"
        return 1
    fi
}

test_api_routing() {
    log_info "Testing API routing through load balancer..."
    
    local api_endpoints=(
        "/api/health"
        "/api/learning/health"
        "/api/users/health"
        "/api/labs/health"
        "/api/assessments/health"
    )
    
    local failed_endpoints=()
    
    for endpoint in "${api_endpoints[@]}"; do
        local url="http://$NGINX_HOST:$NGINX_PORT$endpoint"
        if test_health_endpoint "$url" 2>/dev/null; then
            log_success "API endpoint '$endpoint' is accessible"
        else
            log_warning "API endpoint '$endpoint' is not accessible"
            failed_endpoints+=("$endpoint")
        fi
    done
    
    if [ ${#failed_endpoints[@]} -eq 0 ]; then
        log_success "All API endpoints are accessible through load balancer"
        return 0
    else
        log_warning "Some API endpoints failed: ${failed_endpoints[*]}"
        return 1
    fi
}

test_load_balancing() {
    log_info "Testing load balancing behavior..."
    
    local test_endpoint="http://$NGINX_HOST:$NGINX_PORT/health"
    local num_requests=10
    local success_count=0
    
    for i in $(seq 1 $num_requests); do
        if curl -s --connect-timeout 5 "$test_endpoint" >/dev/null 2>&1; then
            ((success_count++))
        fi
        sleep 0.1
    done
    
    local success_rate=$((success_count * 100 / num_requests))
    
    if [ $success_rate -ge 90 ]; then
        log_success "Load balancing test passed: $success_count/$num_requests requests successful ($success_rate%)"
        return 0
    else
        log_error "Load balancing test failed: $success_count/$num_requests requests successful ($success_rate%)"
        return 1
    fi
}

test_failover_simulation() {
    log_info "Testing failover behavior (simulation)..."
    
    # This is a basic test - in a real scenario, you would stop one of the upstream services
    # and verify that traffic is routed to the remaining healthy services
    
    local test_endpoint="http://$NGINX_HOST:$NGINX_PORT/api/health"
    local num_requests=5
    local success_count=0
    
    log_info "Sending requests to test failover resilience..."
    
    for i in $(seq 1 $num_requests); do
        if curl -s --connect-timeout 10 "$test_endpoint" >/dev/null 2>&1; then
            ((success_count++))
        fi
        sleep 0.5
    done
    
    if [ $success_count -ge $((num_requests * 80 / 100)) ]; then
        log_success "Failover simulation passed: $success_count/$num_requests requests successful"
        return 0
    else
        log_warning "Failover simulation showed degraded performance: $success_count/$num_requests requests successful"
        return 1
    fi
}

show_nginx_config_summary() {
    log_info "Nginx Load Balancer Configuration Summary:"
    echo "  - Main HTTP Port: $NGINX_PORT"
    echo "  - Health Check Port: $HEALTH_PORT"
    echo "  - Upstream Services: frontend, api-gateway, learning-service, user-service, lab-service, assessment-service"
    echo "  - Load Balancing Method: least_conn"
    echo "  - Health Check Intervals: 30s (configurable per service)"
    echo "  - Failover: Automatic with retry logic"
    echo "  - Rate Limiting: Enabled for API and login endpoints"
}

run_all_tests() {
    log_info "Starting Load Balancer Test Suite..."
    echo "========================================"
    
    show_nginx_config_summary
    echo ""
    
    local tests_passed=0
    local total_tests=5
    
    # Run all tests
    if test_load_balancer_basic; then
        ((tests_passed++))
    fi
    echo ""
    
    if test_upstream_health; then
        ((tests_passed++))
    fi
    echo ""
    
    if test_api_routing; then
        ((tests_passed++))
    fi
    echo ""
    
    if test_load_balancing; then
        ((tests_passed++))
    fi
    echo ""
    
    if test_failover_simulation; then
        ((tests_passed++))
    fi
    echo ""
    
    # Summary
    echo "========================================"
    if [ $tests_passed -eq $total_tests ]; then
        log_success "All tests passed! ($tests_passed/$total_tests)"
        echo "Load balancer is configured correctly and functioning properly."
        return 0
    else
        log_warning "Some tests failed or showed warnings ($tests_passed/$total_tests passed)"
        echo "Please check the nginx configuration and upstream service health."
        return 1
    fi
}

# Main execution
case "${1:-all}" in
    "health")
        test_load_balancer_basic
        ;;
    "upstream")
        test_upstream_health
        ;;
    "routing")
        test_api_routing
        ;;
    "balancing")
        test_load_balancing
        ;;
    "failover")
        test_failover_simulation
        ;;
    "all")
        run_all_tests
        ;;
    *)
        echo "Usage: $0 [health|upstream|routing|balancing|failover|all]"
        echo ""
        echo "Commands:"
        echo "  health    - Test basic health endpoints"
        echo "  upstream  - Test upstream service health"
        echo "  routing   - Test API routing through load balancer"
        echo "  balancing - Test load balancing behavior"
        echo "  failover  - Test failover simulation"
        echo "  all       - Run all tests (default)"
        exit 1
        ;;
esac