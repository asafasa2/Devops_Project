# Terraform Practice Lab Exercises

Welcome to the comprehensive Terraform learning environment! This lab provides hands-on exercises to master Infrastructure as Code with Terraform.

## 🎯 Learning Objectives

By completing these exercises, you will:
- Master Terraform fundamentals and workflow
- Learn to create and manage infrastructure resources
- Understand variables, outputs, and state management
- Build reusable modules for complex infrastructure
- Implement best practices for team collaboration

## 📚 Lab Structure

### 01-basic-setup
**Duration:** 60 minutes  
**Level:** Beginner  
Learn Terraform basics, workflow, and create your first resources.

### 02-variables-outputs
**Duration:** 75 minutes  
**Level:** Intermediate  
Master variables, outputs, and configuration flexibility.

### 03-state-management
**Duration:** 60 minutes  
**Level:** Intermediate  
Understand state management, remote backends, and team collaboration.

### 04-modules
**Duration:** 90 minutes  
**Level:** Advanced  
Create reusable modules and build modular infrastructure.

### 05-advanced
**Duration:** 120 minutes  
**Level:** Advanced  
Advanced patterns, best practices, and real-world scenarios.

## 🚀 Getting Started

1. **Access the workspace:**
   ```bash
   docker exec -it terraform-workspace bash
   ```

2. **Navigate to exercises:**
   ```bash
   cd /workspace
   ls -la
   ```

3. **Start with basic setup:**
   ```bash
   cd 01-basic-setup
   cat README.md
   ```

## 🛠️ Available Tools

- **Terraform:** Latest version with all providers
- **Docker:** For creating containerized infrastructure
- **terraform-docs:** Generate documentation
- **tflint:** Linting and validation
- **checkov:** Security scanning
- **MinIO:** S3-compatible backend for state storage

## 💡 Helpful Commands

- `tf` - terraform (alias)
- `tfi` - terraform init
- `tfp` - terraform plan
- `tfa` - terraform apply
- `tfd` - terraform destroy
- `tfv` - terraform validate
- `tff` - terraform fmt
- `lab-help` - Show available commands and exercises

## 🌐 Web Interface

Access the lab web interface at: http://localhost:3000

## 📖 Exercise Format

Each exercise includes:
- **README.md** - Detailed instructions and learning objectives
- **Template files** - Starting point configurations
- **Solution files** - Complete working examples
- **Validation scripts** - Check your progress

## 🎓 Completion Criteria

- Complete all tasks in each exercise
- Understand the concepts demonstrated
- Successfully deploy and manage infrastructure
- Clean up resources after each exercise

## 🆘 Getting Help

- Read the README.md in each exercise directory
- Use `terraform -help` for command help
- Check the web interface for additional resources
- Review solution files if you get stuck

Happy learning! 🚀