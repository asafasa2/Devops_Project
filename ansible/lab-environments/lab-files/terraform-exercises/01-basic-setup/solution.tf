# Terraform Basic Setup Lab - Complete Solution

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

# Docker image resource
resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}

# Docker container resource
resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name  = "nginx-lab"
  
  ports {
    internal = 80
    external = 8080
  }
  
  labels {
    label = "lab"
    value = "terraform-basic"
  }
  
  labels {
    label = "environment"
    value = "learning"
  }
}

# Additional container for advanced exercises
resource "docker_container" "nginx_backup" {
  image = docker_image.nginx.image_id
  name  = "nginx-backup"
  
  ports {
    internal = 80
    external = 8081
  }
  
  env = [
    "NGINX_HOST=localhost",
    "NGINX_PORT=80"
  ]
  
  labels {
    label = "lab"
    value = "terraform-basic"
  }
  
  labels {
    label = "role"
    value = "backup"
  }
}

# Outputs to display important information
output "nginx_container_id" {
  description = "ID of the nginx container"
  value       = docker_container.nginx.id
}

output "nginx_backup_container_id" {
  description = "ID of the nginx backup container"
  value       = docker_container.nginx_backup.id
}

output "nginx_ip_address" {
  description = "IP address of the nginx container"
  value       = docker_container.nginx.network_data[0].ip_address
}

output "access_urls" {
  description = "URLs to access the web servers"
  value = {
    primary = "http://docker-daemon:8080"
    backup  = "http://docker-daemon:8081"
  }
}