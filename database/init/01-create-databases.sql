-- Create databases for the DevOps Practice Environment
-- This script runs automatically when PostgreSQL container starts

-- Create main application database (already created by POSTGRES_DB env var)
-- CREATE DATABASE devops_practice;

-- Create additional databases for different purposes
CREATE DATABASE devops_practice_test;

-- Create application user (already created by POSTGRES_USER env var)
-- CREATE USER devops_user WITH PASSWORD 'dev_password_2024';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE devops_practice TO devops_user;
GRANT ALL PRIVILEGES ON DATABASE devops_practice_test TO devops_user;

-- Connect to main database to create schemas
\c devops_practice;

-- Create schemas for better organization
CREATE SCHEMA IF NOT EXISTS learning;
CREATE SCHEMA IF NOT EXISTS users;
CREATE SCHEMA IF NOT EXISTS assessments;
CREATE SCHEMA IF NOT EXISTS labs;

-- Grant schema privileges
GRANT ALL ON SCHEMA learning TO devops_user;
GRANT ALL ON SCHEMA users TO devops_user;
GRANT ALL ON SCHEMA assessments TO devops_user;
GRANT ALL ON SCHEMA labs TO devops_user;