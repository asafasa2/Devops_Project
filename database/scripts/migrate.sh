#!/bin/bash

# Database Migration Script for DevOps Practice Environment
# This script manages database migrations

set -e

# Configuration
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-devops_practice}"
DB_USER="${DB_USER:-devops_user}"
DB_PASSWORD="${DB_PASSWORD:-dev_password_2024}"
MIGRATIONS_DIR="$(dirname "$0")/../migrations"

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

# Function to check database connection
check_db_connection() {
    print_status "Checking database connection..."
    if ! PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c '\q' 2>/dev/null; then
        print_error "Cannot connect to database. Please check your connection settings."
        print_error "Host: $DB_HOST, Port: $DB_PORT, Database: $DB_NAME, User: $DB_USER"
        exit 1
    fi
    print_status "Database connection successful."
}

# Function to ensure migrations table exists
ensure_migrations_table() {
    print_status "Ensuring migrations table exists..."
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
        CREATE TABLE IF NOT EXISTS migrations (
            id SERIAL PRIMARY KEY,
            version VARCHAR(50) UNIQUE NOT NULL,
            description TEXT,
            applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    " > /dev/null
}

# Function to get applied migrations
get_applied_migrations() {
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
        SELECT version FROM migrations ORDER BY version;
    " | sed 's/^[ \t]*//;s/[ \t]*$//' | grep -v '^$'
}

# Function to get pending migrations
get_pending_migrations() {
    local applied_migrations=$(get_applied_migrations)
    local all_migrations=$(ls "$MIGRATIONS_DIR"/*.sql 2>/dev/null | xargs -n 1 basename | sed 's/\.sql$//' | sort)
    
    for migration in $all_migrations; do
        if ! echo "$applied_migrations" | grep -q "^$migration$"; then
            echo "$migration"
        fi
    done
}

# Function to apply a single migration
apply_migration() {
    local migration_file="$1"
    local migration_version=$(basename "$migration_file" .sql)
    
    print_status "Applying migration: $migration_version"
    
    # Execute the migration
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$migration_file"; then
        print_status "Migration $migration_version applied successfully."
        return 0
    else
        print_error "Failed to apply migration $migration_version"
        return 1
    fi
}

# Function to show migration status
show_status() {
    print_status "Migration Status:"
    echo "=================="
    
    local applied_migrations=$(get_applied_migrations)
    local pending_migrations=$(get_pending_migrations)
    
    if [ -n "$applied_migrations" ]; then
        echo -e "${GREEN}Applied Migrations:${NC}"
        echo "$applied_migrations" | while read -r migration; do
            echo "  ✓ $migration"
        done
        echo
    fi
    
    if [ -n "$pending_migrations" ]; then
        echo -e "${YELLOW}Pending Migrations:${NC}"
        echo "$pending_migrations" | while read -r migration; do
            echo "  ○ $migration"
        done
        echo
    else
        print_status "No pending migrations."
    fi
}

# Function to apply all pending migrations
apply_migrations() {
    local pending_migrations=$(get_pending_migrations)
    
    if [ -z "$pending_migrations" ]; then
        print_status "No pending migrations to apply."
        return 0
    fi
    
    print_status "Found pending migrations:"
    echo "$pending_migrations" | while read -r migration; do
        echo "  - $migration"
    done
    echo
    
    echo "$pending_migrations" | while read -r migration; do
        local migration_file="$MIGRATIONS_DIR/$migration.sql"
        if [ -f "$migration_file" ]; then
            apply_migration "$migration_file"
        else
            print_error "Migration file not found: $migration_file"
            exit 1
        fi
    done
    
    print_status "All migrations applied successfully."
}

# Main script logic
case "${1:-apply}" in
    "apply")
        check_db_connection
        ensure_migrations_table
        apply_migrations
        ;;
    "status")
        check_db_connection
        ensure_migrations_table
        show_status
        ;;
    "help"|"-h"|"--help")
        echo "Database Migration Script"
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  apply   - Apply all pending migrations (default)"
        echo "  status  - Show migration status"
        echo "  help    - Show this help message"
        echo ""
        echo "Environment Variables:"
        echo "  DB_HOST     - Database host (default: localhost)"
        echo "  DB_PORT     - Database port (default: 5432)"
        echo "  DB_NAME     - Database name (default: devops_practice)"
        echo "  DB_USER     - Database user (default: devops_user)"
        echo "  DB_PASSWORD - Database password (default: dev_password_2024)"
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Use '$0 help' for usage information."
        exit 1
        ;;
esac