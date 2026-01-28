#!/bin/bash
# Rollback script for failed deployments

ENVIRONMENT=${1:-dev}
PREVIOUS_VERSION=${2}
ROLLBACK_REASON=${3:-"Manual rollback"}

if [ -z "$PREVIOUS_VERSION" ]; then
    echo "❌ Error: Previous version not specified"
    echo "Usage: $0 <environment> <previous_version> [rollback_reason]"
    echo "Example: $0 prod v1.2.3 'Health check failed'"
    exit 1
fi

echo "🔄 Starting rollback process"
echo "Environment: $ENVIRONMENT"
echo "Rolling back to version: $PREVIOUS_VERSION"
echo "Reason: $ROLLBACK_REASON"
echo "============================================"

# Configuration
COMPOSE_FILES="-f docker-compose.yml -f docker-compose.${ENVIRONMENT}.yml"
BACKUP_DIR="backups/rollback-$(date +%Y%m%d_%H%M%S)"
ROLLBACK_TIMEOUT=300

# Function to create pre-rollback backup
create_backup() {
    echo "💾 Creating pre-rollback backup..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup current environment configuration
    cp .env "$BACKUP_DIR/env-before-rollback" 2>/dev/null || true
    cp "docker-compose.${ENVIRONMENT}.yml" "$BACKUP_DIR/" 2>/dev/null || true
    
    # Backup database
    echo "📊 Backing up database..."
    if docker-compose $COMPOSE_FILES exec -T postgres pg_dump -U devops_user devops_practice > "$BACKUP_DIR/database-before-rollback.sql" 2>/dev/null; then
        echo "✅ Database backup created"
    else
        echo "⚠️ Database backup failed, continuing with rollback"
    fi
    
    # Backup application logs
    echo "📋 Backing up application logs..."
    docker-compose $COMPOSE_FILES logs --no-color > "$BACKUP_DIR/application-logs.txt" 2>/dev/null || true
    
    echo "✅ Backup created at $BACKUP_DIR"
}

# Function to stop current services gracefully
stop_current_services() {
    echo "⏹️ Stopping current services..."
    
    # Get list of running containers
    local containers=$(docker-compose $COMPOSE_FILES ps -q)
    
    if [ -n "$containers" ]; then
        # Graceful shutdown with timeout
        echo "🔄 Attempting graceful shutdown..."
        docker-compose $COMPOSE_FILES stop --timeout=30
        
        # Force stop if needed
        local still_running=$(docker-compose $COMPOSE_FILES ps -q)
        if [ -n "$still_running" ]; then
            echo "⚠️ Some containers didn't stop gracefully, forcing shutdown..."
            docker-compose $COMPOSE_FILES kill
        fi
        
        # Remove containers
        docker-compose $COMPOSE_FILES rm -f
        
        echo "✅ Current services stopped"
    else
        echo "ℹ️ No running services found"
    fi
}

# Function to update configuration for rollback
update_configuration() {
    echo "⚙️ Updating configuration for rollback..."
    
    # Update environment file with previous version
    if [ -f ".env.${ENVIRONMENT}" ]; then
        cp ".env.${ENVIRONMENT}" .env
        
        # Update version tags
        sed -i.bak "s/BUILD_VERSION=.*/BUILD_VERSION=${PREVIOUS_VERSION}/g" .env
        sed -i.bak "s/:latest/:${PREVIOUS_VERSION}/g" .env
        sed -i.bak "s/:v[0-9]\+\.[0-9]\+\.[0-9]\+/:${PREVIOUS_VERSION}/g" .env
        
        echo "✅ Environment configuration updated"
    else
        echo "⚠️ Environment file not found, using defaults"
    fi
}

# Function to pull previous version images
pull_previous_images() {
    echo "📥 Pulling previous version images..."
    
    local services=("frontend" "api-gateway" "learning-service" "user-service" "lab-service" "assessment-service")
    local pull_failures=0
    
    for service in "${services[@]}"; do
        local image="devops-practice/${service}:${PREVIOUS_VERSION}"
        echo "Pulling $image..."
        
        if docker pull "$image" 2>/dev/null; then
            echo "✅ $service: Image pulled successfully"
        else
            echo "⚠️ $service: Failed to pull image, will try to use local image"
            ((pull_failures++))
        fi
    done
    
    if [ $pull_failures -gt 0 ]; then
        echo "⚠️ $pull_failures image(s) failed to pull, continuing with available images"
    else
        echo "✅ All images pulled successfully"
    fi
}

# Function to deploy previous version
deploy_previous_version() {
    echo "🚀 Deploying previous version..."
    
    # Start infrastructure services first
    echo "🔧 Starting infrastructure services..."
    docker-compose $COMPOSE_FILES up -d postgres redis
    
    # Wait for database to be ready
    echo "⏳ Waiting for database to be ready..."
    local db_ready=false
    local attempts=0
    local max_attempts=30
    
    while [ $attempts -lt $max_attempts ] && [ "$db_ready" = false ]; do
        if docker-compose $COMPOSE_FILES exec -T postgres pg_isready -U devops_user -d devops_practice > /dev/null 2>&1; then
            db_ready=true
            echo "✅ Database is ready"
        else
            echo "⏳ Waiting for database... (attempt $((attempts + 1))/$max_attempts)"
            sleep 5
            ((attempts++))
        fi
    done
    
    if [ "$db_ready" = false ]; then
        echo "❌ Database failed to start within timeout"
        return 1
    fi
    
    # Start application services
    echo "🚀 Starting application services..."
    docker-compose $COMPOSE_FILES up -d
    
    echo "✅ Previous version deployed"
}

