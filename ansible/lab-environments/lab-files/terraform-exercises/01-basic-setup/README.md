# Lab 1: Terraform Basic Setup and Resources

## 🎯 Learning Objectives

- Install and configure Terraform
- Understand Terraform workflow (init, plan, apply, destroy)
- Create basic Docker resources
- Manage resource lifecycle
- Understand state management basics

## 📋 Prerequisites

- Basic understanding of containerization
- Familiarity with command line interface

## 🚀 Exercise Overview

In this lab, you'll create your first Terraform configuration to manage Docker containers. You'll learn the fundamental Terraform workflow and understand how Terraform tracks infrastructure state.

## 📝 Tasks

### Task 1: Verify Environment Setup

First, let's verify that Terraform and Docker are properly configured.

```bash
# Check Terraform version
terraform version

# Check Docker connectivity
docker --host tcp://docker-daemon:2376 ps

# Check available providers
terraform providers
```

**Expected Output:**
- Terraform version should be displayed
- Docker should connect successfully
- Provider registry should be accessible

### Task 2: Create Your First Configuration

Create a basic Terraform configuration for Docker resources.

1. **Create main.tf:**

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "tcp://docker-daemon:2376"
}

# TODO: Add Docker image resource here

# TODO: Add Docker container resource here
```

2. **Your tasks:**
   - Add a Docker image resource for `nginx:latest`
   - Add a Docker container resource using the image
   - Configure the container to expose port 80 on port 8080
   - Add appropriate resource names and labels

### Task 3: Initialize Terraform

Initialize your Terraform working directory:

```bash
terraform init
```

**What happens:**
- Downloads required providers
- Creates `.terraform` directory
- Creates `.terraform.lock.hcl` file

**Explore:**
```bash
ls -la
cat .terraform.lock.hcl
```

### Task 4: Plan Your Infrastructure

Create an execution plan:

```bash
terraform plan
```

**Analyze the output:**
- What resources will be created?
- What are the resource attributes?
- Are there any dependencies?

**Save the plan:**
```bash
terraform plan -out=tfplan
```

### Task 5: Apply Configuration

Apply your configuration to create resources:

```bash
terraform apply
```

Or use the saved plan:
```bash
terraform apply tfplan
```

**Verify resources:**
```bash
# Check Terraform state
terraform state list

# Check Docker containers
docker --host tcp://docker-daemon:2376 ps

# Test the web server
curl http://docker-daemon:8080
```

### Task 6: Inspect State and Resources

Explore Terraform state management:

```bash
# List all resources in state
terraform state list

# Show detailed resource information
terraform state show docker_container.nginx

# View the state file
cat terraform.tfstate
```

**Questions to consider:**
- What information is stored in the state file?
- How does Terraform track resource relationships?
- What happens if the state file is lost?

### Task 7: Modify Your Configuration

Make changes to your configuration and observe the update process:

1. **Add environment variables to your container:**

```hcl
resource "docker_container" "nginx" {
  # ... existing configuration ...
  
  env = [
    "NGINX_HOST=localhost",
    "NGINX_PORT=80"
  ]
}
```

2. **Plan and apply the changes:**

```bash
terraform plan
terraform apply
```

**Observe:**
- What type of change is Terraform making?
- Is the container replaced or updated in-place?

### Task 8: Add More Resources

Extend your configuration with additional resources:

1. **Add a second container:**

```hcl
resource "docker_container" "nginx_backup" {
  image = docker_image.nginx.image_id
  name  = "nginx-backup"
  
  ports {
    internal = 80
    external = 8081
  }
}
```

2. **Add outputs to display important information:**

```hcl
output "nginx_container_id" {
  description = "ID of the nginx container"
  value       = docker_container.nginx.id
}

output "nginx_ip_address" {
  description = "IP address of the nginx container"
  value       = docker_container.nginx.network_data[0].ip_address
}
```

3. **Apply the changes:**

```bash
terraform plan
terraform apply
```

### Task 9: Understand Dependencies

Observe how Terraform handles resource dependencies:

```bash
# View the dependency graph
terraform graph

# Show resources in dependency order
terraform state list
```

**Questions:**
- Which resources depend on others?
- How does Terraform determine the creation order?

### Task 10: Clean Up Resources

Learn how to destroy infrastructure:

```bash
# Plan the destruction
terraform plan -destroy

# Destroy all resources
terraform destroy
```

**Verify cleanup:**
```bash
terraform state list
docker --host tcp://docker-daemon:2376 ps
```

## 🎯 Validation Checklist

- [ ] Terraform is properly installed and configured
- [ ] Docker provider is working correctly
- [ ] Basic configuration creates nginx container successfully
- [ ] Container is accessible on configured port
- [ ] State file tracks all resources correctly
- [ ] Configuration changes are applied successfully
- [ ] Additional resources can be added and managed
- [ ] Resource dependencies are understood
- [ ] Infrastructure can be destroyed cleanly

## 🧠 Key Concepts Learned

1. **Terraform Workflow:** init → plan → apply → destroy
2. **Provider Configuration:** How to configure and use providers
3. **Resource Definition:** Syntax and structure of resources
4. **State Management:** How Terraform tracks infrastructure
5. **Resource Dependencies:** Implicit and explicit dependencies
6. **Configuration Changes:** How Terraform handles updates

## 📚 Additional Resources

- [Terraform Docker Provider Documentation](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs)
- [Terraform Configuration Language](https://www.terraform.io/language)
- [Terraform State](https://www.terraform.io/language/state)

## 🎉 Next Steps

Once you've completed this lab, move on to:
- **Lab 2:** Variables and Outputs
- Practice with different providers
- Explore Terraform documentation

Great job completing your first Terraform lab! 🚀