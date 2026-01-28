-- Migration: Initial database schema
-- Version: 20240128_120001
-- Description: Create initial database schema with all tables

\c devops_practice;

-- This migration creates the initial schema
-- Note: The actual table creation is handled by init scripts
-- This migration just records that the initial schema has been applied

INSERT INTO migrations (version, description) 
VALUES ('20240128_120001', 'Initial database schema with users, learning_content, assessments, and lab_sessions tables')
ON CONFLICT (version) DO NOTHING;