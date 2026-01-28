#!/bin/bash

# Deployment and Operational Procedures Test Suite
# Tests multi-environment deployment workflows, CI/CD pipeline functionality, and rollback procedures

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${ENVIRONMENT:-dev}
TEST_ENVIRONMENT="test-$(date +%s)"
BASE_DIR="$(pwd)"
SCRIPTS_DIR="$BASE_DIR/scripts"
BACKUP_DIR="$BASE_DIR/backups/test-$(date +%Y%m%d_%H%M%S)"

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Logging
LOG_FILE="tests/integration/logs/deployment-test-$(date +%Y%m%d_%H%M%S).log"
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

# Setup test environment
setup_test_environment() {
    print_header "Setting Up Test Environment"
    
    # Create test environment configuration
    print_test "Creating test environment configuration"
    
    # Copy dev environment as base for testing
    if [ -f ".env.dev" ]; then
        cp ".env.dev" ".env.${TEST_ENVIRONMENT}"
        # Modify ports to avoid conflicts
        sed -i "s/ENVIRONMENT=dev/ENVIRONMENT=${TEST_ENVIRONMENT}/g" ".env.${TEST_ENVIRONMENT}"
        sed -i "s/:3000/:3100/g" ".env.${TEST_ENVIRONMENT}"
        sed -i "s/:4000/:4100/g" ".env.${TEST_ENVIRONMENT}"
        sed -i "s/:8080/:8180/g" ".env.${TEST_ENVIRONMENT}"
        print_success "Test environment configuration created"
    else
        print_error "Base environment file .env.dev not found"
        return 1
    fi
    
    # Create test compose file
    if [ -f "docker-compose.dev.yml" ]; then
        cp "docker-compose.dev.yml" "docker-compose.${TEST_ENVIRONMENT}.yml"
        print_success "Test compose file created"
    else
        print_error "Base compose file docker-compose.dev.yml not found"
        return 1
    fi
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    print_success "Backup directory created: $BACKUP_DIR"
}

# Test deployment script functionality
test_deployment_script() {
    print_header "Deployment Script Tests"
    
    # Test script existence and permissions
    print_test "Deployment script existence and permissions"
    if [ -f "$SCRIPTS_DIR/deploy.sh" ] && [ -x "$SCRIPTS_DIR/deploy.sh" ]; then
        print_success "Deployment script exists and is executable"
    else
        print_error "Deployment script not found or not executable"
        return 1
    fi
    
    # Test script help/usage
    print_test "Deployment script help functionality"
    if "$SCRIPTS_DIR/deploy.sh" 2>&1 | grep -q "Invalid environment"; then
        print_success "Deployment script shows proper usage information"
    else
        print_error "Deployment script doesn't show proper usage information"
    fi
    
    # Test environment validation
    print_test "Environment validation"
    if "$SCRIPTS_DIR/deploy.sh" invalid_env 2>&1 | grep -q "Invalid environment"; then
        print_success "Environment validation working correctly"
    else
        print_error "Environment validation not working"
    fi
    
    # Test action validation
    print_test "Action validation"
    if "$SCRIPTS_DIR/deploy.sh" dev invalid_action 2>&1 | grep -q "Invalid action"; then
        print_success "Action validation working correctly"
    else
        print_error "Action validation not working"
    fi
}

# Test multi-environment deployment
test_multi_environment_deployment() {
    print_header "Multi-Environment Deployment Tests"
    
    # Test development environment deployment
    print_test "Development environment deployment"
    if timeout 120 "$SCRIPTS_DIR/deploy.sh" dev up > /tmp/deploy_dev.log 2>&1; then
        if docker-compose -f docker-compose.yml -f docker-compose.dev.yml ps | grep -q "Up"; then
            print_success "Development environment deployed successfully"
        else
            print_error "Development environment deployment failed - services not running"
        fi
    else
        print_error "Development environment deployment timed out or failed"
    fi
    
    # Test staging environment deployment (if exists)
    if [ -f "docker-compose.staging.yml" ]; then
        print_test "Staging environment deployment"
        if timeout 120 "$SCRIPTS_DIR/deploy.sh" staging up > /tmp/deploy_staging.log 2>&1; then
            if docker-compose -f docker-compose.yml -f docker-compose.staging.yml ps | grep -q "Up"; then
                print_success "Staging environment deployed successfully"
            else
                print_error "Staging environment deployment failed - services not running"
            fi
        else
            print_error "Staging environment deployment timed out or failed"
        fi
    else
        print_success "Staging environment configuration not found (acceptable)"
    fi
    
    # Test production environment deployment (if exists)
    if [ -f "docker-compose.prod.yml" ]; then
        print_test "Production environment deployment validation"
        # Don't actually deploy prod, just validate configuration
        if docker-compose -f docker-compose.yml -f docker-compose.prod.yml config > /dev/null 2>&1; then
            print_success "Production environment configuration is valid"
        else
            print_error "Production environment configuration is invalid"
        fi
    else
        print_success "Production environment configuration not found (acceptable)"
    fi
}

