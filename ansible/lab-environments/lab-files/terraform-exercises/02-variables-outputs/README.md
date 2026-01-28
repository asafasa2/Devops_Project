# Lab 2: Terraform Variables and Outputs

## 🎯 Learning Objectives

- Define and use input variables effectively
- Understand variable types and validation
- Create meaningful output values
- Use variable files for different environments
- Implement local values for computed expressions

## 📋 Prerequisites

- Completed Lab 1: Basic Setup
- Understanding of Terraform resources and providers

## 🚀 Exercise Overview

In this lab, you'll create a flexible Terraform configuration using variables and outputs. You'll learn how to make your infrastructure code reusable across different environments and how to expose important information through outputs.

## 📝 Tasks

### Task 1: Define Input Variables

Create a comprehensive set of input variables for a web application stack.

1. **Create variables.tf:**

```hcl
# TODO: Define the following variables:
# - environment (string, with validation for dev/staging/prod)
# - app_name (string, default: "webapp")
# - app_port (number, default: 8080)
# - replicas (number, with validation 1-5)
# - enable_monitoring (bool, default: false)
# - tags (map of strings, default: {})
```

**Requirements:**
- Add descriptions for all variables
- Include appropriate default values
- Add validation rules where specified
- Use proper variable types

### Task 2: Create Environment-Specific Variable Files

Create variable files for different environments:

1. **Create dev.tfvars:**
```hcl
environment = "dev"
app_name    = "myapp-dev"
app_port    = 8080
replicas    = 1
enable_monitoring = false
tags = {
  Environment = "development"
  Team        = "platform"
  CostCenter  = "engineering"
}
```

2. **Create prod.tfvars:**
```hcl
environment = "prod"
app_name    = "myapp-prod"
app_port    = 80
replicas    = 3
enable_monitoring = true
tags = {
  Environment = "production"
  Team        = "platform"
  CostCenter  = "engineering"
  Backup      = "required"
}
```

### Task 3: Use Variables in Configuration

Update your main configuration to use the defined variables:

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

# TODO: Create local values for computed expressions
locals {
  # Create computed values like:
  # - container_name = "${var.app_name}-${var.environment}"
  # - common_labels = merge(var.tags, { ManagedBy = "terraform" })
}

# TODO: Create nginx image resource

# TODO: Create multiple container instances using count
# Use count = var.replicas to create multiple containers

# TODO: Conditionally create monitoring container
# Use count = var.enable_monitoring ? 1 : 0
```

### Task 4: Implement Local Values

Add local values to reduce repetition and improve readability:

```hcl
locals {
  container_name = "${var.app_name}-${var.environment}"
  
  common_labels = merge(var.tags, {
    ManagedBy   = "terraform"
    Application = var.app_name
    Environment = var.environment
  })
  
  port_mapping = {
    internal = 80
    external = var.app_port
  }
}
```

### Task 5: Create Multiple Resources with Count

Use the `count` meta-argument to create multiple container instances:

```hcl
resource "docker_container" "app" {
  count = var.replicas
  
  image = docker_image.nginx.image_id
  name  = "${local.container_name}-${count.index + 1}"
  
  ports {
    internal = local.port_mapping.internal
    external = local.port_mapping.external + count.index
  }
  
  dynamic "labels" {
    for_each = local.common_labels
    content {
      label = labels.key
      value = labels.value
    }
  }
  
  labels {
    label = "instance"
    value = tostring(count.index + 1)
  }
}
```

### Task 6: Conditional Resources

Create resources conditionally based on variable values:

```hcl
# Monitoring container (only if monitoring is enabled)
resource "docker_container" "monitoring" {
  count = var.enable_monitoring ? 1 : 0
  
  image = "prom/prometheus:latest"
  name  = "${local.container_name}-monitoring"
  
  ports {
    internal = 9090
    external = 9090
  }
  
  dynamic "labels" {
    for_each = local.common_labels
    content {
      label = labels.key
      value = labels.value
    }
  }
  
  labels {
    label = "role"
    value = "monitoring"
  }
}
```

### Task 7: Define Comprehensive Outputs

Create outputs.tf with meaningful output values:

```hcl
# TODO: Create outputs for:
# - Application URLs (list of all container URLs)
# - Container IDs (list of all container IDs)
# - Environment summary (object with key information)
# - Monitoring URL (conditional, only if monitoring enabled)
```

**Example structure:**
```hcl
output "application_urls" {
  description = "URLs to access the application instances"
  value = [
    for i in range(var.replicas) :
    "http://docker-daemon:${var.app_port + i}"
  ]
}

# Add more outputs here...
```

### Task 8: Test Variable Validation

Test your variable validation rules:

```bash
# Test with invalid environment
terraform plan -var="environment=invalid"

# Test with invalid replica count
terraform plan -var="replicas=10"

# Test with valid values
terraform plan -var-file="dev.tfvars"
```

### Task 9: Deploy Different Environments

Deploy and test different environment configurations:

```bash
# Deploy development environment
terraform apply -var-file="dev.tfvars"

# Check outputs
terraform output

# Test application access
curl http://docker-daemon:8080

# Clean up
terraform destroy -var-file="dev.tfvars"

# Deploy production environment
terraform apply -var-file="prod.tfvars"

# Check outputs and test multiple instances
terraform output
curl http://docker-daemon:80
curl http://docker-daemon:81
curl http://docker-daemon:82

# Check monitoring (if enabled)
curl http://docker-daemon:9090
```

### Task 10: Use Command Line Variables

Practice overriding variables using command line:

```bash
# Override specific variables
terraform plan -var-file="dev.tfvars" -var="replicas=2"

# Use environment variables
export TF_VAR_app_name="cli-override"
terraform plan -var-file="dev.tfvars"

# Test variable precedence
terraform plan -var-file="dev.tfvars" -var="app_name=command-line-override"
```

## 🎯 Validation Checklist

- [ ] All required variables are defined with proper types
- [ ] Variable validation rules work correctly
- [ ] Environment-specific tfvars files are created
- [ ] Local values reduce code repetition
- [ ] Multiple container instances are created using count
- [ ] Conditional resources work based on variables
- [ ] Comprehensive outputs provide useful information
- [ ] Different environments can be deployed successfully
- [ ] Variable precedence is understood and tested
- [ ] Command line variable overrides work correctly

## 🧠 Key Concepts Learned

1. **Variable Types:** string, number, bool, list, map, object
2. **Variable Validation:** Custom validation rules and error messages
3. **Variable Precedence:** Command line > tfvars > environment > defaults
4. **Local Values:** Computed expressions and reducing repetition
5. **Count Meta-Argument:** Creating multiple similar resources
6. **Conditional Resources:** Using count with boolean expressions
7. **Dynamic Blocks:** Creating repeated nested blocks
8. **Output Values:** Exposing important infrastructure information

## 📚 Additional Resources

- [Terraform Variables](https://www.terraform.io/language/values/variables)
- [Terraform Outputs](https://www.terraform.io/language/values/outputs)
- [Terraform Locals](https://www.terraform.io/language/values/locals)
- [Variable Validation](https://www.terraform.io/language/values/variables#custom-validation-rules)

## 🎉 Next Steps

Once you've completed this lab, move on to:
- **Lab 3:** State Management
- Practice with complex variable structures
- Explore workspace management

Excellent work mastering Terraform variables and outputs! 🚀