# Function to verify rollback
verify_rollback() {
    echo "🔍 Verifying rollback..."
    
    local verification_start=$(date +%s)
    local max_wait=180
    local services_healthy=false
    
    while [ $(($(date +%s) - verification_start)) -lt $max_wait ] && [ "$services_healthy" = false ]; do
        echo "⏳ Checking service health..."
        
        local health_checks=0
        local total_checks=0
        
        # Check frontend
        if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
            ((health_checks++))
        fi
        ((total_checks++))
        
        # Check API
        if curl -f -s http://localhost:4000/health > /dev/null 2>&1; then
            ((health_checks++))
        fi
        ((total_checks++))
        
        if [ $health_checks -eq $total_checks ]; then
            services_healthy=true
            echo "✅ All services are healthy"
        else
            echo "⏳ $health_checks/$total_checks services healthy, waiting..."
            sleep 10
        fi
    done
    
    if [ "$services_healthy" = false ]; then
        echo "❌ Rollback verification failed - services not healthy"
        return 1
    fi
    
    # Additional checks
    echo "🔍 Running additional verification checks..."
    
    # Check database connectivity
    if docker-compose $COMPOSE_FILES exec -T postgres pg_isready -U devops_user -d devops_practice > /dev/null 2>&1; then
        echo "✅ Database connectivity verified"
    else
        echo "❌ Database connectivity check failed"
        return 1
    fi
    
    # Check Redis connectivity
    if docker-compose $COMPOSE_FILES exec -T redis redis-cli ping | grep -q "PONG"; then
        echo "✅ Redis connectivity verified"
    else
        echo "❌ Redis connectivity check failed"
        return 1
    fi
    
    echo "✅ Rollback verification completed successfully"
    return 0
}

# Function to update monitoring and notifications
update_monitoring() {
    echo "📊 Updating monitoring and notifications..."
    
    # Update Grafana annotations
    local grafana_url="http://localhost:3001"
    local annotation_data="{
        \"text\": \"Rollback to ${PREVIOUS_VERSION}\",
        \"tags\": [\"rollback\", \"deployment\"],
        \"time\": $(date +%s)000
    }"
    
    curl -s -X POST "${grafana_url}/api/annotations" \
         -H "Content-Type: application/json" \
         -d "$annotation_data" > /dev/null 2>&1 || true
    
    echo "✅ Monitoring updated"
}

# Function to send notifications
send_notifications() {
    local status=$1
    
    echo "📢 Sending notifications..."
    
    local message
    if [ $status -eq 0 ]; then
        message="✅ Rollback completed successfully!
Environment: $ENVIRONMENT
Rolled back to: $PREVIOUS_VERSION
Reason: $ROLLBACK_REASON
Time: $(date)"
    else
        message="❌ Rollback failed!
Environment: $ENVIRONMENT
Target version: $PREVIOUS_VERSION
Reason: $ROLLBACK_REASON
Time: $(date)
Manual intervention required!"
    fi
    
    # Send Slack notification (if configured)
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
        curl -s -X POST "$SLACK_WEBHOOK_URL" \
             -H "Content-Type: application/json" \
             -d "{\"text\": \"$message\"}" > /dev/null 2>&1 || true
    fi
    
    # Log notification
    echo "$message" >> "rollback-notifications.log"
    
    echo "✅ Notifications sent"
}

# Function to cleanup rollback artifacts
cleanup() {
    echo "🧹 Cleaning up rollback artifacts..."
    
    # Remove backup files from sed operations
    find . -name "*.bak" -delete 2>/dev/null || true
    
    # Clean up unused Docker images
    docker image prune -f > /dev/null 2>&1 || true
    
    echo "✅ Cleanup completed"
}

# Main rollback process
main() {
    local rollback_status=0
    local start_time=$(date +%s)
    
    echo "🚀 Starting rollback process..."
    
    # Create backup before rollback
    create_backup
    
    # Stop current services
    if ! stop_current_services; then
        echo "❌ Failed to stop current services"
        rollback_status=1
    fi
    
    # Update configuration
    if [ $rollback_status -eq 0 ]; then
        update_configuration
    fi
    
    # Pull previous images
    if [ $rollback_status -eq 0 ]; then
        pull_previous_images
    fi
    
    # Deploy previous version
    if [ $rollback_status -eq 0 ]; then
        if ! deploy_previous_version; then
            echo "❌ Failed to deploy previous version"
            rollback_status=1
        fi
    fi
    
    # Verify rollback
    if [ $rollback_status -eq 0 ]; then
        if ! verify_rollback; then
            echo "❌ Rollback verification failed"
            rollback_status=1
        fi
    fi
    
    # Update monitoring
    if [ $rollback_status -eq 0 ]; then
        update_monitoring
    fi
    
    # Send notifications
    send_notifications $rollback_status
    
    # Cleanup
    cleanup
    
    # Final summary
    local end_time=$(date +%s)
    local total_time=$((end_time - start_time))
    
    echo ""
    echo "============================================"
    echo "📊 Rollback Summary"
    echo "Environment: $ENVIRONMENT"
    echo "Target version: $PREVIOUS_VERSION"
    echo "Reason: $ROLLBACK_REASON"
    echo "Total time: ${total_time}s"
    echo "Backup location: $BACKUP_DIR"
    
    if [ $rollback_status -eq 0 ]; then
        echo "🎉 Rollback completed successfully!"
        echo "✅ System restored to previous version"
    else
        echo "❌ Rollback failed!"
        echo "⚠️ Manual intervention required"
        echo "📋 Check logs and backup at: $BACKUP_DIR"
    fi
    
    exit $rollback_status
}

# Trap to handle cleanup on script exit
trap 'echo "🛑 Rollback interrupted"; cleanup; exit 1' INT TERM

# Run main rollback process
main