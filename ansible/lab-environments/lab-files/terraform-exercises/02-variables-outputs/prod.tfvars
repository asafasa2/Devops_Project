# Production Environment Configuration

environment = "prod"
app_name    = "myapp-prod"
app_port    = 80
replicas    = 3
enable_monitoring = true

tags = {
  Environment = "production"
  Team        = "platform"
  CostCenter  = "engineering"
  Owner       = "ops-team"
  Backup      = "required"
  Monitoring  = "enabled"
}

container_config = {
  memory_limit = "1g"
  cpu_limit    = "1.0"
  restart      = "always"
}