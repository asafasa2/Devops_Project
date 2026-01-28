# Outputs for Terraform Variables and Outputs Lab - Complete Solution

# Application URLs for all instances
output "application_urls" {
  description = "URLs to access the application instances"
  value = [
    for i in range(var.replicas) :
    "http://docker-daemon:${var.app_port + i}"
  ]
}

# Container IDs for all application instances
output "container_ids" {
  description = "IDs of all application containers"
  value = docker_container.app[*].id
}

# Container names for all application instances
output "container_names" {
  description = "Names of all application containers"
  value = docker_container.app[*].name
}

# Environment summary with key information
output "environment_summary" {
  description = "Summary of the deployed environment"
  value = {
    environment      = var.environment
    application_name = var.app_name
    replica_count    = var.replicas
    base_port        = var.app_port
    monitoring_enabled = var.enable_monitoring
    tags            = var.tags
  }
}

# Monitoring URL (conditional output)
output "monitoring_url" {
  description = "URL to access Prometheus monitoring (if enabled)"
  value       = var.enable_monitoring ? "http://docker-daemon:9090" : "Monitoring not enabled"
}

# Load balancer URL (conditional output)
output "loadbalancer_url" {
  description = "URL to access the load balancer (if multiple replicas)"
  value       = var.replicas > 1 ? "http://docker-daemon:${var.app_port + 100}" : "Load balancer not needed for single replica"
}

# Detailed container information
output "container_details" {
  description = "Detailed information about all containers"
  value = {
    application_containers = [
      for i, container in docker_container.app : {
        name       = container.name
        id         = container.id
        port       = var.app_port + i
        ip_address = container.network_data[0].ip_address
        status     = "running"
      }
    ]
    
    monitoring_container = var.enable_monitoring ? {
      name       = docker_container.monitoring[0].name
      id         = docker_container.monitoring[0].id
      port       = 9090
      ip_address = docker_container.monitoring[0].network_data[0].ip_address
      status     = "running"
    } : null
    
    loadbalancer_container = var.replicas > 1 ? {
      name       = docker_container.loadbalancer[0].name
      id         = docker_container.loadbalancer[0].id
      port       = var.app_port + 100
      ip_address = docker_container.loadbalancer[0].network_data[0].ip_address
      status     = "running"
    } : null
  }
}

# Resource counts
output "resource_counts" {
  description = "Count of different resource types created"
  value = {
    application_containers = var.replicas
    monitoring_containers  = var.enable_monitoring ? 1 : 0
    loadbalancer_containers = var.replicas > 1 ? 1 : 0
    total_containers       = var.replicas + (var.enable_monitoring ? 1 : 0) + (var.replicas > 1 ? 1 : 0)
  }
}

# Configuration validation output
output "configuration_validation" {
  description = "Validation of the current configuration"
  value = {
    environment_valid = contains(["dev", "staging", "prod"], var.environment)
    port_range_valid  = var.app_port >= 1024 && var.app_port <= 65535
    replica_count_valid = var.replicas >= 1 && var.replicas <= 5
    all_valid = (
      contains(["dev", "staging", "prod"], var.environment) &&
      var.app_port >= 1024 && var.app_port <= 65535 &&
      var.replicas >= 1 && var.replicas <= 5
    )
  }
}

# Sensitive output example (marked as sensitive)
output "internal_config" {
  description = "Internal configuration details (sensitive)"
  sensitive   = true
  value = {
    container_names = local.container_names
    common_labels   = local.common_labels
    port_mapping    = local.port_mapping
  }
}