# Network module outputs
output "app_network_id" {
  description = "Application network ID"
  value       = docker_network.app_network.id
}

output "app_network_name" {
  description = "Application network name"
  value       = docker_network.app_network.name
}

output "monitoring_network_id" {
  description = "Monitoring network ID"
  value       = docker_network.monitoring_network.id
}

output "monitoring_network_name" {
  description = "Monitoring network name"
  value       = docker_network.monitoring_network.name
}

output "db_network_id" {
  description = "Database network ID"
  value       = docker_network.db_network.id
}

output "db_network_name" {
  description = "Database network name"
  value       = docker_network.db_network.name
}