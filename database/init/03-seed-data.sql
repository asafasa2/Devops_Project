-- Seed data for the DevOps Practice Environment
-- This script populates the database with sample learning content and test data

\c devops_practice;

-- Insert sample learning content for Docker
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Docker Fundamentals', 'module', 'docker', 'beginner', 
 '{"sections": [{"title": "What is Docker?", "content": "Docker is a containerization platform..."}, {"title": "Containers vs VMs", "content": "Containers are lightweight..."}], "objectives": ["Understand containerization", "Learn Docker basics"]}', 
 '{}', 45),

('Docker Commands Quiz', 'quiz', 'docker', 'beginner',
 '{"questions": [{"question": "What command creates a new container?", "options": ["docker run", "docker create", "docker start", "docker build"], "correct": 0}, {"question": "How do you list running containers?", "options": ["docker list", "docker ps", "docker show", "docker containers"], "correct": 1}]}',
 '{"Docker Fundamentals"}', 15),

('Docker Container Lab', 'lab', 'docker', 'beginner',
 '{"instructions": "Create and manage Docker containers", "tasks": ["Pull nginx image", "Run nginx container", "Access container shell"], "environment": "docker"}',
 '{"Docker Fundamentals"}', 30);

-- Insert sample learning content for Ansible
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Ansible Basics', 'module', 'ansible', 'beginner',
 '{"sections": [{"title": "Introduction to Ansible", "content": "Ansible is an automation tool..."}, {"title": "Playbooks and Tasks", "content": "Playbooks define automation..."}], "objectives": ["Understand configuration management", "Write basic playbooks"]}',
 '{}', 60),

('Ansible Playbook Quiz', 'quiz', 'ansible', 'intermediate',
 '{"questions": [{"question": "What format are Ansible playbooks written in?", "options": ["JSON", "YAML", "XML", "TOML"], "correct": 1}, {"question": "What is an Ansible inventory?", "options": ["A list of tasks", "A list of hosts", "A configuration file", "A playbook"], "correct": 1}]}',
 '{"Ansible Basics"}', 20),

('Ansible Configuration Lab', 'lab', 'ansible', 'intermediate',
 '{"instructions": "Configure servers using Ansible", "tasks": ["Write inventory file", "Create playbook", "Run playbook"], "environment": "ansible"}',
 '{"Ansible Basics"}', 45);

-- Insert sample learning content for Terraform
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('Infrastructure as Code with Terraform', 'module', 'terraform', 'intermediate',
 '{"sections": [{"title": "What is IaC?", "content": "Infrastructure as Code..."}, {"title": "Terraform Basics", "content": "Terraform uses HCL..."}], "objectives": ["Understand IaC principles", "Write Terraform configurations"]}',
 '{}', 75),

('Terraform Syntax Quiz', 'quiz', 'terraform', 'intermediate',
 '{"questions": [{"question": "What language does Terraform use?", "options": ["JSON", "YAML", "HCL", "Python"], "correct": 2}, {"question": "What command applies Terraform changes?", "options": ["terraform run", "terraform apply", "terraform deploy", "terraform execute"], "correct": 1}]}',
 '{"Infrastructure as Code with Terraform"}', 25),

('Terraform Infrastructure Lab', 'lab', 'terraform', 'advanced',
 '{"instructions": "Provision infrastructure with Terraform", "tasks": ["Write main.tf", "Initialize Terraform", "Plan and apply changes"], "environment": "terraform"}',
 '{"Infrastructure as Code with Terraform"}', 60);

-- Insert sample learning content for Jenkins
INSERT INTO learning.learning_content (title, content_type, tool_category, difficulty_level, content_data, prerequisites, estimated_duration) VALUES
('CI/CD with Jenkins', 'module', 'jenkins', 'intermediate',
 '{"sections": [{"title": "Continuous Integration", "content": "CI automates testing..."}, {"title": "Jenkins Pipelines", "content": "Pipelines define CI/CD workflows..."}], "objectives": ["Understand CI/CD", "Create Jenkins pipelines"]}',
 '{}', 90),

('Jenkins Pipeline Quiz', 'quiz', 'jenkins', 'intermediate',
 '{"questions": [{"question": "What is a Jenkins pipeline?", "options": ["A build script", "A workflow definition", "A test suite", "A deployment tool"], "correct": 1}, {"question": "What file defines a pipeline as code?", "options": ["pipeline.yml", "Jenkinsfile", "build.xml", "config.json"], "correct": 1}]}',
 '{"CI/CD with Jenkins"}', 30),

('Jenkins Pipeline Lab', 'lab', 'jenkins', 'advanced',
 '{"instructions": "Create and run Jenkins pipelines", "tasks": ["Write Jenkinsfile", "Configure pipeline", "Run build"], "environment": "jenkins"}',
 '{"CI/CD with Jenkins"}', 75);

-- Insert sample users for testing
INSERT INTO users.users (username, email, password_hash, learning_progress, current_level, total_points) VALUES
('demo_user', 'demo@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.PJ/..G', 
 '{"docker": {"completed_modules": 1, "quiz_scores": [80]}, "ansible": {"completed_modules": 0, "quiz_scores": []}}', 
 'beginner', 150),

('advanced_user', 'advanced@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.PJ/..G',
 '{"docker": {"completed_modules": 3, "quiz_scores": [90, 85]}, "ansible": {"completed_modules": 2, "quiz_scores": [95]}, "terraform": {"completed_modules": 1, "quiz_scores": [88]}}',
 'advanced', 750);

-- Insert sample assessment records
INSERT INTO assessments.assessments (user_id, content_id, score, max_score, completion_time, answers) VALUES
(1, 2, 80, 100, 180, '{"answers": [0, 1], "time_per_question": [45, 135]}'),
(2, 2, 90, 100, 120, '{"answers": [0, 1], "time_per_question": [30, 90]}'),
(2, 5, 95, 100, 240, '{"answers": [1, 1], "time_per_question": [60, 180]}'),
(2, 8, 88, 100, 300, '{"answers": [2, 1], "time_per_question": [90, 210]}');

-- Insert sample lab sessions
INSERT INTO labs.lab_sessions (user_id, lab_type, container_id, status, lab_data) VALUES
(1, 'docker', 'lab_container_001', 'completed', '{"tasks_completed": ["pull_image", "run_container"], "completion_time": 1800}'),
(2, 'ansible', 'lab_container_002', 'active', '{"tasks_completed": ["create_inventory"], "start_time": "2024-01-28T10:00:00Z"}'),
(2, 'terraform', 'lab_container_003', 'completed', '{"tasks_completed": ["write_config", "terraform_init", "terraform_apply"], "completion_time": 3600}');