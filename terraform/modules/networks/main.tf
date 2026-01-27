# Docker networks for service isolation
resource "docker_network" "app_network" {
  name = "${var.environment}-app-network"
  
  driver = "bridge"
  
  ipam_config {
    subnet  = var.app_subnet
    gateway = var.app_gateway
  }
  
  labels {
    label = "environment"
    value = var.environment
  }
  
  labels {
    label = "purpose"
    value = "application"
  }
}

resource "docker_network" "monitoring_network" {
  name = "${var.environment}-monitoring-network"
  
  driver = "bridge"
  
  ipam_config {
    subnet  = var.monitoring_subnet
    gateway = var.monitoring_gateway
  }
  
  labels {
    label = "environment"
    value = var.environment
  }
  
  labels {
    label = "purpose"
    value = "monitoring"
  }
}

resource "docker_network" "db_network" {
  name = "${var.environment}-db-network"
  
  driver = "bridge"
  
  ipam_config {
    subnet  = var.db_subnet
    gateway = var.db_gateway
  }
  
  labels {
    label = "environment"
    value = var.environment
  }
  
  labels {
    label = "purpose"
    value = "database"
  }
}