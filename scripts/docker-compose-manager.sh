#!/bin/bash
# Docker Compose orchestration manager script

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_PROJECT_NAME="devops-practice"

# Default values
ENVIRONMENT="${ENVIRONMENT:-dev}"
ACTION="${1:-help}"
SERVICE="${2:-all}"
SCALE_REPLICAS="${3:-1}"

# Color codes for output
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

# Help function
show_help() {
    cat << EOF
Docker Compose Orchestration Manager

Usage: $0 <action> [service] [options]

Actions:
    up          Start services
    down        Stop and remove services
    restart     Restart services
    logs        Show service logs
    ps          Show running services
    build       Build service images
    pull        Pull latest images
    scale       Scale services
    health      Check service health
    backup      Backup volumes
    restore     Restore volumes
    clean       Clean up unused resources
    test        Run tests
    deploy      Deploy to environment
    rollback    Rollback deployment

Services:
    all         All services (default)
    app         Application services only
    db          Database services only
    monitoring  Monitoring services only
    web         Web services only

Environments (set via ENVIRONMENT variable):
    dev         Development (default)
    staging     Staging
    prod        Production
    test        Testing

Examples:
    $0 up                           # Start all services in dev environment
    ENVIRONMENT=prod $0 up app      # Start app services in production
    $0 scale api-gateway 3          # Scale api-gateway to 3 replicas
    $0 logs api-gateway             # Show logs for api-gateway
    $0 health                       # Check health of all services
    $0 backup                       # Backup all volumes
    $0 test                         # Run test suite

EOF
}

# Get compose files based on environment
get_compose_files() {
    local env="$1"
    local files="-f docker-compose.yml"
    
    case "$env" in
        "dev")
            files="$files -f docker-compose.dev.yml"
            ;;
        "staging")
            files="$files -f docker-compose.staging.yml"
            ;;
        "prod")
            files="$files -f docker-compose.prod.yml"
            ;;
        "test")
            files="-f docker-compose.test.yml"
            ;;
        *)
            log_error "Unknown environment: $env"
            exit 1
            ;;
    esac
    
    echo "$files"
}

# Get service groups
get_services() {
    local group="$1"
    
    case "$group" in
        "all")
            echo ""
            ;;
        "app")
            echo "api-gateway learning-service user-service assessment-service lab-service frontend"
            ;;
        "db")
            echo "postgres redis"
            ;;
        "monitoring")
            echo "prometheus grafana elasticsearch logstash kibana jenkins"
            ;;
        "web")
            echo "nginx frontend"
            ;;
        *)
            echo "$group"
            ;;
    esac
}

# Check if required files exist
check_prerequisites() {
    local env="$1"
    
    if [[ ! -f "$PROJECT_ROOT/docker-compose.yml" ]]; then
        log_error "Base docker-compose.yml not found"
        exit 1
    fi
    
    if [[ "$env" != "test" && ! -f "$PROJECT_ROOT/docker-compose.$env.yml" ]]; then
        log_error "Environment file docker-compose.$env.yml not found"
        exit 1
    fi
    
    # Check if .env file exists for the environment
    if [[ -f "$PROJECT_ROOT/.env.$env" ]]; then
        log_info "Using environment file: .env.$env"
        export $(grep -v '^#' "$PROJECT_ROOT/.env.$env" | xargs)
    elif [[ -f "$PROJECT_ROOT/.env" ]]; then
        log_info "Using default environment file: .env"
        export $(grep -v '^#' "$PROJECT_ROOT/.env" | xargs)
    else
        log_warning "No environment file found, using defaults"
    fi
}

