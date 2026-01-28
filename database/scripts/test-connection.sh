#!/bin/bash

# Database Connection Test Script
# This script tests connectivity to PostgreSQL and Redis

set -e

# Configuration
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-devops_practice}"
DB_USER="${DB_USER:-devops_user}"
DB_PASSWORD="${DB_PASSWORD:-dev_password_2024}"

REDIS_HOST="${REDIS_HOST:-localhost}"
REDIS_PORT="${REDIS_PORT:-6379}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Test PostgreSQL connection
test_postgres() {
    print_status "Testing PostgreSQL connection..."
    print_status "Host: $DB_HOST:$DB_PORT, Database: $DB_NAME, User: $DB_USER"
    
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c 'SELECT version();' > /dev/null 2>&1; then
        print_success "PostgreSQL connection successful"
        
        # Test database schema
        print_status "Checking database schema..."
        local table_count=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
            SELECT COUNT(*) FROM information_schema.tables 
            WHERE table_schema IN ('users', 'learning', 'assessments', 'labs');
        " | tr -d ' ')
        
        print_status "Found $table_count application tables"
        
        if [ "$table_count" -gt 0 ]; then
            print_success "Database schema is properly initialized"
        else
            print_warning "Database schema may not be initialized"
        fi
        
        return 0
    else
        print_error "PostgreSQL connection failed"
        return 1
    fi
}

# Test Redis connection
test_redis() {
    print_status "Testing Redis connection..."
    print_status "Host: $REDIS_HOST:$REDIS_PORT"
    
    if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping > /dev/null 2>&1; then
        print_success "Redis connection successful"
        
        # Test Redis info
        local redis_version=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" info server | grep redis_version | cut -d: -f2 | tr -d '\r')
        print_status "Redis version: $redis_version"
        
        return 0
    else
        print_error "Redis connection failed"
        return 1
    fi
}

# Test both connections
test_all() {
    local postgres_ok=0
    local redis_ok=0
    
    test_postgres || postgres_ok=1
    echo
    test_redis || redis_ok=1
    echo
    
    if [ $postgres_ok -eq 0 ] && [ $redis_ok -eq 0 ]; then
        print_success "All database connections are working properly!"
        return 0
    else
        print_error "Some database connections failed"
        return 1
    fi
}

# Main script logic
case "${1:-all}" in
    "postgres"|"pg")
        test_postgres
        ;;
    "redis")
        test_redis
        ;;
    "all")
        test_all
        ;;
    "help"|"-h"|"--help")
        echo "Database Connection Test Script"
        echo "Usage: $0 [service]"
        echo ""
        echo "Services:"
        echo "  postgres  - Test PostgreSQL connection only"
        echo "  redis     - Test Redis connection only"
        echo "  all       - Test all database connections (default)"
        echo "  help      - Show this help message"
        echo ""
        echo "Environment Variables:"
        echo "  DB_HOST     - PostgreSQL host (default: localhost)"
        echo "  DB_PORT     - PostgreSQL port (default: 5432)"
        echo "  DB_NAME     - Database name (default: devops_practice)"
        echo "  DB_USER     - Database user (default: devops_user)"
        echo "  DB_PASSWORD - Database password (default: dev_password_2024)"
        echo "  REDIS_HOST  - Redis host (default: localhost)"
        echo "  REDIS_PORT  - Redis port (default: 6379)"
        ;;
    *)
        print_error "Unknown service: $1"
        echo "Use '$0 help' for usage information."
        exit 1
        ;;
esac