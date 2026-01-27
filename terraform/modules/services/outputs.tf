# Service module outputs
output "postgres_container_name" {
  description = "PostgreSQL container name"
  value       = docker_container.postgres.name
}

output "redis_container_name" {
  description = "Redis container name"
  value       = docker_container.redis.name
}