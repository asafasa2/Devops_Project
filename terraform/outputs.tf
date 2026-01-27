# Output values for the infrastructure
output "environment" {
  description = "Current environment"
  value       = var.environment
}

output "app_network_id" {
  description = "Application network ID"
  value       = module.networks.app_network_id
}

output "monitoring_network_id" {
  description = "Monitoring network ID"
  value       = module.networks.monitoring_network_id
}

output "database_volume_name" {
  description = "Database volume name"
  value       = module.volumes.db_volume_name
}

output "jenkins_volume_name" {
  description = "Jenkins volume name"
  value       = module.volumes.jenkins_volume_name
}

output "service_endpoints" {
  description = "Service endpoint information"
  value = {
    web_frontend = "http://localhost:3000"
    api_gateway  = "http://localhost:4000"
    grafana      = "http://localhost:3001"
    jenkins      = "http://localhost:8080"
    kibana       = "http://localhost:5601"
  }
}