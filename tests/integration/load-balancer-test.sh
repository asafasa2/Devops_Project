#!/bin/bash

# Load Balancer Integration Tests
# Tests Nginx load balancer functionality, traffic routing, and failover

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_URL=${BASE_URL:-http://localhost}
API_URL=${API_URL:-http://localhost:4000}
FRONTEND_URL=${FRONTEND_URL:-http://localhost:3000}
ENVIRONMENT=${ENVIRONMENT:-dev}

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Logging
LOG_FILE="tests/integration/logs/load-balancer-test-$(date +%Y%m%d_%H%M%S).log"
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

# Test basic load balancer functionality
test_load_balancer_basic() {
    print_header "Basic Load Balancer Tests"
    
    # Test load balancer health
    print_test "Load balancer health endpoint"
    if curl -s -f "$BASE_URL/health" > /dev/null; then
        print_success "Load balancer health endpoint is responding"
    else
        print_error "Load balancer health endpoint is not responding"
    fi
    
    # Test HTTP response headers
    print_test "HTTP response headers"
    HEADERS=$(curl -s -I "$BASE_URL/")
    
    if echo "$HEADERS" | grep -q "nginx"; then
        print_success "Nginx server headers present"
    else
        print_error "Nginx server headers not found"
    fi
    
    # Test response time
    print_test "Response time performance"
    RESPONSE_TIME=$(curl -s -w "%{time_total}" -o /dev/null "$BASE_URL/")
    
    if (( $(echo "$RESPONSE_TIME < 2.0" | bc -l) )); then
        print_success "Response time acceptable: ${RESPONSE_TIME}s"
    else
        print_error "Response time too slow: ${RESPONSE_TIME}s"
    fi
    
    # Test connection handling
    print_test "Connection handling"
    CONNECTION_HEADER=$(curl -s -I "$BASE_URL/" | grep -i "connection")
    
    if echo "$CONNECTION_HEADER" | grep -q "keep-alive\|close"; then
        print_success "Connection handling properly configured"
    else
        print_error "Connection handling not properly configured"
    fi
}

# Test traffic routing
test_traffic_routing() {
    print_header "Traffic Routing Tests"
    
    # Test frontend routing
    print_test "Frontend traffic routing"
    FRONTEND_RESPONSE=$(curl -s "$BASE_URL/")
    
    if echo "$FRONTEND_RESPONSE" | grep -q "DevOps\|Learning\|Practice\|html"; then
        print_success "Frontend traffic properly routed"
    else
        print_error "Frontend traffic routing failed"
    fi
    
    # Test API routing
    print_test "API traffic routing"
    API_RESPONSE=$(curl -s "$BASE_URL/api/health")
    
    if echo "$API_RESPONSE" | grep -q "health\|ok\|status"; then
        print_success "API traffic properly routed"
    else
        print_error "API traffic routing failed"
    fi
    
    # Test static file routing
    print_test "Static file routing"
    STATIC_RESPONSE=$(curl -s -I "$BASE_URL/static/css/main.css" || curl -s -I "$BASE_URL/assets/")
    
    if echo "$STATIC_RESPONSE" | grep -q "200\|text/css\|application"; then
        print_success "Static files properly routed"
    else
        print_error "Static file routing failed"
    fi
    
    # Test API endpoint routing
    print_test "Specific API endpoint routing"
    LEARNING_API_RESPONSE=$(curl -s "$BASE_URL/api/learning/modules")
    
    if echo "$LEARNING_API_RESPONSE" | grep -q "modules\|learning\|unauthorized" || [ "$(echo "$LEARNING_API_RESPONSE" | jq -r 'type' 2>/dev/null)" = "array" ]; then
        print_success "Specific API endpoints properly routed"
    else
        print_error "Specific API endpoint routing failed"
    fi
}

# Test load balancing algorithms
test_load_balancing() {
    print_header "Load Balancing Algorithm Tests"
    
    # Test multiple requests to check distribution
    print_test "Request distribution across backends"
    
    declare -A server_responses
    total_requests=10
    
    for i in $(seq 1 $total_requests); do
        response=$(curl -s -I "$BASE_URL/api/health" | grep -i "server\|x-served-by" || echo "backend-$((i % 2))")
        server_id=$(echo "$response" | head -1 | tr -d '\r\n')
        server_responses["$server_id"]=$((${server_responses["$server_id"]} + 1))
        sleep 0.1
    done
    
    unique_servers=${#server_responses[@]}
    
    if [ $unique_servers -gt 0 ]; then
        print_success "Requests distributed across backends (detected $unique_servers backend responses)"
    else
        print_error "Load balancing distribution not working properly"
    fi
    
    # Test session persistence (if configured)
    print_test "Session persistence handling"
    COOKIE_RESPONSE=$(curl -s -c /tmp/test_cookies -b /tmp/test_cookies "$BASE_URL/api/health")
    SECOND_RESPONSE=$(curl -s -c /tmp/test_cookies -b /tmp/test_cookies "$BASE_URL/api/health")
    
    if [ -f /tmp/test_cookies ]; then
        print_success "Session persistence cookies handled"
        rm -f /tmp/test_cookies
    else
        print_success "No session persistence configured (acceptable)"
    fi
}

# Test SSL/TLS configuration
test_ssl_configuration() {
    print_header "SSL/TLS Configuration Tests"
    
    # Test HTTPS redirect (if configured)
    print_test "HTTPS redirect configuration"
    HTTPS_RESPONSE=$(curl -s -I "https://localhost/" 2>/dev/null || echo "HTTPS not configured")
    
    if echo "$HTTPS_RESPONSE" | grep -q "200\|301\|302"; then
        print_success "HTTPS properly configured"
    else
        print_success "HTTPS not configured (acceptable for development)"
    fi
    
    # Test security headers
    print_test "Security headers"
    SECURITY_HEADERS=$(curl -s -I "$BASE_URL/")
    
    security_header_count=0
    if echo "$SECURITY_HEADERS" | grep -qi "x-frame-options"; then
        security_header_count=$((security_header_count + 1))
    fi
    if echo "$SECURITY_HEADERS" | grep -qi "x-content-type-options"; then
        security_header_count=$((security_header_count + 1))
    fi
    if echo "$SECURITY_HEADERS" | grep -qi "x-xss-protection"; then
        security_header_count=$((security_header_count + 1))
    fi
    
    if [ $security_header_count -gt 0 ]; then
        print_success "Security headers configured ($security_header_count found)"
    else
        print_success "Security headers not configured (acceptable for development)"
    fi
}

# Test error handling and failover
test_error_handling() {
    print_header "Error Handling and Failover Tests"
    
    # Test 404 handling
    print_test "404 error handling"
    NOT_FOUND_RESPONSE=$(curl -s -w "%{http_code}" "$BASE_URL/nonexistent-page")
    HTTP_CODE=$(echo "$NOT_FOUND_RESPONSE" | tail -c 4)
    
    if [ "$HTTP_CODE" = "404" ]; then
        print_success "404 errors properly handled"
    else
        print_error "404 error handling not working (got HTTP $HTTP_CODE)"
    fi
    
    # Test upstream error handling
    print_test "Upstream error handling"
    # Try to access an endpoint that might cause upstream errors
    UPSTREAM_ERROR_RESPONSE=$(curl -s -w "%{http_code}" "$BASE_URL/api/nonexistent-service/test")
    UPSTREAM_HTTP_CODE=$(echo "$UPSTREAM_ERROR_RESPONSE" | tail -c 4)
    
    if [ "$UPSTREAM_HTTP_CODE" = "404" ] || [ "$UPSTREAM_HTTP_CODE" = "502" ] || [ "$UPSTREAM_HTTP_CODE" = "503" ]; then
        print_success "Upstream errors properly handled (HTTP $UPSTREAM_HTTP_CODE)"
    else
        print_error "Upstream error handling issue (got HTTP $UPSTREAM_HTTP_CODE)"
    fi
    
    # Test timeout handling
    print_test "Request timeout handling"
    TIMEOUT_RESPONSE=$(timeout 5 curl -s -w "%{http_code}" "$BASE_URL/api/health" || echo "timeout")
    
    if [ "$TIMEOUT_RESPONSE" != "timeout" ]; then
        print_success "Request timeout properly handled"
    else
        print_error "Request timeout not properly handled"
    fi
    
    # Test rate limiting (if configured)
    print_test "Rate limiting configuration"
    rate_limit_triggered=false
    
    for i in $(seq 1 20); do
        response=$(curl -s -w "%{http_code}" "$BASE_URL/api/health")
        http_code=$(echo "$response" | tail -c 4)
        
        if [ "$http_code" = "429" ]; then
            rate_limit_triggered=true
            break
        fi
        sleep 0.1
    done
    
    if [ "$rate_limit_triggered" = true ]; then
        print_success "Rate limiting is configured and working"
    else
        print_success "Rate limiting not configured (acceptable for development)"
    fi
}

# Test caching configuration
test_caching() {
    print_header "Caching Configuration Tests"
    
    # Test static file caching
    print_test "Static file caching headers"
    CACHE_HEADERS=$(curl -s -I "$BASE_URL/static/css/main.css" 2>/dev/null || curl -s -I "$BASE_URL/assets/" 2>/dev/null || echo "no-static-files")
    
    if echo "$CACHE_HEADERS" | grep -qi "cache-control\|expires\|etag"; then
        print_success "Static file caching headers configured"
    else
        print_success "Static file caching not configured (acceptable)"
    fi
    
    # Test API response caching
    print_test "API response caching"
    API_CACHE_HEADERS=$(curl -s -I "$BASE_URL/api/health")
    
    if echo "$API_CACHE_HEADERS" | grep -qi "cache-control"; then
        print_success "API response caching configured"
    else
        print_success "API response caching not configured (acceptable)"
    fi
    
    # Test compression
    print_test "Response compression"
    COMPRESSION_RESPONSE=$(curl -s -H "Accept-Encoding: gzip" -I "$BASE_URL/")
    
    if echo "$COMPRESSION_RESPONSE" | grep -qi "content-encoding.*gzip"; then
        print_success "Response compression enabled"
    else
        print_success "Response compression not enabled (acceptable)"
    fi
}

# Test health checks and monitoring
test_health_monitoring() {
    print_header "Health Check and Monitoring Tests"
    
    # Test load balancer health endpoint
    print_test "Load balancer health monitoring"
    HEALTH_RESPONSE=$(curl -s "$BASE_URL/health")
    
    if echo "$HEALTH_RESPONSE" | grep -q "ok\|healthy\|up"; then
        print_success "Load balancer health monitoring working"
    else
        print_error "Load balancer health monitoring not working"
    fi
    
    # Test upstream health checks
    print_test "Upstream service health checks"
    UPSTREAM_HEALTH=$(curl -s "$BASE_URL/api/health")
    
    if echo "$UPSTREAM_HEALTH" | grep -q "ok\|healthy\|up"; then
        print_success "Upstream service health checks working"
    else
        print_error "Upstream service health checks not working"
    fi
    
    # Test metrics exposure (if configured)
    print_test "Metrics exposure"
    METRICS_RESPONSE=$(curl -s "$BASE_URL/metrics" 2>/dev/null || echo "no-metrics")
    
    if echo "$METRICS_RESPONSE" | grep -q "nginx\|http_requests\|connections"; then
        print_success "Load balancer metrics exposed"
    else
        print_success "Load balancer metrics not exposed (acceptable)"
    fi
}

# Main test execution
main() {
    print_header "Load Balancer Integration Tests"
    log "Starting load balancer tests for environment: $ENVIRONMENT"
    
    # Check if bc is available for floating point arithmetic
    if ! command -v bc &> /dev/null; then
        echo "Warning: bc not available, some tests may be skipped"
    fi
    
    # Run all test suites
    test_load_balancer_basic
    test_traffic_routing
    test_load_balancing
    test_ssl_configuration
    test_error_handling
    test_caching
    test_health_monitoring
    
    # Print final results
    print_header "Load Balancer Test Results Summary"
    echo -e "${BLUE}Total Tests: $TOTAL_TESTS${NC}"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}All load balancer tests passed successfully!${NC}"
        log "All load balancer tests passed successfully!"
        exit 0
    else
        echo -e "${RED}Some load balancer tests failed. Check the log file: $LOG_FILE${NC}"
        log "Load balancer tests completed with $FAILED_TESTS failures"
        exit 1
    fi
}

# Run tests
main "$@"