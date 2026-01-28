-- Create tables for the DevOps Practice Environment
-- This script creates all necessary tables based on the design document

\c devops_practice;

-- Users table
CREATE TABLE users.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    learning_progress JSONB DEFAULT '{}',
    current_level VARCHAR(20) DEFAULT 'beginner',
    total_points INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Learning content table
CREATE TABLE learning.learning_content (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content_type VARCHAR(50) NOT NULL, -- 'module', 'quiz', 'lab'
    tool_category VARCHAR(50) NOT NULL, -- 'docker', 'ansible', 'terraform', etc.
    difficulty_level VARCHAR(20) NOT NULL,
    content_data JSONB NOT NULL,
    prerequisites TEXT[],
    estimated_duration INTEGER, -- in minutes
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Assessments table
CREATE TABLE assessments.assessments (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users.users(id) ON DELETE CASCADE,
    content_id INTEGER REFERENCES learning.learning_content(id) ON DELETE CASCADE,
    score INTEGER NOT NULL,
    max_score INTEGER NOT NULL,
    completion_time INTEGER, -- in seconds
    answers JSONB,
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Lab sessions table
CREATE TABLE labs.lab_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users.users(id) ON DELETE CASCADE,
    lab_type VARCHAR(50) NOT NULL,
    container_id VARCHAR(100),
    status VARCHAR(20) DEFAULT 'active',
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP,
    lab_data JSONB
);

-- Create indexes for better performance
CREATE INDEX idx_users_username ON users.users(username);
CREATE INDEX idx_users_email ON users.users(email);
CREATE INDEX idx_learning_content_category ON learning.learning_content(tool_category);
CREATE INDEX idx_learning_content_type ON learning.learning_content(content_type);
CREATE INDEX idx_assessments_user_id ON assessments.assessments(user_id);
CREATE INDEX idx_assessments_content_id ON assessments.assessments(content_id);
CREATE INDEX idx_lab_sessions_user_id ON labs.lab_sessions(user_id);
CREATE INDEX idx_lab_sessions_status ON labs.lab_sessions(status);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to users table
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users.users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();