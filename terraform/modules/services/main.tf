# Service container definitions
# This module defines the core application services

# PostgreSQL Database
resource "docker_container" "postgres" {
  name  = "${var.environment}-postgres"
  image = "postgres:15-alpine"
  
  env = [
    "POSTGRES_DB=devops_practice",
    "POSTGRES_USER=devops_user",
    "POSTGRES_PASSWORD=${var.db_password}",
    "PGDATA=/var/lib/postgresql/data/pgdata"
  ]
  
  ports {
    internal = 5432
    external = var.environment == "dev" ? 5432 : null
  }
  
  volumes {
    volume_name    = var.db_volume_name
    container_path = "/var/lib/postgresql/data"
  }
  
  networks_advanced {
    name = var.network_id
  }
  
  restart = "unless-stopped"
  
  labels {
    label = "environment"
    value = var.environment
  }
  
  labels {
    label = "service"
    value = "database"
  }
}

# Redis Cache
resource "docker_container" "redis" {
  name  = "${var.environment}-redis"
  image = "redis:7-alpine"
  
  command = ["redis-server", "--appendonly", "yes"]
  
  ports {
    internal = 6379
    external = var.environment == "dev" ? 6379 : null
  }
  
  networks_advanced {
    name = var.network_id
  }
  
  restart = "unless-stopped"
  
  labels {
    label = "environment"
    value = var.environment
  }
  
  labels {
    label = "service"
    value = "cache"
  }
}