# Create data directories
create_data_dirs() {
    local data_path="${DATA_PATH:-$PROJECT_ROOT/data}"
    
    log_info "Creating data directories in $data_path"
    
    mkdir -p "$data_path"/{postgres,redis,jenkins,grafana,prometheus,elasticsearch,nginx-cache,lab-workspaces}
    
    # Set proper permissions
    chmod 755 "$data_path"
    chmod 700 "$data_path/postgres"
    chmod 755 "$data_path/redis"
    chmod 755 "$data_path/jenkins"
    chmod 755 "$data_path/grafana"
    chmod 755 "$data_path/prometheus"
    chmod 755 "$data_path/elasticsearch"
    chmod 755 "$data_path/nginx-cache"
    chmod 755 "$data_path/lab-workspaces"
    
    log_success "Data directories created"
}

# Start services
start_services() {
    local env="$1"
    local services="$2"
    
    log_info "Starting services in $env environment"
    
    check_prerequisites "$env"
    create_data_dirs
    
    local compose_files=$(get_compose_files "$env")
    local service_list=$(get_services "$services")
    
    cd "$PROJECT_ROOT"
    
    # Pull images first
    log_info "Pulling latest images..."
    docker-compose $compose_files pull $service_list
    
    # Start services
    log_info "Starting services..."
    docker-compose $compose_files up -d $service_list
    
    # Wait for services to be healthy
    log_info "Waiting for services to be healthy..."
    sleep 10
    
    check_health "$env" "$services"
    
    log_success "Services started successfully"
}

# Stop services
stop_services() {
    local env="$1"
    local services="$2"
    
    log_info "Stopping services in $env environment"
    
    local compose_files=$(get_compose_files "$env")
    local service_list=$(get_services "$services")
    
    cd "$PROJECT_ROOT"
    
    docker-compose $compose_files down $service_list
    
    log_success "Services stopped successfully"
}

# Restart services
restart_services() {
    local env="$1"
    local services="$2"
    
    log_info "Restarting services in $env environment"
    
    local compose_files=$(get_compose_files "$env")
    local service_list=$(get_services "$services")
    
    cd "$PROJECT_ROOT"
    
    docker-compose $compose_files restart $service_list
    
    log_success "Services restarted successfully"
}

# Show logs
show_logs() {
    local env="$1"
    local services="$2"
    
    local compose_files=$(get_compose_files "$env")
    local service_list=$(get_services "$services")
    
    cd "$PROJECT_ROOT"
    
    docker-compose $compose_files logs -f --tail=100 $service_list
}

# Show running services
show_services() {
    local env="$1"
    
    local compose_files=$(get_compose_files "$env")
    
    cd "$PROJECT_ROOT"
    
    docker-compose $compose_files ps
}

# Build images
build_images() {
    local env="$1"
    local services="$2"
    
    log_info "Building images for $env environment"
    
    local compose_files=$(get_compose_files "$env")
    local service_list=$(get_services "$services")
    
    cd "$PROJECT_ROOT"
    
    docker-compose $compose_files build --no-cache $service_list
    
    log_success "Images built successfully"
}

# Scale services
scale_services() {
    local env="$1"
    local service="$2"
    local replicas="$3"
    
    log_info "Scaling $service to $replicas replicas in $env environment"
    
    local compose_files=$(get_compose_files "$env")
    
    cd "$PROJECT_ROOT"
    
    docker-compose $compose_files up -d --scale "$service=$replicas" "$service"
    
    log_success "Service scaled successfully"
}

# Check service health
check_health() {
    local env="$1"
    local services="$2"
    
    log_info "Checking service health in $env environment"
    
    local compose_files=$(get_compose_files "$env")
    local service_list=$(get_services "$services")
    
    cd "$PROJECT_ROOT"
    
    # Get list of running containers
    local containers=$(docker-compose $compose_files ps -q $service_list)
    
    if [[ -z "$containers" ]]; then
        log_warning "No containers found"
        return 1
    fi
    
    local healthy=0
    local total=0
    
    for container in $containers; do
        total=$((total + 1))
        local health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "no-health-check")
        local status=$(docker inspect --format='{{.State.Status}}' "$container")
        local name=$(docker inspect --format='{{.Name}}' "$container" | sed 's/^.//')
        
        if [[ "$status" == "running" ]]; then
            if [[ "$health" == "healthy" || "$health" == "no-health-check" ]]; then
                log_success "$name: healthy"
                healthy=$((healthy + 1))
            else
                log_warning "$name: $health"
            fi
        else
            log_error "$name: $status"
        fi
    done
    
    log_info "Health check complete: $healthy/$total services healthy"
    
    if [[ $healthy -eq $total ]]; then
        return 0
    else
        return 1
    fi
}

