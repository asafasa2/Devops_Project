# Terraform Variables and Outputs Lab - Complete Solution

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

# Local values for computed expressions
locals {
  container_name = "${var.app_name}-${var.environment}"
  
  common_labels = merge(var.tags, {
    ManagedBy   = "terraform"
    Application = var.app_name
    Environment = var.environment
    Lab         = "variables-outputs"
  })
  
  port_mapping = {
    internal = 80
    external = var.app_port
  }
  
  # Generate container names with indices
  container_names = [
    for i in range(var.replicas) :
    "${local.container_name}-${i + 1}"
  ]
}

# Docker image resource
resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}

# Multiple application containers using count
resource "docker_container" "app" {
  count = var.replicas
  
  image = docker_image.nginx.image_id
  name  = local.container_names[count.index]
  
  ports {
    internal = local.port_mapping.internal
    external = local.port_mapping.external + count.index
  }
  
  # Resource limits from variable
  memory = var.container_config.memory_limit
  cpu_shares = tonumber(replace(var.container_config.cpu_limit, ".", "")) * 100
  restart = var.container_config.restart
  
  # Dynamic labels from local values
  dynamic "labels" {
    for_each = local.common_labels
    content {
      label = labels.key
      value = labels.value
    }
  }
  
  # Additional instance-specific labels
  labels {
    label = "instance"
    value = tostring(count.index + 1)
  }
  
  labels {
    label = "role"
    value = "application"
  }
  
  # Custom nginx configuration
  upload {
    content = templatefile("${path.module}/templates/nginx.conf.tpl", {
      server_name = "${var.app_name}-${count.index + 1}"
      port        = 80
    })
    file = "/etc/nginx/conf.d/default.conf"
  }
}

# Conditional monitoring container
resource "docker_container" "monitoring" {
  count = var.enable_monitoring ? 1 : 0
  
  image = "prom/prometheus:latest"
  name  = "${local.container_name}-monitoring"
  
  ports {
    internal = 9090
    external = 9090
  }
  
  # Dynamic labels from local values
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
  
  # Prometheus configuration
  upload {
    content = templatefile("${path.module}/templates/prometheus.yml.tpl", {
      targets = [
        for i in range(var.replicas) :
        "docker-daemon:${var.app_port + i}"
      ]
    })
    file = "/etc/prometheus/prometheus.yml"
  }
}

# Load balancer container (if multiple replicas)
resource "docker_container" "loadbalancer" {
  count = var.replicas > 1 ? 1 : 0
  
  image = "nginx:latest"
  name  = "${local.container_name}-lb"
  
  ports {
    internal = 80
    external = var.app_port + 100  # LB on different port
  }
  
  # Dynamic labels from local values
  dynamic "labels" {
    for_each = local.common_labels
    content {
      label = labels.key
      value = labels.value
    }
  }
  
  labels {
    label = "role"
    value = "loadbalancer"
  }
  
  # Load balancer configuration
  upload {
    content = templatefile("${path.module}/templates/lb-nginx.conf.tpl", {
      upstream_servers = [
        for i in range(var.replicas) :
        "docker-daemon:${var.app_port + i}"
      ]
    })
    file = "/etc/nginx/nginx.conf"
  }
}