#!/bin/bash
# Environment Configuration Management Script

set -e

ACTION=${1}
ENVIRONMENT=${2:-dev}
SERVICE=${3:-all}

if [ -z "$ACTION" ]; then
    echo "Usage: $0 <action> [environment] [service]"
    echo "Actions: deploy, start, stop, restart, status, logs, scale, update"
    echo "Environments: dev, staging, prod"
    echo "Services: all, frontend, api-gateway, learning-service, user-service, lab-service, assessment-service"
    exit 1
fi

# Configuration
COMPOSE_PROJECT_NAME="devops-practice-${ENVIRONMENT}"
COMPOSE_FILES="-f docker-compose.yml -f docker-compose.${ENVIRONMENT}.yml"

echo "🔧 Environment Management"
echo "Action: $ACTION"
echo "Environment: $ENVIRONMENT"
echo "Service: $SERVICE"
echo "=========================="

# Function to check if environment files exist
check_environment_files() {
    if [ ! -f "docker-compose.${ENVIRONMENT}.yml" ]; then
        echo "❌ Environment file docker-compose.${ENVIRONMENT}.yml not found"
        exit 1
    fi
    
    if [ ! -f ".env.${ENVIRONMENT}" ]; then
        echo "⚠️ Environment variables file .env.${ENVIRONMENT} not found, using defaults"
    else
        cp ".env.${ENVIRONMENT}" .env
        echo "✅ Environment variables loaded from .env.${ENVIRONMENT}"
    fi
}

# Function to validate service name
validate_service() {
    local valid_services=("all" "frontend" "api-gateway" "learning-service" "user-service" "lab-service" "assessment-service" "postgres" "redis" "nginx" "jenkins" "grafana" "prometheus")
    
    if [[ ! " ${valid_services[@]} " =~ " ${SERVICE} " ]]; then
        echo "❌ Invalid service: $SERVICE"
        echo "Valid services: ${valid_services[*]}"
        exit 1
    fi
}

# Function to get service command
get_service_cmd() {
    if [ "$SERVICE" = "all" ]; then
        echo ""
    else
        echo "$SERVICE"
    fi
}

# Function to deploy environment
deploy_environment() {
    echo "🚀 Deploying $ENVIRONMENT environment..."
    
    # Pull latest images
    docker-compose $COMPOSE_FILES pull $(get_service_cmd)
    
    # Deploy services
    docker-compose $COMPOSE_FILES up -d $(get_service_cmd)
    
    # Wait for services to be ready
    echo "⏳ Waiting for services to be ready..."
    sleep 30
    
    # Health check
    health_check
}

# Function to start services
start_services() {
    echo "▶️ Starting $SERVICE in $ENVIRONMENT environment..."
    docker-compose $COMPOSE_FILES start $(get_service_cmd)
}

# Function to stop services
stop_services() {
    echo "⏹️ Stopping $SERVICE in $ENVIRONMENT environment..."
    docker-compose $COMPOSE_FILES stop $(get_service_cmd)
}

# Function to restart services
restart_services() {
    echo "🔄 Restarting $SERVICE in $ENVIRONMENT environment..."
    docker-compose $COMPOSE_FILES restart $(get_service_cmd)
}

# Function to show status
show_status() {
    echo "📊 Status of $ENVIRONMENT environment:"
    docker-compose $COMPOSE_FILES ps
    
    echo ""
    echo "📈 Resource usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" $(docker-compose $COMPOSE_FILES ps -q)
}

# Function to show logs
show_logs() {
    echo "📋 Logs for $SERVICE in $ENVIRONMENT environment:"
    if [ "$SERVICE" = "all" ]; then
        docker-compose $COMPOSE_FILES logs --tail=100 -f
    else
        docker-compose $COMPOSE_FILES logs --tail=100 -f $SERVICE
    fi
}

# Function to scale services
scale_services() {
    local replicas=${4:-2}
    
    if [ "$SERVICE" = "all" ]; then
        echo "❌ Cannot scale all services at once. Please specify a service."
        exit 1
    fi
    
    echo "📈 Scaling $SERVICE to $replicas replicas in $ENVIRONMENT environment..."
    docker-compose $COMPOSE_FILES up -d --scale $SERVICE=$replicas
}

# Function to update services
update_services() {
    local version=${4:-latest}
    
    echo "🔄 Updating $SERVICE to version $version in $ENVIRONMENT environment..."
    
    # Update image tags in environment file
    if [ "$SERVICE" != "all" ]; then
        sed -i "s/${SERVICE}:.*/${SERVICE}:${version}/g" .env
    else
        sed -i "s/:latest/:${version}/g" .env
    fi
    
    # Redeploy with new version
    deploy_environment
}

