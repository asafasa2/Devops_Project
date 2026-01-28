# Database Migrations

This directory contains database migration scripts for the DevOps Practice Environment.

## Migration System

The migration system uses a simple versioning approach where each migration file is numbered sequentially.

### Migration File Naming Convention

- Format: `YYYYMMDD_HHMMSS_description.sql`
- Example: `20240128_120000_add_user_preferences.sql`

### Migration Table

The system tracks applied migrations in the `migrations` table:

```sql
CREATE TABLE migrations (
    id SERIAL PRIMARY KEY,
    version VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Running Migrations

Use the migration script to apply pending migrations:

```bash
# Apply all pending migrations
./database/scripts/migrate.sh

# Check migration status
./database/scripts/migrate.sh status

# Rollback last migration (if rollback script exists)
./database/scripts/migrate.sh rollback
```

### Creating New Migrations

1. Create a new migration file with the proper naming convention
2. Include both the migration SQL and rollback SQL (if applicable)
3. Test the migration on a development database first

### Migration Best Practices

- Always backup the database before running migrations in production
- Test migrations thoroughly in development environment
- Keep migrations small and focused on a single change
- Include rollback scripts when possible
- Document any manual steps required