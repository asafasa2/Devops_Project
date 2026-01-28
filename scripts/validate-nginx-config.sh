#!/bin/bash

# Nginx Configuration Validation Script
# Validates nginx configuration files using Docker container

set -e

# Configuration
NGINX_IMAGE="${NGINX_IMAGE:-nginx:alpine}"
CONFIG_DIR="$(pwd)/nginx"
ENVIRONMENT="${ENVIRONMENT:-dev}"

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

# Validate nginx configuration file
validate_config() {
    local config_file="$1"
    local config_name="$2"
    
    log_info "Validating $config_name configuration..."
    
    if [ ! -f "$config_file" ]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi
    
    # Use Docker to validate the configuration
    local validation_output
    validation_output=$(docker run --rm -v "$config_file:/etc/nginx/nginx.conf:ro" "$NGINX_IMAGE" sh -c 'nginx -T 2>&1 | grep -E "(syntax|test)" || nginx -t 2>&1' 2>/dev/null)
    
    if echo "$validation_output" | grep -q "syntax is ok\|test is successful"; then
        log_success "$config_name configuration syntax is valid"
        return 0
    elif echo "$validation_output" | grep -q "host not found in upstream"; then
        log_warning "$config_name configuration syntax is valid (upstream hosts not resolvable outside Docker network)"
        return 0
    else
        log_error "$config_name configuration has syntax errors"
        
        # Show detailed error information
        log_info "Detailed error information:"
        echo "$validation_output"
        return 1
    fi
}

# Validate all configuration files
validate_all_configs() {
    log_info "Starting nginx configuration validation..."
    echo "========================================"
    
    local configs_valid=0
    local total_configs=0
    
    # Validate main configuration
    if [ -f "$CONFIG_DIR/nginx.conf" ]; then
        total_configs=$((total_configs + 1))
        if validate_config "$CONFIG_DIR/nginx.conf" "Main"; then
            configs_valid=$((configs_valid + 1))
        fi
        echo ""
    fi
    
    # Validate development configuration
    if [ -f "$CONFIG_DIR/nginx.dev.conf" ]; then
        total_configs=$((total_configs + 1))
        if validate_config "$CONFIG_DIR/nginx.dev.conf" "Development"; then
            configs_valid=$((configs_valid + 1))
        fi
        echo ""
    fi
    
    # Validate production configuration
    if [ -f "$CONFIG_DIR/nginx.prod.conf" ]; then
        total_configs=$((total_configs + 1))
        if validate_config "$CONFIG_DIR/nginx.prod.conf" "Production"; then
            configs_valid=$((configs_valid + 1))
        fi
        echo ""
    fi
    
    # Summary
    echo "========================================"
    if [ $configs_valid -eq $total_configs ]; then
        log_success "All nginx configurations are valid ($configs_valid/$total_configs)"
        return 0
    else
        log_error "Some nginx configurations have errors ($configs_valid/$total_configs valid)"
        return 1
    fi
}

# Test configuration with specific environment
test_environment_config() {
    local env="$1"
    local config_file
    
    case "$env" in
        "dev"|"development")
            config_file="$CONFIG_DIR/nginx.dev.conf"
            ;;
        "prod"|"production")
            config_file="$CONFIG_DIR/nginx.prod.conf"
            ;;
        "main"|"base")
            config_file="$CONFIG_DIR/nginx.conf"
            ;;
        *)
            log_error "Unknown environment: $env"
            echo "Supported environments: dev, prod, main"
            return 1
            ;;
    esac
    
    if [ -f "$config_file" ]; then
        validate_config "$config_file" "$env"
    else
        log_error "Configuration file not found for environment '$env': $config_file"
        return 1
    fi
}

# Show configuration summary
show_config_summary() {
    log_info "Nginx Configuration Summary:"
    echo "  Configuration Directory: $CONFIG_DIR"
    echo "  Available Configurations:"
    
    if [ -f "$CONFIG_DIR/nginx.conf" ]; then
        echo "    - nginx.conf (Main configuration)"
    fi
    
    if [ -f "$CONFIG_DIR/nginx.dev.conf" ]; then
        echo "    - nginx.dev.conf (Development configuration)"
    fi
    
    if [ -f "$CONFIG_DIR/nginx.prod.conf" ]; then
        echo "    - nginx.prod.conf (Production configuration)"
    fi
    
    if [ -d "$CONFIG_DIR/ssl" ]; then
        echo "    - ssl/ (SSL certificates directory)"
        if [ -f "$CONFIG_DIR/ssl/cert.pem" ] && [ -f "$CONFIG_DIR/ssl/key.pem" ]; then
            echo "      ✓ SSL certificates available"
        else
            echo "      ⚠ SSL certificates not found"
        fi
    fi
}

# Show usage information
show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Validate nginx configuration files using Docker"
    echo ""
    echo "Commands:"
    echo "  all                    Validate all configuration files (default)"
    echo "  env <environment>      Validate specific environment configuration"
    echo "  summary               Show configuration summary"
    echo "  help                  Show this help message"
    echo ""
    echo "Environments:"
    echo "  dev, development      Development configuration"
    echo "  prod, production      Production configuration"
    echo "  main, base           Main/base configuration"
    echo ""
    echo "Options:"
    echo "  --image IMAGE         Docker image to use for validation (default: nginx:alpine)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Validate all configurations"
    echo "  $0 env dev           # Validate development configuration"
    echo "  $0 env prod          # Validate production configuration"
    echo "  $0 summary           # Show configuration summary"
}

# Main execution
main() {
    local command="${1:-all}"
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --image)
                NGINX_IMAGE="$2"
                shift 2
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        log_info "Docker is required to validate nginx configurations"
        exit 1
    fi
    
    # Execute command
    case "$command" in
        "all")
            validate_all_configs
            ;;
        "env")
            if [ -z "$2" ]; then
                log_error "Environment not specified"
                show_usage
                exit 1
            fi
            test_environment_config "$2"
            ;;
        "summary")
            show_config_summary
            ;;
        "help")
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"