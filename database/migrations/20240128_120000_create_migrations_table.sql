-- Migration: Create migrations tracking table
-- Version: 20240128_120000
-- Description: Create table to track applied database migrations

\c devops_practice;

-- Create migrations table to track applied migrations
CREATE TABLE IF NOT EXISTS migrations (
    id SERIAL PRIMARY KEY,
    version VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert this migration record
INSERT INTO migrations (version, description) 
VALUES ('20240128_120000', 'Create migrations tracking table')
ON CONFLICT (version) DO NOTHING;