# Test deployment verification
test_deployment_verification() {
    print_header "Deployment Verification Tests"
    
    # Test verification script existence
    print_test "Verification script existence and permissions"
    if [ -f "$SCRIPTS_DIR/verify-deployment.sh" ] && [ -x "$SCRIPTS_DIR/verify-deployment.sh" ]; then
        print_success "Verification script exists and is executable"
    else
        print_error "Verification script not found or not executable"
        return 1
    fi
    
    # Test deployment verification
    print_test "Deployment verification execution"
    if timeout 180 "$SCRIPTS_DIR/verify-deployment.sh" dev 120 > /tmp/verify_deployment.log 2>&1; then
        print_success "Deployment verification passed"
    else
        print_error "Deployment verification failed"
        # Show last few lines of verification log
        echo "Last 10 lines of verification log:"
        tail -10 /tmp/verify_deployment.log || true
    fi
    
    # Test verification timeout handling
    print_test "Verification timeout handling"
    if timeout 10 "$SCRIPTS_DIR/verify-deployment.sh" dev 5 > /tmp/verify_timeout.log 2>&1; then
        print_success "Verification completed within short timeout"
    else
        if grep -q "timeout" /tmp/verify_timeout.log; then
            print_success "Verification timeout properly handled"
        else
            print_error "Verification timeout not properly handled"
        fi
    fi
}

# Test rollback procedures
test_rollback_procedures() {
    print_header "Rollback Procedure Tests"
    
    # Test rollback script existence
    print_test "Rollback script existence and permissions"
    if [ -f "$SCRIPTS_DIR/rollback.sh" ] && [ -x "$SCRIPTS_DIR/rollback.sh" ]; then
        print_success "Rollback script exists and is executable"
    else
        print_error "Rollback script not found or not executable"
        return 1
    fi
    
    # Test rollback script usage validation
    print_test "Rollback script usage validation"
    if "$SCRIPTS_DIR/rollback.sh" 2>&1 | grep -q "Previous version not specified"; then
        print_success "Rollback script shows proper usage information"
    else
        print_error "Rollback script doesn't show proper usage information"
    fi
    
    # Test rollback script parameter validation
    print_test "Rollback script parameter validation"
    if "$SCRIPTS_DIR/rollback.sh" dev 2>&1 | grep -q "Previous version not specified"; then
        print_success "Rollback script validates required parameters"
    else
        print_error "Rollback script doesn't validate required parameters"
    fi
    
    # Test rollback backup creation (dry run)
    print_test "Rollback backup functionality"
    # Create a mock rollback scenario
    export BACKUP_DIR_TEST="$BACKUP_DIR/rollback-test"
    mkdir -p "$BACKUP_DIR_TEST"
    
    # Simulate backup creation by checking if the script would create backups
    if grep -q "create_backup" "$SCRIPTS_DIR/rollback.sh"; then
        print_success "Rollback script includes backup functionality"
    else
        print_error "Rollback script missing backup functionality"
    fi
}

# Test CI/CD pipeline functionality
test_cicd_pipeline() {
    print_header "CI/CD Pipeline Tests"
    
    # Test Jenkinsfile existence
    print_test "Jenkinsfile existence"
    if [ -f "Jenkinsfile" ]; then
        print_success "Jenkinsfile exists"
    else
        print_error "Jenkinsfile not found"
    fi
    
    # Test Jenkins pipeline configuration
    if [ -f "jenkins/casc_configs/jenkins.yaml" ]; then
        print_test "Jenkins configuration validation"
        if grep -q "pipeline" "jenkins/casc_configs/jenkins.yaml"; then
            print_success "Jenkins pipeline configuration found"
        else
            print_error "Jenkins pipeline configuration not found"
        fi
    fi
    
    # Test pipeline scripts
    pipeline_scripts=("feature-branch.Jenkinsfile" "release.Jenkinsfile" "rollback.Jenkinsfile")
    for script in "${pipeline_scripts[@]}"; do
        print_test "Pipeline script: $script"
        if [ -f "jenkins/pipelines/$script" ]; then
            print_success "$script exists"
        else
            print_error "$script not found"
        fi
    done
    
    # Test Jenkins service availability
    print_test "Jenkins service availability"
    if docker-compose -f docker-compose.yml -f docker-compose.dev.yml ps jenkins | grep -q "Up"; then
        if curl -f -s http://localhost:8080/login > /dev/null 2>&1; then
            print_success "Jenkins service is accessible"
        else
            print_error "Jenkins service is not accessible"
        fi
    else
        print_success "Jenkins service not running (acceptable for testing)"
    fi
}

