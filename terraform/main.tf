# Main Terraform configuration for DevOps Practice Environment
terraform {
  required_version = ">= 1.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# Configure the Docker Provider
provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Create networks for different environments
module "networks" {
  source = "./modules/networks"
  
  environment = var.environment
}

# Create volumes for persistent data
module "volumes" {
  source = "./modules/volumes"
  
  environment = var.environment
}

# Deploy application services
module "services" {
  source = "./modules/services"
  
  environment     = var.environment
  app_replicas   = var.app_replicas
  db_password    = var.db_password
  network_id     = module.networks.app_network_id
  db_volume_name = module.volumes.db_volume_name
  
  depends_on = [module.networks, module.volumes]
}