# Function to perform health check
health_check() {
    echo "🏥 Performing health check..."
    
    local services_to_check=()
    if [ "$SERVICE" = "all" ]; then
        services_to_check=("frontend" "api-gateway")
    else
        services_to_check=("$SERVICE")
    fi
    
    local failed_checks=0
    
    for svc in "${services_to_check[@]}"; do
        case $svc in
            "frontend")
                if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
                    echo "✅ Frontend: Healthy"
                else
                    echo "❌ Frontend: Unhealthy"
                    ((failed_checks++))
                fi
                ;;
            "api-gateway")
                if curl -f -s http://localhost:4000/health > /dev/null 2>&1; then
                    echo "✅ API Gateway: Healthy"
                else
                    echo "❌ API Gateway: Unhealthy"
                    ((failed_checks++))
                fi
                ;;
            "grafana")
                if curl -f -s http://localhost:3001/api/health > /dev/null 2>&1; then
                    echo "✅ Grafana: Healthy"
                else
                    echo "❌ Grafana: Unhealthy"
                    ((failed_checks++))
                fi
                ;;
            "prometheus")
                if curl -f -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
                    echo "✅ Prometheus: Healthy"
                else
                    echo "❌ Prometheus: Unhealthy"
                    ((failed_checks++))
                fi
                ;;
        esac
    done
    
    if [ $failed_checks -eq 0 ]; then
        echo "🎉 All services are healthy!"
        return 0
    else
        echo "⚠️ $failed_checks service(s) failed health checks"
        return 1
    fi
}

# Function to backup environment
backup_environment() {
    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)_${ENVIRONMENT}"
    mkdir -p "$backup_dir"
    
    echo "💾 Creating backup of $ENVIRONMENT environment..."
    
    # Backup database
    docker-compose $COMPOSE_FILES exec -T postgres pg_dump -U devops_user devops_practice > "$backup_dir/database.sql"
    
    # Backup volumes
    docker run --rm -v devops-practice-${ENVIRONMENT}-postgres-data:/data -v $(pwd)/$backup_dir:/backup alpine tar czf /backup/postgres-data.tar.gz -C /data .
    docker run --rm -v devops-practice-${ENVIRONMENT}-redis-data:/data -v $(pwd)/$backup_dir:/backup alpine tar czf /backup/redis-data.tar.gz -C /data .
    
    # Backup configuration
    cp .env "$backup_dir/"
    cp docker-compose.${ENVIRONMENT}.yml "$backup_dir/"
    
    echo "✅ Backup created at $backup_dir"
}

# Function to restore environment
restore_environment() {
    local backup_dir=${4}
    
    if [ -z "$backup_dir" ] || [ ! -d "$backup_dir" ]; then
        echo "❌ Backup directory not specified or doesn't exist"
        echo "Usage: $0 restore $ENVIRONMENT all <backup_directory>"
        exit 1
    fi
    
    echo "🔄 Restoring $ENVIRONMENT environment from $backup_dir..."
    
    # Stop services
    stop_services
    
    # Restore database
    if [ -f "$backup_dir/database.sql" ]; then
        docker-compose $COMPOSE_FILES up -d postgres
        sleep 10
        docker-compose $COMPOSE_FILES exec -T postgres psql -U devops_user -d devops_practice < "$backup_dir/database.sql"
    fi
    
    # Restore volumes
    if [ -f "$backup_dir/postgres-data.tar.gz" ]; then
        docker run --rm -v devops-practice-${ENVIRONMENT}-postgres-data:/data -v $(pwd)/$backup_dir:/backup alpine tar xzf /backup/postgres-data.tar.gz -C /data
    fi
    
    if [ -f "$backup_dir/redis-data.tar.gz" ]; then
        docker run --rm -v devops-practice-${ENVIRONMENT}-redis-data:/data -v $(pwd)/$backup_dir:/backup alpine tar xzf /backup/redis-data.tar.gz -C /data
    fi
    
    # Restore configuration
    if [ -f "$backup_dir/.env" ]; then
        cp "$backup_dir/.env" .env
    fi
    
    # Start services
    start_services
    
    echo "✅ Restore completed"
}

# Main execution
main() {
    check_environment_files
    validate_service
    
    case $ACTION in
        "deploy")
            deploy_environment
            ;;
        "start")
            start_services
            ;;
        "stop")
            stop_services
            ;;
        "restart")
            restart_services
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "scale")
            scale_services
            ;;
        "update")
            update_services
            ;;
        "health")
            health_check
            ;;
        "backup")
            backup_environment
            ;;
        "restore")
            restore_environment
            ;;
        *)
            echo "❌ Unknown action: $ACTION"
            echo "Available actions: deploy, start, stop, restart, status, logs, scale, update, health, backup, restore"
            exit 1
            ;;
    esac
}

# Run main function
main