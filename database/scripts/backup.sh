#!/bin/bash

# Database Backup Script for DevOps Practice Environment
# This script creates backups of the PostgreSQL database

set -e

# Configuration
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-devops_practice}"
DB_USER="${DB_USER:-devops_user}"
DB_PASSWORD="${DB_PASSWORD:-dev_password_2024}"
BACKUP_DIR="${BACKUP_DIR:-$(dirname "$0")/../backups}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_backup_$TIMESTAMP.sql"

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

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Function to create backup
create_backup() {
    print_status "Creating database backup..."
    print_status "Database: $DB_NAME"
    print_status "Backup file: $BACKUP_FILE"
    
    if PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" > "$BACKUP_FILE"; then
        print_status "Backup created successfully: $BACKUP_FILE"
        
        # Compress the backup
        if command -v gzip >/dev/null 2>&1; then
            gzip "$BACKUP_FILE"
            print_status "Backup compressed: ${BACKUP_FILE}.gz"
        fi
        
        return 0
    else
        print_error "Failed to create backup"
        return 1
    fi
}

# Function to restore from backup
restore_backup() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        print_error "Please specify a backup file to restore from"
        echo "Usage: $0 restore <backup_file>"
        exit 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    print_warning "This will restore the database from: $backup_file"
    print_warning "All current data will be lost!"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Restore cancelled."
        exit 0
    fi
    
    print_status "Restoring database from backup..."
    
    # Check if file is compressed
    if [[ "$backup_file" == *.gz ]]; then
        if gunzip -c "$backup_file" | PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"; then
            print_status "Database restored successfully from: $backup_file"
        else
            print_error "Failed to restore database"
            exit 1
        fi
    else
        if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" < "$backup_file"; then
            print_status "Database restored successfully from: $backup_file"
        else
            print_error "Failed to restore database"
            exit 1
        fi
    fi
}

# Function to list available backups
list_backups() {
    print_status "Available backups in $BACKUP_DIR:"
    if ls "$BACKUP_DIR"/*.sql* 1> /dev/null 2>&1; then
        ls -la "$BACKUP_DIR"/*.sql*
    else
        print_warning "No backup files found in $BACKUP_DIR"
    fi
}

# Function to cleanup old backups
cleanup_backups() {
    local days="${1:-7}"
    print_status "Cleaning up backups older than $days days..."
    
    find "$BACKUP_DIR" -name "*.sql*" -type f -mtime +$days -delete
    print_status "Cleanup completed."
}

# Main script logic
case "${1:-backup}" in
    "backup")
        create_backup
        ;;
    "restore")
        restore_backup "$2"
        ;;
    "list")
        list_backups
        ;;
    "cleanup")
        cleanup_backups "$2"
        ;;
    "help"|"-h"|"--help")
        echo "Database Backup Script"
        echo "Usage: $0 [command] [options]"
        echo ""
        echo "Commands:"
        echo "  backup           - Create a database backup (default)"
        echo "  restore <file>   - Restore database from backup file"
        echo "  list             - List available backup files"
        echo "  cleanup [days]   - Remove backups older than specified days (default: 7)"
        echo "  help             - Show this help message"
        echo ""
        echo "Environment Variables:"
        echo "  DB_HOST     - Database host (default: localhost)"
        echo "  DB_PORT     - Database port (default: 5432)"
        echo "  DB_NAME     - Database name (default: devops_practice)"
        echo "  DB_USER     - Database user (default: devops_user)"
        echo "  DB_PASSWORD - Database password (default: dev_password_2024)"
        echo "  BACKUP_DIR  - Backup directory (default: ../backups)"
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Use '$0 help' for usage information."
        exit 1
        ;;
esac