# Backup volumes
backup_volumes() {
    local env="$1"
    local backup_dir="${BACKUP_DIR:-$PROJECT_ROOT/backups}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    log_info "Backing up volumes for $env environment"
    
    mkdir -p "$backup_dir"
    
    # Get volume list
    local volumes=$(docker volume ls --filter "name=${env}-" --format "{{.Name}}")
    
    for volume in $volumes; do
        log_info "Backing up volume: $volume"
        
        docker run --rm \
            -v "$volume:/backup-source:ro" \
            -v "$backup_dir:/backup-dest" \
            alpine:latest \
            tar czf "/backup-dest/${volume}_${timestamp}.tar.gz" -C /backup-source .
        
        log_success "Volume $volume backed up"
    done
    
    log_success "All volumes backed up to $backup_dir"
}

# Run tests
run_tests() {
    log_info "Running test suite"
    
    cd "$PROJECT_ROOT"
    
    # Start test environment
    docker-compose -f docker-compose.test.yml up -d --build
    
    # Wait for services to be ready
    sleep 30
    
    # Run tests
    local test_result=0
    
    log_info "Running unit tests..."
    docker-compose -f docker-compose.test.yml exec -T api-gateway-test npm test || test_result=1
    docker-compose -f docker-compose.test.yml exec -T user-service-test python -m pytest || test_result=1
    docker-compose -f docker-compose.test.yml exec -T assessment-service-test python -m pytest || test_result=1
    
    log_info "Running integration tests..."
    docker-compose -f docker-compose.test.yml run --rm integration-tests || test_result=1
    
    log_info "Running e2e tests..."
    docker-compose -f docker-compose.test.yml run --rm e2e-tests || test_result=1
    
    # Cleanup test environment
    docker-compose -f docker-compose.test.yml down -v
    
    if [[ $test_result -eq 0 ]]; then
        log_success "All tests passed"
    else
        log_error "Some tests failed"
        exit 1
    fi
}

# Clean up resources
cleanup_resources() {
    log_info "Cleaning up unused Docker resources"
    
    # Remove stopped containers
    docker container prune -f
    
    # Remove unused images
    docker image prune -f
    
    # Remove unused volumes
    docker volume prune -f
    
    # Remove unused networks
    docker network prune -f
    
    log_success "Cleanup completed"
}

# Main execution
main() {
    cd "$PROJECT_ROOT"
    
    case "$ACTION" in
        "up")
            start_services "$ENVIRONMENT" "$SERVICE"
            ;;
        "down")
            stop_services "$ENVIRONMENT" "$SERVICE"
            ;;
        "restart")
            restart_services "$ENVIRONMENT" "$SERVICE"
            ;;
        "logs")
            show_logs "$ENVIRONMENT" "$SERVICE"
            ;;
        "ps")
            show_services "$ENVIRONMENT"
            ;;
        "build")
            build_images "$ENVIRONMENT" "$SERVICE"
            ;;
        "pull")
            local compose_files=$(get_compose_files "$ENVIRONMENT")
            docker-compose $compose_files pull
            ;;
        "scale")
            scale_services "$ENVIRONMENT" "$SERVICE" "$SCALE_REPLICAS"
            ;;
        "health")
            check_health "$ENVIRONMENT" "$SERVICE"
            ;;
        "backup")
            backup_volumes "$ENVIRONMENT"
            ;;
        "test")
            run_tests
            ;;
        "clean")
            cleanup_resources
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Execute main function
main "$@"