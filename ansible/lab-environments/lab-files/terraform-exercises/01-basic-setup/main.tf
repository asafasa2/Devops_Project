# Terraform Basic Setup Lab - Starting Template
# Complete this configuration by adding the missing resources

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

# TODO: Add Docker image resource for nginx:latest
# Hint: Use resource "docker_image" "nginx" { ... }

# TODO: Add Docker container resource
# Hint: Use resource "docker_container" "nginx" { ... }
# Requirements:
# - Use the nginx image from above
# - Name the container "nginx-lab"
# - Expose internal port 80 to external port 8080
# - Add labels for identification