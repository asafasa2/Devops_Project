-- CKA Simulator Database Schema
-- This file creates the necessary tables for the CKA simulator functionality

-- Create CKA sessions table
CREATE TABLE IF NOT EXISTS cka_sessions (
    id UUID PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    scenario_id VARCHAR(100) NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    end_time TIMESTAMP WITH TIME ZONE,
    end_reason VARCHAR(50), -- 'manual', 'timeout', 'shutdown'
    status VARCHAR(50) NOT NULL DEFAULT 'initializing', -- 'initializing', 'ready', 'active', 'completed', 'error'
    containers JSONB NOT NULL,
    network_name VARCHAR(255) NOT NULL,
    progress JSONB DEFAULT '{"currentTask": 0, "completedTasks": [], "timeRemaining": 0, "score": 0}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create index on user_id for faster queries
CREATE INDEX IF NOT EXISTS idx_cka_sessions_user_id ON cka_sessions(user_id);

-- Create index on scenario_id for analytics
CREATE INDEX IF NOT EXISTS idx_cka_sessions_scenario_id ON cka_sessions(scenario_id);

-- Create index on start_time for time-based queries
CREATE INDEX IF NOT EXISTS idx_cka_sessions_start_time ON cka_sessions(start_time);

-- Create CKA task attempts table for detailed tracking
CREATE TABLE IF NOT EXISTS cka_task_attempts (
    id SERIAL PRIMARY KEY,
    session_id UUID NOT NULL REFERENCES cka_sessions(id) ON DELETE CASCADE,
    task_id INTEGER NOT NULL,
    scenario_id VARCHAR(100) NOT NULL,
    attempt_number INTEGER NOT NULL DEFAULT 1,
    is_successful BOOLEAN NOT NULL DEFAULT FALSE,
    validation_output TEXT,
    hints_used INTEGER DEFAULT 0,
    time_spent INTEGER, -- seconds spent on this task
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create index on session_id for faster queries
CREATE INDEX IF NOT EXISTS idx_cka_task_attempts_session_id ON cka_task_attempts(session_id);

-- Create CKA scenarios metadata table
CREATE TABLE IF NOT EXISTS cka_scenarios (
    id VARCHAR(100) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    difficulty VARCHAR(50), -- 'easy', 'medium', 'hard'
    time_limit INTEGER NOT NULL, -- in minutes
    weight INTEGER DEFAULT 0, -- exam weight percentage
    total_points INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Insert default CKA scenarios
INSERT INTO cka_scenarios (id, title, description, difficulty, time_limit, weight, total_points) VALUES
('cluster-setup', 'Cluster Setup and Management', 'Initialize and configure a Kubernetes cluster using kubeadm', 'medium', 30, 25, 25),
('pod-management', 'Pod Creation and Management', 'Create and manage pods with various configurations including resource limits and environment variables', 'easy', 20, 13, 13),
('storage-management', 'Storage and Persistent Volumes', 'Configure persistent storage solutions including PVs, PVCs, and StatefulSets', 'medium', 25, 20, 20),
('troubleshooting', 'Cluster Troubleshooting', 'Diagnose and fix various cluster issues including pod failures, node problems, and networking issues', 'hard', 35, 30, 30),
('service-networking', 'Service and Networking', 'Create services, configure networking, and set up ingress controllers', 'medium', 25, 20, 20)
ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    difficulty = EXCLUDED.difficulty,
    time_limit = EXCLUDED.time_limit,
    weight = EXCLUDED.weight,
    total_points = EXCLUDED.total_points,
    updated_at = NOW();

-- Create CKA leaderboard view
CREATE OR REPLACE VIEW cka_leaderboard AS
SELECT 
    user_id,
    COUNT(*) as total_sessions,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_sessions,
    AVG(CASE WHEN progress->>'score' IS NOT NULL THEN (progress->>'score')::INTEGER ELSE 0 END) as avg_score,
    MAX(CASE WHEN progress->>'score' IS NOT NULL THEN (progress->>'score')::INTEGER ELSE 0 END) as best_score,
    AVG(EXTRACT(EPOCH FROM (end_time - start_time))/60) as avg_duration_minutes,
    MAX(start_time) as last_session
FROM cka_sessions 
WHERE start_time >= NOW() - INTERVAL '30 days'
GROUP BY user_id
ORDER BY best_score DESC, avg_score DESC;

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_cka_sessions_updated_at 
    BEFORE UPDATE ON cka_sessions 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cka_scenarios_updated_at 
    BEFORE UPDATE ON cka_scenarios 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Create function to clean up old sessions (older than 7 days)
CREATE OR REPLACE FUNCTION cleanup_old_cka_sessions()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM cka_sessions 
    WHERE start_time < NOW() - INTERVAL '7 days'
    AND status IN ('completed', 'error');
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON cka_sessions TO devops_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON cka_task_attempts TO devops_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON cka_scenarios TO devops_user;
GRANT SELECT ON cka_leaderboard TO devops_user;
GRANT USAGE, SELECT ON SEQUENCE cka_task_attempts_id_seq TO devops_user;

-- Add comments for documentation
COMMENT ON TABLE cka_sessions IS 'Stores CKA practice session information including containers and progress';
COMMENT ON TABLE cka_task_attempts IS 'Tracks individual task attempts within CKA sessions';
COMMENT ON TABLE cka_scenarios IS 'Metadata about available CKA practice scenarios';
COMMENT ON VIEW cka_leaderboard IS 'Leaderboard showing user performance in CKA practice sessions';

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_cka_sessions_status ON cka_sessions(status);
CREATE INDEX IF NOT EXISTS idx_cka_sessions_end_time ON cka_sessions(end_time);
CREATE INDEX IF NOT EXISTS idx_cka_task_attempts_task_id ON cka_task_attempts(task_id);
CREATE INDEX IF NOT EXISTS idx_cka_task_attempts_scenario_id ON cka_task_attempts(scenario_id);

COMMIT;