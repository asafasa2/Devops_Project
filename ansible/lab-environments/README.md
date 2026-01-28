# DevOps Practice Lab Environments

This directory contains comprehensive lab environments for hands-on DevOps learning and practice.

## 🚀 Available Lab Environments

### Ansible Practice Lab
**File:** `ansible-practice-lab.yml`  
**Script:** `start-ansible-lab.sh`  
**Focus:** Configuration management, automation, and infrastructure orchestration

**Features:**
- Ansible control node with all tools pre-installed
- Multiple managed nodes (Ubuntu, CentOS)
- Pre-configured SSH access and inventory
- Interactive learning modules and exercises
- Real-world scenarios and assessments

### Terraform Practice Lab
**File:** `terraform-practice-lab.yml`  
**Script:** `start-terraform-lab.sh`  
**Focus:** Infrastructure as Code, state management, and modular design

**Features:**
- Terraform workspace with latest tools
- Docker-in-Docker for provider testing
- MinIO S3-compatible backend for state storage
- Comprehensive exercises from basics to advanced
- Module development and best practices

## 🛠️ Quick Start

### Start Ansible Lab
```bash
cd ansible/lab-environments
./start-ansible-lab.sh
```

### Start Terraform Lab
```bash
cd ansible/lab-environments
./start-terraform-lab.sh
```

## 📚 Lab Structure

Each lab environment includes:

### Dockerfiles
Custom container images with pre-installed tools and configurations:
- `Dockerfile.ansible-control` - Ansible control node
- `Dockerfile.managed-node` - Target nodes for configuration
- `Dockerfile.terraform-workspace` - Terraform development environment
- `Dockerfile.terraform-lab-ui` - Web interface for exercises

### Lab Files
Organized learning materials:
```
lab-files/
├── exercises/          # Step-by-step hands-on exercises
├── templates/          # Configuration templates
├── assessments/        # Skills validation scenarios
└── interactive-modules/ # Web-based learning content
```

### Docker Compose Services
Complete environments with:
- Tool containers (Ansible, Terraform)
- Target infrastructure (managed nodes, Docker daemon)
- Supporting services (databases, monitoring)
- Web interfaces for enhanced learning

## 🎯 Learning Objectives

### Ansible Labs
- Master configuration management principles
- Learn playbook development and best practices
- Understand inventory management and variables
- Practice role development and reuse
- Implement automation workflows

### Terraform Labs
- Understand Infrastructure as Code concepts
- Master Terraform workflow and state management
- Learn variable management and outputs
- Develop reusable modules
- Implement remote state and team collaboration

## 🔧 Prerequisites

- Docker and Docker Compose installed
- Basic understanding of containerization
- Command line familiarity
- Text editor (vim, nano, or VS Code)

## 📖 Usage Instructions

### 1. Choose Your Lab
Select the appropriate lab based on your learning objectives:
- **Ansible** for configuration management and automation
- **Terraform** for infrastructure provisioning and IaC

### 2. Start the Environment
Use the provided startup scripts:
```bash
# For Ansible
./start-ansible-lab.sh

# For Terraform  
./start-terraform-lab.sh
```

### 3. Access the Workspace
Connect to the lab environment:
```bash
# Ansible control node
docker exec -it ansible-control bash

# Terraform workspace
docker exec -it terraform-workspace bash
```

### 4. Follow the Exercises
Navigate to the exercises directory and follow the README instructions:
```bash
cd /workspace  # or /ansible-workspace
ls -la
cat README.md
```

### 5. Clean Up
Stop and clean up when finished:
```bash
# Stop services
./start-ansible-lab.sh stop
./start-terraform-lab.sh stop

# Full cleanup (removes all data)
./start-ansible-lab.sh cleanup
./start-terraform-lab.sh cleanup
```

## 🌐 Web Interfaces

Both labs include web interfaces for enhanced learning:

- **Ansible Lab UI:** http://localhost:3000
- **Terraform Lab UI:** http://localhost:3000
- **MinIO Console:** http://localhost:9001 (Terraform lab)

## 🆘 Troubleshooting

### Common Issues

**Docker not running:**
```bash
# Start Docker service
sudo systemctl start docker
```

**Port conflicts:**
```bash
# Check port usage
netstat -tulpn | grep :3000

# Stop conflicting services or modify docker-compose.yml
```

**Permission issues:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Logout and login again
```

**Container startup failures:**
```bash
# Check logs
docker-compose logs [service-name]

# Rebuild containers
docker-compose build --no-cache
```

### Getting Help

1. Check the README.md in each exercise directory
2. Use the web interface for additional resources
3. Review Docker Compose logs for service issues
4. Consult the official documentation:
   - [Ansible Documentation](https://docs.ansible.com/)
   - [Terraform Documentation](https://www.terraform.io/docs/)

## 🎓 Completion and Assessment

### Progress Tracking
- Complete exercises in order
- Validate your work using provided scripts
- Review solution files when needed
- Practice with different scenarios

### Skills Assessment
- Comprehensive quizzes in the database
- Hands-on scenario-based assessments
- Real-world problem-solving exercises
- Best practices implementation

## 🚀 Next Steps

After completing the labs:
1. Practice with real cloud providers (AWS, Azure, GCP)
2. Integrate with CI/CD pipelines
3. Explore advanced topics like policy as code
4. Contribute to open-source projects
5. Pursue professional certifications

## 📝 Contributing

To add new exercises or improve existing ones:
1. Follow the established directory structure
2. Include comprehensive README files
3. Provide both templates and solutions
4. Test thoroughly in the lab environment
5. Update this documentation

Happy learning! 🎉