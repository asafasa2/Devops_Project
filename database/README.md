# Database Layer - DevOps Practice Environment

This directory contains all database-related configurations, scripts, and documentation for the DevOps Practice Environment.

## Overview

The database layer consists of:
- **PostgreSQL**: Primary database for persistent data storage
- **Redis**: In-memory cache for sessions and temporary data

## Directory Structure

```
database/
├── init/                   # Database initialization scripts
│   ├── 01-create-databases.sql
│   ├── 02-create-tables.sql
│   └── 03-seed-data.sql
├── migrations/             # Database migration scripts
│   ├── README.md
│   ├── 20240128_120000_create_migrations_table.sql
│   └── 20240128_120001_initial_schema.sql
├── redis/                  # Redis configuration
│   └── redis.conf
├── scripts/                # Database management scripts
│   ├── migrate.sh
│   ├── backup.sh
│   └── test-connection.sh
└── README.md              # This file
```

## Database Schema

### PostgreSQL Databases

- **devops_practice**: Main application database
- **devops_practice_test**: Test database for automated testing

### Schemas

The main database is organized into logical schemas:

- **users**: User management and authentication
- **learning**: Learning content and modules
- **assessments**: Quizzes, tests, and scoring
- **labs**: Lab environments and sessions

### Tables

#### users.users
Stores user account information and learning progress.

| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL | Primary key |
| username | VARCHAR(50) | Unique username |
| email | VARCHAR(100) | User email address |
| password_hash | VARCHAR(255) | Hashed password |
| learning_progress | JSONB | Progress tracking data |
| current_level | VARCHAR(20) | User skill level |
| total_points | INTEGER | Accumulated points |
| created_at | TIMESTAMP | Account creation time |
| updated_at | TIMESTAMP | Last update time |

#### learning.learning_content
Contains all learning materials, quizzes, and lab definitions.

| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL | Primary key |
| title | VARCHAR(200) | Content title |
| content_type | VARCHAR(50) | Type: module, quiz, lab |
| tool_category | VARCHAR(50) | DevOps tool category |
| difficulty_level | VARCHAR(20) | Difficulty level |
| content_data | JSONB | Content structure and data |
| prerequisites | TEXT[] | Required prerequisites |
| estimated_duration | INTEGER | Duration in minutes |
| created_at | TIMESTAMP | Creation time |

#### assessments.assessments
Records user assessment attempts and scores.

| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL | Primary key |
| user_id | INTEGER | Reference to users.users |
| content_id | INTEGER | Reference to learning_content |
| score | INTEGER | Achieved score |
| max_score | INTEGER | Maximum possible score |
| completion_time | INTEGER | Time taken in seconds |
| answers | JSONB | User answers and metadata |
| completed_at | TIMESTAMP | Completion time |

#### labs.lab_sessions
Tracks active and completed lab sessions.

| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL | Primary key |
| user_id | INTEGER | Reference to users.users |
| lab_type | VARCHAR(50) | Type of lab environment |
| container_id | VARCHAR(100) | Docker container ID |
| status | VARCHAR(20) | Session status |
| start_time | TIMESTAMP | Session start time |
| end_time | TIMESTAMP | Session end time |
| lab_data | JSONB | Lab-specific data |

### Redis Databases

Redis is configured with 16 databases for different purposes:

- **Database 0**: User sessions
- **Database 1**: Learning progress cache
- **Database 2**: Lab environment cache
- **Database 3**: Assessment cache
- **Databases 4-15**: Available for future use

## Getting Started

### 1. Start Database Services

```bash
# Start PostgreSQL and Redis containers
docker-compose up -d postgres redis
```

### 2. Test Connections

```bash
# Test both PostgreSQL and Redis connections
./database/scripts/test-connection.sh

# Test individual services
./database/scripts/test-connection.sh postgres
./database/scripts/test-connection.sh redis
```

### 3. Run Migrations

```bash
# Apply all pending migrations
./database/scripts/migrate.sh

# Check migration status
./database/scripts/migrate.sh status
```

## Database Management

### Migrations

The migration system tracks database schema changes:

```bash
# Apply migrations
./database/scripts/migrate.sh apply

# Check status
./database/scripts/migrate.sh status
```

### Backups

Regular backups are essential for data protection:

```bash
# Create backup
./database/scripts/backup.sh

# List available backups
./database/scripts/backup.sh list

# Restore from backup
./database/scripts/backup.sh restore /path/to/backup.sql

# Cleanup old backups (older than 7 days)
./database/scripts/backup.sh cleanup
```

## Environment Variables

Configure database connections using these environment variables:

### PostgreSQL
- `DB_HOST`: Database host (default: localhost)
- `DB_PORT`: Database port (default: 5432)
- `DB_NAME`: Database name (default: devops_practice)
- `DB_USER`: Database user (default: devops_user)
- `DB_PASSWORD`: Database password (default: dev_password_2024)

### Redis
- `REDIS_HOST`: Redis host (default: localhost)
- `REDIS_PORT`: Redis port (default: 6379)

## Sample Data

The database includes sample data for testing and development:

- **Users**: Demo accounts with different skill levels
- **Learning Content**: Sample modules for Docker, Ansible, Terraform, and Jenkins
- **Assessments**: Example quiz results and scores
- **Lab Sessions**: Sample lab environment records

## Security Considerations

### Development Environment
- Default passwords are used for ease of development
- Database is accessible from all container networks
- No SSL/TLS encryption (suitable for local development only)

### Production Considerations
- Change all default passwords
- Enable SSL/TLS encryption
- Restrict network access
- Implement proper backup encryption
- Use secrets management for sensitive data

## Troubleshooting

### Common Issues

1. **Connection Refused**
   - Check if containers are running: `docker-compose ps`
   - Verify network connectivity: `docker network ls`
   - Check container logs: `docker-compose logs postgres redis`

2. **Permission Denied**
   - Ensure database user has proper privileges
   - Check file permissions on scripts: `chmod +x database/scripts/*.sh`

3. **Migration Failures**
   - Check migration file syntax
   - Verify database connection
   - Review migration logs for specific errors

4. **Data Persistence Issues**
   - Verify volume mounts in docker-compose.yml
   - Check volume permissions: `docker volume inspect <volume_name>`

### Logs and Monitoring

```bash
# View PostgreSQL logs
docker-compose logs postgres

# View Redis logs
docker-compose logs redis

# Monitor database performance
docker stats $(docker-compose ps -q postgres redis)
```

## Development Workflow

1. **Schema Changes**: Create new migration files in `migrations/` directory
2. **Testing**: Use test database for development and testing
3. **Backup**: Regular backups before major changes
4. **Documentation**: Update this README when adding new features

## Integration with Application Services

The database layer is designed to work with the microservices architecture:

- **User Management Service**: Connects to users schema
- **Learning Management Service**: Uses learning schema
- **Assessment Service**: Manages assessments schema
- **Lab Environment Service**: Handles labs schema

Each service should use connection pooling and proper error handling when interacting with the database layer.