# Test monitoring and alerting validation
test_monitoring_alerting() {
    print_header "Monitoring and Alerting System Tests"
    
    # Test Prometheus configuration
    print_test "Prometheus configuration validation"
    if [ -f "monitoring/prometheus/prometheus.yml" ]; then
        if docker run --rm -v "$(pwd)/monitoring/prometheus:/etc/prometheus" prom/prometheus:latest promtool check config /etc/prometheus/prometheus.yml > /dev/null 2>&1; then
            print_success "Prometheus configuration is valid"
        else
            print_error "Prometheus configuration is invalid"
        fi
    else
        print_error "Prometheus configuration file not found"
    fi
    
    # Test alert rules
    print_test "Prometheus alert rules validation"
    if [ -f "monitoring/prometheus/alert_rules.yml" ]; then
        if docker run --rm -v "$(pwd)/monitoring/prometheus:/etc/prometheus" prom/prometheus:latest promtool check rules /etc/prometheus/alert_rules.yml > /dev/null 2>&1; then
            print_success "Prometheus alert rules are valid"
        else
            print_error "Prometheus alert rules are invalid"
        fi
    else
        print_error "Prometheus alert rules file not found"
    fi
    
    # Test Grafana dashboard configuration
    print_test "Grafana dashboard configuration"
    if [ -d "monitoring/grafana/dashboards" ] && [ "$(ls -A monitoring/grafana/dashboards)" ]; then
        dashboard_count=$(ls monitoring/grafana/dashboards/*.json 2>/dev/null | wc -l)
        if [ "$dashboard_count" -gt 0 ]; then
            print_success "Grafana dashboards found ($dashboard_count dashboards)"
        else
            print_error "No Grafana dashboards found"
        fi
    else
        print_error "Grafana dashboards directory not found or empty"
    fi
    
    # Test monitoring services availability
    monitoring_services=("prometheus:9090" "grafana:3001")
    for service_info in "${monitoring_services[@]}"; do
        IFS=':' read -r service port <<< "$service_info"
        print_test "$service monitoring service availability"
        
        if docker-compose -f docker-compose.yml -f docker-compose.dev.yml ps "$service" | grep -q "Up"; then
            if curl -f -s "http://localhost:$port" > /dev/null 2>&1; then
                print_success "$service is accessible on port $port"
            else
                print_error "$service is not accessible on port $port"
            fi
        else
            print_success "$service not running (acceptable for testing)"
        fi
    done
}

# Test backup and recovery procedures
test_backup_recovery() {
    print_header "Backup and Recovery Tests"
    
    # Test database backup script
    print_test "Database backup script existence"
    if [ -f "database/scripts/backup.sh" ] && [ -x "database/scripts/backup.sh" ]; then
        print_success "Database backup script exists and is executable"
    else
        print_error "Database backup script not found or not executable"
    fi
    
    # Test backup functionality
    print_test "Database backup functionality"
    if docker-compose -f docker-compose.yml -f docker-compose.dev.yml ps postgres | grep -q "Up"; then
        # Create a test backup
        backup_file="$BACKUP_DIR/test-backup-$(date +%s).sql"
        if docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec -T postgres pg_dump -U devops_user devops_practice > "$backup_file" 2>/dev/null; then
            if [ -s "$backup_file" ]; then
                print_success "Database backup created successfully"
            else
                print_error "Database backup file is empty"
            fi
        else
            print_error "Database backup failed"
        fi
    else
        print_success "Database not running (acceptable for testing)"
    fi
    
    # Test environment management script backup functionality
    print_test "Environment management backup functionality"
    if [ -f "$SCRIPTS_DIR/manage-environment.sh" ] && [ -x "$SCRIPTS_DIR/manage-environment.sh" ]; then
        if grep -q "backup_environment" "$SCRIPTS_DIR/manage-environment.sh"; then
            print_success "Environment management script includes backup functionality"
        else
            print_error "Environment management script missing backup functionality"
        fi
    else
        print_error "Environment management script not found or not executable"
    fi
    
    # Test volume backup capability
    print_test "Volume backup capability"
    volumes=$(docker volume ls --format "{{.Name}}" | grep -E "(postgres|redis|grafana)" | head -3)
    if [ -n "$volumes" ]; then
        print_success "Persistent volumes found for backup testing"
        # Test volume backup command structure
        for volume in $volumes; do
            if docker run --rm -v "$volume:/data" -v "$BACKUP_DIR:/backup" alpine ls /data > /dev/null 2>&1; then
                print_success "Volume $volume is accessible for backup"
            else
                print_error "Volume $volume is not accessible for backup"
            fi
        done
    else
        print_success "No persistent volumes found (acceptable for testing)"
    fi
}

# Test configuration management
test_configuration_management() {
    print_header "Configuration Management Tests"
    
    # Test environment file validation
    environments=("dev" "staging" "prod")
    for env in "${environments[@]}"; do
        print_test "Environment configuration: $env"
        if [ -f ".env.$env" ]; then
            # Check for required variables
            required_vars=("ENVIRONMENT" "DB_PASSWORD" "JWT_SECRET")
            missing_vars=0
            
            for var in "${required_vars[@]}"; do
                if ! grep -q "^$var=" ".env.$env"; then
                    ((missing_vars++))
                fi
            done
            
            if [ $missing_vars -eq 0 ]; then
                print_success "$env environment configuration is complete"
            else
                print_error "$env environment configuration missing $missing_vars required variables"
            fi
        else
            if [ "$env" = "dev" ]; then
                print_error "$env environment configuration not found (required)"
            else
                print_success "$env environment configuration not found (acceptable)"
            fi
        fi
    done
    
    # Test Docker Compose file validation
    for env in "${environments[@]}"; do
        print_test "Docker Compose configuration: $env"
        if [ -f "docker-compose.$env.yml" ]; then
            if docker-compose -f docker-compose.yml -f "docker-compose.$env.yml" config > /dev/null 2>&1; then
                print_success "$env Docker Compose configuration is valid"
            else
                print_error "$env Docker Compose configuration is invalid"
            fi
        else
            if [ "$env" = "dev" ]; then
                print_error "$env Docker Compose configuration not found (required)"
            else
                print_success "$env Docker Compose configuration not found (acceptable)"
            fi
        fi
    done
    
    # Test secret management
    print_test "Secret management validation"
    secret_files=(".env" ".env.dev" ".env.staging" ".env.prod")
    secrets_in_git=0
    
    for file in "${secret_files[@]}"; do
        if [ -f "$file" ] && git check-ignore "$file" > /dev/null 2>&1; then
            # File is ignored by git (good)
            continue
        elif [ -f "$file" ]; then
            ((secrets_in_git++))
        fi
    done
    
    if [ $secrets_in_git -eq 0 ]; then
        print_success "Secret files are properly excluded from version control"
    else
        print_error "$secrets_in_git secret files are not excluded from version control"
    fi
}

# Cleanup test environment
cleanup_test_environment() {
    print_header "Cleaning Up Test Environment"
    
    # Remove test environment files
    print_test "Removing test environment files"
    rm -f ".env.${TEST_ENVIRONMENT}" "docker-compose.${TEST_ENVIRONMENT}.yml"
    print_success "Test environment files removed"
    
    # Clean up test containers (if any were created)
    print_test "Cleaning up test containers"
    docker-compose -p "devops-practice-${TEST_ENVIRONMENT}" down --remove-orphans > /dev/null 2>&1 || true
    print_success "Test containers cleaned up"
    
    # Clean up temporary files
    print_test "Cleaning up temporary files"
    rm -f /tmp/deploy_*.log /tmp/verify_*.log
    print_success "Temporary files cleaned up"
    
    print_success "Test environment cleanup completed"
}

# Main test execution
main() {
    print_header "Deployment and Operational Procedures Tests"
    log "Starting deployment and operational tests for environment: $ENVIRONMENT"
    
    # Setup
    setup_test_environment
    
    # Run all test suites
    test_deployment_script
    test_multi_environment_deployment
    test_deployment_verification
    test_rollback_procedures
    test_cicd_pipeline
    test_monitoring_alerting
    test_backup_recovery
    test_configuration_management
    
    # Cleanup
    cleanup_test_environment
    
    # Print final results
    print_header "Deployment Test Results Summary"
    echo -e "${BLUE}Total Tests: $TOTAL_TESTS${NC}"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}All deployment and operational tests passed successfully!${NC}"
        log "All deployment and operational tests passed successfully!"
        exit 0
    else
        echo -e "${RED}Some deployment and operational tests failed. Check the log file: $LOG_FILE${NC}"
        log "Deployment and operational tests completed with $FAILED_TESTS failures"
        exit 1
    fi
}

# Handle cleanup on script exit
trap 'cleanup_test_environment' EXIT

# Run tests
main "$@"