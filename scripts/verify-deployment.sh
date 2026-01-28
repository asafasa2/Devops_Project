#!/bin/bash
# Deployment verification script

ENVIRONMENT=${1:-dev}
TIMEOUT=${2:-300}

echo "🔍 Verifying deployment for $ENVIRONMENT environment..."
echo "Timeout: ${TIMEOUT}s"
echo "============================================"

# Configuration
COMPOSE_FILES="-f docker-compose.yml -f docker-compose.${ENVIRONMENT}.yml"
START_TIME=$(date +%s)

# Function to check elapsed time
check_timeout() {
    local current_time=$(date +%s)
    local elapsed=$((current_time - START_TIME))
    
    if [ $elapsed -gt $TIMEOUT ]; then
        echo "⏰ Verification timeout reached (${TIMEOUT}s)"
        return 1
    fi
    
    return 0
}

# Function to check container status
check_containers() {
    echo "📦 Checking container status..."
    
    local containers=$(docker-compose $COMPOSE_FILES ps -q)
    local total_containers=$(echo "$containers" | wc -l)
    local running_containers=0
    
    if [ -z "$containers" ]; then
        echo "❌ No containers found"
        return 1
    fi
    
    for container in $containers; do
        local status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null)
        local health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null)
        local name=$(docker inspect --format='{{.Name}}' "$container" 2>/dev/null | sed 's/\///')
        
        if [ "$status" = "running" ]; then
            if [ "$health" = "healthy" ] || [ "$health" = "<no value>" ]; then
                echo "✅ $name: Running and healthy"
                ((running_containers++))
            else
                echo "⚠️ $name: Running but unhealthy ($health)"
            fi
        else
            echo "❌ $name: Not running ($status)"
        fi
    done
    
    echo "📊 Container status: $running_containers/$total_containers running"
    
    if [ $running_containers -eq $total_containers ]; then
        return 0
    else
        return 1
    fi
}

# Function to check service health endpoints
check_service_health() {
    echo "🏥 Checking service health endpoints..."
    
    local services=(
        "frontend:http://localhost:3000/health:Web Frontend"
        "api-gateway:http://localhost:4000/health:API Gateway"
        "grafana:http://localhost:3001/api/health:Grafana"
        "prometheus:http://localhost:9090/-/healthy:Prometheus"
        "jenkins:http://localhost:8080/login:Jenkins"
        "kibana:http://localhost:5601/api/status:Kibana"
    )
    
    local failed_checks=0
    local total_checks=0
    
    for service_info in "${services[@]}"; do
        IFS=':' read -r service_name url display_name <<< "$service_info"
        
        # Check if service is defined in compose file
        if docker-compose $COMPOSE_FILES config --services | grep -q "^${service_name}$"; then
            ((total_checks++))
            echo -n "Checking $display_name... "
            
            if curl -f -s --max-time 10 "$url" > /dev/null 2>&1; then
                echo "✅ Healthy"
            else
                echo "❌ Unhealthy"
                ((failed_checks++))
            fi
        fi
    done
    
    echo "📊 Health check results: $((total_checks - failed_checks))/$total_checks services healthy"
    
    if [ $failed_checks -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Function to check database connectivity
check_database_connectivity() {
    echo "🗄️ Checking database connectivity..."
    
    # Check PostgreSQL
    if docker-compose $COMPOSE_FILES exec -T postgres pg_isready -U devops_user -d devops_practice > /dev/null 2>&1; then
        echo "✅ PostgreSQL: Connected"
    else
        echo "❌ PostgreSQL: Connection failed"
        return 1
    fi
    
    # Check Redis
    if docker-compose $COMPOSE_FILES exec -T redis redis-cli ping | grep -q "PONG"; then
        echo "✅ Redis: Connected"
    else
        echo "❌ Redis: Connection failed"
        return 1
    fi
    
    return 0
}

# Function to check logs for errors
check_logs_for_errors() {
    echo "📋 Checking logs for errors..."
    
    local error_patterns=("ERROR" "FATAL" "Exception" "failed" "timeout" "connection refused")
    local warning_patterns=("WARN" "WARNING" "deprecated")
    
    local error_count=0
    local warning_count=0
    
    # Get logs from the last 5 minutes
    local logs=$(docker-compose $COMPOSE_FILES logs --since=5m 2>&1)
    
    for pattern in "${error_patterns[@]}"; do
        local count=$(echo "$logs" | grep -i "$pattern" | wc -l)
        error_count=$((error_count + count))
    done
    
    for pattern in "${warning_patterns[@]}"; do
        local count=$(echo "$logs" | grep -i "$pattern" | wc -l)
        warning_count=$((warning_count + count))
    done
    
    if [ $error_count -gt 0 ]; then
        echo "⚠️ Found $error_count error(s) in recent logs"
        echo "Recent errors:"
        echo "$logs" | grep -i -E "(ERROR|FATAL|Exception|failed|timeout|connection refused)" | tail -5
        return 1
    elif [ $warning_count -gt 0 ]; then
        echo "⚠️ Found $warning_count warning(s) in recent logs"
        return 0
    else
        echo "✅ No errors found in recent logs"
        return 0
    fi
}

# Function to check resource usage
check_resource_usage() {
    echo "📈 Checking resource usage..."
    
    local containers=$(docker-compose $COMPOSE_FILES ps -q)
    local high_cpu_count=0
    local high_memory_count=0
    
    for container in $containers; do
        local stats=$(docker stats --no-stream --format "{{.CPUPerc}},{{.MemPerc}},{{.Name}}" "$container" 2>/dev/null)
        
        if [ -n "$stats" ]; then
            IFS=',' read -r cpu_perc mem_perc name <<< "$stats"
            
            # Remove % sign and convert to number
            cpu_num=$(echo "$cpu_perc" | sed 's/%//')
            mem_num=$(echo "$mem_perc" | sed 's/%//')
            
            # Check for high resource usage (>80%)
            if (( $(echo "$cpu_num > 80" | bc -l) )); then
                echo "⚠️ High CPU usage: $name ($cpu_perc)"
                ((high_cpu_count++))
            fi
            
            if (( $(echo "$mem_num > 80" | bc -l) )); then
                echo "⚠️ High memory usage: $name ($mem_perc)"
                ((high_memory_count++))
            fi
        fi
    done
    
    if [ $high_cpu_count -eq 0 ] && [ $high_memory_count -eq 0 ]; then
        echo "✅ Resource usage is within normal limits"
        return 0
    else
        echo "⚠️ High resource usage detected"
        return 1
    fi
}

# Function to perform network connectivity tests
check_network_connectivity() {
    echo "🌐 Checking network connectivity..."
    
    # Test internal service communication
    local api_container=$(docker-compose $COMPOSE_FILES ps -q api-gateway)
    
    if [ -n "$api_container" ]; then
        # Test database connection from API
        if docker exec "$api_container" nc -z postgres 5432 2>/dev/null; then
            echo "✅ API → Database: Connected"
        else
            echo "❌ API → Database: Connection failed"
            return 1
        fi
        
        # Test Redis connection from API
        if docker exec "$api_container" nc -z redis 6379 2>/dev/null; then
            echo "✅ API → Redis: Connected"
        else
            echo "❌ API → Redis: Connection failed"
            return 1
        fi
    fi
    
    return 0
}

# Function to run performance tests
run_performance_tests() {
    echo "⚡ Running basic performance tests..."
    
    local frontend_url="http://localhost:3000"
    local api_url="http://localhost:4000/health"
    
    # Test frontend response time
    local frontend_time=$(curl -o /dev/null -s -w '%{time_total}' "$frontend_url" 2>/dev/null || echo "999")
    if (( $(echo "$frontend_time < 5.0" | bc -l) )); then
        echo "✅ Frontend response time: ${frontend_time}s"
    else
        echo "⚠️ Frontend response time: ${frontend_time}s (slow)"
    fi
    
    # Test API response time
    local api_time=$(curl -o /dev/null -s -w '%{time_total}' "$api_url" 2>/dev/null || echo "999")
    if (( $(echo "$api_time < 2.0" | bc -l) )); then
        echo "✅ API response time: ${api_time}s"
    else
        echo "⚠️ API response time: ${api_time}s (slow)"
    fi
    
    # Basic load test
    echo "🔄 Running basic load test (10 concurrent requests)..."
    local load_test_result=0
    for i in {1..10}; do
        curl -s -o /dev/null "$frontend_url" &
    done
    wait
    
    echo "✅ Basic load test completed"
    return 0
}

# Main verification process
main() {
    local overall_status=0
    local checks_passed=0
    local total_checks=8
    
    echo "🚀 Starting deployment verification..."
    echo ""
    
    # Wait for containers to start
    echo "⏳ Waiting for containers to start..."
    sleep 30
    
    # Run verification checks
    if check_containers; then
        ((checks_passed++))
    else
        overall_status=1
    fi
    
    if ! check_timeout; then
        echo "❌ Verification timed out"
        exit 1
    fi
    
    echo ""
    if check_service_health; then
        ((checks_passed++))
    else
        overall_status=1
    fi
    
    if ! check_timeout; then
        echo "❌ Verification timed out"
        exit 1
    fi
    
    echo ""
    if check_database_connectivity; then
        ((checks_passed++))
    else
        overall_status=1
    fi
    
    echo ""
    if check_logs_for_errors; then
        ((checks_passed++))
    else
        overall_status=1
    fi
    
    echo ""
    if check_resource_usage; then
        ((checks_passed++))
    else
        overall_status=1
    fi
    
    echo ""
    if check_network_connectivity; then
        ((checks_passed++))
    else
        overall_status=1
    fi
    
    echo ""
    if run_performance_tests; then
        ((checks_passed++))
    else
        overall_status=1
    fi
    
    # Final summary
    echo ""
    echo "============================================"
    echo "📊 Verification Summary"
    echo "Environment: $ENVIRONMENT"
    echo "Checks passed: $checks_passed/$total_checks"
    
    local end_time=$(date +%s)
    local total_time=$((end_time - START_TIME))
    echo "Total time: ${total_time}s"
    
    if [ $overall_status -eq 0 ]; then
        echo "🎉 Deployment verification PASSED!"
        echo "✅ All systems are operational"
    else
        echo "❌ Deployment verification FAILED!"
        echo "⚠️ Some issues were detected"
    fi
    
    exit $overall_status
}

# Run main verification
main